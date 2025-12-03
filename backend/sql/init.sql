CREATE DATABASE IF NOT EXISTS smart_bus_db;
USE smart_bus_db;

-- Drivers/Workers table
CREATE TABLE drivers (
  id INT AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(50) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  name VARCHAR(100),
  bus_registration VARCHAR(20),
  contact VARCHAR(15),
  role ENUM('driver', 'conductor') DEFAULT 'conductor',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Bus status (live tracking)
CREATE TABLE bus_status (
  id INT AUTO_INCREMENT PRIMARY KEY,
  bus_registration VARCHAR(20) UNIQUE,
  route VARCHAR(100),
  destination VARCHAR(100),
  latitude DECIMAL(10, 8),
  longitude DECIMAL(11, 8),
  crowding ENUM('Low', 'Medium', 'High') DEFAULT 'Medium',
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_bus_reg (bus_registration)
);

-- Routes table
CREATE TABLE routes (
  id INT AUTO_INCREMENT PRIMARY KEY,
  bus_registration VARCHAR(20),
  from_location VARCHAR(100),
  to_location VARCHAR(100),
  departure_time TIME,
  arrival_time TIME,
  stops JSON,
  qr_code TEXT,
  created_by VARCHAR(50),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
