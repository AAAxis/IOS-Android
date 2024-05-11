import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxi_app/authentication/auth_screen.dart';
import 'package:taxi_app/mainScreens/message_support.dart';
import 'package:taxi_app/mainScreens/qr_code.dart';
import 'package:taxi_app/rental.dart';
import 'package:taxi_app/widgets/My_Settings.dart';




class ThirdScreen extends StatefulWidget {


  @override
  _ThirdScreenState createState() => _ThirdScreenState();
}

class _ThirdScreenState extends State<ThirdScreen> {
  String buttonText = 'Balance'; // Default text for balance button

  String _balance = '0'; // Variable to store the balance


  @override
  void initState() {
    super.initState();
    // Call fetchTransactions when the screen loads
    fetchTransactions();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SingleChildScrollView(
        child: Padding(
        padding: const EdgeInsets.all(16.0),
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
            SizedBox(height: 40),
            Text(
              'Balance',
              style: TextStyle(fontSize: 27, fontWeight: FontWeight.normal), // Larger font size
            ),
            SizedBox(height: 10),
            // Credit Card Placeholder
            Container(
              padding: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.0),
                color: Colors.black87, // Set card color to black
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Icon for Mastercard
                      Row(
                        children: [
                          // Icon for Mastercard
                          Icon(
                            Icons.credit_card,
                            color: Colors.white, // Mastercard's color
                            size: 30,
                          ),
                          SizedBox(width: 10), // Add some space between the icon and text
                          // Text for the balance amount
                          Text(
                            '\₪$_balance', // Display balance amount
                            style: TextStyle(
                              color: Colors.white, // Text color
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 110),
                  Text(
                    '**** **** **** 5488',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  FutureBuilder<String>(
                    future: _getName(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        return Text(
                          '${snapshot.data}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        );
                      } else {
                        return SizedBox();
                      }
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => RentalScreen()),
                    );
                  },
                  icon: Icon(Icons.directions_bike),
                  label: Text('Rental Options'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black,
                    side: BorderSide(color: Colors.black), // Border color
                    padding: EdgeInsets.all(16.0), // Button padding
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => YourScreen()),
                    );
                  },
                  icon: Icon(Icons.settings),
                  label: Text('Repairs'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black,
                    side: BorderSide(color: Colors.black), // Border color
                    padding: EdgeInsets.all(16.0), // Button padding
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Navigate to My Settings Screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => MyDrawerPage()),
                    );
                  },
                  icon: Icon(Icons.account_circle),
                  label: Text('My Profile'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black,
                    side: BorderSide(color: Colors.black), // Border color
                    padding: EdgeInsets.all(16.0), // Button padding
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    // Pass the uid to ChatRoom widget
                    SharedPreferences prefs = await SharedPreferences.getInstance();
                    String uid = prefs.getString('uid') ?? ''; // Replace with the actual uid value
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SendMessagePage()),
                    );
                  },
                  icon: Icon(Icons.message),
                  label: Text('Law Support'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black,
                    side: BorderSide(color: Colors.black), // Border color
                    padding: EdgeInsets.all(16.0), // Button padding
                  ),
                ),
              ),
            ),



            ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 4), // Adjust padding as needed
              leading: Icon(Icons.exit_to_app),
              title: Text('Sign Out'),
              onTap: () {
                signOutAndClearPrefs(context);
              },
            ),
          ],
        ),
      ),
        ),
    );
  }

  Future<void> fetchTransactions() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // Reference to the user's document in Firestore
      DocumentReference userRef = FirebaseFirestore.instance.collection('contractors').doc(user.uid);

      // Reference to the "invoices" subcollection for the user
      CollectionReference invoicesRef = userRef.collection('invoices');

      // Query to get only paid invoices
      QuerySnapshot paidInvoicesSnapshot = await invoicesRef.where('status', isEqualTo: 'paid').get();

      // Calculate the balance based on the sum of paid invoices
      double balance = 0;

      // Iterate over each paid invoice
      for (DocumentSnapshot invoice in paidInvoicesSnapshot.docs) {
        // Ensure invoice data is not null and is of the expected type
        Map<String, dynamic>? invoiceData = invoice.data() as Map<String, dynamic>?;

        if (invoiceData != null) {
          // Parse 'total' from String to double before adding it to the balance
          double? total = invoiceData['total'] as double?;

          if (total != null) {
            // Add the total amount to the balance
            balance += total;
          }
        }
      }

      // Update the balance locally
      setState(() {
        if (balance % 1 == 0) {
          // If balance is an integer, display it without the decimal part
          _balance = balance.toInt().toString();
        } else {
          // Otherwise, display the balance with 2 decimal places
          _balance = balance.toStringAsFixed(2);
        }
      });
    }
  }

  // Function to get name from shared preferences
  Future<String> _getName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('name') ?? 'Pedro Paskal';
  }
}

Future<void> signOutAndClearPrefs(BuildContext context) async {
  await FirebaseAuth.instance.signOut();
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (context) => LoginScreen()),
  );
}
