import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mobo_game/Pages/Authenticate/location.dart';
import 'package:mobo_game/Pages/Authenticate/singin.dart';
import 'package:mobo_game/Pages/Authenticate/userLocation.dart';
import 'package:mobo_game/Pages/HomePage/Buy.dart';
import 'package:mobo_game/Pages/HomePage/HomeBody.dart';
import 'package:mobo_game/Pages/HomePage/order/AdminOrders.dart';
import 'package:mobo_game/Pages/HomePage/order/OrderDeliveried.dart';
import 'package:mobo_game/Pages/HomePage/cart.dart';
import 'package:mobo_game/Pages/Profile/newProfile.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  // List of pages to be displayed
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomeContent(),
      CartContent(),
      BuyContent(),
      NewProfile(),
    ];

    if (_selectedIndex >= _pages.length) {
      _selectedIndex = 0;
    }

    // if (fetchPhoneNumberStatus == 'verified') {
    //   IsUserVerified();
    // }
    //Call fetchPhoneNumberStatus when HomePage is loaded
    fetchPhoneNumberStatus().then((phoneNumberStatus) {
      if (phoneNumberStatus != null) {
        // If phoneNumberStatus is verified, call IsUserVerified function
        if (phoneNumberStatus != 'Verified') {
          IsUserVerified();
        }
      } else {
        print('Failed to fetch phoneNumberStatus.');
      }
    });
  }

  void IsUserVerified() {
    showDialog(
      context: context,
      barrierDismissible:
          false, // Prevent dismissing when tapping outside the dialog
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Importent'),
          content: const Text('You have to complete your profile first!'),
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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NewProfile(),
                  ),
                );
              },
              child: const Text('Ok'),
            ),
          ],
        );
      },
    );
  }

  Future<String?> fetchPhoneNumberStatus() async {
    // Get the current user
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      // Get a reference to the Firestore collection
      DocumentReference userDoc = FirebaseFirestore.instance
          .collection('userProfiles')
          .doc(currentUser.uid);

      try {
        // Fetch the document snapshot
        DocumentSnapshot docSnapshot = await userDoc.get();

        // Check if the document exists and contains the phoneNumberStatus field
        if (docSnapshot.exists && docSnapshot.data() != null) {
          // Extract the phoneNumberStatus value
          dynamic data = docSnapshot.data();

          // Ensure data is Map<String, dynamic> before accessing its properties
          if (data is Map<String, dynamic> &&
              data.containsKey('phoneNumberStatus')) {
            dynamic phoneNumberStatus = data['phoneNumberStatus'];
            String ps = phoneNumberStatus.toString();
            print(' phoneNumberStatus..........: $ps');

            // Return the phoneNumberStatus as a string
            if (phoneNumberStatus != null) {
              return phoneNumberStatus.toString();
            }
          }
        }
      } catch (error) {
        print('Error fetching phoneNumberStatus: $error');
      }
    }

    // Return null if the user is not logged in or the data cannot be fetched
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    User? currentUser = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
        title: Center(
          child: GestureDetector(
            onTap: () {
              final FirebaseAuth _auth = FirebaseAuth.instance;
              User? currentUser = _auth.currentUser;
              if (currentUser != null &&
                  currentUser.email == "mdsakib134867@gmail.com")
                showOptionsDialog(context);

              print("Tapping here...............");
            },
            child: Image.asset(
              'assets/download.jpeg',
              width: 40,
              height: 40,
            ),
          ),
        ),
        actions: [
          GestureDetector(
            onTap: () {
              //

              if (currentUser != null &&
                  currentUser.email != "mdsakib134867@gmail.com" &&
                  currentUser.email != "mdkowsaralamrony@gmail.com")
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => OrderDeliverid()),
                );

              if (currentUser != null &&
                  (currentUser.email == "mdsakib134867@gmail.com" ||
                      currentUser.email == "mdkowsaralamrony@gmail.com"))
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AdminOrdersPage()),
                );
            },
            child: const Row(
              children: [
                Icon(Icons.account_balance_wallet),
                SizedBox(width: 16),
              ],
            ),
          )
        ],
      ),
      drawer: Container(
        width: MediaQuery.of(context).size.width / 1.7,
        child: Drawer(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    const DrawerHeader(
                      decoration: BoxDecoration(
                        color: Colors.blue,
                      ),
                      child: Center(
                        child: Text(
                          'Menu',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                          ),
                        ),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.person,
                        color: Colors.blue,
                        size: 30,
                      ),
                      title: const Text(
                        'Profile',
                        style: TextStyle(fontSize: 20, color: Colors.blue),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _selectPage(3);
                      },
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.home,
                        color: Colors.blue,
                        size: 30,
                      ),
                      title: const Text(
                        'Home',
                        style: TextStyle(fontSize: 20, color: Colors.blue),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _selectPage(0);
                      },
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.shopping_cart,
                        color: Colors.green,
                        size: 30,
                      ),
                      title: const Text(
                        'Cart',
                        style: TextStyle(fontSize: 20, color: Colors.green),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _selectPage(1);
                      },
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.code,
                        color: Colors.orange,
                        size: 30,
                      ),
                      title: const Text(
                        'Buy',
                        style: TextStyle(fontSize: 20, color: Colors.orange),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _selectPage(2);
                      },
                    ),

                    ListTile(
                      leading: const Icon(
                        Icons.code,
                        color: Colors.orange,
                        size: 30,
                      ),
                      title: const Text(
                        'demo',
                        style: TextStyle(fontSize: 20, color: Colors.orange),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LocationPage(),
                          ),
                        );
                      },
                    ),
                    // ListTile(
                    //   leading: Icon(
                    //     Icons.code,
                    //     color: Colors.orange,
                    //     size: 30,
                    //   ),
                    //   title: Text(
                    //     'Save Locally',
                    //     style: TextStyle(fontSize: 20, color: Colors.orange),
                    //   ),
                    //   onTap: () {
                    //     Navigator.push(
                    //       context,
                    //       MaterialPageRoute(
                    //         builder: (context) => MyHomePageimg(),
                    //       ),
                    //     );
                    //   },
                    // ),
                  ],
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(
                  Icons.logout,
                  color: Colors.red,
                  size: 30,
                ),
                title: const Text(
                  'Logout',
                  style: TextStyle(fontSize: 20, color: Colors.red),
                ),
                onTap: () {
                  showLogoutConfirmationDialog(context);
                },
              ),
            ],
          ),
        ),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _selectPage,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart),
              label: 'Cart',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.code),
              label: 'Buy',
            ),
            if (_selectedIndex >= 2) //  display based on selected index
              const BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'NewProfile',
              ),
          ],
          backgroundColor: Colors.blue,
          selectedItemColor: Colors.white,
          unselectedItemColor: const Color.fromARGB(255, 79, 78, 78),
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
          elevation: 10,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          type: BottomNavigationBarType.fixed,
        ),
      ),
    );
  }

  void _selectPage(int index) {
    if (index >= 0 && index < _pages.length) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  void showOptionsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Options'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('Go to firebase Database'),
                onTap: () {
                  // Implement edit logic here
                  //Navigator.of(context).pop();
                  launch(
                      'https://console.firebase.google.com/u/0/project/mobo-game-b66c7/firestore/databases/-default-/data/~2Fhomeitems~2F50M6ph3suFskzV8njKtJ');
                },
              ),
              ListTile(
                title: Text('Go to SuperAdmin Page'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UserListPage(),
                          ),
                        );
                },
              ),
              ListTile(
                title: Text('cancle'),
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

  void showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout Confirmation'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                // Perform logout logic here

                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) =>
                        const SignIn(), // Replace with your actual home screen
                  ),
                );

                // For example, you can call a method to sign out from Firebase
                await FirebaseAuth.instance.signOut();

                // You can print a message after a successful logout
                print('User logged out successfully!');

                // Navigate to the sign-in page after a successful logout
                // Navigator.pushAndRemoveUntil(
                //   context,
                //   MaterialPageRoute(
                //     builder: (context) => SignIn(),
                //   ),
                //   (Route<dynamic> route) => false, // Remove all previous routes
                // );
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}
