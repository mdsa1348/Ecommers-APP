import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mobo_game/Pages/HomePage/HomeBody.dart';
import 'package:mobo_game/Pages/HomePage/Homepage.dart';
import 'package:sign_in_button/sign_in_button.dart';

class SignIn extends StatefulWidget {
  const SignIn({Key? key}) : super(key: key);

  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? _user;

  @override
  void initState() {
    super.initState();
    _auth.authStateChanges().listen((User? event) {
      print("Authentication state changed: $event");
      setState(() {
        _user = event;
      });

      // Check if user is signed in, and navigate to another page
      if (_user != null) {
        WidgetsBinding.instance?.addPostFrameCallback((_) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) =>
                  HomePage(), // Replace with your actual home screen
            ),
          );
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Google Sign In"),
      ),
      body: _user != null ? _userInfo() : _googleSignInButton(),
    );
  }

  void _handlegoogleSignIn() async {
    try {
      GoogleAuthProvider _googleAuthProvider = GoogleAuthProvider();

      if (kIsWeb) {
        // On web, use signInWithPopup
        await _auth.signInWithPopup(_googleAuthProvider);
      } else {
        // On mobile, initiate the Google Sign In process
        final GoogleSignInAccount? googleSignInAccount =
            await GoogleSignIn().signIn();

        if (googleSignInAccount == null) {
          // The user canceled the sign-in process
          return;
        }

        // Obtain the GoogleSignInAuthentication object
        final GoogleSignInAuthentication googleSignInAuthentication =
            await googleSignInAccount.authentication;

        // Create a new GoogleAuthCredential using the obtained idToken
        final OAuthCredential googleAuthCredential =
            GoogleAuthProvider.credential(
          accessToken: googleSignInAuthentication.accessToken,
          idToken: googleSignInAuthentication.idToken,
        );

        // Sign in to Firebase with the GoogleAuthCredential
        await _auth.signInWithCredential(googleAuthCredential);
      }
    } catch (e) {
      print(e);
    }
  }

  Widget _googleSignInButton() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Center(
            child: SizedBox(
              height: 50,
              child: SignInButton(
                Buttons.google,
                text: "Sign Up With Google",
                onPressed: _handlegoogleSignIn,
              ),
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  // Add your navigation logic here
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => HomePage()),
                  );
                },
                child: const Text("Your Button Text"),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _userInfo() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Welcome, ${_user?.displayName ?? "User"}!',
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              // Sign out the user
              await _auth.signOut();
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

// class HomeScreen extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text("Home Screen"),
//       ),
//       body: Center(
//         child: Text("Welcome to the Home Screen!"),
//       ),
//     );
//   }
// }
