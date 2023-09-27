import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'account_page.dart';
import 'login_page.dart';
import 'map_page.dart'; // Import the login page if it exists in your code

class CustomBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  CustomBottomNavigationBar({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) async {
        // Handle bottom navigation item taps here
        if (index == 1) {
          // Check if the user's email exists in shared preferences
          final SharedPreferences prefs = await SharedPreferences.getInstance();
          final String? userEmail = prefs.getString('user_email');

          if (userEmail != null) {
            // If the email exists, navigate to the account page
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AccountPage()),
            );
          } else {
            // If the email does not exist, show the login page
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => LoginPage()),
            );
          }
        } else if (index == 2) {
          // If the "Map" tab is selected, navigate to the MapScreen
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => MapScreen()),
          );
        } else {
          onTap(index);
        }
      },
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.account_circle),
          label: 'Account',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.map),
          label: 'Map',
        ),
      ],
    );
  }
}
