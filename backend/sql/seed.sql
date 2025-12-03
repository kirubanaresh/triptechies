USE smart_bus_db;

-- Test conductor (rokesh/123456)
INSERT INTO drivers (username, password_hash, name, bus_registration, role) VALUES 
('rokesh', '$2b$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Rokesh Kumar', 'TN7894AB', 'conductor'),
('driver1', '$2b$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Driver One', 'TN5642XY', 'driver');

-- Sample bus status
INSERT INTO bus_status (bus_registration, route, destination, latitude, longitude, crowding) VALUES 
('TN7894AB', 'Dharmapuri → Coimbatore', 'Coimbatore', 12.9716, 77.5946, 'Medium')
ON DUPLICATE KEY UPDATE 
  route=VALUES(route), destination=VALUES(destination), latitude=VALUES(latitude), longitude=VALUES(longitude), crowding=VALUES(crowding);
