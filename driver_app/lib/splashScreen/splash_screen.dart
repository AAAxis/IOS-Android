import 'dart:async';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:driver_app/authentication/auth_screen.dart';
import 'package:driver_app/home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../global/global.dart';

class MySplashScreen extends StatefulWidget {
  const MySplashScreen({Key? key}) : super(key: key);

  @override
  State<MySplashScreen> createState() => _MySplashScreenState();
}

class _MySplashScreenState extends State<MySplashScreen> {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  void _navigateToHomeScreen() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (c) => MyHomePage()), // Replace 'HomeScreen' with your home screen widget.
    );
  }

  void _navigateToLoginScreen() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (c) => MergedLoginScreen()), // Replace 'MergedLoginScreen' with your login screen widget.
    );
  }

  void _requestPermissionManually() async {
    final trackingStatus = await AppTrackingTransparency.requestTrackingAuthorization();
    print('Manual tracking permission request status: $trackingStatus');

    final prefs = await SharedPreferences.getInstance();

    if (trackingStatus == TrackingStatus.authorized) {
      // User granted permission
      await prefs.setBool('trackingPermissionStatus', true);
    } else {
      // User denied permission or not determined, store it as false
      await prefs.setBool('trackingPermissionStatus', false);
    }

    // Continue with your application flow after checking tracking permission
    _navigateToHomeScreen();
  }

  @override
  void initState() {
    super.initState();

    Future.delayed(Duration(seconds: 2), () async {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('email');

      if (email != null && email.isNotEmpty) {
        // Email exists in SharedPreferences, navigate to the home screen.
        _navigateToHomeScreen();
      } else if (_firebaseAuth.currentUser != null) {
        // Firebase user is authenticated, navigate to the home screen.
        _navigateToHomeScreen();
      } else {
        // Neither email in SharedPreferences nor Firebase user authenticated, request tracking permission.
        _requestPermissionManually();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragEnd: (_) {
        // Handle vertical swipe to continue
        _navigateToLoginScreen();
      },
      child: Material(
        child: Container(
          color: Colors.white,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(100.0),
                  child: SizedBox(
                    width: 250,
                    height: 250,
                    child: Image.asset("images/splash.png"),
                  ),
                ),
                const SizedBox(height: 30,),
                Text(
                  "Swipe to Continue >>",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
