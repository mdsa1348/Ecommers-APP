import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class DetailedItemPage extends StatelessWidget {
  final String itemId;
  final String seconditem;
  final Map<String, dynamic> item;

  DetailedItemPage(
      {required this.itemId, required this.seconditem, required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Item Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display item image with transparent background
            GestureDetector(
              onTap: () {
                _showFullImage(context, item['imageUrl']);
              },
              child: Hero(
                tag:
                    'item_image_${item['itemId']}', // Unique tag for Hero animation
                child: CachedNetworkImage(
                  imageUrl: item['imageUrl'],
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                  fit: BoxFit.cover,
                  width: MediaQuery.of(context).size.width,
                  height: 300, // Adjust height as needed
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Display item details
            Center(
              child: Text(
                item['title'],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Description: ${item['description'] ?? 'N/A'}',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 25),
            Text(
              'Amount: ${item['amount'] != null ? '${item['amount']} tk' : 'N/A'}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),
            Text(
              'Item Amount: ${item['itemamount'] != null ? '${item['itemamount']} piece' : 'N/A'}',
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 28, 89, 30)),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 35),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: CircularProgressIndicator()));
                // Call function to add item to cart
                addToCartToFirestore(context, itemId, seconditem);
              },
              child: const Text('Add to Cart'),
            ),
            ElevatedButton(
              onPressed: () {
                _showBuyDialog(context);
              },
              child: const Text('Buy'),
            ),
          ],
        ),
      ),
    );
  }

  // Function to show full image in a dialog
  void _showFullImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            //placeholder: (context, url) => CircularProgressIndicator(),
            errorWidget: (context, url, error) => const Icon(Icons.error),
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  // Function to show dialog for buying item
  void _showBuyDialog(BuildContext context) {
    String itemAmount = ''; // Variable to store item amount
    String deliveryDate = ''; // Variable to store delivery date

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Buy Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Item Amount'),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                itemAmount = value; // Update item amount when input changes
              },
            ),
            const SizedBox(height: 10),
            TextField(
              decoration: const InputDecoration(
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
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // Call function to add item to buy list

              await addToBuyToFirestore(context, itemId, seconditem, itemAmount,
                  deliveryDate, item['amount']);
              Navigator.of(context).pop();
            },
            child: const Text('Buy'),
          ),
        ],
      ),
    );
  }

  // Function to add item to cart in Firestore
  Future<void> addToCartToFirestore(
      BuildContext context, String itemId, String seconditem) async {
    try {
      // Get current user
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String userId = user.uid;

        // Check if the collection exists
        bool collectionExists = await doesCollectionExist('Cart');

        // If the collection doesn't exist, create it
        if (!collectionExists) {
          await FirebaseFirestore.instance.collection('Cart').doc().set({});
        }

        // Check if the item already exists in the user's cart with the same itemId and same seconditem
        bool itemExists = await FirebaseFirestore.instance
            .collection('Cart')
            .doc(userId)
            .collection('items')
            .where('itemId', isEqualTo: itemId)
            .where('seconditem', isEqualTo: seconditem)
            .limit(1)
            .get()
            .then((querySnapshot) => querySnapshot.size > 0);

        if (!itemExists) {
          // Item doesn't exist, so add it to the cart
          await FirebaseFirestore.instance
              .collection('Cart')
              .doc(userId) // Use user's ID as document ID
              .collection('items') // Subcollection for user's items
              .add({
            'itemId': itemId,
            'seconditem': seconditem,
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Item added to cart')),
          );
        } else {
          // Item already exists in the cart, show message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Item already exists in the cart')),
          );
        }
      } else {
        // Handle case where user is not signed in
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User is not signed in')),
        );
      }
    } catch (e) {
      print('Error adding item to cart: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to add item to cart')),
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

  // Function to add item to buy list in Firestore
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
