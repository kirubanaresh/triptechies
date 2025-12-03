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
  if (!authHeader || !authHeader.startsWith('Bearer '))
    return res.status(401).json({ error: 'Authorization header missing' });

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

// Customer login (simple - no password for demo)
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
    res.json({ success: true, message: 'Bus location updated' });
  } catch (err) {
    console.error('Update error:', err);
    res.status(500).json({ error: 'Database error' });
  }
});

// Get bus info by registration (public)
app.get('/api/bus/:busRegistration', async (req, res) => {
  try {
    const { busRegistration } = req.params;
    const [rows] = await pool.execute(
      'SELECT * FROM bus_status WHERE bus_registration = ? ORDER BY updated_at DESC LIMIT 1', 
      [busRegistration]
    );
    
    if (rows.length === 0) 
      return res.status(404).json({ error: 'Bus not found' });
    
    res.json(rows[0]);
  } catch (err) {
    console.error('Bus fetch error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

// Create route & generate QR (worker)
app.post('/api/routes/create', authenticateJWT, async (req, res) => {
  try {
    const { busRegistration, from_location, to_location, departure_time, arrival_time, stops } = req.body;
    
    const qrData = `bus:${busRegistration}|route:${from_location}-${to_location}`;
    const qrCode = await QRCode.toDataURL(qrData);
    
    const [result] = await pool.execute(
      'INSERT INTO routes (bus_registration, from_location, to_location, departure_time, arrival_time, stops, qr_code, created_by) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
      [busRegistration, from_location, to_location, departure_time, arrival_time, JSON.stringify(stops), qrCode, req.user.username]
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

// Get worker profile
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
app.listen(PORT, () => {
  console.log(`🚀 Server running on http://localhost:${PORT}`);
  console.log(`📱 Emulator: http://10.0.2.2:${PORT}`);
});
