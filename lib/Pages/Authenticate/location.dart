import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geocoding/geocoding.dart'; // Import geocoding package

class LocationPage extends StatefulWidget {
  @override
  _LocationPageState createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  String _locationText = 'Getting location...';

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  Future<void> _getLocation() async {
    if (await _getLocationPermission()) {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String locationName = place.name ?? ''; // Extract place name
        String address =
            '${place.subLocality}, ${place.locality}, ${place.country}';
        setState(() {
          _locationText = 'Location: $locationName\nAddress: $address';
          print('Current location: $locationName, $address');
        });
      } else {
        setState(() {
          _locationText = 'No address found for the current location.';
        });
      }
    } else {
      setState(() {
        _locationText = 'Location permission denied.';
      });
    }
  }

  Future<bool> _getLocationPermission() async {
    if (await Permission.location.isGranted) {
      // Permission already granted
      return true;
    } else {
      if (await Permission.location.request().isGranted) {
        // Permission granted
        return true;
      } else {
        // Permission denied
        return false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Location Page'),
      ),
      body: Center(
        child: Text(_locationText),
      ),
    );
  }
}
