import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class BusInfoScreen extends StatefulWidget {
  final String busRegistration;

  const BusInfoScreen({Key? key, required this.busRegistration}) : super(key: key);

  @override
  _BusInfoScreenState createState() => _BusInfoScreenState();
}

class _BusInfoScreenState extends State<BusInfoScreen> {
  Map<String, dynamic>? busInfo;
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchBusInfo();
  }

  Future<void> fetchBusInfo() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await http.get(
        Uri.parse('http://localhost:3000/api/bus/${widget.busRegistration}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          busInfo = data;
          isLoading = false;
        });
      } else if (response.statusCode == 404) {
        setState(() {
          errorMessage = 'Bus not found';
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load bus info';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bus Info: ${widget.busRegistration}'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ListView(
                    children: [
                      Text('Bus Registration: ${busInfo?['bus_registration'] ?? '-'}',
                          style: const TextStyle(fontSize: 18)),
                      const SizedBox(height: 8),
                      Text('Route: ${busInfo?['route'] ?? '-'}',
                          style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 8),
                      Text('Destination: ${busInfo?['destination'] ?? '-'}',
                          style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 8),
                      Text('Latitude: ${busInfo?['latitude'] ?? '-'}',
                          style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 8),
                      Text('Longitude: ${busInfo?['longitude'] ?? '-'}',
                          style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 8),
                      Text('Crowding: ${busInfo?['crowding'] ?? '-'}',
                          style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 8),
                      Text(
                        'Last Updated: ${busInfo?['updated_at'] ?? '-'}',
                        style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
    );
  }
}
