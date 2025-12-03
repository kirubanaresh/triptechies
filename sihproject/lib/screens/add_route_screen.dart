import 'package:flutter/material.dart';
import 'worker_dashboard_screen.dart';

class AddRouteScreen extends StatefulWidget {
  @override
  _AddRouteScreenState createState() => _AddRouteScreenState();
}

class _AddRouteScreenState extends State<AddRouteScreen> {
  final _busNumberController = TextEditingController(text: '7894');
  final _fromController = TextEditingController(text: 'dharmauri');
  final _toController = TextEditingController(text: 'coimbatore');
  final _departureController = TextEditingController(text: '08:00');
  final _arrivalController = TextEditingController(text: '14:00');
  final _stopNameController = TextEditingController();
  final _stopTimeController = TextEditingController();
  List<Map<String, String>> addedStops = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFEEF3F8),
      body: Container(
        width: 420,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.fromLTRB(24, 20, 24, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: Color(0xFF374151)),
                    onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => WorkerDashboardScreen()),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
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
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    SizedBox(height: 24),
                    
                    // Basic Information Card
                    _buildCard(
                      title: 'Basic Information',
                      children: [
                        // Row 1
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _busNumberController,
                                decoration: InputDecoration(
                                  labelText: 'Bus Number',
                                  prefixIcon: Icon(Icons.directions_bus_outlined),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: TextField(
                                controller: _fromController,
                                decoration: InputDecoration(
                                  labelText: 'From Location',
                                  prefixIcon: Icon(Icons.location_on_outlined),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        SizedBox(
                          width: 120,
                          child: TextField(
                            controller: _departureController,
                            decoration: InputDecoration(
                              labelText: 'Departure Time',
                              prefixIcon: Icon(Icons.access_time),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(height: 24),
                        // Row 2
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _toController,
                                decoration: InputDecoration(
                                  labelText: 'To Location',
                                  prefixIcon: Icon(Icons.location_on_outlined),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: TextField(
                                controller: _arrivalController,
                                decoration: InputDecoration(
                                  labelText: 'Arrival Time',
                                  prefixIcon: Icon(Icons.access_time),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 24),
                    
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
                                  prefixIcon: Icon(Icons.location_city_outlined),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            SizedBox(
                              width: 100,
                              child: TextField(
                                controller: _stopTimeController,
                                decoration: InputDecoration(
                                  hintText: 'Time',
                                  prefixIcon: Icon(Icons.access_time),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Color(0xFF00C567), Color(0xFF00A255)],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                onPressed: () {
                                  if (_stopNameController.text.isNotEmpty && _stopTimeController.text.isNotEmpty) {
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
                                icon: Icon(Icons.add, color: Colors.white, size: 24),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Color(0xFFECFDF5),
                            border: Border.all(color: Color(0xFFBBF7D0)),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Added Stops (${addedStops.length})',
                                style: TextStyle(
                                  color: Color(0xFF166534),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              if (addedStops.isEmpty)
                                Text(
                                  'No stops added yet',
                                  style: TextStyle(color: Color(0xFF22C55E), fontSize: 14),
                                ),
                              ...addedStops.map((stop) => Padding(
                                padding: EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Icon(Icons.location_on, size: 16, color: Color(0xFF166534)),
                                    SizedBox(width: 8),
                                    Expanded(child: Text('${stop['name']} - ${stop['time']}')),
                                    IconButton(
                                      icon: Icon(Icons.delete, color: Color(0xFF166534)),
                                      onPressed: () => setState(() => addedStops.remove(stop)),
                                    ),
                                  ],
                                ),
                              )),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 32),
                    
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
                              backgroundColor: Color(0xFFF3F4F6),
                              foregroundColor: Color(0xFF6B7280),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Text('Clear All Stops', style: TextStyle(fontSize: 16)),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Route Created Successfully!'),
                                  backgroundColor: Color(0xFF3E60FF),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF3E60FF),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Text('Create Route & Generate QR', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 32),
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
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20)],
        border: Border.all(color: Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF374151)),
          ),
          SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }
}
