import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/bottom_nav_bar.dart';
import '../services/socket_service.dart';
import '../services/weather_service.dart';
import '../widgets/weather_card.dart';
import 'chat_screen.dart';

class CustomerDashboardScreen extends StatefulWidget {
  @override
  _CustomerDashboardScreenState createState() =>
      _CustomerDashboardScreenState();
}

class _CustomerDashboardScreenState extends State<CustomerDashboardScreen> {
  int currentIndex = 0;
  final SocketService _socketService = SocketService();
  final WeatherService _weatherService = WeatherService();
  final FlutterTts flutterTts = FlutterTts();

  Map<String, dynamic>? _weather;
  Map<String, dynamic>? _busUpdate;
  bool _isSosLoading = false;

  final _fromController = TextEditingController();
  final _toController = TextEditingController();

  List<dynamic> _buses = [];

  Future<void> _searchBuses() async {
    final from = _fromController.text.trim();
    final to = _toController.text.trim();
    if (from.isEmpty || to.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter both From and To')),
      );
      return;
    }

    // Use 10.0.2.2 for emulator or specific IP if Config exists. 
    // Hardcoding for now to match verified working state or use Config if imported.
    // Since Config isn't imported here, I'll stick to the likely working URL or add Config.
    final uri = Uri.parse(
      'http://10.0.2.2:3000/api/routes/search?from=$from&to=$to',
    );

    try {
      final res = await http.get(uri);
      final data = jsonDecode(res.body);

      if (res.statusCode == 200 && data['success'] == true) {
        setState(() {
          _buses = data['data'] as List;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Search failed')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _initSocket();
    _fetchWeather();
    _initTts();
  }

  void _initTts() async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(0.5);
  }

  void _initSocket() {
    _socketService.initSocket();
    _socketService.socket.on('bus_update', (data) {
      if (mounted) {
        setState(() {
          _busUpdate = data;
        });
        _speakUpdate(data);
      }
    });
  }

  void _speakUpdate(dynamic data) async {
    String text = "Bus ${data['busRegistration']} is now at known location";
    await flutterTts.speak(text);
  }

  void _fetchWeather() async {
    final weather = await _weatherService.fetchWeather('Chennai');
    if (mounted) {
      setState(() {
        _weather = weather;
      });
    }
  }

  Future<void> _handleSos() async {
    setState(() => _isSosLoading = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Location permissions are denied')));
           return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      
      final response = await http.post(
        Uri.parse('http://10.0.2.2:3000/api/sos'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'busRegistration': _busUpdate?['busRegistration'] ?? 'UNKNOWN',
          'location': {
            'latitude': position.latitude,
            'longitude': position.longitude
          },
          'userId': '12345'
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('SOS SENT! Emergency alert broadcasted.'), backgroundColor: Colors.red));
      } else {
        throw Exception('Failed to send SOS');
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to send SOS: $e')));
    } finally {
      if (mounted) setState(() => _isSosLoading = false);
    }
  }

  @override
  void dispose() {
    _socketService.dispose();
    flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE9ECF2),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildHeader(),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    // SOS Button
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isSosLoading ? null : _handleSos,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: _isSosLoading 
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text('🚨 SOS EMERGENCY 🚨', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ),
                    ),

                    // Weather Card
                    if (_weather != null) WeatherCard(weather: _weather),

                    // Live Update Banner
                    if (_busUpdate != null) _buildLiveUpdateBanner(),
                    SizedBox(height: 20),

                    _buildSearchCard(),
                    const SizedBox(height: 20),
                    _buildBusSearchCard(),
                    const SizedBox(height: 20),
                    _buildStationBoardCard(),
                    const SizedBox(height: 20),

                    // Search results from backend
                     if (_buses.isNotEmpty)
                      ..._buses.map((bus) {
                        final reg = bus['bus_registration'] ?? '';
                        final from = bus['from_location'] ?? '';
                        final to = bus['to_location'] ?? '';
                        final dep = (bus['departure_time'] ?? '').toString();
                        final crowd =
                            bus['crowding'] ?? bus['live_route'] ?? '';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 12,
                              ),
                            ],
                            border: Border.all(
                                color: const Color(0xFFF1F5F9)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                reg.toString(),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF3E60FF),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$from → $to',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Departure: $dep',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                              if (crowd.toString().isNotEmpty)
                                Text(
                                  crowd.toString(),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => ChatScreen())); // ChatScreen is imported or will be
        },
        child: Icon(Icons.chat),
        backgroundColor: Color(0xFF3B82F6),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: currentIndex,
        onTap: (index) => setState(() => currentIndex = index),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Color(0xFF3B82F6),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(Icons.menu, color: Colors.white, size: 16),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Where is My Bus',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                ),
                Text(
                  'Live tracking for your journey',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveUpdateBanner() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border.all(color: Colors.red.shade200),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.directions_bus, color: Colors.red),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Live Update: ${_busUpdate!['busRegistration']}', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                Text('Crowding: ${_busUpdate!['crowding'] ?? 'Unknown'}%', style: TextStyle(color: Colors.red.shade700)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSearchCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 32,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'From / To',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _fromController,
            decoration: InputDecoration(
              hintText: 'From Station',
              hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
              prefixIcon: const Icon(Icons.location_on_outlined,
                  color: Color(0xFF6B7280)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 16),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Color(0xFF6B7280),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.swap_vert,
                  color: Colors.white, size: 24),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _toController,
            decoration: InputDecoration(
              hintText: 'To Station',
              hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
              prefixIcon: const Icon(Icons.location_on_outlined,
                  color: Color(0xFF6B7280)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 16),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _searchBuses,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3E60FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Find Buses',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusSearchCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 32,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bus No. / Bus Name',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 16),
          const TextField(
            decoration: InputDecoration(
              hintText: 'Enter bus number or name',
              hintStyle: TextStyle(color: Color(0xFF9CA3AF)),
              prefixIcon: Icon(Icons.search, color: Color(0xFF6B7280)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
                borderSide: BorderSide(color: Color(0xFFDFE3EA)),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () {
                // TODO: implement bus number search API
              },
              icon: const Icon(Icons.search, size: 20),
              label: const Text(
                'Search Bus',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3E60FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStationBoardCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 32,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Station Departure Board',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              hintText: 'Enter station name',
              hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
              prefixIcon:
                  const Icon(Icons.location_city, color: Color(0xFF6B7280)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFDFE3EA)),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () {
                // TODO: implement station board API
              },
              icon: const Icon(Icons.list_alt, size: 20),
              label: const Text(
                'View Board',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3E60FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
