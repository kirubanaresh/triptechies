require('dotenv').config();
const express = require('express');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcrypt');
const cors = require('cors');
const QRCode = require('qrcode');
const pool = require('./db');

const app = express();
const JWT_SECRET = process.env.JWT_SECRET || 'your_jwt_secret_here';

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

// Customer login (simple)
app.post('/api/customer/login', async (req, res) => {
  try {
    const { phone } = req.body;
    if (!phone) return res.status(400).json({ error: 'Phone required' });

    const token = jwt.sign({ phone, role: 'customer' }, JWT_SECRET, {
      expiresIn: '24h',
    });
    res.json({ token, role: 'customer' });
  } catch (err) {
    res.status(500).json({ error: 'Login failed' });
  }
});

// Worker login
app.post('/api/auth/login', async (req, res) => {
  try {
    console.log(
      '🔑 Login attempt:',
      req.body.username,
      req.body.password ? '[HIDDEN]' : 'MISSING',
    );
    const { username, password } = req.body;
    if (!username || !password)
      return res
        .status(400)
        .json({ error: 'Username and password required' });

    const [users] = await pool.execute(
      'SELECT id, username, password_hash, role FROM drivers WHERE username = ?',
      [username],
    );
    console.log('👥 Found users:', users.length);
    if (users.length === 0)
      return res.status(401).json({ error: 'Invalid credentials' });

    const user = users[0];
    const valid = await bcrypt.compare(password, user.password_hash);
    console.log('🔓 Password check:', valid);
    if (!valid) return res.status(401).json({ error: 'Invalid credentials' });

    const token = jwt.sign(
      { username: user.username, role: user.role },
      JWT_SECRET,
      { expiresIn: '12h' },
    );
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
    const {
      username,
      password,
      name,
      bus_registration,
      contact,
      role, // 'driver' or 'conductor'
    } = req.body;

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
      [
        username,
        password_hash,
        name || null,
        bus_registration,
        contact || null,
        role || 'conductor',
      ],
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
      return res.status(409).json({
        success: false,
        message: 'Username or bus already exists',
      });
    }
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// Update bus location (worker only)
app.post('/api/driver/update_location', authenticateJWT, async (req, res) => {
  try {
    if (req.user.role !== 'conductor' && req.user.role !== 'driver')
      return res.status(403).json({ error: 'Access denied' });

    const {
      busRegistration,
      route,
      destination,
      latitude,
      longitude,
      crowding,
    } = req.body;
    if (!busRegistration || !route || !destination)
      return res
        .status(400)
        .json({ error: 'Required fields missing' });

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

    await pool.execute(sql, [
      busRegistration,
      route,
      destination,
      latitude,
      longitude,
      crowding,
    ]);
    res.json({ success: true, message: 'Bus location updated' });
  } catch (err) {
    console.error('Update error:', err);
    res.status(500).json({ error: 'Database error' });
  }
});

// Create route & QR
app.post('/api/routes/create', authenticateJWT, async (req, res) => {
  try {
    const {
      busRegistration,
      from_location,
      to_location,
      departure_time,
      arrival_time,
      stops,
    } = req.body;

    if (!busRegistration || !from_location || !to_location) {
      return res.status(400).json({
        success: false,
        message: 'Missing required fields',
      });
    }

    const stopsJson = JSON.stringify(stops || []);

    const qrData = `bus:${busRegistration}|route:${from_location}-${to_location}`;
    const qrCode = await QRCode.toDataURL(qrData);

    const [result] = await pool.execute(
      `INSERT INTO routes
       (bus_registration, from_location, to_location,
        departure_time, arrival_time, stops, qr_code, created_by)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        busRegistration,
        from_location,
        to_location,
        departure_time,
        arrival_time,
        stopsJson,
        qrCode,
        req.user.username,
      ],
    );

    res.json({
      success: true,
      routeId: result.insertId,
      qrCode,
      message: 'Route created & QR generated',
    });
  } catch (err) {
    console.error('Route creation error:', err);
    res
      .status(500)
      .json({ success: false, message: 'Failed to create route' });
  }
});

// Search routes by from/to
app.get('/api/routes/search', async (req, res) => {
  try {
    const { from, to } = req.query;

    if (!from || !to) {
      return res.status(400).json({
        success: false,
        message: 'from and to are required',
      });
    }

    const sql = `
      SELECT 
        r.id,
        r.bus_registration,
        r.from_location,
        r.to_location,
        r.departure_time,
        r.arrival_time,
        r.stops,
        b.route AS live_route,
        b.destination,
        b.latitude,
        b.longitude,
        b.crowding,
        b.updated_at
      FROM routes r
      LEFT JOIN bus_status b
        ON r.bus_registration = b.bus_registration
      WHERE 
        LOWER(r.from_location) = LOWER(?)
        AND LOWER(r.to_location) = LOWER(?)
      ORDER BY r.departure_time ASC
    `;

    const [rows] = await pool.execute(sql, [from, to]);

    res.json({ success: true, count: rows.length, data: rows });
  } catch (err) {
    console.error('Route search error:', err);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// Worker profile
app.get('/api/driver/profile', authenticateJWT, async (req, res) => {
  try {
    const [rows] = await pool.execute(
      'SELECT username, name, bus_registration, contact, role FROM drivers WHERE username = ?',
      [req.user.username],
    );
    if (rows.length === 0)
      return res.status(404).json({ error: 'Profile not found' });
    res.json(rows[0]);
  } catch (err) {
    res.status(500).json({ error: 'Profile fetch failed' });
  }
});

// Basic bus status (by registration)
app.get('/api/bus/:busRegistration', async (req, res) => {
  try {
    const { busRegistration } = req.params;
    const [rows] = await pool.execute(
      'SELECT * FROM bus_status WHERE bus_registration = ? ORDER BY updated_at DESC LIMIT 1',
      [busRegistration],
    );

    if (rows.length === 0)
      return res.status(404).json({ error: 'Bus not found' });

    res.json(rows[0]);
  } catch (err) {
    console.error('Bus fetch error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

// Full bus details (route + status)
app.get('/api/bus/details/:busRegistration', async (req, res) => {
  try {
    const { busRegistration } = req.params;

    const [routesRows] = await pool.execute(
      `SELECT id, bus_registration, from_location, to_location,
              departure_time, arrival_time, stops
       FROM routes
       WHERE bus_registration = ?
       ORDER BY created_at DESC
       LIMIT 1`,
      [busRegistration],
    );

    const [statusRows] = await pool.execute(
      `SELECT route, destination, latitude, longitude, crowding, updated_at
       FROM bus_status
       WHERE bus_registration = ?
       ORDER BY updated_at DESC
       LIMIT 1`,
      [busRegistration],
    );

    if (routesRows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'No route found for this bus',
      });
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

// START SERVER LAST
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`🚀 Server running on http://localhost:${PORT}`);
  console.log(`📱 Emulator: http://10.0.2.2:${PORT}`);
});
