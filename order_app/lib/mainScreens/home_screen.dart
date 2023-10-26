import 'package:order_app/authentication/auth_screen.dart';
import 'package:flutter/material.dart';
import 'package:order_app/mainScreens/discover_screen.dart';
import 'package:order_app/widgets/my_drawer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'chat_screen.dart';

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _currentIndex = 0;
  bool _isLoggedIn = false; // Initialize as not logged in

  final List<Widget> _screens = [
    HomeScreen(),
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
    return Theme(
      data: ThemeData(
        // Customize the theme here
        appBarTheme: AppBarTheme(
          color: Colors.black, // Set the app bar background color to black
        ),
        scaffoldBackgroundColor: Colors.white12, // Set the scaffold background color to black
      ),
      child: Scaffold(

        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          selectedItemColor: Colors.black, // Set icon color to black
          onTap: (index) {
            if (index == 1 && !_isLoggedIn) {
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
              icon: _isLoggedIn
                  ? Icon(Icons.person, size: 35) // Display user icon if logged in
                  : Icon(Icons.login, size: 35), // Display login icon if not logged in
              label: _isLoggedIn ? 'Profile' : 'Login', // Label text
            ),
          ],
        ),
      ),
    );
  }
}
