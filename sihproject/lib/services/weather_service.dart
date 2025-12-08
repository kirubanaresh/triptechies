import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  // Replace with your actual backend URL or external API
  final String _baseUrl = 'http://10.0.2.2:3000/api/weather'; 

  Future<Map<String, dynamic>?> fetchWeather(String location) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl?location=$location'));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Failed to load weather');
        // Return mock data if API fails for demo purposes
        return {
          'temp': 28,
          'condition': 'Sunny',
          'location': location,
          'humidity': 65
        };
      }
    } catch (e) {
      print('Error fetching weather: $e');
      // Return mock data on error for demo stability
       return {
          'temp': 28,
          'condition': 'Sunny',
          'location': location,
          'humidity': 65
        };
    }
  }
}
