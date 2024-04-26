import 'package:driver_app/edit.dart';
import 'package:driver_app/upload.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminPage extends StatefulWidget {
  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  String? siteToken;
  Map<String, dynamic>? merchantData;
  bool receivingOrders = false;


  @override
  void initState() {
    super.initState();
    loadSiteToken();
  }

  // Function to toggle receiving orders status
  Future<void> toggleReceivingOrdersStatus() async {
    try {
      // Access Firestore instance
      FirebaseFirestore firestore = FirebaseFirestore.instance;

      // Update receivingOrders status in Firestore
      await firestore.collection('merchants').doc(siteToken).update({
        'receivingOrders': !receivingOrders,
      });

      // Update UI
      setState(() {
        receivingOrders = !receivingOrders;
      });
    } catch (error) {
      // Handle error
    }
  }

  // Function to display balance



  void _openMyOrdersLink() async {
    // Retrieve token from SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString('siteToken') ?? '';


    // URL with token appended
    String url = 'https://polskoydm.pythonanywhere.com/$token/dashboard';


      await launch(url);

  }


  // Function to load site token from SharedPreferences
  Future<void> loadSiteToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      siteToken = prefs.getString('siteToken');
    });

    // Once token is loaded, fetch merchant data
    if (siteToken != null) {
      fetchMerchantData(siteToken!);
    }
  }

  // Function to fetch merchant data from Firebase
  Future<void> fetchMerchantData(String token) async {
    try {
      // Access Firestore instance
      FirebaseFirestore firestore = FirebaseFirestore.instance;

      // Get the document from the "merchants" collection using the merchant ID
      DocumentSnapshot documentSnapshot = await firestore.collection('merchants').doc(token).get();

      // Check if the document exists
      if (documentSnapshot.exists) {
        setState(() {
          // Set the merchant data
          merchantData = documentSnapshot.data() as Map<String, dynamic>?;
          // Retrieve balance and receiving orders status
          receivingOrders = merchantData!['receivingOrders'] ?? false;
        });
      } else {
        setState(() {
          // Handle if the document doesn't exist
          merchantData = null;
        });
      }
    } catch (error) {
      setState(() {
        // Handle any errors
        merchantData = null;
      });
    }
  }

  // Function to clear SharedPreferences
  Future<void> clearSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pop(context); // Close the AdminPage after logging out
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Page'),
      ),
      body: Center(
        child: siteToken != null
            ? merchantData != null
            ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => EditProfileScreen()),
                );
              },
              child: merchantData!['link'] != null
                  ? Image.network(
                merchantData!['link'],
                width: 200,
                height: 200,
                fit: BoxFit.cover,
              )
                  : SizedBox(), // If image is null, show nothing
            ),
            Text('Store Name: ${merchantData!['name'] ?? 'N/A'}'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                toggleReceivingOrdersStatus(); // Toggle receiving orders status
              },
              child: Text(receivingOrders ? 'Close Store' : 'Open Store'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProductScreen()),
                );
              },
              child: Text('Add Item'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                // Add your logic for My Orders button here
                _openMyOrdersLink();
              },
              child: Text('My Orders'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                clearSharedPreferences(); // Log out
              },
              child: Text('Log Out'),
            ),
            SizedBox(height: 10),


          ],
        )
            : CircularProgressIndicator() // Show a loading indicator while fetching data
            : Text('Site Token not loaded'), // Handle if siteToken is null
      ),
    );
  }

}

