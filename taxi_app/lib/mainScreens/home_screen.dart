import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxi_app/mainScreens/bills.dart';
import 'package:taxi_app/mainScreens/law_support.dart';
import 'package:taxi_app/mainScreens/notifications.dart';
import 'package:taxi_app/mainScreens/qr_code.dart';
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

// Function to launch the URL
  void _launchURL(String url) async {
    if (await launch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  _openGoogleMaps() async {
    // URL for Google Maps with the specified location
    final url = 'https://www.google.com/maps/search/?api=1&query=Get+Moto+Tel+Aviv';

    // Check if the URL can be launched
    if (await canLaunch(url)) {
      // Launch the URL
      await launch(url);
    } else {
      // Handle error
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            height: 35.0, // Adjust the height as needed
          ),


          Padding(
            padding: const EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 0.0), // Adjust margins as needed
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(7.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GestureDetector(
                      onTap: _openGoogleMaps,
                      child: Image.asset(
                        "images/image.png", // Replace "images/image.png" with the path to your local image asset
                        height: 200.0,
                        fit: BoxFit.cover,
                      ),
                    ),
                    SizedBox(height: 10.0),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all<Color>(Colors.black),
                              // Set text color to white
                              foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
                            ),
                            onPressed: () {
                              // Add your action for Insurance]
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => YourScreen()),
                              );
                            },
                            child: Text("QR Code"),
                          ),

                        ),
                        SizedBox(width: 10.0), // Add spacing between the text and the button
                        Expanded(
                          flex: 2,
                          child: Text(
                            "We carry quality scooters and offer 15% discount on repairs",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black, // Set text color to white
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          Expanded(
            child: ListView(
              children: <Widget>[
                ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 4), // Adjust padding as needed
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
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 4), // Adjust padding as needed
                  leading: Icon(Icons.messenger_outline_outlined),
                  title: Text('Chat Support'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SendMessagePage()),
                    );
                       },
                ),
                Divider(),
                ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 4), // Adjust padding as needed
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
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 4), // Adjust padding as needed
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
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 4), // Adjust padding as needed
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
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 4), // Adjust padding as needed
                  leading: const Icon(Icons.exit_to_app, color: Colors.black),
                  title: const Text(
                    "Sign Out",
                    style: TextStyle(color: Colors.black),
                  ),
                  onTap: () {
                    signOutAndClearPrefs(context);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}
