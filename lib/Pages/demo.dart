// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// class NewProfile extends StatefulWidget {
//   final User? user = FirebaseAuth.instance.currentUser;

//   @override
//   _NewProfileState createState() => _NewProfileState();
// }

// class _NewProfileState extends State<NewProfile> {
//   late TextEditingController nameController;
//   late TextEditingController emailController;
//   late TextEditingController addressController;
//   late TextEditingController phoneController;
//   late TextEditingController otpController;

//   bool isEditMode = false;
//   String phoneNumberStatus = ''; // Status of phone number verification
//   String verificationId = '';
//   int? resendToken;

//   @override
//   void initState() {
//     super.initState();
//     // Initialize controllers with current user data
//     nameController =
//         TextEditingController(text: widget.user?.displayName ?? "");
//     emailController = TextEditingController(text: widget.user?.email ?? "");
//     addressController = TextEditingController(text: "");
//     phoneController =
//         TextEditingController(text: ""); // Initialize with an empty string
//     otpController = TextEditingController();
//     // Fetch user profile data from Firestore
//     fetchUserProfile();
//   }

//   Future<void> fetchUserProfile() async {
//     User? currentUser = FirebaseAuth.instance.currentUser;

//     if (currentUser != null) {
//       DocumentReference userDoc = FirebaseFirestore.instance
//           .collection('userProfiles')
//           .doc(currentUser.uid);

//       try {
//         DocumentSnapshot snapshot = await userDoc.get();

//         if (!snapshot.exists) {
//           // If the document doesn't exist, create it with initial data
//           await userDoc.set({
//             'name': currentUser.displayName,
//             'email': currentUser.email,
//             'address': '',
//             'phoneNumber': '',
//             'phoneNumberStatus': '', // Initial status is empty
//           });
//         } else {
//           // If the document exists, update the phoneController with the fetched phoneNumber
//           final Map<String, dynamic>? userData =
//               snapshot.data() as Map<String, dynamic>?;

//           if (userData != null && userData.containsKey('phoneNumber')) {
//             setState(() {
//               phoneController.text = userData['phoneNumber'];
//               phoneNumberStatus = userData['phoneNumberStatus'] ?? '';
//             });
//           }
//           if (userData != null && userData.containsKey('address')) {
//             setState(() {
//               addressController.text = userData['address'];
//             });
//           }
//         }
//       } catch (e) {
//         print('Error fetching user profile: $e');
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Profile'),
//         actions: [
//           IconButton(
//             icon: Icon(Icons.edit),
//             onPressed: () {
//               setState(() {
//                 isEditMode = !isEditMode;
//               });
//             },
//           ),
//         ],
//       ),
//       body: Container(
//         margin: EdgeInsets.only(top: 30.0, left: 20, right: 20, bottom: 40),
//         padding: EdgeInsets.all(16.0),
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(16.0),
//           border: Border.all(color: Colors.grey),
//         ),
//         child: SingleChildScrollView(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               _buildEditableField("Name", nameController, isEditMode),
//               SizedBox(height: 10),
//               _buildEditableField("Email", emailController, isEditMode),
//               SizedBox(height: 10),
//               _buildEditableField("Address", addressController, isEditMode),
//               SizedBox(height: 10),
//               _buildEditableField("Phone Number", phoneController, isEditMode),
//               SizedBox(height: 10),
//               if (isEditMode &&
//                   (phoneNumberStatus.isEmpty ||
//                       phoneNumberStatus == 'Verification Failed'))
//                 ElevatedButton(
//                   onPressed: () async {
//                     await _verifyingPhoneNumber();
//                   },
//                   child: Text('Verify Phone Number'),
//                 ),
//               if (phoneNumberStatus.isNotEmpty)
//                 Text('Phone Number Status: $phoneNumberStatus'),
//               if (isEditMode) SizedBox(height: 10),
//               if (isEditMode && phoneNumberStatus.isEmpty)
//                 ElevatedButton(
//                   onPressed: () async {
//                     // Save changes to Firestore only if phone number is verified
//                     if (phoneNumberStatus == 'Verified') {
//                       await updateProfileData(
//                         name: isEditMode ? nameController.text : null,
//                         address: isEditMode ? addressController.text : null,
//                         phoneNumber: isEditMode ? phoneController.text : null,
//                       );
//                     } else {
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         SnackBar(
//                           content: Text('Phone number not verified.'),
//                         ),
//                       );
//                     }

//                     // Disable edit mode after saving changes
//                     setState(() {
//                       isEditMode = false;
//                     });
//                   },
//                   child: Text('Update'),
//                 ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   void _showOtpVerificationPopup() {
//     showDialog(
//       context: context,
//       barrierDismissible:
//           false, // Prevent dismissing when tapping outside the dialog
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text('OTP Verification'),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               TextField(
//                 controller: otpController,
//                 keyboardType: TextInputType.number,
//                 decoration: InputDecoration(labelText: 'Enter OTP'),
//               ),
//               SizedBox(height: 10),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   ElevatedButton(
//                     onPressed: () {
//                       Navigator.of(context).pop();
//                     },
//                     child: Text('cancle'),
//                   ),
//                   ElevatedButton(
//                     onPressed: () {
//                       _verifyOtpAndSignIn();
//                     },
//                     child: Text('Verify'),
//                   ),
//                 ],
//               ),
//               ElevatedButton(
//                 onPressed: () {
//                   _resendOtp(); // Resend OTP
//                 },
//                 child: Text('Resend OTP'),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   void _resendOtp() {
//     // Implement resend OTP logic here
//   }

//   Future<void> _verifyOtpAndSignIn() async {
//     String otp = otpController.text.trim();

//     if (otp.isNotEmpty && verificationId != null) {
//       // Create a PhoneAuthCredential object
//       PhoneAuthCredential credential = PhoneAuthProvider.credential(
//         verificationId: verificationId,
//         smsCode: otp,
//       );

//       try {
//         // Sign in the user with the credential
//         await FirebaseAuth.instance.signInWithCredential(credential);
//         setState(() {
//           phoneNumberStatus = 'Verified';
//         });
//         // Update the phone number in Firebase
//         //await updatePhoneNumberInFirebase(phoneNumber);
//       } catch (e) {
//         // Handle sign-in errors
//         print('Error verifying OTP: $e');
//       }
//     } else {
//       print('OTP or verification ID is empty');
//     }
//   }

//   Future<void> _verifyPhoneNumber() async {
//     String phoneNumber = phoneController.text.trim();

//     if (phoneNumber.isNotEmpty) {
//       await FirebaseAuth.instance.verifyPhoneNumber(
//         phoneNumber: phoneNumber,
//         verificationCompleted: (PhoneAuthCredential credential) async {
//           // Auto-verification if phone number is detected automatically
//           await FirebaseAuth.instance.signInWithCredential(credential);
//           setState(() {
//             phoneNumberStatus = 'Verified';
//           });
//           // Update the phone number in Firebase
//           //await updatePhoneNumberInFirebase(phoneNumber);
//           _showOtpVerificationPopup(); // Show OTP verification popup
//         },
//         verificationFailed: (FirebaseAuthException e) {
//           print('Phone number verification failed: ${e.message}');
//           setState(() {
//             phoneNumberStatus = 'Unverified';
//           });
//         },
//         codeSent: (String verificationId, int? resendToken) async {
//           // Handle code sent
//           // Typically, a verification code is sent via SMS
//           // You can show UI to enter the verification code and then use it to sign in
//           setState(() {
//             this.verificationId = verificationId;
//             this.resendToken = resendToken;
//           });
//         },
//         codeAutoRetrievalTimeout: (String verificationId) {
//           // Handle timeout
//           // The automatic retrieval of the verification code timed out
//         },
//       );
//     } else {
//       print('Phone number is empty');
//     }
//   }

//   Future<void> _verifyingPhoneNumber() async {
//     String phoneNumber = phoneController.text.trim();

//     if (phoneNumber.isNotEmpty) {
//       await FirebaseAuth.instance.verifyPhoneNumber(
//         phoneNumber: phoneNumber,
//         verificationCompleted: (PhoneAuthCredential credential) async {
//           // Auto-verification if phone number is detected automatically
//           await FirebaseAuth.instance.signInWithCredential(credential);
//           setState(() {
//             phoneNumberStatus = 'Verified';
//           });

//           //_showOtpVerificationPopup();
//         },
//         verificationFailed: (FirebaseAuthException e) {
//           print('Phone number verification failed: ${e.message}');
//           setState(() {
//             phoneNumberStatus = 'NonVerification';
//           });
//         },
//         codeSent: (String verificationId, int? resendToken) async {
//           // Handle code sent
//           // Typically, a verification code is sent via SMS
//           // You can show UI to enter the verification code and then use it to sign in
//           setState(() {
//             this.verificationId = verificationId;
//             this.resendToken = resendToken;
//           });
//         },
//         codeAutoRetrievalTimeout: (String verificationId) {
//           // Handle timeout
//           // The automatic retrieval of the verification code timed out
//         },
//       );
//     } else {
//       print('Phone number is empty');
//     }
//   }

//   Future<void> updatePhoneNumberInFirebase(String phoneNumber) async {
//     // Get the current user
//     User? currentUser = FirebaseAuth.instance.currentUser;

//     if (currentUser != null) {
//       // Reference to the user's document in the 'userProfiles' collection
//       DocumentReference userDoc = FirebaseFirestore.instance
//           .collection('userProfiles')
//           .doc(currentUser.uid);

//       try {
//         // Update the phoneNumber and phoneNumberStatus in the document
//         await userDoc.update({
//           'phoneNumber': phoneNumber,
//           'phoneNumberStatus': 'Verified',
//         });

//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Phone number updated successfully!')),
//         );
//         print('Phone number updated successfully!');
//       } catch (e) {
//         print('Error updating phone number: $e');
//       }
//     }
//   }

//   Future<void> updateProfileData({
//     String? name,
//     String? phoneNumber,
//     String? address,
//   }) async {
//     // Get the current user
//     User? currentUser = FirebaseAuth.instance.currentUser;

//     if (currentUser != null) {
//       // Reference to the user's document in the 'userProfiles' collection
//       DocumentReference userDoc = FirebaseFirestore.instance
//           .collection('userProfiles')
//           .doc(currentUser.uid);

//       try {
//         // Create a map to hold the fields that need to be updated
//         Map<String, dynamic> updateData = {};

//         // Add fields to the map if they are not null or empty
//         if (name != null && name.isNotEmpty) {
//           updateData['name'] = name;
//         }

//         if (phoneNumber != null && phoneNumber.isNotEmpty) {
//           updateData['phoneNumber'] = phoneNumber;
//           // If phone number is updated, set the status to empty
//           updateData['phoneNumberStatus'] = '';
//         }

//         if (address != null && address.isNotEmpty) {
//           updateData['address'] = address;
//         }
//         // Update the document with the new data
//         await userDoc.update(updateData);

//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Profile updated successfully!')),
//         );
//         print('User profile updated successfully!');
//       } catch (e) {
//         print('Error updating user profile: $e');
//       }
//     }
//   }

//   Widget _buildEditableField(
//       String label, TextEditingController controller, bool isEditable) {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.lightBlueAccent, // Set background color for each box
//         borderRadius: BorderRadius.circular(8.0),
//       ),
//       child: TextFormField(
//         decoration: InputDecoration(
//           labelText: label,
//           contentPadding: EdgeInsets.all(12.0),
//           border: InputBorder.none, // Remove the underline
//         ),
//         readOnly: !isEditable ||
//             label == 'Email', // Make the email field non-editable
//         controller: controller,
//         style: TextStyle(
//           backgroundColor:
//               Colors.transparent, // Set transparent background for text field
//         ),
//       ),
//     );
//   }
// }
