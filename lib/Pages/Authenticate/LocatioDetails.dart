import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart'; // Import for formatting timestamps
import 'package:flutter/services.dart';
import 'package:maps_launcher/maps_launcher.dart';

class LatLng {
  final double latitude;
  final double longitude;

  LatLng(this.latitude, this.longitude);
}

class UserDetailsPage extends StatefulWidget {
  final String userId;

  const UserDetailsPage({Key? key, required this.userId}) : super(key: key);

  @override
  _UserDetailsPageState createState() => _UserDetailsPageState();
}

class _UserDetailsPageState extends State<UserDetailsPage> {
  List<String> addresses = [];
  List<String> placeNames = [];
  List<String> addedTimes = [];
  List<LatLng> locations = [];

  @override
  void initState() {
    super.initState();
    fetchLocationAddress();
  }

  Future<void> fetchLocationAddress() async {
    try {
      // Fetch location data from Firestore
      QuerySnapshot<Map<String, dynamic>> userLocationsSnapshot =
          await FirebaseFirestore.instance
              .collection('locations')
              .doc(widget.userId)
              .collection('user_locations')
              .get();

      // Use Future.wait to fetch all documents simultaneously
      await Future.wait(userLocationsSnapshot.docs.map((doc) async {
        GeoPoint location = doc.data()['location'];
        double latitude = location.latitude;
        double longitude = location.longitude;

        // Convert latitude and longitude to address
        List<Placemark> placemarks =
            await placemarkFromCoordinates(latitude, longitude);
        if (placemarks.isNotEmpty) {
          Placemark placemark = placemarks.first;
          addresses.add(placemark.street.toString());
          placeNames.add(
              '${placemark.subLocality}, ${placemark.locality}, ${placemark.country}');
          Timestamp timestamp = doc.data()['timestamp'];
          addedTimes.add(_formatTimestamp(timestamp));
          locations.add(LatLng(latitude, longitude));
        }
      }));

      setState(() {});
    } catch (error) {
      print('Error fetching location address: $error');
    }
  }

  String _formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    String formattedTime = DateFormat('dd MMM yyyy, hh:mm a').format(dateTime);
    return formattedTime;
  }

  // Function to copy text to clipboard
  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Copied to clipboard')),
    );
  }

  // Function to open the map with the specified location
  void _openLocationInMap(LatLng location) async {
    MapsLauncher.launchCoordinates(location.latitude, location.longitude);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Details'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Center(
          child: ListView.builder(
            itemCount: addresses.length,
            itemBuilder: (context, index) {
              // Inside the ListView.builder's itemBuilder:
              return Card(
                elevation: 4,
                margin: EdgeInsets.symmetric(vertical: 10),
                child: Padding(
                  padding: EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Location Address:',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.copy),
                            onPressed: () => _copyToClipboard(addresses[index]),
                          ),
                        ],
                      ),
                      SizedBox(height: 5),
                      GestureDetector(
                        onTap: () => _openLocationInMap(locations[index]),
                        child: Text(
                          addresses[index],
                          style: TextStyle(fontSize: 15, color: Colors.blue),
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Place Name:',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 5),
                      SelectableText(
                        placeNames[index],
                        style: TextStyle(fontSize: 15, color: Colors.black87),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Added Time:',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 5),
                      SelectableText(
                        addedTimes[index],
                        style: TextStyle(fontSize: 15, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
