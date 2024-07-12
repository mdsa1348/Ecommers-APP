import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mobo_game/Pages/Authenticate/signup.dart';
import 'package:mobo_game/Pages/Authenticate/singin.dart';
import 'package:mobo_game/Pages/HomePage/Homepage.dart';
import 'package:mobo_game/firebase_msz.dart';
import 'package:mobo_game/firebase_options.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ); // Initialize Firebase

  // Initialize Firebase messaging service
  FirebaseMessagingService().initialize();

  // Initialize Google sign-in
  GoogleSignIn googleSignIn = GoogleSignIn();

  // Initialize local notifications
  initializeNotifications();


  runApp(MyApp());

  // Get location and then run the app
  await _getLocation();
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FutureBuilder(
        // Use a FutureBuilder to check the authentication state
        future: FirebaseAuth.instance.authStateChanges().first,
        builder: (BuildContext context, AsyncSnapshot<User?> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // If the connection is still in progress, show a loading indicator or splash screen
            return CircularProgressIndicator();
          } else {
            // Check if the user is signed in
            bool isUserSignedIn = snapshot.hasData;

            // Choose the appropriate home page based on the sign-in status
            Widget homePage = isUserSignedIn ? HomePage() : SignIn();
            //Widget homePage = HomePage();
            // home: initialUser != null ? HomeScreen() : AuthenticationScreen(),
            return homePage;
          }
        },
      ),
    );
  }
}

// Function to check if a collection exists
Future<bool> doesCollectionExist(String collectionName) async {
  QuerySnapshot collectionSnapshot = await FirebaseFirestore.instance
      .collection(collectionName)
      .limit(1)
      .get();
  return collectionSnapshot.docs.isNotEmpty;
}

Future<void> _getLocation() async {
  print('Location retrieval started...');

  // Check and request location permission
  if (await Permission.location.request().isGranted) {
    // If permission granted, get current position
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;

      // Check if the user's document exists in the 'locations' collection
      DocumentSnapshot locationDoc = await FirebaseFirestore.instance
          .collection('locations')
          .doc(userId)
          .get();

      if (locationDoc.exists) {
        // If the document exists, update the timestamp
        await FirebaseFirestore.instance
            .collection('locations')
            .doc(userId)
            .update({
          'timestamp': FieldValue.serverTimestamp(),
        });
      } else {
        // If the document doesn't exist, create a new one
        await FirebaseFirestore.instance
            .collection('locations')
            .doc(userId)
            .set({
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      // Check if the current location is within 100 meters of any existing location
      QuerySnapshot userLocationSnapshots = await FirebaseFirestore.instance
          .collection('locations')
          .doc(userId)
          .collection('user_locations')
          .get();

      bool locationExistsWithin100m = false;
      String existingLocationId = '';

      userLocationSnapshots.docs.forEach((doc) {
        GeoPoint geoPoint = doc['location'];
        double distance = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          geoPoint.latitude,
          geoPoint.longitude,
        );

        if (distance < 100) {
          locationExistsWithin100m = true;
          existingLocationId = doc.id;
        }
      });

      if (!locationExistsWithin100m) {
        // If the location is not within 100 meters of any existing location, add it
        await FirebaseFirestore.instance
            .collection('locations')
            .doc(userId)
            .collection('user_locations')
            .add({
          'location': GeoPoint(position.latitude, position.longitude),
          'timestamp': FieldValue.serverTimestamp(),
        });
        print('Location added to Firestore.');
      } else {
        // If the location is within 100 meters of an existing location, update the timestamp
        await FirebaseFirestore.instance
            .collection('locations')
            .doc(userId)
            .collection('user_locations')
            .doc(existingLocationId)
            .update({
          'timestamp': FieldValue.serverTimestamp(),
        });
        print('Location timestamp updated in Firestore.');
      }
    } catch (error) {
      print('Error updating/adding location to Firestore: $error');
    }
  } else {
    // If permission denied, handle accordingly
    print('Location permission denied.');
  }
}
