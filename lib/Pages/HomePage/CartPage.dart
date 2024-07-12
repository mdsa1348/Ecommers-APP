import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// class CartContent extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Cart'),
//       ),
//       body: StreamBuilder(
//         stream: FirebaseAuth.instance.authStateChanges(),
//         builder: (BuildContext context, AsyncSnapshot<User?> snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return Center(child: CircularProgressIndicator());
//           } else {
//             if (snapshot.hasData && snapshot.data != null) {
//               // User is signed in
//               User user = snapshot.data!;
//               return CartItemList(userId: user.uid);
//             } else {
//               // User is not signed in
//               return Center(child: Text('Please sign in to view your cart'));
//             }
//           }
//         },
//       ),
//     );
//   }
// }

// class CartItemList extends StatelessWidget {
//   final String userId;

//   CartItemList({required this.userId});

//   @override
//   Widget build(BuildContext context) {
//     return StreamBuilder(
//       stream: FirebaseFirestore.instance
//           .collection('Cart')
//           .doc(userId)
//           .collection('items')
//           .snapshots(),
//       builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return Center(child: CircularProgressIndicator());
//         } else if (snapshot.hasError) {
//           return Center(child: Text('Error: ${snapshot.error}'));
//         } else {
//           List<QueryDocumentSnapshot> documents = snapshot.data!.docs;
//           if (documents.isEmpty) {
//             return Center(child: Text('Your cart is empty'));
//           } else {
//             return ListView.builder(
//               itemCount: documents.length,
//               itemBuilder: (BuildContext context, int index) {
//                 var data = documents[index].data() as Map<String, dynamic>;
//                 print('Fetching item data for Item ID: ${data['itemId']}');
//                 return FutureBuilder(
//                   future: fetchItemData(),
//                   builder: (BuildContext context,
//                       AsyncSnapshot<DocumentSnapshot> secondItemSnapshot) {
//                     if (secondItemSnapshot.connectionState ==
//                         ConnectionState.waiting) {
//                       return CircularProgressIndicator();
//                     } else if (secondItemSnapshot.hasError) {
//                       print(
//                           'Error fetching item data: ${secondItemSnapshot.error}');
//                       return Text('Error: ${secondItemSnapshot.error}');
//                     } else {
//                       print(
//                           'Item data fetched successfully for Item ID: ${data['itemId']}');
//                       var secondItemData = secondItemSnapshot.data!.data()
//                           as Map<String, dynamic>;
//                       return ListTile(
//                         title: Text('Item ID: ${data['itemId']}'),
//                         subtitle: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text('Second Item: ${data['seconditem'] ?? 'N/A'}'),
//                             Text(
//                                 'Additional Data: ${secondItemData['additionalData']}'),
//                             // Add more fields from secondItemData as needed
//                           ],
//                         ),
//                       );
//                     }
//                   },
//                 );
//               },
//             );
//           }
//         }
//       },
//     );
//  

class Cart extends StatefulWidget {
  @override
  _CartContentState createState() => _CartContentState();
}

class _CartContentState extends State<Cart> {
  Future<DocumentSnapshot>? _itemDataFuture;

  @override
  void initState() {
    super.initState();
    _fetchItemData();
  }

  Future<void> _fetchItemData() async {
    setState(() {
      _itemDataFuture = fetchItemData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cart'),
      ),
      body: Center(
        child: FutureBuilder<DocumentSnapshot>(
          future: _itemDataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else if (!snapshot.hasData || !snapshot.data!.exists) {
              return Text('Item data does not exist!');
            } else {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Item data fetched successfully!',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Item title: ${snapshot.data!['title']}',
                    style: TextStyle(fontSize: 18),
                  ),
                  // Add other widgets to display additional item data here
                ],
              );
            }
          },
        ),
      ),
    );
  }
}

// Function to fetch data from Firestore
Future<DocumentSnapshot> fetchItemData() async {
  print('Fetching item data...');
  try {
    DocumentSnapshot snapshot = await FirebaseFirestore.instance
        .collection('ItemTypesItems')
        .doc('vAcjtjudDqDDHR92buL3')
        .collection('userItems')
        .doc('rk4ZblyV3vGZ6cTHrhOb')
        .get();
    if (snapshot.exists) {
      print('Item data fetched successfully!');
      // print(
      //     'Item title: ${snapshot.data()?['title']}'); // Print the title field
    } else {
      print('Item data does not exist!');
    }
    return snapshot;
  } catch (e) {
    print('Error fetching item data: $e');
    throw e; // Rethrow the error for handling further up the call stack if needed
  }
}

  // Function to fetch second item data from Firestore
  Future<DocumentSnapshot> fetchSecondItem(
      String itemId, String seconditem) async {
    print('Fetching second item data for Item ID: $itemId');
    return FirebaseFirestore.instance
        .collection('ItemTypesItems')
        .doc(itemId)
        .collection('userItems')
        .doc(seconditem) // ID is the same as the itemId
        .get();
  }


// // Function to fetch data from Firestore
// Future<DocumentSnapshot> fetchItemData() async {
//   return FirebaseFirestore.instance
//       .collection('ItemTypesItems')
//       .doc('vAcjtjudDqDDHR92buL3')
//       .collection('userItems')
//       .doc('rk4ZblyV3vGZ6cTHrhOb')
//       .get();
// }

// // Function to fetch second item data from Firestore
// Future<DocumentSnapshot> fetchSecondItem(
//     String itemId, String seconditem) async {
//   return FirebaseFirestore.instance
//       .collection('ItemTypesItems')
//       .doc(itemId)
//       .collection('userItems')
//       .doc(seconditem) // ID is the same as the itemId
//       .get();
// }
