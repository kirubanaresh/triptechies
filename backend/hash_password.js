const bcrypt = require('bcrypt');

async function generateHash(password) {
  const hash = await bcrypt.hash(password, 10);
  console.log(`Plain password: ${password}`);
  console.log(`Hash: ${hash}`);
}

generateHash('kiruba123');
