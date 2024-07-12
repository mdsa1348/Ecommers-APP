// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:flutter/material.dart';
// import 'package:google_sign_in/google_sign_in.dart';

// class Signup extends StatefulWidget {
//   const Signup({Key? key}) : super(key: key);

//   @override
//   _SignupState createState() => _SignupState();
// }

// class _SignupState extends State<Signup> {
//   late FirebaseAuth _auth;
//   late GoogleSignIn _googleSignIn;

//   @override
//   void initState() {
//     super.initState();
//     Firebase.initializeApp().then((value) {
//       setState(() {
//         _auth = FirebaseAuth.instance;
//         _googleSignIn = GoogleSignIn();
//       });
//     });
//   }

//   Future<UserCredential?> _handleSignIn() async {
//     try {
//       final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
//       final GoogleSignInAuthentication googleAuth =
//           await googleUser!.authentication;
//       final AuthCredential credential = GoogleAuthProvider.credential(
//         accessToken: googleAuth.accessToken,
//         idToken: googleAuth.idToken,
//       );
//       return await _auth.signInWithCredential(credential);
//     } catch (error) {
//       print(error);
//       return null;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Google Sign Up'),
//       ),
//       body: Center(
//         child: ElevatedButton(
//           onPressed: () async {
//             UserCredential? userCredential = await _handleSignIn();
//             if (userCredential != null) {
//               // User signed in successfully
//               print('User signed in: ${userCredential.user!.displayName}');
//             }
//           },
//           child: Text('Sign Up with Google'),
//         ),
//       ),
//     );
//   }
// }
