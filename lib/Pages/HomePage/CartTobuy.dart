import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CartToBuyPage extends StatelessWidget {
  final String itemId;
  final String secondItem;

  CartToBuyPage({required this.itemId, required this.secondItem});

  Future<DocumentSnapshot> fetchItem() async {
    return FirebaseFirestore.instance
        .collection('ItemTypesItems')
        .doc(itemId)
        .collection('userItems')
        .doc(secondItem)
        .get();
  }

  @override
  Widget build(BuildContext context) {
    final Future<DocumentSnapshot> _itemFuture = fetchItem();

    return Scaffold(
      appBar: AppBar(
        title: Text('Item Details'),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: _itemFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text('Item not found'));
          } else {
            final itemData = snapshot.data!;
            final itemTitle = itemData['title'];
            final imageUrl = itemData['imageUrl']; // Assuming imageUrl exists
            final amount = itemData['amount']; // Assuming amount exists
            final description =
                itemData['description']; // Assuming amount exists
            final itemamount = itemData['itemamount']; // Assuming amount exists

            return SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Display Item Title

                  SizedBox(height: 10.0),

                  // Display Item Image if available
                  if (imageUrl != null)
                    Image.network(
                      imageUrl,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  SizedBox(height: 10.0),
                  Text(
                    'Title: $itemTitle',
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10.0),
                  Text(
                    'Description: $description ',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10.0),

                  // Display Item Amount
                  Text(
                    'Amount: $amount tk',
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10.0),
                  Text(
                    'Item Amount: $itemamount tk',
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10.0),

                  // Other Details (if available)
                  // You can add more details here based on your Firestore document structure

                  // Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(width: 20.0),
                      ElevatedButton(
                        onPressed: () {
                          // Action to buy the item
                          _showBuyDialog(context, amount);
                        },
                        child: Text('Buy Now'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  // Function to show dialog for buying item
  void _showBuyDialog(BuildContext context, String amount) {
    String itemAmount = ''; // Variable to store item amount
    String deliveryDate = ''; // Variable to store delivery date

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Buy Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(labelText: 'Item Amount'),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                itemAmount = value; // Update item amount when input changes
              },
            ),
            SizedBox(height: 10),
            TextField(
              decoration: InputDecoration(
                labelText: 'Delivery Date',
                hintText: 'DD--MM-YY', // Placeholder text
              ),
              keyboardType: TextInputType.datetime,
              onChanged: (value) {
                deliveryDate = value; // Update delivery date when input changes
              },
              // You may use a date picker here for better user experience
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // Call function to add item to buy list
              await addToBuyToFirestore(context, itemId, secondItem, itemAmount,
                  deliveryDate, amount);
              Navigator.of(context).pop();
            },
            child: Text('Buy'),
          ),
        ],
      ),
    );
  }

// Function to check if a collection exists
  Future<bool> doesCollectionExist(String collectionName) async {
    QuerySnapshot collectionSnapshot = await FirebaseFirestore.instance
        .collection(collectionName)
        .limit(1)
        .get();
    return collectionSnapshot.docs.isNotEmpty;
  }

  Future<void> addToBuyToFirestore(
      BuildContext context,
      String itemId,
      String seconditem,
      String itemAmount,
      String deliveryDate,
      String amount) async {
    try {
      // Get current user
      User? user = FirebaseAuth.instance.currentUser;

      // Convert amount and itemAmount to numeric types
      double amountValue = double.parse(amount);
      int itemAmountValue = int.parse(itemAmount);

      // Calculate total amount
      double totalAmount = amountValue * itemAmountValue;

      if (user != null) {
        String userId = user.uid;

        // Check if the collection exists
        bool collectionExists = await doesCollectionExist('Buy');

        // If the collection doesn't exist, create it
        if (!collectionExists) {
          await FirebaseFirestore.instance.collection('Buy').doc().set({});
        }

        // Retrieve user input for item amount and delivery date
        // For simplicity, assume you've stored these inputs in variables

        DateTime now = DateTime.now();

        bool itemExists = await FirebaseFirestore.instance
            .collection('Buy')
            .doc(userId)
            .collection('items')
            .where('itemId', isEqualTo: itemId)
            .where('seconditem', isEqualTo: seconditem)
            .where('delivaryConfirm', isEqualTo: 'false')
            .limit(1)
            .get()
            .then((querySnapshot) => querySnapshot.size > 0);

        if (!itemExists) {
          // Add item to Firestore Buy collection
          await FirebaseFirestore.instance
              .collection('Buy')
              .doc(userId)
              .collection('items')
              .add({
            'itemId': itemId,
            'seconditem': seconditem,
            'itemAmount': itemAmount,
            'totalamount': totalAmount,
            'OrderConfirm': 'false',
            'delivaryConfirm': 'false',
            'deliveryDate': deliveryDate,
            'paid': 0, // Store as numeric type, initially set to 0
            'due': 0, // Store as numeric type, initially set to 0
            'buyTime': now,
            'delivaryConfirmDate': null, // Set to null initially
          });

          // Check if the collection exists
          bool collectionExists = await doesCollectionExist('AdminsBuy');

          bool itemExistss = await FirebaseFirestore.instance
              .collection('AdminsBuy')
              .where('UsersId', isEqualTo: userId)
              .limit(1)
              .get()
              .then((querySnapshot) => querySnapshot.size > 0);

          // If the collection doesn't exist, create it
          if (!collectionExists) {
            await FirebaseFirestore.instance
                .collection('AdminsBuy')
                .doc()
                .set({});
          }
          if (!itemExistss) {
            await FirebaseFirestore.instance.collection('AdminsBuy').add({
              'UsersId': userId,
              'seconditem': seconditem,
              'buyTime': now,
            });
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Item added to Buy')),
          );
        } else {
          // Item already exists in the cart, show message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Item already exists in the Buy')),
          );
        }
      } else {
        // Handle case where user is not signed in
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User is not signed in')),
        );
      }
    } catch (e) {
      print('Error adding item to buy list: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to add item to buy list')),
      );
    }
  }
}
