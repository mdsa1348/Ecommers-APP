import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:mobo_game/Pages/Admin/AdimBuy.dart';

class OrderDeliverid extends StatefulWidget {
  @override
  _OrderDeliveridState createState() => _OrderDeliveridState();
}

class _OrderDeliveridState extends State<OrderDeliverid> {
  late double finalBalance;
  late double total;
  @override
  void initState() {
    super.initState();
    finalBalance = 0.0;
    total = 0.0;
    // Initialize final balance
    calculateTotalAmount(); // Calculate total amount initially
  }

  void calculateTotalAmount() {
    final user = FirebaseAuth.instance.currentUser;
    final userId = user!.uid;

    FirebaseFirestore.instance
        .collection('Buy')
        .doc(userId)
        .collection('items')
        .where('delivaryConfirm', isEqualTo: 'true')
        .get()
        .then((querySnapshot) {
      double total = 0.0;
      querySnapshot.docs.forEach((doc) {
        double amount = double.parse(doc['totalamount']);
        total += amount;
      });
      setState(() {
        finalBalance = total;
      });
    }).catchError((error) {
      print('Error calculating total amount: $error');
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userId = user!.uid;

    final FirebaseAuth _auth = FirebaseAuth.instance;
    User? currentUser = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
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
          if (currentUser != null &&
    (currentUser.email == "mdsakib134867@gmail.com" ||
        currentUser.email == "mdkowsaralamrony@gmail.com"))
            Row(
              children: [
                // Inside the build method
                Text(
                  '${finalBalance.toStringAsFixed(2)}tk', // Move toStringAsFixed here
                  style: TextStyle(fontSize: 18.0),
                ),

                SizedBox(width: 8),
                Icon(Icons.account_balance_wallet),
                SizedBox(width: 16),
              ],
            ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Buy')
            .doc(userId)
            .collection('items')
            .where('delivaryConfirm', isEqualTo: 'true') // Filter condition
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final items = snapshot.data!.docs;

            // Recalculate final balance when data changes
            //finalBalance = 0.0; // Reset final balance
            for (var item in items) {
              String totalAmount = item['totalamount'];
              double amountValue = double.parse(totalAmount);

              if (totalAmount != null) {
                finalBalance += amountValue;
              }
            }

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
                final paid = item['paid'];
                final due = item['due'];
                final delivaryConfirm = item['delivaryConfirm'];
                final delivaryConfirmDate = item['delivaryConfirmDate'];

                double amountValue = double.parse(totalamount);
                finalBalance += amountValue;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 15.0),
                  child: FutureBuilder<DocumentSnapshot>(
                    future: fetchSecondItem(itemId, secondItem),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      } else if (!snapshot.hasData || !snapshot.data!.exists) {
                        return const Text('Item not found');
                      } else {
                        final itemData = snapshot.data!;
                        final itemTitle = itemData['title'];
                        final imageUrl = itemData['imageUrl'];
                        final amount = itemData['amount'];

                        return GestureDetector(
                          onTap: () {},
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
                                      Text('My Require: $itemAmount pieces',
                                          style: const TextStyle(
                                            fontSize: 14.0,
                                            fontWeight: FontWeight.bold,
                                            backgroundColor: Color.fromARGB(
                                                255, 36, 187, 43),
                                          )),
                                      Text('Total Amount: $totalamount tk',
                                          style: const TextStyle(
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
                                            'Delivery On(D-M-Y): ${DateFormat('d-M-y').format(delivaryConfirmDate.toDate())} ',
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

}
