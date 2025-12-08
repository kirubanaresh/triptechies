import 'package:flutter/material.dart';

class WeatherCard extends StatelessWidget {
  final Map<String, dynamic>? weather;

  const WeatherCard({Key? key, this.weather}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (weather == null) return SizedBox.shrink();

    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${weather!['temp']}°C',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 5),
              Text(
                weather!['condition'] ?? 'Unknown',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white70,
                ),
              ),
              Text(
                weather!['location'] ?? '',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white60,
                ),
              ),
            ],
          ),
          Icon(
            _getWeatherIcon(weather!['condition']),
            size: 50,
            color: Colors.white,
          ),
        ],
      ),
    );
  }

  IconData _getWeatherIcon(String? condition) {
    if (condition == null) return Icons.wb_sunny;
    switch (condition.toLowerCase()) {
      case 'rain':
        return Icons.grain;
      case 'cloudy':
        return Icons.cloud;
      case 'storm':
        return Icons.flash_on;
      default:
        return Icons.wb_sunny;
    }
  }
}
