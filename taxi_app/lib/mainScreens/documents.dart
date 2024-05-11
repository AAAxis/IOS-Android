import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:taxi_app/rental.dart';

class DriverLicenseScreen extends StatefulWidget {
  @override
  _DriverLicenseScreenState createState() => _DriverLicenseScreenState();
}

class _DriverLicenseScreenState extends State<DriverLicenseScreen> {
  TextEditingController numberController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController dobController = TextEditingController();
  File? _imageFile;
  String? _uploadedFileURL;
  bool _uploading = false;

  @override
  void dispose() {
    numberController.dispose();
    nameController.dispose();
    dobController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: "polskoydm@outlook.com",
        password: "passwordless",
      );
      // User signed in successfully, now you can proceed with document upload
      await _uploadImage();
    } catch (error) {
      // Handle authentication errors
      print("Error signing in: $error");
    }
  }


  Future<void> _uploadImage() async {
    setState(() {
      _uploading = true;
    });

    FirebaseStorage storage = FirebaseStorage.instance;
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    Reference reference = storage.ref().child('driver_license/$fileName');
    UploadTask uploadTask = reference.putFile(_imageFile!);

    try {
      TaskSnapshot taskSnapshot = await uploadTask;
      String downloadUrl = await taskSnapshot.ref.getDownloadURL();

      setState(() {
        _uploadedFileURL = downloadUrl;
        _uploading = false;
      });

    } catch (error) {
      setState(() {
        _uploading = false;
      });
      print("Error uploading image: $error");
      // Handle error
    }
  }

  Future<void> _saveData() async {
    if (numberController.text.isEmpty ||
        nameController.text.isEmpty ||
        dobController.text.isEmpty ||
        _imageFile == null) {
      // Check if any field is empty
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill all fields and upload an image.'),
        ),
      );
      return;
    }

    setState(() {
      _uploading = true;
    });

    // Retrieve current user's email
    String? userEmail;
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      userEmail = user.email;
    } else {
      // Handle case where user is not signed in
      // You may want to show a message or navigate the user to sign in
      print('User is not signed in.');
      return;
    }

    await FirebaseFirestore.instance.collection('driver_license').add({
      'number': numberController.text,
      'name': nameController.text,
      'dob': dobController.text,
      'image_url': _uploadedFileURL!,
    });

    // Store the mobile number to SharedPreferences
    await _storeMobileNumber(numberController.text);

    // Clear controllers and image after saving
    numberController.clear();
    nameController.clear();
    dobController.clear();
    setState(() {
      _imageFile = null;
      _uploading = false;
    });

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => RentalScreen()),
    );
  }

  Future<void> _storeMobileNumber(String number) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.setString('phone', '$number');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Driver License'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                GestureDetector(
                  onTap: () async {
                    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
                    if (pickedFile != null) {
                      setState(() {
                        _imageFile = File(pickedFile.path);
                      });
                    }
                  },
                  child: Container(
                    height: 200,
                    color: Colors.grey[300],
                    child: Center(
                      child: _imageFile == null
                          ? Icon(Icons.add, size: 50)
                          : Image.file(_imageFile!, height: 200),
                    ),
                  ),
                ),
                SizedBox(height: 20.0),
                TextField(
                  controller: numberController,
                  decoration: InputDecoration(
                    labelText: 'Mobile Phone',
                    prefixIcon: Icon(Icons.mobile_friendly),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                    LengthLimitingTextInputFormatter(10),
                  ],
                ),

                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    final selectedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                    );
                    if (selectedDate != null) {
                      setState(() {
                        dobController.text = DateFormat('yyyy-MM-dd').format(selectedDate);
                      });
                    }
                  },
                  child: AbsorbPointer(
                    child: TextField(
                      controller: dobController,
                      decoration: InputDecoration(
                        labelText: 'Date of Birth',
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20.0),
                ElevatedButton(
                  onPressed: _uploading
                      ? null
                      : () async {
                    if (_imageFile != null) {
                      await _signIn();
                      await _saveData(); // Call _saveData() here
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Please select an image.'),
                        ),
                      );
                    }
                  },
                  child: _uploading ? CircularProgressIndicator() : Text('Save'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

