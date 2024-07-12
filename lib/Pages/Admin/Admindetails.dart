import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class UserDetailWidget extends StatelessWidget {
  final String userId;

  UserDetailWidget({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Buy'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Buy')
            .doc(userId)
            .collection('items')
            .where('delivaryConfirm',
                      isEqualTo: 'false')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final items = snapshot.data!.docs;
            return SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: items.map((item) {
                  final selecteditemId = item.id;
                  final secondItem = item['seconditem'];
                  final itemId = item['itemId'];
                  final itemAmount = item['itemAmount'];
                  final deliveryDate = item['deliveryDate'];
                  final OrderConfirm = item['OrderConfirm'];
                  final delivaryConfirmDate = item['delivaryConfirmDate'];
                  final paid = item['paid'] ?? 'N/A';
                  final due = item['due'] ?? 'N/A';
                  final totalamount = item['totalamount'] ??
                      'N/A'; // Use 'N/A' if totalamount doesn't exist

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 15.0),
                    child: FutureBuilder<DocumentSnapshot>(
                      future: fetchSecondItem(itemId, secondItem),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        } else if (!snapshot.hasData ||
                            !snapshot.data!.exists) {
                          return Text('Item not found');
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
                                  secondItem,
                                  totalamount.toString(),
                                  paid.toString(),
                                  due.toString(),amount);
                            },
                            child: Container(
                              color: getOrderConfirmColor(OrderConfirm),
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
                                        Text(
                                            'Item Required: $itemAmount pieces',
                                            style: TextStyle(
                                              fontSize: 14.0,
                                              fontWeight: FontWeight.bold,
                                              backgroundColor: Color.fromARGB(
                                                  255, 36, 187, 43),
                                            )),
                                        Text('Total Ammount: $totalamount tk',
                                            style: TextStyle(
                                              fontSize: 14.0,
                                              fontWeight: FontWeight.bold,
                                            )),
                                        Text('Total Paid: $paid tk',
                                            style: const TextStyle(
                                              fontSize: 14.0,
                                              fontWeight: FontWeight.bold,
                                            )),
                                        Text('Total Due: $due tk',
                                            style: const TextStyle(
                                              fontSize: 14.0,
                                              fontWeight: FontWeight.bold,
                                            )),
                                        Text(
                                            'Delivery On(D-M-Y): ${delivaryConfirmDate != null && delivaryConfirmDate is Timestamp ? DateFormat('d-M-y').format(delivaryConfirmDate.toDate()) : deliveryDate}',
                                            style:
                                                const TextStyle(fontSize: 14.0))
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
                }).toList(),
              ),
            );
          }
        },
      ),
    );
  }

  Color getOrderConfirmColor(String orderConfirm) {
    switch (orderConfirm) {
      case 'confirmed':
        return Colors.green; // Set green color for confirmed orders
      case 'deliveried':
        return Colors.blue;
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
      String totalamount,
      String paid,
      String due,String amount) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Options'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('Confirm This Order'),
                onTap: () {
                  // Implement edit logic here
                  Navigator.of(context).pop();
                  ConfirmThisOrde(context, selecteditemId);

                  //confirmFunction(context, phoneNumber, secondphone);
                },
              ),
              SizedBox(height: 10),
              ListTile(
                title: Text('Confirm This Delivary'),
                onTap: () {
                  // Implement edit logic here
                  Navigator.of(context).pop();
                  ConfirmThisDelivary(context, selecteditemId, totalamount,
                      itemAmount, paid, due);
                },
              ),
              SizedBox(height: 10),
              ListTile(
                title: Text('Edit'),
                onTap: () {
                  // Implement edit logic here
                  Navigator.of(context).pop();
                  _showEditDialog(context, itemAmount, deliveryDate,
                      selecteditemId, secondItem, totalamount,amount);
                },
              ),
              SizedBox(height: 10),
              ListTile(
                title: Text('Reject This Order'),
                onTap: () {
                  // Implement edit logic here
                  Navigator.of(context).pop();
                  RejectThisDelivary(context, selecteditemId);
                  //confirmFunction(context, phoneNumber, secondphone);
                },
              ),
              ListTile(
                title: Text('Close'),
                onTap: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void RejectThisDelivary(BuildContext context, String selecteditemId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Reject Confirmation'),
          content: Text('Are you sure you want to Reject this item?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                FirebaseFirestore.instance
                    .collection('Buy')
                    .doc(userId)
                    .collection('items')
                    .doc(selecteditemId)
                    .update({
                  'OrderConfirm': 'rejected',
                }).then((_) {
                  print('Order Reject updated successfully.');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Order Reject updated successfully.')),
                  );
                }).catchError((error) {
                  print('Error updating order confirmation: $error');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Order Reject updated Failed.')),
                  );
                });
              },
              child: Text('Confirmation'),
            ),
          ],
        );
      },
    );
  }

  void ConfirmThisDelivary(BuildContext context, String selecteditemId,
      String totalamount, String itemAmount, String paid, String due) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Delivary'),
          content: Text('Are you sure you want to Confirm this Delivary?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                _showBuyDialog(
                    context, selecteditemId, totalamount, itemAmount, paid);
              },
              child: Text('Confirmation'),
            ),
          ],
        );
      },
    );
  }

  void _showBuyDialog(BuildContext context, String selecteditemId,
      String totalamount, String itemAmount, String paid) {
    TextEditingController itemAmountController =
        TextEditingController(text: itemAmount);
    TextEditingController totalAmountController =
        TextEditingController(text: totalamount);
    TextEditingController paidController = TextEditingController(text: '');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Buy Item'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: itemAmountController,
                decoration: const InputDecoration(
                    labelText: 'Items Amount You will give :'),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  // You can remove this onChanged callback if you don't need to update the value in real-time
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: totalAmountController,
                decoration: const InputDecoration(labelText: 'Total Amount :'),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  // You can remove this onChanged callback if you don't need to update the value in real-time
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: paidController,
                decoration:
                    const InputDecoration(labelText: 'Paid Amount(tk):'),
                keyboardType: TextInputType.number,
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
                Navigator.of(context).pop();

                // Parse the input as double
                double newPaidAmount = double.parse(paidController.text);
                double totalAmount = double.parse(totalAmountController.text);

                // Fetch current paid amount from Firestore
                double currentPaidAmount = double.parse(paid);

                // Add the new paid amount to the current paid amount
                double paidValue = currentPaidAmount + newPaidAmount;

                // Calculate the due amount
                double dueAmount = totalAmount - paidValue;

                // Call function to add item to buy list
                DateTime now = DateTime.now();

                // Update Firestore document with updated paid value and calculated due amount
                await FirebaseFirestore.instance
                    .collection('Buy')
                    .doc(userId)
                    .collection('items')
                    .doc(selecteditemId)
                    .update({
                  'delivaryConfirm': 'true',
                  'itemAmount': itemAmountController.text,
                  'totalamount': totalAmountController.text,
                  'paid': paidValue, // Update with updated paid value
                  'due': dueAmount, // Update with calculated due amount
                  'OrderConfirm': 'deliveried',
                  'delivaryConfirmDate': now,
                });
              },
              child: const Text('Buy'),
            ),
          ],
        );
      },
    );
  }

  void ConfirmThisOrde(BuildContext context, String selecteditemId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Order Confirmation'),
          content: Text('Are you sure you want to Confirmation this Order?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                FirebaseFirestore.instance
                    .collection('Buy')
                    .doc(userId)
                    .collection('items')
                    .doc(selecteditemId)
                    .update({
                  'OrderConfirm': 'confirmed',
                }).then((_) {
                  print('Order confirmation updated successfully.');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content:
                            Text('Order confirmation updated successfully.')),
                  );
                }).catchError((error) {
                  print('Error updating order confirmation: $error');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Order confirmation updated Failed.')),
                  );
                });
              },
              child: Text('Confirmation'),
            ),
          ],
        );
      },
    );
  }

  void _showEditDialog(
      BuildContext context,
      String itemAmount,
      String deliveryDate,
      String itemId,
      String secondItem,
      String totalamount,String amount) {
    String updatedItemAmount = itemAmount;
    String updatedDeliveryDate = deliveryDate;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Edit Item'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: InputDecoration(labelText: 'Item Amount'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      updatedItemAmount = value;
                    },
                    controller: TextEditingController(text: itemAmount),
                  ),
                  
                  SizedBox(height: 10),
                  TextField(
                    decoration: InputDecoration(
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
                  child: Text('Cancel'),
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
                  child: Text('Update'),
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
      String updatedDeliveryDate,
      String amount) async {
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
          SnackBar(content: Text('Item updated')),
        );
      } else {
        // Handle case where user is not signed in
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User is not signed in')),
        );
      }
    } catch (e) {
      print('Error updating item in buy list: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update item')),
      );
    }
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
    print('Fetching second item data for Item ID: $itemId');

    try {
      await FirebaseFirestore.instance
          .collection('Buy')
          .doc(userId)
          .collection('items')
          .doc(itemId)
          .delete();

      print('Item deleted successfully!');
    } catch (error) {
      print('Error deleting item: $error');
    }
  }
}
