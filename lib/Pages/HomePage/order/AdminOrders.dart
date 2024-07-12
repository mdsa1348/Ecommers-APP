import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobo_game/Pages/HomePage/order/AdminOrderDetails.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminOrdersPage extends StatefulWidget {
  @override
  _AdminOrdersPageState createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends State<AdminOrdersPage> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Shops Order'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by shop name',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                // Call buildResults with _searchController
                setState(() {}); // Trigger rebuild to update search results
              },
            ),
          ),
          Expanded(
            child: _searchController.text.isNotEmpty
                ? buildResults(context, _searchController.text)
                : StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('AdminsBuy')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      } else {
                        final adminBuyDocs = snapshot.data!.docs;
                        return SingleChildScrollView(
                          child: Column(
                            children: [
                              for (final adminBuyDoc in adminBuyDocs)
                                Builder(
                                  builder: (BuildContext context) {
                                    final adminBuyData = adminBuyDoc.data()
                                        as Map<String, dynamic>;
                                    final usersId = adminBuyData['UsersId'];
                                    if (usersId is String) {
                                      return FutureBuilder<DocumentSnapshot>(
                                        future: FirebaseFirestore.instance
                                            .collection('userProfiles')
                                            .doc(usersId)
                                            .get(),
                                        builder: (context, userSnapshot) {
                                          if (userSnapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return CircularProgressIndicator();
                                          } else if (userSnapshot.hasError) {
                                            return Text(
                                                'Error: ${userSnapshot.error}');
                                          } else if (!userSnapshot.hasData ||
                                              userSnapshot.data == null) {
                                            return Card(
                                              child: ListTile(
                                                title: Text('User not found'),
                                              ),
                                            );
                                          } else {
                                            final userData = userSnapshot.data!
                                                .data() as Map<String, dynamic>;
                                            final userName =
                                                userData['name'] ?? 'N/A';
                                            final shopName =
                                                userData['shopname'] ?? 'N/A';
                                            final secondphone =
                                                userData['secondphone'] ??
                                                    'N/A';
                                            final userAddress =
                                                userData['address'] ?? 'N/A';
                                            final phoneNumber =
                                                userData['phoneNumber'] ??
                                                    'N/A';
                                            return GestureDetector(
                                              onLongPress: () {
                                                showOptionsDialog(context,
                                                    phoneNumber, secondphone);
                                              },
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        AdminOrderDetailWidget(
                                                            userId: usersId),
                                                  ),
                                                );
                                              },
                                              child: Card(
                                                child: ListTile(
                                                  title: Text(
                                                      'Shop Name: $shopName'),
                                                  subtitle: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text('Name: $userName'),
                                                      Text(
                                                          'Address: $userAddress'),
                                                      Text(
                                                          'Phone Number: $phoneNumber'),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                      );
                                    } else {
                                      print(
                                          'Invalid or missing UsersId field in document ${adminBuyDoc.id}');
                                      return SizedBox.shrink();
                                    }
                                  },
                                ),
                            ],
                          ),
                        );
                      }
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void showOptionsDialog(
      BuildContext context, String phoneNumber, String secondphone) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Options'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('Call This User'),
                onTap: () {
                  callFunction(context, phoneNumber, secondphone);
                },
              ),
              ListTile(
                title: Text('Cancel This Order'),
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

  void callFunction(
      BuildContext context, String phoneNumber, String secondphone) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Call Options'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('Verified Number'),
                onTap: () {
                  if (phoneNumber != null) {
                    try {
                      launch("tel:$phoneNumber");
                    } catch (e) {
                      print('Error launching phone call: $e');
                    }
                  } else {
                    print('User phone number not found');
                  }
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                title: Text('Secondary Number'),
                onTap: () {
                  if (secondphone != null) {
                    try {
                      launch("tel:$secondphone");
                    } catch (e) {
                      print('Error launching phone call: $e');
                    }
                  } else {
                    print('User phone number not found');
                  }
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                title: Text('Cancel This Order'),
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

  Widget buildResults(BuildContext context, String searchText) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('userProfiles').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          final items = snapshot.data!.docs;
          // Filter items based on searchText
          final filteredItems = items.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final shopname = data['shopname'] as String?;
            // Perform case-insensitive search
            return shopname?.toLowerCase().contains(searchText.toLowerCase()) ??
                false;
          }).toList();
          print('Search results: $filteredItems');
          return ListView.builder(
            itemCount: filteredItems.length,
            itemBuilder: (context, index) {
              final item = filteredItems[index].data() as Map<String, dynamic>;
              // Handle null values gracefully
              final shopname = item['shopname'] as String? ?? 'N/A';
              final name = item['name'] as String? ?? 'N/A';
              final secondphone = item['secondphone'] ?? 'N/A';
              final userAddress = item['address'] ?? 'N/A';
              final phoneNumber = item['phoneNumber'] ?? 'N/A';
              final userId = filteredItems[index].id; // Extract UsersId
              return GestureDetector(
                onTap: () {
                  // Maintain onTap function with null check for UsersId
                  print('Error: UsersId is null $userId');

                  //final userId = item['UsersId'] as String?;
                  if (userId != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AdminOrderDetailWidget(userId: userId),
                      ),
                    );
                  } else {
                    print('Error: UsersId is null');
                  }
                },
                onLongPress: () {
                  showOptionsDialog(context, phoneNumber, secondphone);
                },
                child: Card(
                  color: Colors.grey[200], // Background color
                  child: ListTile(
                    title: Text('Shop Name: $shopname'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Name: $name'),
                        Text('Address: $userAddress'),
                        Text('Phone Number: $phoneNumber'),
                        Text('Second Phone Number: $secondphone'),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        }
      },
    );
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        Navigator.of(context).pop();
      },
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          _searchController.clear();
          buildResults(context, '');
        },
      ),
    ];
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    // Return an empty container as we're not implementing suggestions based on shop name
    return Container();
  }
}
