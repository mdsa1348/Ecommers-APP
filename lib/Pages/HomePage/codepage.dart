import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:mobo_game/Pages/HomePage/SecondPage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class LocalHomeContent extends StatefulWidget {
  @override
  _LocalHomeContentState createState() => _LocalHomeContentState();
}

class _LocalHomeContentState extends State<LocalHomeContent> {
  String? userId;
  List<Widget> addedBoxes = [];

  @override
  void initState() {
    super.initState();
    fetchUserId();
    fetchUserItems(); // Call fetchUserItems when the page is loaded
  }

  Future<void> fetchUserId() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        userId = user.uid;
      });
    }
  }

  Future<void> fetchUserItems() async {
    try {
      // Ensure userId is not null
      if (userId != null) {
        print('Fetching items for user: $userId');

        // Retrieve items from local storage
        List<Map<String, dynamic>> localItems =
            await getLocalUserItems(userId!);

        // Clear existing addedBoxes
        setState(() {
          addedBoxes.clear();
        });

        // Process each local item
        for (var itemData in localItems) {
          // Get data from local storage
          String title = itemData['title'];
          String imageUrl = itemData['imageUrl'];

          // Add a widget for each item to addedBoxes
          setState(() {
            addedBoxes.add(
              GestureDetector(
                onTap: () {
                  print('Item ID: ${itemData['id']}');
                  navigateToSecondPage(itemData['id']);
                },
                onLongPress: () {
                  // Show edit and delete options
                  showOptionsDialog(itemData['id']);
                },
                child: Column(
                  children: [
                    Container(
                      width: 135,
                      height: 145,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: FileImage(File(imageUrl)),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      title ?? 'Title not available',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            );
          });
        }
      }
    } catch (e) {
      print('Error fetching user items: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getLocalUserItems(String userId) async {
    // Open database
    Database db = await openDatabase('your_database.db');

    // Query items for the user
    List<Map<String, dynamic>> items = await db.query(
      'userItems',
      where: 'userId = ?',
      whereArgs: [userId],
    );

    // Close the database
    await db.close();

    return items;
  }

  void showOptionsDialog(String itemId) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Options'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('Edit'),
                onTap: () {
                  // Implement edit logic here
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                title: Text('Delete'),
                onTap: () {
                  // Show confirmation dialog
                  showDeleteConfirmationDialog(itemId);
                  //Navigator.of(context).pop(); // Close options dialog
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

  void showDeleteConfirmationDialog(String itemId) async {
    await showDialog(
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
            TextButton(
              onPressed: () async {
                // Perform the deletion
                await deleteItem(itemId);
                // Close both confirmation and options dialogs
                Navigator.of(context)
                    .popUntil(ModalRoute.withName(Navigator.defaultRouteName));
                fetchUserItems();
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> deleteItem(String itemId) async {
    try {
      if (userId != null) {
        await FirebaseFirestore.instance
            .collection('homeitems')
            .doc(userId)
            .collection('userItems')
            .doc(itemId)
            .delete();
        print('Item deleted successfully: $itemId');
        // Refresh the user items after deletion
        fetchUserItems();
      }
    } catch (e) {
      print('Error deleting item: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        color: Color.fromARGB(255, 239, 239, 239),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'code app!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      showAddForm();
                    },
                    child: Text('Add'),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Container(
                width: double.infinity,
                height: MediaQuery.of(context).size.height * 0.65,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color.fromARGB(255, 244, 243, 243),
                  border: Border.all(color: Color.fromARGB(255, 131, 130, 130)),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Color.fromARGB(255, 97, 97, 97).withOpacity(0.5),
                      spreadRadius: 10,
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hello, this is your homepage content.'),
                    SizedBox(height: 10),
                    Expanded(
                      child: ListView.builder(
                        itemCount: (addedBoxes.length / 2).ceil(),
                        itemBuilder: (BuildContext context, int rowIndex) {
                          int startIndex = rowIndex * 2;
                          int endIndex = (rowIndex + 1) * 2;

                          // Ensure endIndex is within the bounds of the addedBoxes list
                          endIndex = endIndex > addedBoxes.length
                              ? addedBoxes.length
                              : endIndex;

                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: addedBoxes
                                .sublist(startIndex, endIndex)
                                .map(
                                  (item) => GestureDetector(
                                    child: Container(
                                      margin: EdgeInsets.only(bottom: 10),
                                      child: item,
                                    ),
                                  ),
                                )
                                .toList(),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void showAddForm() async {
    File? imageFile;
    String? title;
    String? selectedType;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text('Add Item'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final picker = ImagePicker();
                        final pickedFile =
                            await picker.pickImage(source: ImageSource.gallery);
                        setState(() {
                          if (pickedFile != null) {
                            imageFile = File(pickedFile.path);
                          }
                        });
                      },
                      child: imageFile != null
                          ? Image.file(
                              imageFile!,
                              height: 100,
                              width: 100,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              height: 100,
                              width: 100,
                              color: Colors.grey,
                              child: Icon(Icons.add),
                            ),
                    ),
                    SizedBox(height: 10),
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Title'),
                      onChanged: (value) {
                        title = value;
                      },
                    ),
                    SizedBox(height: 10),
                    Text('Select Type:'),
                    Row(
                      children: [
                        Radio<String>(
                          value: 'normal',
                          groupValue: selectedType,
                          onChanged: (value) {
                            setState(() {
                              selectedType = value;
                            });
                          },
                        ),
                        Text('normal'),
                        Radio<String>(
                          value: 'Unicode',
                          groupValue: selectedType,
                          onChanged: (value) {
                            setState(() {
                              selectedType = value;
                            });
                          },
                        ),
                        Text('Unicode'),
                      ],
                    ),
                  ],
                ),
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
                    try {
                      if (imageFile != null &&
                          title != null &&
                          selectedType != null &&
                          userId != null) {
                        // Save the image locally with a custom filename
                        String fileName =
                            '${DateTime.now().millisecondsSinceEpoch}.jpg';
                        String? localImagePath =
                            await saveImageLocally(imageFile!, fileName);

                        if (localImagePath != null) {
                          // Add the item locally
                          Map<String, dynamic> itemData = {
                            'title': title,
                            'type': selectedType,
                            'imageUrl':
                                localImagePath, // Store local image path instead of URL
                          };

                          // Add the item to Firestore
                          await FirebaseFirestore.instance
                              .collection('homeitems')
                              .doc(userId)
                              .collection('userItems')
                              .add(itemData);

                          // Refresh user items
                          fetchUserItems();

                          // Close the dialog after successful data sending
                          Navigator.of(context).pop();
                        } else {
                          print('Error saving image locally.');
                        }
                      }
                    } catch (e) {
                      print('Error adding item to Firestore: $e');
                    }
                  },
                  child: Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<String?> uploadImageToStorage(
      File imageFile, String userId, String fileName) async {
    if (imageFile != null) {
      try {
        Reference ref = FirebaseStorage.instance
            .ref()
            .child('images')
            .child(userId)
            .child(fileName); // Use the custom filename
        UploadTask uploadTask = ref.putFile(imageFile);
        TaskSnapshot storageTaskSnapshot =
            await uploadTask.whenComplete(() => null);
        String downloadUrl = await storageTaskSnapshot.ref.getDownloadURL();
        return downloadUrl;
      } catch (e) {
        print('Error uploading image to Storage: $e');
        return null;
      }
    }
    return null;
  }

  Future<String?> saveImageLocally(File imageFile, String fileName) async {
    try {
      Directory appDir = await getApplicationDocumentsDirectory();
      String assetsDir = 'assets';
      String imagesDirPath = '${appDir.path}/$assetsDir';

      // Create the directory if it doesn't exist
      await Directory(imagesDirPath).create(recursive: true);

      String localPath = '$imagesDirPath/$fileName';
      await imageFile.copy(localPath);
      return localPath;
    } catch (e) {
      print('Error saving image locally: $e');
      return null;
    }
  }

  Future<String?> getImageLocalPath(String fileName) async {
    Directory appDir = await getApplicationDocumentsDirectory();
    String localPath = '${appDir.path}/$fileName';

    if (File(localPath).existsSync()) {
      return localPath;
    } else {
      return null;
    }
  }

  void navigateToSecondPage(String itemId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SecondPage(itemId: itemId),
      ),
    );
  }
}
