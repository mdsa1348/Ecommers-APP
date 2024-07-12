import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mobo_game/Pages/Admin/Admindetails.dart'; // Import your UserDetailWidget if not already imported

class AdminDetailsPage extends StatefulWidget {
  @override
  _AdminDetailsPageState createState() => _AdminDetailsPageState();
}

class _AdminDetailsPageState extends State<AdminDetailsPage> {
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
        title: Text('Admin Details'),
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
                setState(() {}); // Trigger rebuild to update search results
              },
            ),
          ),
          Expanded(
            child: _searchController.text.isNotEmpty
                ? buildResults(context, _searchController.text)
                : buildAdminDetails(context),
          ),
        ],
      ),
    );
  }

  Widget buildAdminDetails(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('AdminsBuy')
          
          .orderBy('buyTime',
              descending: false) // Assuming buyTime is a timestamp field
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
                      final adminBuyData =
                          adminBuyDoc.data() as Map<String, dynamic>;
                      final usersId = adminBuyData['UsersId'];
                      if (usersId is String) {
                        print(
                            'User ID in document ${adminBuyDoc.id}: $usersId');
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
                              return Text('Error: ${userSnapshot.error}');
                            } else if (!userSnapshot.hasData ||
                                userSnapshot.data == null) {
                              return Card(
                                child: ListTile(
                                  title: Text('User not found'),
                                ),
                              );
                            } else {
                              final userData = userSnapshot.data!.data()
                                  as Map<String, dynamic>;
                              final userName = userData['name'] ?? 'N/A';
                              final shopName = userData['shopname'] ?? 'N/A';
                              final secondphone =
                                  userData['secondphone'] ?? 'N/A';
                              final userAddress = userData['address'] ?? 'N/A';
                              final phoneNumber =
                                  userData['phoneNumber'] ?? 'N/A';
                                   final buyTime = adminBuyData['buyTime'] as Timestamp?;
                            final formattedBuyTime = buyTime != null
                                ? DateFormat('yyyy-MM-dd HH:mm:ss').format(buyTime.toDate())
                                : 'N/A';
                                
                              return GestureDetector(
                                onLongPress: () {
                                  showOptionsDialog(
                                      context, phoneNumber, secondphone);
                                },
                                onTap: () {
                                  print('User ID in document : $usersId');
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          UserDetailWidget(userId: usersId),
                                    ),
                                  );
                                },
                                child: Card(
                                  child: ListTile(
                                    title: Text('Shop Name: $shopName'),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Name: $userName'),
                                        Text('Address: $userAddress'),
                                        Text('Phone Number: $phoneNumber'),
                                        Text('Buy Time: $formattedBuyTime'),
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
          final filteredItems = items.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final shopname = data['shopname'] as String?;
            return shopname?.toLowerCase().contains(searchText.toLowerCase()) ??
                false;
          }).toList();
          print('Search results: $filteredItems');
          return ListView.builder(
            itemCount: filteredItems.length,
            itemBuilder: (context, index) {
              final item = filteredItems[index].data() as Map<String, dynamic>;
              final shopname = item['shopname'] as String? ?? 'N/A';
              final name = item['name'] as String? ?? 'N/A';
              final secondphone = item['secondphone'] ?? 'N/A';
              final userAddress = item['address'] ?? 'N/A';
              final phoneNumber = item['phoneNumber'] ?? 'N/A';
              final userId = filteredItems[index].id;
              return GestureDetector(
                onTap: () {
                  if (userId != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserDetailWidget(userId: userId),
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
                  color: Colors.grey[200],
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
          setState(() {}); // Trigger rebuild to update search results
        },
      ),
    ];
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return Container(); // Not implementing suggestions based on shop name
  }
}
