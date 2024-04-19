import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxi_app/mainScreens/bills.dart';
import 'package:taxi_app/mainScreens/notifications.dart';
import 'package:taxi_app/mainScreens/rental.dart';
import 'package:taxi_app/widgets/my_drawer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../authentication/auth_screen.dart';

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();



  Future<void> signOutAndClearPrefs(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => MergedLoginScreen()),
    );
  }

  // Function to launch the URL
  void _launchURL(String url) async {
    if (await launch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,

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
            leading: Icon(Icons.help_outline),
            title: Text('Help'),
            onTap: () {
              // Add your action for Insurance]
              _launchURL('https://theholylabs.com'); // Replace the URL with your terms and conditions URL

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
