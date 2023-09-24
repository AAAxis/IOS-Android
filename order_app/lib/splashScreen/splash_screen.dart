import 'dart:async';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:order_app/authentication/auth_screen.dart';
import 'package:order_app/mainScreens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../global/global.dart';



class MySplashScreen extends StatefulWidget {
  const MySplashScreen({Key? key}) : super(key: key);

  @override
  State<MySplashScreen> createState() => _MySplashScreenState();
}

class _MySplashScreenState extends State<MySplashScreen> {

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance; // Initialize Firebase Auth


  startTimer()
  {
    ///Auth Check
    Timer(Duration(seconds: 3), () async {
      if(firebaseAuth.currentUser != null)
      {
        Navigator.push(context, MaterialPageRoute(builder: (c)=> const HomeScreen()));
      } else
      {
        print('Waiting for response');
      }
    }); //Timer
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
    Navigator.push(context, MaterialPageRoute(builder: (c)=> const HomeScreen()));
  }

  @override
  void initState() {
    super.initState();

    startTimer();

  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Container(
        color: Colors.white,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(100.0), // Adjust the radius as needed
                child: SizedBox(
                  width: 250, // Adjust the width as needed
                  height: 250, // Adjust the height as needed
                  child: Image.asset("images/splash.jpg"),
                ),
              ),
              const SizedBox(height: 10,),
              const Padding(
                padding: const EdgeInsets.all(18.0),
                child: Text(
                  "Make Happy",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                    fontFamily: "Signatra",
                    letterSpacing: 3,
                  ),
                ),
              ),
              // Conditionally render the button based on authentication status
              if (_firebaseAuth.currentUser == null)
                ElevatedButton(
                  onPressed: () {
                    _requestPermissionManually();
                    // Handle button click for unauthenticated user
                  },
                  child: Text("Next"),
                ),
            ],
          ),
        ),
      ),
    );
  }
}


