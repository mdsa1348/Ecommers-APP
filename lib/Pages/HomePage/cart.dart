import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobo_game/Pages/HomePage/CartTobuy.dart';

class CartContent extends StatefulWidget {
  @override
  _CartContentState createState() => _CartContentState();
}

class _CartContentState extends State<CartContent> {
  late Stream<QuerySnapshot> _itemsStream;
  late User _user;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser!;
    _itemsStream = FirebaseFirestore.instance
        .collection('Cart')
        .doc(_user.uid)
        .collection('items')
        .snapshots();
  }

  @override
  void dispose() {
    super.dispose();
    // Dispose the stream to avoid memory leaks
    _itemsStream.drain();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cart'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _itemsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final items = snapshot.data!.docs;
            return ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final selecteditemId = item.id;
                final secondItem = item['seconditem'];
                final itemId = item['itemId'];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 15.0),
                  child: FutureBuilder<DocumentSnapshot>(
                    future: fetchSecondItem(itemId, secondItem),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Text('Network Connection Poor');
                      } else if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      } else if (!snapshot.hasData || !snapshot.data!.exists) {
                        return Text('Item not found or Maybe deleted by Admin');
                      } else {
                        final itemData = snapshot.data!;
                        final itemTitle = itemData['title'];
                        final imageUrl = itemData['imageUrl'];
                        final amount = itemData['amount'];
                        return GestureDetector(
                          onTap: () {
                            showOptionsDialog(
                                context, selecteditemId, secondItem, itemId);
                          },
                          child: Container(
                            color: index % 2 == 0
                                ? Colors.grey[200]
                                : Colors.white,
                            padding: EdgeInsets.symmetric(
                                vertical: 8.0, horizontal: 16.0),
                            child: Row(
                              children: [
                                CachedNetworkImage(
                                  imageUrl: imageUrl,
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                  errorWidget: (context, url, error) =>
                                      Icon(Icons.error),
                                ),
                                SizedBox(width: 10.0),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Item Title: $itemTitle',
                                        style: TextStyle(
                                          fontSize: 16.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text('Amount: $amount tk',
                                          style: TextStyle(
                                            fontSize: 14.0,
                                            fontWeight: FontWeight.bold,
                                          )),
                                      Text('Item ID: $itemId',
                                          style: TextStyle(fontSize: 14.0)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                    },
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }

  void showOptionsDialog(BuildContext context, String selecteditemId,
      String secondItem, String itemId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Options'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('Buy'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CartToBuyPage(
                        itemId: itemId,
                        secondItem: secondItem,
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                title: Text('Close'),
                onTap: () {
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                title: Text('Delete this item'),
                onTap: () {
                  showDeleteConfirmationDialog(context, selecteditemId);
                },
              ),
              ListTile(
                title: Text('Delete Entire Cart'),
                onTap: () {
                  showDeleteEntireConfirmationDialog(context, selecteditemId);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Function to show dialog for buying item
  void _showBuyDialog(BuildContext context, String secondItem, String itemId) {
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
              Navigator.of(context).pop();

              await addToBuyToFirestore(
                  context, itemId, secondItem, itemAmount, deliveryDate);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Item added to Buy')),
              );
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

  // Function to add item to buy list in Firestore
  Future<void> addToBuyToFirestore(BuildContext context, String itemId,
      String seconditem, String itemAmount, String deliveryDate) async {
    try {
      // Get current user
      User? user = FirebaseAuth.instance.currentUser;
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
            .limit(1)
            .get()
            .then((querySnapshot) => querySnapshot.size > 0);

        if (!itemExists) {
          // Add item to Firestore Buy collection
          await FirebaseFirestore.instance
              .collection('Buy')
              .doc(userId) // Use user's ID as document ID
              .collection('items') // Subcollection for user's items
              .add({
            'itemId': itemId,
            'seconditem': seconditem,
            'itemAmount': itemAmount,
            'OrderConfirm': 'false',
            'deliveryDate': deliveryDate,
            'buyTime': now, // Add current time of buying
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
            });
          }

          // ScaffoldMessenger.of(context).showSnackBar(
          //   SnackBar(content: Text('Item added to Buy')),
          // );
        } else {
          // Item already exists in the cart, show message
          // ScaffoldMessenger.of(context).showSnackBar(
          //   SnackBar(content: Text('Item already exists in the Buy')),
          // );
        }
      } else {
        // Handle case where user is not signed in
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(content: Text('User is not signed in')),
        // );
      }
    } catch (e) {
      print('Error adding item to buy list: $e');
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text('Failed to add item to buy list')),
      // );
    }
  }

  void showDeleteEntireConfirmationDialog(BuildContext context, String itemId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Confirmation'),
          content: Text('Are you sure you want to delete this Entire Cart?'),
          actions: [
            TextButton(
              onPressed: () {
                // Cancel the deletion
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Perform the deletion
                await _deleteEntireItem(itemId);
                // Close both confirmation and options dialogs
                Navigator.of(context)
                    .popUntil(ModalRoute.withName(Navigator.defaultRouteName));
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteEntireItem(String itemId) async {
    final user = FirebaseAuth.instance.currentUser;
    final userId = user!.uid;
    print('Fetching second item data for Item ID: $itemId');

    try {
      // Delete all documents within the 'items' subcollection
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('Cart')
          .doc(userId) // User's ID as document ID
          .collection('items')
          .get();

      // Loop through each document and delete it
      for (DocumentSnapshot docSnapshot in querySnapshot.docs) {
        await docSnapshot.reference.delete();
      }

      print('All items deleted successfully!');
    } catch (error) {
      print('Error deleting items: $error');
    }
  }

  void showDeleteConfirmationDialog(BuildContext context, String itemId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Confirmation'),
          content: Text('Are you sure you want to delete this item?'),
          actions: [
            TextButton(
              onPressed: () {
                // Cancel the deletion
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Perform the deletion
                await _deleteItem(itemId);
                // Close both confirmation and options dialogs
                Navigator.of(context)
                    .popUntil(ModalRoute.withName(Navigator.defaultRouteName));
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<DocumentSnapshot> fetchSecondItem(
      String itemId, String secondItem) async {
    print('Fetching second item data for Item ID: $itemId');
    return FirebaseFirestore.instance
        .collection('ItemTypesItems')
        .doc(itemId)
        .collection('userItems')
        .doc(secondItem)
        .get();
  }

  Future<void> _deleteItem(String itemId) async {
    final user = FirebaseAuth.instance.currentUser;
    final userId = user!.uid;
    print('Fetching second item data for Item ID: $itemId');

    try {
      await FirebaseFirestore.instance
          .collection('Cart')
          .doc(userId) // User's ID as document ID
          .collection('items')
          .doc(itemId) // Document ID of the item to delete
          .delete();

      print('Item deleted successfully!');
    } catch (error) {
      print('Error deleting item: $error');
    }
  }
}
