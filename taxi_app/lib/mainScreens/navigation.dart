import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxi_app/authentication/registration.dart';
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


  Future<Widget> _getEarningsPage(BuildContext context) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final status = prefs.getString('status');

    if (status == 'approved') {
      return ThirdScreen();
    } else {
      return MultiStepRegistrationScreen();
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
          FutureBuilder<Widget>(
            future: _getEarningsPage(context),
            builder: (BuildContext context, AsyncSnapshot<Widget> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else {
                return snapshot.data ?? Container(); // Return a default widget if snapshot.data is null
              }
            },
          ),
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
            label: 'Schedule',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.money_sharp),
            label: 'Earnings', // Initial label while waiting for future
          ),
        ],
      ),
    );
  }
}
