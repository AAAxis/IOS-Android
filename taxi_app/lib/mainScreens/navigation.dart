import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxi_app/mainScreens/bank.dart';
import 'package:taxi_app/mainScreens/bills.dart';
import 'package:taxi_app/mainScreens/documents.dart';
import 'package:taxi_app/mainScreens/home_screen.dart';
import 'package:taxi_app/mainScreens/rental.dart';
import 'package:taxi_app/mainScreens/secon_screen.dart';
import 'package:taxi_app/widgets/my_drawer.dart';
import '../authentication/auth_screen.dart';
import 'third_screen.dart';


class Navigation extends StatefulWidget {
  @override
  _NavigationState createState() => _NavigationState();
}

class _NavigationState extends State<Navigation> {
  int _currentIndex = 0;

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

  Future<void> _showEarningsDialog(BuildContext context) async {
    try {
      final apiUrl = 'https://polskoydm.pythonanywhere.com/driver_info';
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('email') ?? 'N/A';

      final Uri uri = Uri.parse('$apiUrl?email=$email'); // Create the URI
      print('Request URL: ${uri.toString()}'); // Print the URL

      final response = await http.get(uri);
      print('Response: ${response.body}'); // Print the response body

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final money = data['money'];
        await SharedPreferences.getInstance().then((sharedPreferences) {
          sharedPreferences.setInt('money', money);
        });

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Monthly Deposit'),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    Text('My Balance: $money'),
                    SizedBox(height: 10), // Add some spacing between the text and button
                    ElevatedButton(
                      onPressed: () {
                        // Navigate to EditBankScreen when the button is pressed
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => EditBankScreen()),
                        );
                      },
                      child: Text('Payout Method'),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('Close'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      } else {
        throw Exception('Failed to load driver info');
      }
    } catch (e) {
      // Handle any exceptions that occur during the request
      print('Error fetching user info: $e');
      // You can add error handling logic here, e.g., showing an error message to the user.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,

      body: IndexedStack(
        index: _currentIndex,
        children: [
          MyHomePage(),
          ScheduleScreen(),

          ThirdScreen()


        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.perm_identity_outlined),
            label: 'Account',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.schedule),
            label: 'Schedudle',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.money_sharp),
            label: 'Earnings',
          ),
        ],
      ),
    );
  }
}
