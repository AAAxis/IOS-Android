import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:taxi_app/mainScreens/law_support.dart';
import 'dart:convert';
import 'bank.dart'; // Import your BankScreen

class ThirdScreen extends StatefulWidget {
  @override
  _ThirdScreenState createState() => _ThirdScreenState();
}






class _ThirdScreenState extends State<ThirdScreen> {
  int _money = 0;

  @override
  void initState() {
    super.initState();
    _fetchEarnings();
  }

  Future<void> _fetchEarnings() async {
    try {
      final apiUrl = 'https://polskoydm.pythonanywhere.com/driver_info';
      // Assuming you have a fixed email for testing
      final email = FirebaseAuth.instance.currentUser?.email ?? "No Email";

      final Uri uri = Uri.parse('$apiUrl?email=$email'); // Create the URI

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final money = data['money'];

        setState(() {
          _money = money;
        });
      } else {
        throw Exception('Failed to load driver info');
      }
    } catch (e) {
      print('Error fetching user info: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 5,
            blurRadius: 7,
            offset: Offset(0, 3),
          ),
        ],
      ),
      padding: EdgeInsets.all(20.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 160.0, // Double the height
              decoration: BoxDecoration(
                color: Colors.blueAccent, // Change color as needed
                borderRadius: BorderRadius.circular(20.0), // Increase border radius for a rounded card
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 3,
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              padding: EdgeInsets.all(20.0), // Increase padding for more space
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'My Balance',
                        style: TextStyle(
                          fontSize: 20, // Increase font size for the title
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      SizedBox(height: 50), // Add more space between title and balance
                      Text(
                        '\$$_money',
                        style: TextStyle(
                          fontSize: 26, // Increase font size for the balance
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    Icons.account_balance_wallet,
                    color: Colors.white,
                    size: 60, // Increase icon size
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 3,
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              padding: EdgeInsets.all(10.0),
              child: Row(
                children: [
                  Icon(Icons.star),
                  SizedBox(width: 10),
                  Text(
                    'Customer Rating: 100%',
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 3,
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              padding: EdgeInsets.all(10.0),
              child: Row(
                children: [
                  Icon(Icons.local_shipping),
                  SizedBox(width: 10),
                  Text(
                    '0 Lifetime Deliveries',
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                // Show a dialog with fake transfers table
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: Text('Transfers And Deposits'),
                      content: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Fake transfers table
                            // Replace this with your transfers table widget

                            SizedBox(height: 20),
                            // Check if there are deposits

                            Text('No deposits yet'), // Display message when no deposits
                            SizedBox(height: 20),
                            // Bank Account
                            Row(
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => EditBankScreen()),
                                    );
                                  },
                                  child: Text('Payment Method'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 3,
                      blurRadius: 5,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                padding: EdgeInsets.all(10.0),
                child: Row(
                  children: [
                    Icon(Icons.attach_money),
                    SizedBox(width: 10),
                    Text(
                      'Transfers And Deposit',
                      style: TextStyle(fontSize: 18),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),
            Divider(),
            ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5), // Adjust padding as needed
              leading: Icon(Icons.message),
              title: Text('Law Support'),
              onTap: () {
                // Add your action for Rental Vehicle
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SendMessagePage()),
                );

              },
            ),



          ],
        ),
      ),
    );
  }
}
