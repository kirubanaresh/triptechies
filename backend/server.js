const http = require('http');
const socketIo = require('socket.io');
require('dotenv').config();
const express = require('express');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcrypt');
const cors = require('cors');
const QRCode = require('qrcode');
const pool = require('./db');
const connectMongoDB = require('./db-mongo.js');
const LocationLog = require('./models/LocationLog.js');

const app = express();
const server = http.createServer(app);
const io = socketIo(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"]
  }
});

const JWT_SECRET = process.env.JWT_SECRET || 'your_jwt_secret_here';

// Connect MongoDB
connectMongoDB();

app.use(cors());
app.use(express.json());

// JWT middleware
const authenticateJWT = (req, res, next) => {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Authorization header missing' });
  }

  const token = authHeader.split(' ')[1];
  jwt.verify(token, JWT_SECRET, (err, decoded) => {
    if (err) return res.status(401).json({ error: 'Invalid token' });
    req.user = decoded;
    next();
  });
};

// Health check
app.get('/', (req, res) => {
  res.json({ message: 'Smart Bus Tracking API - Ready!' });
});

// Socket.io connection (Upstream)
io.on('connection', (socket) => {
  console.log('New client connected:', socket.id);

  socket.on('join_bus', (busId) => {
    socket.join(busId);
    console.log(`Socket ${socket.id} joined bus room: ${busId}`);
  });

  socket.on('disconnect', () => {
    console.log('Client disconnected:', socket.id);
  });
});

// Customer login (simple)
app.post('/api/customer/login', async (req, res) => {
  try {
    const { phone } = req.body;
    if (!phone) return res.status(400).json({ error: 'Phone required' });

    const token = jwt.sign({ phone, role: 'customer' }, JWT_SECRET, { expiresIn: '24h' });
    res.json({ token, role: 'customer' });
  } catch (err) {
    res.status(500).json({ error: 'Login failed' });
  }
});

// Worker login
app.post('/api/auth/login', async (req, res) => {
  try {
    console.log('🔑 Login attempt:', req.body.username, req.body.password ? '[HIDDEN]' : 'MISSING');
    const { username, password } = req.body;
    if (!username || !password)
      return res.status(400).json({ error: 'Username and password required' });

    const [users] = await pool.execute(
      'SELECT id, username, password_hash, role FROM drivers WHERE username = ?',
      [username]
    );
    console.log('👥 Found users:', users.length);
    if (users.length === 0)
      return res.status(401).json({ error: 'Invalid credentials' });

    const user = users[0];
    const valid = await bcrypt.compare(password, user.password_hash);
    console.log('🔓 Password check:', valid);
    if (!valid) return res.status(401).json({ error: 'Invalid credentials' });

    const token = jwt.sign({ username: user.username, role: user.role }, JWT_SECRET, { expiresIn: '12h' });
    console.log('✅ Login SUCCESS:', user.username);
    res.json({ token, role: user.role, name: user.username });
  } catch (err) {
    console.error('Login error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

// Worker registration + QR code
app.post('/api/auth/register', async (req, res) => {
  try {
    const { username, password, name, bus_registration, contact, role } = req.body;

    if (!username || !password || !bus_registration) {
      return res.status(400).json({
        success: false,
        message: 'username, password, bus_registration required',
      });
    }

    const password_hash = await bcrypt.hash(password, 10);
    const qrPayload = `bus:${bus_registration}`;
    const qrCode = await QRCode.toDataURL(qrPayload);

    const [result] = await pool.execute(
      `INSERT INTO drivers (username, password_hash, name, bus_registration, contact, role)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [username, password_hash, name || null, bus_registration, contact || null, role || 'conductor']
    );

    return res.json({
      success: true,
      driverId: result.insertId,
      bus_registration,
      qrCode,
      message: 'Worker registered & QR generated',
    });
  } catch (err) {
    console.error('Register error:', err);
    if (err.code === 'ER_DUP_ENTRY') {
      return res.status(409).json({ success: false, message: 'Username or bus already exists' });
    }
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// Update bus location (worker only)
app.post('/api/driver/update_location', authenticateJWT, async (req, res) => {
  try {
    if (req.user.role !== 'conductor' && req.user.role !== 'driver')
      return res.status(403).json({ error: 'Access denied' });

    const { busRegistration, route, destination, latitude, longitude, crowding } = req.body;
    if (!busRegistration || !route || !destination)
      return res.status(400).json({ error: 'Required fields missing' });

    const sql = `
      INSERT INTO bus_status (bus_registration, route, destination, latitude, longitude, crowding)
      VALUES (?, ?, ?, ?, ?, ?)
      ON DUPLICATE KEY UPDATE
        route = VALUES(route),
        destination = VALUES(destination),
        latitude = VALUES(latitude),
        longitude = VALUES(longitude),
        crowding = VALUES(crowding),
        updated_at = CURRENT_TIMESTAMP
    `;

    await pool.execute(sql, [busRegistration, route, destination, latitude, longitude, crowding]);

    // Save history to MongoDB (Async) - KEPT FROM STASH
    const log = new LocationLog({
      busId: busRegistration,
      routeId: route,
      latitude,
      longitude,
      occupancy: crowding
    });
    log.save().catch(err => console.error('Mongo Log Error:', err));

    // Emit live update via Socket.io - KEPT FROM STASH
    io.to(busRegistration).emit('bus_update', {
      busRegistration,
      latitude,
      longitude,
      crowding,
      updatedAt: new Date()
    });

    res.json({ success: true, message: 'Bus location updated' });
  } catch (err) {
    console.error('Update error:', err);
    res.status(500).json({ error: 'Database error' });
  }
});

// Create route & QR (KEPT FROM STASH)
app.post('/api/routes/create', authenticateJWT, async (req, res) => {
  try {
    const { busRegistration, from_location, to_location, departure_time, arrival_time, stops } = req.body;

    const qrData = `bus:${busRegistration}|route:${from_location}-${to_location}`;
    const qrCode = await QRCode.toDataURL(qrData);

    const [result] = await pool.execute(
      'INSERT INTO routes (bus_registration, from_location, to_location, departure_time, arrival_time, stops, qr_code, created_by) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
      [busRegistration, from_location, to_location, departure_time, arrival_time, JSON.stringify(stops || []), qrCode, req.user.username]
    );

    res.json({
      success: true,
      routeId: result.insertId,
      qrCode,
      message: 'Route created & QR generated'
    });
  } catch (err) {
    console.error('Route creation error:', err);
    res.status(500).json({ error: 'Failed to create route' });
  }
});

// Search routes by from/to
app.get('/api/routes/search', async (req, res) => {
  try {
    const { from, to } = req.query;
    if (!from || !to) return res.status(400).json({ success: false, message: 'from and to are required' });

    const sql = `
      SELECT r.id, r.bus_registration, r.from_location, r.to_location, r.departure_time, r.arrival_time, r.stops,
             b.route AS live_route, b.destination, b.latitude, b.longitude, b.crowding, b.updated_at
      FROM routes r
      LEFT JOIN bus_status b ON r.bus_registration = b.bus_registration
      WHERE LOWER(r.from_location) = LOWER(?) AND LOWER(r.to_location) = LOWER(?)
      ORDER BY r.departure_time ASC
    `;

    const [rows] = await pool.execute(sql, [from, to]);
    res.json({ success: true, count: rows.length, data: rows });
  } catch (err) {
    console.error('Route search error:', err);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// Basic bus status
app.get('/api/bus/:busRegistration', async (req, res) => {
  try {
    const { busRegistration } = req.params;
    const [rows] = await pool.execute(
      'SELECT * FROM bus_status WHERE bus_registration = ? ORDER BY updated_at DESC LIMIT 1',
      [busRegistration]
    );

    if (rows.length === 0) return res.status(404).json({ error: 'Bus not found' });
    res.json(rows[0]);
  } catch (err) {
    console.error('Bus fetch error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

// Full bus details (NEW FROM UPSTREAM)
app.get('/api/bus/details/:busRegistration', async (req, res) => {
  try {
    const { busRegistration } = req.params;

    const [routesRows] = await pool.execute(
      `SELECT id, bus_registration, from_location, to_location, departure_time, arrival_time, stops
       FROM routes WHERE bus_registration = ? ORDER BY created_at DESC LIMIT 1`,
      [busRegistration]
    );

    const [statusRows] = await pool.execute(
      `SELECT route, destination, latitude, longitude, crowding, updated_at
       FROM bus_status WHERE bus_registration = ? ORDER BY updated_at DESC LIMIT 1`,
      [busRegistration]
    );

    if (routesRows.length === 0) {
      return res.status(404).json({ success: false, message: 'No route found for this bus' });
    }

    res.json({
      success: true,
      route: routesRows[0],
      status: statusRows[0] || null,
    });
  } catch (err) {
    console.error('Bus details error:', err);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// Mock Weather & Accessories API (KEPT FROM STASH)
app.get('/api/weather', (req, res) => {
  const { location } = req.query;
  const conditions = ['Sunny', 'Rainy', 'Cloudy', 'High AQI', 'Cold'];
  const condition = conditions[Math.floor(Math.random() * conditions.length)];
  let temp = 25;
  let accessories = [];
  let warning = null;

  switch (condition) {
    case 'Rainy': temp = 20; accessories = ['Umbrella', 'Raincoat', 'Waterproof Shoes']; warning = 'Heavy rain expected. Delay probable.'; break;
    case 'Sunny': temp = 35; accessories = ['Sunglasses', 'Sunscreen', 'Water Bottle']; break;
    case 'Cold': temp = 10; accessories = ['Jacket', 'Sweater', 'Scarf']; break;
    case 'High AQI': temp = 28; accessories = ['N95 Mask', 'Air Purifier (Home)']; warning = 'Air Quality is Poor. Wear a mask.'; break;
    default: accessories = ['Water Bottle'];
  }

  res.json({ location: location || 'Unknown', temperature: temp, condition, accessories, warning });
});

// SOS Alert (KEPT FROM STASH)
app.post('/api/sos', (req, res) => {
  const { busRegistration, location, userId } = req.body;
  console.log('🆘 SOS ALERT RECEIVED:', { busRegistration, location, userId });
  io.emit('sos_alert', { message: 'EMERGENCY ALERT', busRegistration, location, timestamp: new Date() });
  res.json({ success: true, message: 'SOS Alert Sent!' });
});

// Cleanliness Feedback (KEPT FROM STASH)
app.post('/api/feedback', (req, res) => {
  const { busRegistration, rating, comments } = req.body;
  console.log('⭐ Feedback:', { busRegistration, rating, comments });
  res.json({ success: true, message: 'Feedback received' });
});

// Helper: Find Routes (KEPT FROM STASH)
async function findBusRoute(from, to) {
  try {
    const [direct] = await pool.execute(
      `SELECT * FROM routes WHERE from_location LIKE ? AND to_location LIKE ?`,
      [`%${from}%`, `%${to}%`]
    );
    if (direct.length > 0) return { type: 'direct', routes: direct };

    const [indirect] = await pool.execute(
      `SELECT 
        r1.bus_registration as bus1, r1.to_location as transfer, r1.departure_time as dep1, r1.arrival_time as arr1,
        r2.bus_registration as bus2, r2.departure_time as dep2, r2.arrival_time as arr2
       FROM routes r1 
       JOIN routes r2 ON r1.to_location = r2.from_location 
       WHERE r1.from_location LIKE ? AND r2.to_location LIKE ?`,
      [`%${from}%`, `%${to}%`]
    );
    if (indirect.length > 0) return { type: 'indirect', routes: indirect };
    return { type: 'none', routes: [] };
  } catch (err) {
    console.error("Route Find Error:", err);
    return { type: 'error', routes: [] };
  }
}

// Chatbot API (KEPT FROM STASH)
app.post('/api/chat', async (req, res) => {
  const { message, language } = req.body;
  const lang = language || 'en';
  const lowerMsg = message.toLowerCase();

  const phrases = {
    en: { greeting: "Hello! I can help you find buses, check weather, or track your ride.", unknown: "I didn't understand. Try 'Bus from X to Y' or 'Weather'." },
    ta: { greeting: "வணக்கம்! பேருந்துகளைக் கண்டறிய நான் உதவ முடியும்.", unknown: "புரியவில்லை. 'X இல் இருந்து Y வரை பேருந்து' என்று முயற்சிக்கவும்." },
    hi: { greeting: "नमस्ते! मैं आपको बसें खोजने में मदद कर सकता हूँ।", unknown: "समझ नहीं आया। कृपया 'X से Y तक बस' आज़माएं।" },
    fr: { greeting: "Bonjour! Je peux vous aider à trouver des bus.", unknown: "Je n'ai pas compris. Essayez 'Bus de X à Y'." },
    de: { greeting: "Hallo! Ich kann Ihnen helfen, Busse zu finden.", unknown: "Ich habe nicht verstanden. Versuchen Sie 'Bus von X nach Y'." }
  };

  let reply = phrases[lang]?.greeting || phrases['en'].greeting;
  let data = null;

  try {
    if (lowerMsg.includes('bus') && lowerMsg.includes('from') && lowerMsg.includes('to')) {
      const parts = lowerMsg.split(/from|to/);
      if (parts.length >= 3) {
        const from = parts[1].trim();
        const to = parts[2].trim();
        reply = `Searching buses from ${from} to ${to}...`;
        const result = await findBusRoute(from, to);
        if (result.type === 'direct') {
          reply = `Found ${result.routes.length} direct buses from ${from} to ${to}.`;
          data = { type: 'route_list', routes: result.routes };
        } else if (result.type === 'indirect') {
          reply = `No direct bus found. Found connecting routes via ${result.routes[0].transfer}.`;
          data = { type: 'route_indirect', routes: result.routes };
        } else {
          reply = `Sorry, no buses found between ${from} and ${to}.`;
        }
      }
    } else if (lowerMsg.includes('weather') || lowerMsg.includes('climate')) {
      reply = "Weather is currently Sunny, 32°C. Wear sunglasses!";
    } else if (lowerMsg.includes('sos') || lowerMsg.includes('help')) {
      reply = "SOS Alert Triggered! Sending location to emergency contacts.";
      io.emit('sos_alert', { message: 'USER REQUESTED HELP', timestamp: new Date() });
    } else {
      reply = phrases[lang]?.unknown || phrases['en'].unknown;
    }
  } catch (e) {
    console.error("Chat Logic Error", e);
    reply = "My brain is having trouble right now. Try again later.";
  }
  res.json({ reply, data });
});

// Worker profile (KEPT FROM STASH)
app.get('/api/driver/profile', authenticateJWT, async (req, res) => {
  try {
    const [rows] = await pool.execute(
      'SELECT username, name, bus_registration, contact, role FROM drivers WHERE username = ?',
      [req.user.username]
    );
    if (rows.length === 0) return res.status(404).json({ error: 'Profile not found' });
    res.json(rows[0]);
  } catch (err) {
    res.status(500).json({ error: 'Profile fetch failed' });
  }
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log(`🚀 Server running on http://localhost:${PORT}`);
  console.log(`📱 Emulator: http://10.0.2.2:${PORT}`);
  console.log(`🌐 Host: http://10.177.163.159:${PORT}`);
});
