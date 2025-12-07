// route_qr_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RouteQRScreen extends StatefulWidget {
  @override
  _RouteQRScreenState createState() => _RouteQRScreenState();
}

class _RouteQRScreenState extends State<RouteQRScreen> {
  String? _qrDataUrl;
  String? _busReg;

  @override
  void initState() {
    super.initState();
    _loadQR();
  }

  Future<void> _loadQR() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _qrDataUrl = prefs.getString('last_route_qr');
      _busReg = prefs.getString('last_route_bus');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Route QR Code')),
      body: Center(
        child: _qrDataUrl == null
            ? const Text('No route QR saved yet')
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.memory(
                    base64Decode(_qrDataUrl!.split(',').last),
                    width: 240,
                    height: 240,
                  ),
                  const SizedBox(height: 12),
                  if (_busReg != null)
                    Text(
                      'Bus: $_busReg',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
