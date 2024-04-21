import 'dart:async';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxi_app/authentication/auth_screen.dart';// import your authentication screen
import 'package:taxi_app/mainScreens/home_screen.dart';
import 'package:taxi_app/mainScreens/navigation.dart';

import '../global/global.dart';

class MySplashScreen extends StatefulWidget {
  const MySplashScreen({Key? key}) : super(key: key);

  @override
  State<MySplashScreen> createState() => _MySplashScreenState();
}

class _MySplashScreenState extends State<MySplashScreen> {



  Future<void> _requestPermissionManually() async {
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
  }

  @override
  void initState() {
    super.initState();
    _checkCurrentUser();
  }

  void _checkCurrentUser() {
    Timer(Duration(seconds: 3), () async {
      String userStatus = sharedPreferences!.getString("status") ?? "Disabled"; // Retrieve user status from SharedPreferences

      // Navigate to ContractorScreen or SelfEmployedScreen based on status
      if (userStatus == 'contractor') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Navigation()),
        );
      } else if (userStatus == 'self-employed') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MyHomePage()),
        );
      } else {
        await _requestPermissionManually();
        // Handle other cases, for example, navigate to an authentication screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MergedLoginScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragEnd: (_) {
        // Handle vertical swipe to continue
        _requestPermissionManually();
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
                    child: Image.asset("images/logo-color.png"),
                  ),
                ),
                const SizedBox(height: 30,),
                Text(
                  "Swipe to Continue >>",
                  style: TextStyle(
                    color: Colors.black, // Change the color to your preference
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
