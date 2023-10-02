import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:driver_app/home_screen.dart';
import 'package:driver_app/order_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: SplashScreenRouter(),
    );
  }
}

class SplashScreenRouter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      // Check if there's an email in SharedPreferences
      future: getEmailFromPrefs(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          final userEmail = snapshot.data;
          if (userEmail != null) {
            // Email found in SharedPreferences, navigate to home screen
            return MyHomePage(); // Replace with your actual home screen widget
          }
        }

        // No email in SharedPreferences or still loading, continue with splash screen
        return MySplashScreen();
      },
    );
  }

  Future<String?> getEmailFromPrefs() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_email');
  }
}

class MySplashScreen extends StatefulWidget {
  const MySplashScreen({Key? key}) : super(key: key);

  @override
  State<MySplashScreen> createState() => _MySplashScreenState();
}

class _MySplashScreenState extends State<MySplashScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkEmailInPrefs();
  }

  void _checkEmailInPrefs() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final userEmail = prefs.getString('user_email');

    if (userEmail != null) {
      // User's email found in SharedPreferences, navigate to home screen
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => MyHomePage()));
    } else {
      setState(() {
        _isLoading = false; // Email not found, stop showing loading indicator
      });
    }
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
    Navigator.push(context, MaterialPageRoute(builder: (context) => MyHomePage()));
  }

  void _becomeDriver() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => AddDriverForm()));
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
                borderRadius: BorderRadius.circular(100.0),
                child: SizedBox(
                  width: 250,
                  height: 250,
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
              ElevatedButton(
                onPressed: _becomeDriver,
                child: Text("Become a Partner"),
              ),

              if (!_isLoading) // Show these buttons when loading is complete
                Column(
                  children: [
                    const SizedBox(height: 10,),
                    ElevatedButton(
                      onPressed: _requestPermissionManually,
                      child: Text("Let's Start"),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
