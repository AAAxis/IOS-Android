import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class Driver {
  String name;
  String phone;
  int earnings;
  String email;

  Driver({
    this.name = '',
    this.phone = '',
    this.earnings = 0,
    this.email = '',
  });
}

class AccountPage extends StatefulWidget {
  @override
  _AccountPageState createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  late Driver driver;

  @override
  void initState() {
    super.initState();
    driver = Driver();
    _getUserInfo();
  }

  Future<void> _getUserInfo() async {
    final apiUrl = 'https://polskoydm.pythonanywhere.com/driver_profile';
    print('API URL: $apiUrl');

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('user_email') ?? 'N/A';

    final response = await http.get(
      Uri.parse('$apiUrl?email=$email'),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);

      print('API Response: $data');

      final name = data['name'] as String;
      final phone = data['phone'] as String;
      final earnings = data['earnings'] as int;
      final email = data['email'] as String;

      setState(() {
        driver = Driver(name: name, phone: phone, earnings: earnings, email: email);
      });

      print('Server response OK');
    } else {
      throw Exception('Failed to load driver info');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Account Page'),
      ),
      body: Center(
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
            Text('Name: ${driver.name}'),
            Text('Email: ${driver.email}'),
            Text('Phone: ${driver.phone}'),

            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _clearPrefs();
                Navigator.pop(context);
              },
              child: Text('Log Out'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _clearPrefs() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
