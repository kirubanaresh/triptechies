require('dotenv').config();
const mysql = require('mysql2/promise');

(async () => {
  try {
    console.log('DB Config:', {
      host: process.env.DB_HOST,
      user: process.env.DB_USER,
      password: process.env.DB_PASSWORD ? '[SET]' : '[MISSING]',
      database: process.env.DB_NAME
    });
    
    const pool = mysql.createPool({
      host: process.env.DB_HOST,
      user: process.env.DB_USER,
      password: process.env.DB_PASSWORD,
      database: process.env.DB_NAME
    });
    
    const [users] = await pool.execute("SELECT * FROM drivers WHERE username = 'rokesh'");
    console.log('✅ Found users:', users.length);
    console.log('First user:', users[0]);
    
    const bcrypt = require('bcrypt');
    const isValid = await bcrypt.compare('123456', users[0].password_hash);
    console.log('✅ Password valid:', isValid);
    
    process.exit(0);
  } catch (e) {
    console.log('❌ ERROR:', e.message);
    process.exit(1);
  }
})();
