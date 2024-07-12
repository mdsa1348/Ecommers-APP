import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobo_game/Pages/Admin/AdimBuy.dart';
import 'package:intl/intl.dart';

class BuyContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userId = user!.uid;

    final FirebaseAuth _auth = FirebaseAuth.instance;
    User? currentUser = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buy'),
        actions: [
          // Admin panel settings button
          if (currentUser != null &&
    (currentUser.email == "mdsakib134867@gmail.com" ||
        currentUser.email == "mdkowsaralamrony@gmail.com"))
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              onPressed: () {
                // Navigate to the admin details page
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AdminDetailsPage()),
                );
              },
            ),
          // Admin panel settings button for other users
          // if (currentUser != null &&
          //     currentUser.email != "mdsakib134867@gmail.com")
          //   IconButton(
          //     icon: Icon(Icons.admin_panel_settings),
          //     onPressed: () {
          //       // Navigate to the admin details page
          //       Navigator.push(
          //         context,
          //         MaterialPageRoute(builder: (context) => AdminDetailsPage()),
          //       );
          //     },
          //   ),
        ],
      ),
      body: Column(
        children: [
          // Text widget
          Container(
            padding: const EdgeInsets.all(10),
            child: const Text(
              'If Accepted(Green), Rejected(Red),None(White)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                backgroundColor: Color.fromARGB(255, 215, 213, 213),
              ),
            ),
          ),
          // StreamBuilder
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Buy')
                  .doc(userId)
                  .collection('items')
                  .where('delivaryConfirm',
                      isEqualTo: 'false') // Filter condition
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
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
                      final itemAmount = item['itemAmount'];
                      final deliveryDate = item['deliveryDate'];
                      final OrderConfirm = item['OrderConfirm'];
                      final totalamount = item['totalamount'];
                      final delivaryConfirm = item['delivaryConfirm'];
                      final delivaryConfirmDate = item['delivaryConfirmDate'];

                      print(
                          "delivaryConfirmDate....from itemid $selecteditemId....:: $delivaryConfirmDate");

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 15.0),
                        child: FutureBuilder<DocumentSnapshot>(
                          future: fetchSecondItem(itemId, secondItem),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            } else if (snapshot.hasError) {
                              return Text('Error: ${snapshot.error}');
                            } else if (!snapshot.hasData ||
                                !snapshot.data!.exists) {
                              return const Text('Item not found');
                            } else {
                              final itemData = snapshot.data!;
                              final itemTitle = itemData['title'];
                              final imageUrl = itemData['imageUrl'];
                              final amount = itemData['amount'];

                              return GestureDetector(
                                onTap: () {
                                  showOptionsDialog(
                                      context,
                                      selecteditemId,
                                      itemAmount,
                                      deliveryDate,
                                      itemId,
                                      secondItem,amount);
                                },
                                child: Container(
                                  color: getOrderConfirmColor(OrderConfirm),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 8.0, horizontal: 16.0),
                                  child: Row(
                                    children: [
                                      CachedNetworkImage(
                                        imageUrl: imageUrl,
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                        errorWidget: (context, url, error) =>
                                            const Icon(Icons.error),
                                      ),
                                      const SizedBox(width: 10.0),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Item Title: $itemTitle',
                                              style: const TextStyle(
                                                fontSize: 16.0,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text('Amount: $amount tk',
                                                style: const TextStyle(
                                                  fontSize: 14.0,
                                                  fontWeight: FontWeight.bold,
                                                )),
                                            Text(
                                                'My Require: $itemAmount pieces',
                                                style: const TextStyle(
                                                  fontSize: 14.0,
                                                  fontWeight: FontWeight.bold,
                                                  backgroundColor:
                                                      Color.fromARGB(
                                                          255, 36, 187, 43),
                                                )),
                                            Text(
                                                'Total Amount: $totalamount tk',
                                                style: const TextStyle(
                                                  fontSize: 14.0,
                                                  fontWeight: FontWeight.bold,
                                                )),
                                            Text(
                                                'Delivery On(D-M-Y): $deliveryDate',
                                                style:
                                                    TextStyle(fontSize: 14.0))
                                            // Text(
                                            //     'Delivery On(D-M-Y): ${delivaryConfirmDate != null && delivaryConfirmDate.isNotEmpty ? DateFormat('d-M-y').format(DateTime.parse(delivaryConfirmDate)) : deliveryDate}',
                                            //     style: const TextStyle(
                                            //         fontSize: 14.0))
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
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, String itemAmount,
      String deliveryDate, String itemId, String secondItem,String amount) {
    String updatedItemAmount = itemAmount;
    String updatedDeliveryDate = deliveryDate;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Item'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: const InputDecoration(labelText: 'Item Amount'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      updatedItemAmount = value;
                    },
                    controller: TextEditingController(text: itemAmount),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Delivery Date',
                      hintText: 'DD-MM-YY',
                    ),
                    keyboardType: TextInputType.datetime,
                    onChanged: (value) {
                      updatedDeliveryDate = value;
                    },
                    controller: TextEditingController(text: deliveryDate),
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
                    await updateBuyItemInFirestore(
                      context,
                      itemId,
                      secondItem,
                      updatedItemAmount,
                      updatedDeliveryDate,
                      amount
                    );
                    Navigator.of(context).pop();
                  },
                  child: const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

// Function to update item in buy list in Firestore
  Future<void> updateBuyItemInFirestore(
      BuildContext context,
      String itemId,
      String seconditem,
      String updatedItemAmount,
      String updatedDeliveryDate,String amount) async {
    try {
      print(' updating itemID in buy list: $itemId');
      print(' updating seconditem in buy list: $seconditem');

      // Get current user
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String userId = user.uid;

        double amountValue = double.parse(amount);
      int itemAmountValue = int.parse(updatedItemAmount);

      // Calculate total amount
      double totalAmount = amountValue * itemAmountValue;

        // Update the document in Firestore
        await FirebaseFirestore.instance
            .collection('Buy')
            .doc(userId)
            .collection('items')
            .doc(itemId) // Document ID of the item to update
            .update({
          'itemAmount': updatedItemAmount,
          'totalamount': totalAmount,
          'deliveryDate': updatedDeliveryDate,
          // You can update other fields similarly
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item updated')),
        );
      } else {
        // Handle case where user is not signed in
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User is not signed in')),
        );
      }
    } catch (e) {
      print('Error updating item in buy list: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update item')),
      );
    }
  }

  Color getOrderConfirmColor(String orderConfirm) {
    switch (orderConfirm) {
      case 'confirmed':
        return Colors.green; // Set green color for confirmed orders
      case 'deliveried':
        return Colors.blue; // Set green color for confirmed orders
      case 'rejected':
        return Colors.red; // Set red color for rejected orders
      default:
        return Colors.white; // Set default color
    }
  }

  void showOptionsDialog(
      BuildContext context,
      String selecteditemId,
      String itemAmount,
      String deliveryDate,
      String itemId,
      String secondItem,
      String amount) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Options'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Close'),
                onTap: () {
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                title: const Text('Edit'),
                onTap: () {
                  // Implement edit logic here
                  Navigator.of(context).pop();
                  _showEditDialog(context, itemAmount, deliveryDate,
                      selecteditemId, secondItem,amount);
                },
              ),
              ListTile(
                title: const Text('Delete'),
                onTap: () {
                  // Show confirmation dialog
                  showDeleteConfirmationDialog(context, selecteditemId);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void showDeleteConfirmationDialog(BuildContext context, String itemId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Confirmation'),
          content: const Text('Are you sure you want to delete this item?'),
          actions: [
            TextButton(
              onPressed: () {
                // Cancel the deletion
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Perform the deletion
                await _deleteItem(itemId);
                // Close both confirmation and options dialogs
                Navigator.of(context)
                    .popUntil(ModalRoute.withName(Navigator.defaultRouteName));
              },
              child: const Text('Delete'),
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
      // Check if the document meets the condition before deleting
      DocumentSnapshot itemSnapshot = await FirebaseFirestore.instance
          .collection('Buy')
          .doc(userId) // User's ID as document ID
          .collection('items')
          .doc(itemId) // Document ID of the item to delete
          .get();

// Check if the document exists
      if (itemSnapshot.exists) {
        // Cast the data to Map<String, dynamic>
        Map<String, dynamic>? data =
            itemSnapshot.data() as Map<String, dynamic>?;

        if (data != null) {
          // Check if the delivaryConfirm field is equal to "false"
          if (data['delivaryConfirm'] == 'false') {
            // Delete the document
            await itemSnapshot.reference.delete();
            print('Item deleted successfully!');
          } else {
            print('The document does not meet the deletion criteria.');
          }
        } else {
          print('Data is null or not of type Map<String, dynamic>.');
        }
      } else {
        print('The document does not exist.');
      }
    } catch (error) {
      print('Error deleting item: $error');
    }
  }
}
