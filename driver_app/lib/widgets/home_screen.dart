import 'package:driver_app/authentication/auth_screen.dart';
import 'package:driver_app/chat_screen.dart';
import 'package:driver_app/my_list.dart';
import 'package:driver_app/widgets/my_drawer.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyOrderPage extends StatefulWidget {
  @override
  _MyOrderPageState createState() => _MyOrderPageState();
}

class _MyOrderPageState extends State<MyOrderPage> {
  int _currentIndex = 0;
  bool _isLoggedIn = false; // Initialize as not logged in

  final List<Widget> _screens = [
    MyList(),
    ChatScreen(),
    MyDrawerPage(),
  ];

  @override
  void initState() {
    super.initState();
    checkLoggedInStatus(); // Check the login status when the widget initializes
  }

  // Function to check login status
  void checkLoggedInStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      // Check if "user_email" is present in SharedPreferences
      _isLoggedIn = prefs.getString('email') != null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      backgroundColor: Colors.white, // Set the scaffold background color to black
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.black, // Set icon color to black
        onTap: (index) {
          if (index == 2 && !_isLoggedIn) {
            // If "Login" button is tapped and not logged in, navigate to AuthScreen
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => MergedLoginScreen(),
            ));
          } else {
            setState(() {
              _currentIndex = index;
            });
          }
        },
        type: BottomNavigationBarType.fixed, // Fixed type to center icons
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home, size: 35), // Increase icon size
            label: 'Home', // Label text
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_bike_rounded, size: 35), // Increase icon size
            label: 'Activity', // Label text
          ),
          BottomNavigationBarItem(
            icon: _isLoggedIn
                ? Icon(Icons.person, size: 35) // Display user icon if logged in
                : Icon(Icons.login, size: 35), // Display login icon if not logged in
            label: _isLoggedIn ? 'Accaunt' : 'Login', // Label text
          ),
        ],
      ),
    );
  }
}
