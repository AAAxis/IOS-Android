import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

import '../global/global.dart';
import '../mainScreens/navigation.dart';

class FirstPage extends StatefulWidget {
  @override
  _FirstPageState createState() => _FirstPageState();
}

class _FirstPageState extends State<FirstPage> {
  TextEditingController _nameController = TextEditingController();
  TextEditingController _phoneController = TextEditingController();
  TextEditingController _addressController = TextEditingController();
  bool _isButtonEnabled = false;

  @override
  void initState() {
    super.initState();

    String storedName = sharedPreferences!.getString("name") ?? "";
    _nameController.text = storedName == "Add Full Name" ? "" : storedName;
    _phoneController.text = '';
    _addressController.text = 'Tel Aviv';

    _nameController.addListener(_validateInputs);
    _phoneController.addListener(_validateInputs);
    _addressController.addListener(_validateInputs);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _validateInputs() {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final address = _addressController.text.trim();

    // Check if name is not empty and not equal to "Add Full Name", and other fields are not empty and phone is valid
    final isValid = name.isNotEmpty && address.isNotEmpty && _validatePhone(phone);

    setState(() {
      _isButtonEnabled = isValid;
    });
  }

  bool _validatePhone(String text) {
    String phonePattern = r'^\+[1-9]\d{10}$';
    RegExp regExp = RegExp(phonePattern);
    return regExp.hasMatch(text);
  }


  void updateName(String newName) {
    setState(() {
      sharedPreferences!.setString("name", newName);
    });
  }


  void updateAddress(String newAddress) {
    setState(() {
      sharedPreferences!.setString("address", newAddress);
    });
  }

  void updatePhone(String newPhone) {
    setState(() {
      sharedPreferences!.setString("phone", newPhone);
    });
  }

  Future<void> _sendRegistrationEmail() async {
    final email = sharedPreferences?.getString("email");
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final employmentType = 'contractor';
    final city = _addressController.text.trim();


    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => Navigation()),
    );



    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDocRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);
      await userDocRef.update({'name': name, 'phone': phone, 'address': city});
      updateName(name);
      updateAddress(city);
      updatePhone(phone);
    }

    final data = {
      'email': email,
      'name': name,
      'phone': phone,
      'employmentType': employmentType,
      'city': city,
    };

    print('Sending data: $data');

    try {
      final response = await http.post(
        Uri.parse('https://polskoydm.pythonanywhere.com/generate-pdf-and-send-email'),
        body: json.encode(data),
        headers: {'Content-Type': 'application/json'},
      );

      print('Response: ${response.body}');



    } catch (e) {
      print('Error: $e');
      throw Exception('Failed to send registration data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            'Registration',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20.0),
          Center(
            child: TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person),
              ),
            ),
          ),
          SizedBox(height: 20.0),
          Center(
            child: TextField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: Icon(Icons.phone),
              ),
            ),
          ),
          SizedBox(height: 20.0),
          Center(
            child: TextField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: 'Delivery City',
                prefixIcon: Icon(Icons.location_city),
              ),
            ),
          ),
          SizedBox(height: 20.0),
          ElevatedButton(
            onPressed: _isButtonEnabled ? _sendRegistrationEmail : null,
            child: Text('Submit'),
          ),
        ],
      ),
    );
  }
}
