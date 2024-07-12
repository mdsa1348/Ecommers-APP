import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImageUploadPage extends StatefulWidget {
  @override
  _ImageUploadPageState createState() => _ImageUploadPageState();
}

class _ImageUploadPageState extends State<ImageUploadPage> {
  File? _imageFile;
  String? _imageUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Image Upload'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _imageFile != null
                ? Image.file(
              _imageFile!,
              height: 200,
              width: 200,
              fit: BoxFit.cover,
            )
                : Placeholder(
              fallbackHeight: 200,
              fallbackWidth: 200,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _pickImage();
              },
              child: Text('Pick Image'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _uploadImage();
              },
              child: Text('Upload Image'),
            ),
            SizedBox(height: 20),
            _imageUrl != null
                ? Text('Download URL: $_imageUrl')
                : Container(),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    setState(() {
      _imageFile = pickedFile != null ? File(pickedFile.path) : null;
      _imageUrl = null; // Reset the URL when a new image is picked
    });
  }

  Future<void> _uploadImage() async {
    if (_imageFile != null) {
      try {
        // Generate a unique filename
        String fileName = DateTime.now().millisecondsSinceEpoch.toString();

        // Get a reference to the Firebase Storage location
        Reference storageReference =
        FirebaseStorage.instance.ref().child('uploaded_images/$fileName');

        // Read the file as bytes
        List<int> data = await _imageFile!.readAsBytes();

        // Upload the file to Firebase Storage using putData
        await storageReference.putData(Uint8List.fromList(data));

        // Get the download URL of the uploaded file
        String imageUrl = await storageReference.getDownloadURL();

        setState(() {
          _imageUrl = imageUrl;
        });

        print('Image uploaded successfully. URL: $imageUrl');
      } catch (e) {
        print('Error uploading image to Storage: $e');
      }
    } else {
      print('No image selected.');
    }
  }
}

void main() {
  runApp(MaterialApp(
    home: ImageUploadPage(),
  ));
}
