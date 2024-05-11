import 'dart:io';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxi_app/authentication/add_data.dart';
import 'package:taxi_app/authentication/email_login.dart';
import 'package:taxi_app/mainScreens/navigation.dart';
import 'package:the_apple_sign_in/the_apple_sign_in.dart';
import '../global/global.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;
final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {



  Future<void> appleSign() async {
    try {
      AuthorizationResult authorizationResult =
      await TheAppleSignIn.performRequests([
        const AppleIdRequest(requestedScopes: [Scope.email, Scope.fullName])
      ]);

      switch (authorizationResult.status) {
        case AuthorizationStatus.authorized:
          print("authorized");
          AppleIdCredential? appleCredentials = authorizationResult.credential;
          OAuthProvider oAuthProvider = OAuthProvider("apple.com");
          OAuthCredential oAuthCredential = oAuthProvider.credential(
            idToken: String.fromCharCodes(appleCredentials!.identityToken!),
            accessToken:
            String.fromCharCodes(appleCredentials.authorizationCode!),
          );

          UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(oAuthCredential);
          if (userCredential.user != null) {
            String uid = userCredential.user!.uid;
            String userEmail = userCredential.user!.email ?? "";
            bool trackingPermissionStatus =
                sharedPreferences!.getBool("tracking") ?? false;

            DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
                .collection("contractors")
                .doc(uid)
                .get();

            bool isFirstLogin = !userSnapshot.exists;
            if (isFirstLogin) {
              await FirebaseFirestore.instance
                  .collection("contractors")
                  .doc(uid)
                  .set({
                "uid": uid,
                "email": userEmail,
                "name": "Add Full Name",
                "phone": "Add Phone",
                "address": "Add Location",
                "status": "contractor",
                "trackingPermission": trackingPermissionStatus,
              });
              // Navigate to Add Data Screen
              await readDataAndSetDataLocally(userCredential.user!);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => FirstPage()),
              );
            } else {
              // Navigate to Home Page
              await readDataAndSetDataLocally(userCredential.user!);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Navigation()),
              );
            }


          }
          break;
        case AuthorizationStatus.error:
          print("error" + authorizationResult.error.toString());
          break;
        case AuthorizationStatus.cancelled:
          print("cancelled");
          break;
        default:
          print("none of the above: default");
          break;
      }
    } catch (e) {
      print("Apple auth failed $e");
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final UserCredential authResult =
        await _auth.signInWithCredential(credential);
        final User? user = authResult.user;

        if (user != null) {
          String uid = user.uid;
          String userImageUrl = user.photoURL ?? "";
          String userEmail = user.email ?? "";
          String userName = user.displayName ?? "";

          DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
              .collection("contractors")
              .doc(uid)
              .get();

          bool isFirstLogin = !userSnapshot.exists;
          if (isFirstLogin) {
            bool trackingPermissionStatus =
                sharedPreferences!.getBool("tracking") ?? false;

            FirebaseFirestore.instance.collection("contractors").doc(uid).set({
              "uid": uid,
              "email": userEmail,
              "name": userName,
              "phone": "Add Phone",
              "address": "Add Location",
              "status": 'contractor',
              "trackingPermission": trackingPermissionStatus,
            });
            // Navigate to Add Data Screen
            readDataAndSetDataLocally(user);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => FirstPage()),
            );
          } else {
            readDataAndSetDataLocally(user);
            // Navigate to Home Page
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => Navigation()),
            );
          }


        }
      }
    } catch (error) {
      print("Google Sign-In Error: $error");
    }
  }

  Future<void> readDataAndSetDataLocally(User currentUser) async {
    await FirebaseFirestore.instance
        .collection("contractors")
        .doc(currentUser.uid)
        .get()
        .then((snapshot) async {

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString("uid", currentUser.uid);
      await prefs.setString("email", snapshot.data()!["email"]);
      await prefs.setString("name", snapshot.data()!["name"]);
      await prefs.setString("phone", snapshot.data()!["phone"]);
      await prefs.setString("address", snapshot.data()!["address"]);
      await prefs.setString("status", snapshot.data()!["status"]);

    });
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffffffff),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image(
                image: NetworkImage(
                  "https://cdn3.iconfinder.com/data/icons/network-and-communications-6/130/291-128.png",
                ),
                height: 90,
                width: 90,
                fit: BoxFit.cover,
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(0, 8, 0, 30),
                child: Text(
                  "Sign In",
                  textAlign: TextAlign.start,
                  overflow: TextOverflow.clip,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontStyle: FontStyle.normal,
                    fontSize: 20,
                    color: Color(0xff3a57e8),
                  ),
                ),
              ),
              if (Platform.isIOS) // Check if the platform is iOS
                Padding(
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 0), // Adjust padding here
                  child: OutlinedButton(
                    onPressed: () {
                      appleSign();
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.black),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Continue with Apple",
                          style: TextStyle(
                            fontWeight: FontWeight.w400,
                            fontStyle: FontStyle.normal,
                            fontSize: 14,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(width: 8),
                        Image.asset(
                          'images/apple.png',
                          width: 50,
                          height: 50,
                        ),
                      ],
                    ),
                  ),
                ),

              if (Platform.isAndroid) // Check if the platform is iOS
                Padding(
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      OutlinedButton(
                        onPressed: () {
                          _signInWithGoogle();
                        },
                        style: OutlinedButton.styleFrom( // Text color
                          side: BorderSide(color: Colors.black), // Border color
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Continue with Google",
                              style: TextStyle(
                                fontWeight: FontWeight.w400,
                                fontStyle: FontStyle.normal,
                                fontSize: 14,
                                color: Colors.black, // Text color
                              ),
                            ),
                            SizedBox(width: 8), // Add some spacing between the text and the icon
                            Image.asset(
                              'images/google.png', // Add the path to your Google logo image
                              width: 50,
                              height: 50,
                            ),
                          ],
                        ),
                      ),

                    ],
                  ),
                ),

              if (Platform.isIOS || Platform.isAndroid) // Check if the platform is iOS or Android
                Padding(
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => EmailLoginScreen()));
                      // Add your logic for signing in with email here
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.black),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Continue with Email",
                          style: TextStyle(
                            fontWeight: FontWeight.w400,
                            fontStyle: FontStyle.normal,
                            fontSize: 14,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.email, // You can use any email-related icon here
                          color: Colors.black, // Icon color
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                ),


            ],
          ),
        ),
      ),
    );
  }


}