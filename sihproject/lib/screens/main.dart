import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/update_bus_screen.dart';
import 'screens/qr_scanner_screen.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bus Info App',
      initialRoute: '/login',
      routes: {
        '/login': (context) => LoginScreen(),
        '/updateBus': (context) => UpdateBusScreen(),
        '/scanQR': (context) => QRScannerScreen(),
      },
    );
  }
}
