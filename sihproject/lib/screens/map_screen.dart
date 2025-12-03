import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  Completer<GoogleMapController> _controller = Completer();
  LatLng _currentPosition = LatLng(12.9716, 77.5946);
  Location location = Location();
  late StreamSubscription<LocationData> _locationSubscription;
  Marker? _busMarker;

  @override
  void initState() {
    super.initState();
    _listenLocationChanges();
  }

  void _listenLocationChanges() async {
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) _serviceEnabled = await location.requestService();

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
    }

    if (_serviceEnabled && _permissionGranted == PermissionStatus.granted) {
      _locationSubscription = location.onLocationChanged.listen((LocationData loc) {
        _updateBusPosition(LatLng(loc.latitude!, loc.longitude!));
      });
    }
  }

  void _updateBusPosition(LatLng pos) {
    setState(() {
      _currentPosition = pos;
      _busMarker = Marker(
        markerId: MarkerId('busMarker'),
        position: _currentPosition,
        infoWindow: InfoWindow(title: 'Bus Current Location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      );
    });
  }

  @override
  void dispose() {
    _locationSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Real-time Bus Tracking')),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(target: _currentPosition, zoom: 14),
        markers: _busMarker != null ? {_busMarker!} : {},
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
        },
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
      ),
    );
  }
}
