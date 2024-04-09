import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxi_app/authentication/registration.dart';
import 'package:taxi_app/mainScreens/bank.dart';
import 'package:taxi_app/mainScreens/bills.dart';
import 'package:taxi_app/mainScreens/notifications.dart';
import 'package:taxi_app/mainScreens/rental.dart';
import 'package:taxi_app/widgets/my_drawer.dart';
import 'package:url_launcher/url_launcher.dart';


import '../authentication/auth_screen.dart';
import '../global/global.dart';

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();


  void _openTelegram(String username) async {
    // Replace <username> with the username you want to open in Telegram
    String url = 'https://t.me/$username';
    if (await launch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
  Future<void> signOutAndClearPrefs(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => MergedLoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('Home Page'),
      ),

      body: ListView(
        children: <Widget>[
          ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5), // Adjust padding as needed
            leading: Icon(Icons.directions_car),
            title: Text('Rental Vehicle'),
            onTap: () {
              // Add your action for Rental Vehicle
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => RentalScreen()),
              );
            },
          ),

Divider(),
          ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5), // Adjust padding as needed
            leading: Icon(Icons.receipt),
            title: Text('Add Bills'),
            onTap: () {
              // Add your action for Add Bills
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DisplayScreen()),
              );
            },
          ),
          Divider(),
          ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5), // Adjust padding as needed
            leading: Icon(Icons.document_scanner_outlined),
            title: Text('Driver Contract'),
            onTap: () {
              // Add your action for Rental Vehicle
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MultiStepRegistrationScreen()),
              );
            },
          ),
          Divider(),
          ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5), // Adjust padding as needed
            leading: Icon(Icons.help_outline_sharp),
            title: Text('Help'),
            onTap: () {
              // Add your action for Insurance]
              _openTelegram('+16474724580');
            },
          ),

          Divider(),
          ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5), // Adjust padding as needed
            leading: Icon(Icons.notifications),
            title: Text('Notifications'),
            onTap: () {
              // Add your action for Rental Vehicle
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => NotificationScreen()),
              );
            },
          ),
          Divider(),
          ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5), // Adjust padding as needed
            leading: const Icon(Icons.language, color: Colors.black),
            title: const Text(
              "Language: English",
              style: TextStyle(color: Colors.black),
            ),
          ),
          Divider(),
          ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5), // Adjust padding as needed
            leading: Icon(Icons.perm_identity_outlined),
            title: Text('My Profile'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MyDrawerPage()),
              );
            },
          ),
          Divider(),
          ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5), // Adjust padding as needed
            leading: const Icon(Icons.exit_to_app, color: Colors.black),
            title: const Text(
              "Sign Out",
              style: TextStyle(color: Colors.black),
            ),
            onTap: () {
              signOutAndClearPrefs(context);
            },
          ),



          // Add more list items as needed
        ],
      ),
    );
  }
}
