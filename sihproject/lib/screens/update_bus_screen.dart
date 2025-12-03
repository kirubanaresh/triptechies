import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UpdateBusScreen extends StatefulWidget {
  @override
  _UpdateBusScreenState createState() => _UpdateBusScreenState();
}

class _UpdateBusScreenState extends State<UpdateBusScreen> {
  final busRegController = TextEditingController();
  final routeController = TextEditingController();
  final destController = TextEditingController();
  String? status;

  Future<void> updateBusDetails() async {
    try {
      // Get token from login (stored after successful login)
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) {
        setState(() => status = 'No login token found');
        return;
      }

      final locationData = {
        'busRegistration': busRegController.text,
        'route': routeController.text,
        'destination': destController.text,
        'latitude': 12.9716,  // hardcoded for now
        'longitude': 77.5946, // hardcoded for now
        'crowding': 'Medium',  // hardcoded for now
      };

      final response = await http.post(
        Uri.parse('http://10.0.2.2:3000/api/driver/update_location'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',  // This is the missing part!
        },
        body: jsonEncode(locationData),
      );

      setState(() {
        status = response.statusCode == 200
            ? 'Location updated successfully!'
            : 'Update failed: ${response.statusCode}';
      });
    } catch (e) {
      setState(() => status = 'Error updating bus: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Update Bus Details')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: busRegController,
              decoration: InputDecoration(labelText: 'Bus Registration'),
            ),
            TextField(
              controller: routeController,
              decoration: InputDecoration(labelText: 'Route'),
            ),
            TextField(
              controller: destController,
              decoration: InputDecoration(labelText: 'Destination'),
            ),
            SizedBox(height: 12),
            ElevatedButton(
              onPressed: updateBusDetails,
              child: Text('Update Location'),
            ),
            SizedBox(height: 20),
            if (status != null) Text(status!, style: TextStyle(color: Colors.green)),
          ],
        ),
      ),
    );
  }
}
