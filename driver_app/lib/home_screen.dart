import 'package:driver_app/chat_screen.dart';
import 'package:flutter/material.dart';

import 'account_page.dart';
import 'map_page.dart';
import 'order_screen.dart';

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    MapScreen(),
    ChatScreen(),
    AccountPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 15.0),
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(30.0)),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 40.0),
                  child: BottomNavigationBar(
                    currentIndex: _currentIndex,
                    selectedItemColor: Colors.black, // Set icon color to black
                    onTap: (index) {
                      setState(() {
                        _currentIndex = index;
                      });
                    },
                    type: BottomNavigationBarType.fixed, // Fixed type to center icons
                    items: [
                      BottomNavigationBarItem(
                        icon: Icon(Icons.home, size: 35), // Increase icon size
                        label: 'Explore', // Label text
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.message, size: 35), // Increase icon size
                        label: 'My Chats', // Label text
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.person, size: 35), // Increase icon size
                        label: 'Profile', // Label text
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
