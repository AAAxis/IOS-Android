import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Driver {
  int earnings;
  String email;
  String name;
  String phone;

  Driver({
    this.earnings = 0,
    this.email = '',
    this.name = '',
    this.phone = '',
  });
}

class AccountPage extends StatefulWidget {
  @override
  _AccountPageState createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  late Driver driver;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();


  bool _isEditing = false;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    driver = Driver();
    _getUserInfo();
  }


  Future<void> _getUserInfo() async {
    final apiUrl = 'https://polskoydm.pythonanywhere.com/driver_money';
    print('API URL: $apiUrl');

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('email') ?? 'N/A';
    final phone = prefs.getString('phone') ?? 'N/A';
    final name = prefs.getString('name') ?? 'N/A';


    final response = await http.get(
      Uri.parse('$apiUrl?email=$email'),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);

      print('API Response: $data');

      final earnings = data['earnings'] as int;
      final email = data['email'] as String;

      setState(() {
        driver = Driver(earnings: earnings, email: email, phone: phone, name:name);
      });

      print('Server response OK');
    } else {
      throw Exception('Failed to load driver info');
    }
  }

  Future<void> _updateDriverInfo() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;

    final firestore = FirebaseFirestore.instance;

    try {
      await firestore.collection('drivers').doc(uid).update({
        'name': driver.name,
        'phone': driver.phone,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Driver information updated successfully!'),
        ),
      );

      setState(() {
        _isEditing = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update driver information.'),
        ),
      );
    }
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
      nameController.text = driver.name;
      phoneController.text = driver.phone;
    });
  }

  Future<void> _clearPrefs() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    // Log out the user
    await FirebaseAuth.instance.signOut();

    // Navigate to the login screen
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Account Page'),
      ),
      body: Center(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 20),
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue,
                ),
                child: Center(
                  child: Text(
                    '\$${driver.earnings.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text('Logged In as ${driver.email}'),
              SizedBox(height: 20),
              _isEditing
                  ? TextFormField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Name'),
                initialValue: driver.name,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    driver.name = value;
                  });
                },
              )
                  : Text('Name: ${driver.name}'),
              _isEditing
                  ? TextFormField(
                controller: phoneController,
                decoration: InputDecoration(labelText: 'Phone'),
                initialValue: driver.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    driver.phone = value;
                  });
                },
              )
                  : Text('Phone: ${driver.phone}'),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isEditing ? _updateDriverInfo : _startEditing,
                child: _isEditing ? Text('Save') : Text('Edit'),
              ),
              ElevatedButton(
                onPressed: _clearPrefs,
                child: Text('Log Out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
