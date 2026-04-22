const mysql = require('mysql2/promise');

// โหลด .env เฉพาะตอน local
if (process.env.NODE_ENV !== 'production') {
  require('dotenv').config();
}

const pool = mysql.createPool({
  host: process.env.DB_HOST,
  port: parseInt(process.env.DB_PORT),
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  waitForConnections: true,
  connectionLimit: 10,
  charset: 'utf8mb4'
});

// debug
console.log("ENV CHECK:", {
  host: process.env.DB_HOST,
  port: process.env.DB_PORT,
  db: process.env.DB_NAME
});

(async () => {
  try {
    const conn = await pool.getConnection();
    console.log("✅ DB CONNECTED");
    conn.release();
  } catch (err) {
    console.error("❌ DB ERROR:", err.message);
  }
})();

module.exports = pool;
