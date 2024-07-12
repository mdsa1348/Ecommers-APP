import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobo_game/Pages/HomePage/DetailedPage.dart';

class ThirdPage extends StatefulWidget {
  final String itemId;

  ThirdPage({required this.itemId});

  @override
  _ThirdPageState createState() => _ThirdPageState();
}

class _ThirdPageState extends State<ThirdPage> {
  String? userId;
  double _uploadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    fetchUserId();
  }

  Future<void> fetchUserId() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        userId = user.uid;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Third Page'),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome to the Third Page!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  showAddCard();
                },
                child: Text('Add'),
              ),
              SizedBox(height: 20),
              buildItemsList(),
            ],
          ),
        ),
      ),
    );
  }

  void showAddCard() async {
    String? title;
    String? description;
    String? amount;
    String? itemamount;
    File? imageFile;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Item'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return SingleChildScrollView(
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
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Description'),
                      maxLines: 3,
                      onChanged: (value) {
                        description = value;
                      },
                    ),
                    SizedBox(height: 10),
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Amount'),
                      onChanged: (value) {
                        amount = value;
                      },
                    ),
                    SizedBox(height: 10),
                    TextFormField(
                      decoration:
                          InputDecoration(labelText: 'Item Amount (Available)'),
                      onChanged: (value) {
                        itemamount = value;
                      },
                    ),
                    SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: _uploadProgress,
                      minHeight: 10,
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () async {
                        if (title != null &&
                            description != null &&
                            amount != null &&
                            itemamount != null &&
                            userId != null &&
                            imageFile != null) {
                          setState(() {
                            _uploadProgress = 0.0;
                          });

                          await addItem(title!, description!, amount!,
                              itemamount!, imageFile!, setState);
                          Navigator.pop(context);
                        }
                      },
                      child: Text('Add'),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> addItem(String title, String description, String amount,
      String itemamount, File imageFile, StateSetter setState) async {
    try {
      String imageUrl = await uploadImage(imageFile, (double progress) {
        setState(() {
          _uploadProgress = progress;
        });
      });

      // Check if the collection exists
      bool collectionExists = await doesCollectionExist('ItemTypesItems');

      // If the collection doesn't exist, create it
      if (!collectionExists) {
        await FirebaseFirestore.instance
            .collection('ItemTypesItems')
            .doc()
            .set({});
      }

      // Get the current server timestamp
      Timestamp timestamp = Timestamp.now();

      // Add the item to the collection
      await FirebaseFirestore.instance
          .collection('ItemTypesItems')
          .doc(widget.itemId)
          .collection('userItems')
          .add({
        'title': title,
        'description': description,
        'amount': amount,
        'itemamount': itemamount,
        'userId': userId,
        'imageUrl': imageUrl,
        'createdAt': timestamp,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Item added Successfully')),
      );
    } catch (e) {
      print('Error adding item to Firestore: $e');
    }
  }

// Function to check if a collection exists
  Future<bool> doesCollectionExist(String collectionName) async {
    QuerySnapshot collectionSnapshot = await FirebaseFirestore.instance
        .collection(collectionName)
        .limit(1)
        .get();
    return collectionSnapshot.docs.isNotEmpty;
  }

  Future<String> uploadImage(
      File imageFile, void Function(double) progressCallback) async {
    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference ref =
          FirebaseStorage.instance.ref().child('images').child(fileName);

      UploadTask uploadTask = ref.putFile(imageFile);
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        double progress = snapshot.bytesTransferred / snapshot.totalBytes;
        progressCallback(progress);
      });

      await uploadTask;
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error uploading image to Storage: $e');
      throw Exception('Failed to upload image');
    }
  }

  Widget buildItemsList() {
     final FirebaseAuth _auth = FirebaseAuth.instance;
    User? currentUser = _auth.currentUser;
    
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('ItemTypesItems')
          .doc(widget.itemId)
          .collection('userItems')
          .snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          var items = snapshot.data?.docs ?? [];
          return ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (context, index) {
              var item = items[index].data() as Map<String, dynamic>;
              var seconditem = items[index].id;
              var itemId = widget.itemId;
              return GestureDetector(
                onTap: () {
                  print("widget.itemId : $itemId");
                  print("seceonditem : $seconditem");

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetailedItemPage(
                          itemId: widget.itemId,
                          seconditem: seconditem,
                          item: item),
                    ),
                  );
                },
                onLongPress: () {
                   if (currentUser != null &&
    (currentUser.email == "mdsakib134867@gmail.com" ||
        currentUser.email == "mdkowsaralamrony@gmail.com"))
                  showEditOptionsDialog(items[index].id, item);
                },
                child: Card(
                  elevation: 3,
                  margin: EdgeInsets.symmetric(vertical: 10),
                  child: Container(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: MediaQuery.of(context).size.width * 0.40,
                          height: MediaQuery.of(context).size.width * 0.50,
                          child: CachedNetworkImage(
                            imageUrl: item['imageUrl'],
                            fit: BoxFit.fill,
                            // placeholder: (context, url) =>
                            //     CircularProgressIndicator(), // Placeholder widget while loading
                            errorWidget: (context, url, error) => Icon(Icons
                                .error), // Widget to display in case of an error
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['title'],
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Amount: ${item['amount'] ?? 'N/A'}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Available: ${item['itemamount'] ?? 'N/A'}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color.fromARGB(255, 17, 114, 9),
                                  fontSize: 17,
                                ),
                              ),
                              SizedBox(height: 16),
                              Text(
                                item['description'] ??
                                    'No description available',
                                style: TextStyle(
                                  fontSize: 14,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
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

  void showEditOptionsDialog(String itemId, Map<String, dynamic> itemData) {
    showDialog(
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
                  Navigator.pop(context);
                  showEditCard(itemId, itemData);
                },
              ),
              ListTile(
                title: Text('Delete'),
                onTap: () {
                  Navigator.pop(context);
                  showDeleteConfirmationDialog(itemId, itemData);
                },
              ),
              ListTile(
                title: Text('Cancel'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void showEditCard(String itemId, Map<String, dynamic> itemData) async {
    String? title = itemData['title'];
    String? description = itemData['description'];
    String? amount = itemData['amount'];
    String? itemamount = itemData['itemamount'];
    File? imageFile;

    await showDialog(
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
                          : itemData['imageUrl'] != null
                              ? Image.network(
                                  itemData['imageUrl'],
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
                      initialValue: title,
                      decoration: InputDecoration(labelText: 'Title'),
                      onChanged: (value) {
                        title = value;
                      },
                    ),
                    SizedBox(height: 10),
                    TextFormField(
                      initialValue: description,
                      decoration: InputDecoration(labelText: 'Description'),
                      maxLines: 3,
                      onChanged: (value) {
                        description = value;
                      },
                    ),
                    SizedBox(height: 10),
                    TextFormField(
                      initialValue: amount,
                      decoration: InputDecoration(labelText: 'Amount'),
                      onChanged: (value) {
                        amount = value;
                      },
                    ),
                    SizedBox(height: 10),
                    TextFormField(
                      initialValue: itemamount,
                      decoration: InputDecoration(labelText: 'Item Amount'),
                      onChanged: (value) {
                        itemamount = value;
                      },
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () async {
                        if (title != null &&
                            description != null &&
                            amount != null &&
                            itemamount != null) {
                          // Get the current server timestamp
                          Timestamp timestamp = Timestamp.now();

                          await updateItem(
                              itemId,
                              {
                                'title': title!,
                                'description': description!,
                                'amount': amount!,
                                'itemamount': itemamount!,
                                'createdAt': timestamp,
                              },
                              imageFile,
                              itemData['imageUrl']);
                          Navigator.pop(context);
                        }
                      },
                      child: Text('Update'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> updateItem(String itemId, Map<String, dynamic> data,
      File? imageFile, String? previousImageUrl) async {
    try {
      if (imageFile != null) {
        String imageUrl = await uploadImage(imageFile, (double progress) {});
        data['imageUrl'] = imageUrl;

        if (previousImageUrl != null) {
          Reference previousImageRef =
              FirebaseStorage.instance.refFromURL(previousImageUrl);
          await previousImageRef.delete();
        }
      }
      await FirebaseFirestore.instance
          .collection('ItemTypesItems')
          .doc(widget.itemId)
          .collection('userItems')
          .doc(itemId)
          .update(data);
    } catch (e) {
      print('Error updating item: $e');
    }
  }

  void showDeleteConfirmationDialog(
      String itemId, Map<String, dynamic> itemData) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Confirmation'),
          content: Text('Are you sure you want to delete this item?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                String? imageFile = itemData['imageUrl'];
                deleteItem(itemId, imageFile);
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

  void deleteItem(String itemId, String? imageUrl) async {
    try {
      await FirebaseFirestore.instance
          .collection('ItemTypesItems')
          .doc(widget.itemId)
          .collection('userItems')
          .doc(itemId)
          .delete();

      if (imageUrl != null) {
        Reference imageRef = FirebaseStorage.instance.refFromURL(imageUrl);
        await imageRef.delete();
      }
    } catch (e) {
      print('Error deleting item: $e');
    }
  }
}
