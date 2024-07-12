import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobo_game/Pages/HomePage/ThirdPage.dart';

class SecondPage extends StatefulWidget {
  final String itemId;

  SecondPage({required this.itemId});

  @override
  _SecondPageState createState() => _SecondPageState();
}

class _SecondPageState extends State<SecondPage> {
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

        // Reference to the user's subcollection
        CollectionReference userItemsCollection =
            FirebaseFirestore.instance.collection('ItemTypes');

        // Fetch documents from the user's subcollection
        QuerySnapshot userItems = await userItemsCollection.get();

        print('Fetched ${userItems.docs.length} items');

        // Clear existing addedBoxes
        setState(() {
          addedBoxes.clear();
        });

        // Process each document
        for (QueryDocumentSnapshot item in userItems.docs) {
          print('Item data: ${item.data()}');

          // Get title from the document data
          String title = item['title'];
          String itemId = item.id; // Get the document ID

          // Add a widget for each item to addedBoxes
          setState(() {
            addedBoxes.add(
              GestureDetector(
                onTap: () {
                  print('Item ID: $itemId');
                  navigateToThirdPage(itemId);
                },
                onLongPress: () {
                  // Show edit and delete options
                  showOptionsDialog(itemId);
                },
                child: Column(
                  children: [
                    Container(
                      width: 135,
                      height: 145,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage(item['imageUrl']),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      title,
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Second Page'),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome to the Second Page!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              Container(
                width: double.infinity,
                height: MediaQuery.of(context).size.height * 0.75,
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
                    Text('Hello, this is your Second Page content.'),
                    SizedBox(height: 10),
                    Expanded(
                      child: ListView.builder(
                        itemCount: (addedBoxes.length / 2).ceil(),
                        itemBuilder: (BuildContext context, int rowIndex) {
                          int startIndex = rowIndex * 2;
                          int endIndex = (rowIndex + 1) * 2;

                          endIndex = endIndex > addedBoxes.length
                              ? addedBoxes.length
                              : endIndex;

                          List<Widget> reversedItems =
                              addedBoxes.reversed.toList();

                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: reversedItems
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showAddForm();
        },
        child: Icon(Icons.add),
      ),
    );
  }

  void showAddForm() async {
    File? imageFile;
    String? title;
    String? selectedType;
    bool isLoading = false; // Track loading state
    double uploadProgress = 0.0; // Track upload progress

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
                    // Display image picker or loading indicator based on isLoading state
                    isLoading
                        ? Column(
                            children: [
                              CircularProgressIndicator(),
                              Text(
                                  'Uploading... ${(uploadProgress * 100).toStringAsFixed(2)}%'),
                            ],
                          )
                        : GestureDetector(
                            onTap: () async {
                              final picker = ImagePicker();
                              final pickedFile = await picker.pickImage(
                                  source: ImageSource.gallery);
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
                      setState(() {
                        isLoading = true; // Set loading state to true
                      });

                      if (imageFile != null &&
                          title != null &&
                          selectedType != null &&
                          userId != null) {
                        String? imageUrl = await uploadImageToStorage(
                            imageFile!, userId!, (double progress) {
                          setState(() {
                            uploadProgress = progress; // Update upload progress
                          });
                        });

                        // Add the item to Firestore
                        await FirebaseFirestore.instance
                            .collection('ItemTypes')
                            .add({
                          'title': title,
                          'type': selectedType,
                          'imageUrl': imageUrl,
                        });

                        // Close the card after successful data sending
                        Navigator.of(context).pop();
                        fetchUserItems();
                      }
                    } catch (e) {
                      print('Error adding item to Firestore: $e');
                    } finally {
                      setState(() {
                        isLoading = false; // Set loading state to false
                      });
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
      File imageFile, String userId, Function(double) progressCallback) async {
    if (imageFile != null) {
      try {
        String fileName = DateTime.now().millisecondsSinceEpoch.toString();
        Reference ref =
            FirebaseStorage.instance.ref().child('itemimages').child(fileName);

        UploadTask uploadTask = ref.putFile(imageFile);

        // Listen to the snapshotEvents stream to get upload progress
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          double progress = snapshot.bytesTransferred / snapshot.totalBytes;
          progressCallback(progress); // Call the progress callback function
        });

        // Wait for the upload to complete
        await uploadTask;

        String downloadUrl = await ref.getDownloadURL();
        return downloadUrl;
      } catch (e) {
        print('Error uploading image to Storage: $e');
        return null;
      }
    }
    return null;
  }

  void navigateToThirdPage(String itemId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ThirdPage(itemId: itemId),
      ),
    );
  }
}
