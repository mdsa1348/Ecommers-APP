import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobo_game/Pages/HomePage/ThirdPage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:mobo_game/Pages/HomePage/SecondPage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

class HomeContent extends StatefulWidget {
  @override
  _HomeContentState createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
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
    final FirebaseAuth _auth = FirebaseAuth.instance;
    User? currentUser = _auth.currentUser;
    try {
      // Ensure userId is not null
      if (userId != null) {
        print('Fetching items for user: $userId');

        // Reference to the user's subcollection
        CollectionReference userItemsCollection =
            FirebaseFirestore.instance.collection('homeitems');

        // Fetch documents from the user's subcollection
        QuerySnapshot userItems = await userItemsCollection.get();

        print('Fetched ${userItems.docs.length} items');

        // Clear existing addedBoxes
        setState(() {
          addedBoxes.clear();
        });

        // Process each document
        userItems.docs.forEach((item) {
          //print('Item data: ${item.data()}');

          // Get item data from the document data
          Map<String, dynamic> itemData = item.data()! as Map<String, dynamic>;
          String title = itemData['title'];
          String itemId = item.id; // Get the document ID
          String imageUrl = itemData['imageUrl'];

          // Add a widget for each item to addedBoxes
          setState(() {
            addedBoxes.add(
              GestureDetector(
                onTap: () {
                  print('Item ID: $itemId');
                  navigateToSecondPage(itemId);
                },
                onLongPress: () {
                  // Show edit and delete options
                  if (currentUser != null &&
                      (currentUser.email == "mdsakib134867@gmail.com" ||
                          currentUser.email == "mdkowsaralamrony@gmail.com"))
                    showOptionsDialog(itemId, itemData);
                },
                child: Column(
                  children: [
                    Container(
                      width: 135,
                      height: 145,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: CachedNetworkImageProvider(imageUrl),
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
        });
      }
    } catch (e) {
      print('Error fetching user items: $e');
    }
  }

  void showOptionsDialog(String itemId, Map<String, dynamic> itemData) async {
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
                  Navigator.of(context).pop();

                  // Implement edit logic here
                  _showEditForm(itemId, itemData);
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
                    'Welcome to our apps!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Implement your add button logic here
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

  void _showEditForm(String itemId, Map<String, dynamic> itemData) {
    File? newImageFile;
    String? newTitle;
    String? selectedType = itemData['type'];
    bool isLoading = false;
    double uploadProgress = 0.0;
    String? previousImageUrl = itemData['imageUrl'];

    newTitle = itemData['title'];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text('Edit Item'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                                source: ImageSource.gallery,
                              );
                              setState(() {
                                if (pickedFile != null) {
                                  newImageFile = File(pickedFile.path);
                                }
                              });
                            },
                            child: newImageFile != null
                                ? Image.file(
                                    newImageFile!,
                                    height: 100,
                                    width: 100,
                                    fit: BoxFit.cover,
                                  )
                                : previousImageUrl != null
                                    ? Image.network(
                                        previousImageUrl,
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
                      initialValue: newTitle,
                      decoration: InputDecoration(labelText: 'Title'),
                      onChanged: (value) {
                        newTitle = value;
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
                        isLoading = true;
                      });

                      if (newImageFile != null ||
                          newTitle != null ||
                          selectedType != null) {
                        Map<String, dynamic> updatedData = {};

                        if (newTitle != null) updatedData['title'] = newTitle;
                        if (selectedType != null)
                          updatedData['type'] = selectedType;

                        if (newImageFile != null) {
                          String? imageUrl = await _uploadImageToStorage(
                            newImageFile!,
                            itemId,
                            (double progress) {
                              setState(() {
                                uploadProgress = progress;
                              });
                            },
                          );
                          updatedData['imageUrl'] = imageUrl;
                          Timestamp timestamp = Timestamp.now();
                          updatedData['createdAt'] = timestamp;

                          if (previousImageUrl != null) {
                            await deleteImageFromStorage(previousImageUrl);
                          }
                        }

                        await FirebaseFirestore.instance
                            .collection('homeitems')
                            .doc(itemId)
                            .update(updatedData);

                        Navigator.of(context).pop();
                        fetchUserItems();
                      }
                    } catch (e) {
                      print('Error updating item: $e');
                    } finally {
                      setState(() {
                        isLoading = false;
                      });
                    }
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

  Future<void> deleteImageFromStorage(String imageUrl) async {
    try {
      // Parse the image URL to get the path in the storage bucket
      String imagePath = Uri.parse(imageUrl).path;

      // Get a reference to the image file in Firebase Storage
      Reference imageRef = FirebaseStorage.instance.ref().child(imagePath);

      // Delete the image file
      await imageRef.delete();

      print('Image deleted successfully from Firebase Storage');
    } catch (e) {
      print('Error deleting image from Firebase Storage: $e');
    }
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
                        String? imageUrl = await _uploadImageToStorage(
                            imageFile!, userId!, (double progress) {
                          setState(() {
                            uploadProgress = progress; // Update upload progress
                          });
                        });

                        bool collectionExists =
                            await doesCollectionExist('homeitems');

                        // If the collection doesn't exist, create it
                        if (!collectionExists) {
                          await FirebaseFirestore.instance
                              .collection('homeitems')
                              .doc()
                              .set({});
                        }
                        // Get the current server timestamp
                        Timestamp timestamp = Timestamp.now();

                        // Add the item to Firestore
                        await FirebaseFirestore.instance
                            .collection('homeitems')
                            .add({
                          'title': title,
                          'type': selectedType,
                          'imageUrl': imageUrl,
                          'createdAt': timestamp,
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

  // Function to check if a collection exists
  Future<bool> doesCollectionExist(String collectionName) async {
    QuerySnapshot collectionSnapshot = await FirebaseFirestore.instance
        .collection(collectionName)
        .limit(1)
        .get();
    return collectionSnapshot.docs.isNotEmpty;
  }

  Future<String?> _uploadImageToStorage(
      File imageFile, String itemId, Function(double) progressCallback) async {
    if (imageFile != null) {
      try {
        String fileName = DateTime.now().millisecondsSinceEpoch.toString();
        Reference ref = FirebaseStorage.instance
            .ref()
            .child('images')
            .child(itemId)
            .child(fileName);

        UploadTask uploadTask = ref.putFile(imageFile);

        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          double progress = snapshot.bytesTransferred / snapshot.totalBytes;
          progressCallback(progress);
        });

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

  Future<String?> saveImageLocally(File imageFile, String fileName) async {
    try {
      String assetsDir = 'assets';
      Directory appDir = await getApplicationDocumentsDirectory();
      String localPath = '${appDir.path}/$assetsDir/$fileName';
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
        builder: (context) => ThirdPage(itemId: itemId),
      ),
    );
  }
}
