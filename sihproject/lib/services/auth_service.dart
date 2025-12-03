import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  final String baseUrl = 'http://localhost:3000';
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  Future<bool> login(String username, String password) async {
    final url = Uri.parse('$baseUrl/api/auth/login');
    final response = await http.post(url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}));

    if (response.statusCode == 200) {
      final token = jsonDecode(response.body)['token'];
      await storage.write(key: 'jwt_token', value: token);
      return true;
    }
    return false;
  }

  Future<String?> getToken() async => await storage.read(key: 'jwt_token');

  Future<bool> updateBusLocation(Map<String, dynamic> locationData) async {
    final token = await getToken();
    if (token == null) throw Exception('Login required');

    final url = Uri.parse('$baseUrl/api/driver/update_location');
    final response = await http.post(url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(locationData));

    return response.statusCode == 200;
  }
}
