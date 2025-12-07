import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'worker_dashboard_screen.dart';

class AddRouteScreen extends StatefulWidget {
  @override
  _AddRouteScreenState createState() => _AddRouteScreenState();
}

class _AddRouteScreenState extends State<AddRouteScreen> {
  final _busNumberController = TextEditingController(text: '7894');
  final _fromController = TextEditingController(text: 'dharmapuri');
  final _toController = TextEditingController(text: 'coimbatore');
  final _departureController = TextEditingController(text: '08:00');
  final _arrivalController = TextEditingController(text: '14:00');
  final _stopNameController = TextEditingController();
  final _stopTimeController = TextEditingController();

  List<Map<String, String>> addedStops = [];
  bool _isLoading = false;

  Future<void> _createRoute() async {
    if (_busNumberController.text.trim().isEmpty ||
        _fromController.text.trim().isEmpty ||
        _toController.text.trim().isEmpty ||
        _departureController.text.trim().isEmpty ||
        _arrivalController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fill all basic fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Not logged in')),
        );
        setState(() => _isLoading = false);
        return;
      }

      final body = {
        'busRegistration': _busNumberController.text.trim(),
        'from_location': _fromController.text.trim(),
        'to_location': _toController.text.trim(),
        'departure_time': '${_departureController.text.trim()}:00',
        'arrival_time': '${_arrivalController.text.trim()}:00',
        'stops': addedStops,
      };

      final res = await http.post(
        Uri.parse('http://10.0.2.2:3000/api/routes/create'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      final data = jsonDecode(res.body);

      if (res.statusCode == 200 && data['success'] == true) {
        final String qrDataUrl = data['qrCode'];

        // save permanently
        final prefs2 = await SharedPreferences.getInstance();
        await prefs2.setString('last_route_qr', qrDataUrl);
        await prefs2.setString(
            'last_route_bus', _busNumberController.text.trim());

        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Route QR Code'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.memory(
                  base64Decode(qrDataUrl.split(',').last),
                  width: 220,
                  height: 220,
                ),
                const SizedBox(height: 12),
                Text(
                  'Bus: ${_busNumberController.text.trim()}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_fromController.text.trim()} → ${_toController.text.trim()}',
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Route create failed')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _busNumberController.dispose();
    _fromController.dispose();
    _toController.dispose();
    _departureController.dispose();
    _arrivalController.dispose();
    _stopNameController.dispose();
    _stopTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF3F8),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon:
                        const Icon(Icons.arrow_back, color: Color(0xFF374151)),
                    onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) => WorkerDashboardScreen()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Route Information',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 24),

                    // Basic Information Card
                    _buildCard(
                      title: 'Basic Information',
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _busNumberController,
                                decoration: InputDecoration(
                                  labelText: 'Bus Number',
                                  prefixIcon: const Icon(
                                      Icons.directions_bus_outlined),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextField(
                                controller: _fromController,
                                decoration: InputDecoration(
                                  labelText: 'From Location',
                                  prefixIcon: const Icon(
                                      Icons.location_on_outlined),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: 120,
                          child: TextField(
                            controller: _departureController,
                            decoration: InputDecoration(
                              labelText: 'Departure Time',
                              prefixIcon:
                                  const Icon(Icons.access_time_outlined),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _toController,
                                decoration: InputDecoration(
                                  labelText: 'To Location',
                                  prefixIcon: const Icon(
                                      Icons.location_on_outlined),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextField(
                                controller: _arrivalController,
                                decoration: InputDecoration(
                                  labelText: 'Arrival Time',
                                  prefixIcon:
                                      const Icon(Icons.access_time_outlined),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Intermediate Stops Card
                    _buildCard(
                      title: 'Intermediate Stops',
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _stopNameController,
                                decoration: InputDecoration(
                                  hintText: 'Stop Name',
                                  prefixIcon: const Icon(
                                      Icons.location_city_outlined),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 100,
                              child: TextField(
                                controller: _stopTimeController,
                                decoration: InputDecoration(
                                  hintText: 'Time',
                                  prefixIcon:
                                      const Icon(Icons.access_time_outlined),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF00C567), Color(0xFF00A255)],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                onPressed: () {
                                  if (_stopNameController.text.isNotEmpty &&
                                      _stopTimeController.text.isNotEmpty) {
                                    setState(() {
                                      addedStops.add({
                                        'name': _stopNameController.text,
                                        'time': _stopTimeController.text,
                                      });
                                      _stopNameController.clear();
                                      _stopTimeController.clear();
                                    });
                                  }
                                },
                                icon: const Icon(Icons.add,
                                    color: Colors.white, size: 24),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            border:
                                Border.all(color: const Color(0xFFBBF7D0)),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Added Stops (${addedStops.length})',
                                style: const TextStyle(
                                  color: Color(0xFF166534),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              if (addedStops.isEmpty)
                                const Text(
                                  'No stops added yet',
                                  style: TextStyle(
                                      color: Color(0xFF22C55E), fontSize: 14),
                                ),
                              ...addedStops.map(
                                (stop) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 4),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.location_on,
                                          size: 16,
                                          color: Color(0xFF166534)),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                            '${stop['name']} - ${stop['time']}'),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete,
                                            color: Color(0xFF166534)),
                                        onPressed: () => setState(
                                            () => addedStops.remove(stop)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => setState(() {
                              addedStops.clear();
                              _stopNameController.clear();
                              _stopTimeController.clear();
                            }),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF3F4F6),
                              foregroundColor: const Color(0xFF6B7280),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 16),
                            ),
                            child: const Text('Clear All Stops',
                                style: TextStyle(fontSize: 16)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _createRoute,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3E60FF),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 16),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(
                                              Colors.white),
                                    ),
                                  )
                                : const Text(
                                    'Create Route & Generate QR',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
          ),
        ],
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }
}
