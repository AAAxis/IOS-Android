import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:order_app/global/global.dart';
import 'package:order_app/mainScreens/home_screen.dart';
import 'package:order_app/widgets/error_dialog.dart';
import 'package:order_app/widgets/loading_dialog.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'auth_screen.dart';
import 'package:the_apple_sign_in/the_apple_sign_in.dart';


final FirebaseAuth _auth = FirebaseAuth.instance;
final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);


class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}



class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();


  formValidation() {
    if (emailController.text.isNotEmpty && passwordController.text.isNotEmpty) {
      //login
      loginNow();
    }
    else {
      showDialog(
          context: context,
          builder: (c) {
            return ErrorDialog(
              message: "Please write email/password.",
            );
          }
      );
    }
  }


  loginNow() async
  {
    showDialog(
        context: context,
        builder: (c) {
          return LoadingDialog(
            message: "Checking Credentials",
          );
        }
    );

    User? currentUser;
    await firebaseAuth.signInWithEmailAndPassword(
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
    ).then((auth) {
      currentUser = auth.user!;
    }).catchError((error) {
      Navigator.pop(context);
      showDialog(
          context: context,
          builder: (c) {
            return ErrorDialog(
              message: error.message.toString(),
            );
          }
      );
    });
    if (currentUser != null) {
      readDataAndSetDataLocally(currentUser!);
    }
  }

  Future<void> appleSign() async {
    AuthorizationResult authorizationResult =
    await TheAppleSignIn.performRequests([
      const AppleIdRequest(requestedScopes: [Scope.email, Scope.fullName])
    ]);

    switch (authorizationResult.status) {
      case AuthorizationStatus.authorized:
        print("authorized");
        try {
          AppleIdCredential? appleCredentials = authorizationResult.credential;
          OAuthProvider oAuthProvider = OAuthProvider("apple.com");
          OAuthCredential oAuthCredential = oAuthProvider.credential(
              idToken: String.fromCharCodes(appleCredentials!.identityToken!),
              accessToken:
              String.fromCharCodes(appleCredentials.authorizationCode!));

          UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(oAuthCredential);
          if (userCredential.user != null) {
            String uid = userCredential.user?.uid ?? "";
            String userEmail = userCredential.user?.email ?? "";
            bool trackingPermissionStatus = sharedPreferences!.getBool("tracking") ?? false;


            // Check if the user exists in Firestore
            DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
                .collection("users")
                .doc(uid)
                .get();

            if (!userSnapshot.exists) {
              // Add user data to Firestore
              await FirebaseFirestore.instance.collection("users").doc(uid).set({
                "uid": uid,
                "email": userCredential.user!.email,
                "name": "Add Full Name",
                "phone": "Add Phone Number",
                "address": "Add Delivery Address",
                "userAvatarUrl":
                "https://cdn.pixabay.com/photo/2017/11/10/05/48/user-2935527_1280.png",
                "status": "approved",
                "trackingPermission": trackingPermissionStatus,
              });
            }


            // Store user data in shared preferences
            await readDataAndSetDataLocally(userCredential.user!);
          }
        } catch (e) {
          print("Apple auth failed $e");
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
  }

  Future<void> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final UserCredential authResult = await _auth.signInWithCredential(credential);
        final User? user = authResult.user;

        if (user != null) {
          String uid = user.uid;
          String userImageUrl = user.photoURL ?? "";
          String userEmail = user.email ?? "";
          String userName = user.displayName ?? "";

          // Check if the user exists in Firestore
          DocumentSnapshot userSnapshot = await FirebaseFirestore.instance.collection("users").doc(uid).get();

          if (!userSnapshot.exists) {
            // Retrieve tracking permission status from SharedPreferences and convert to bool
            bool trackingPermissionStatus = sharedPreferences!.getBool("tracking") ?? false;

            // Add user data to Firestore, including tracking permission
            FirebaseFirestore.instance.collection("users").doc(uid).set({
              "uid": uid,
              "email": userEmail,
              "name": userName,
              "phone": "Add Phone Number",
              "address": "Add Delivery Address",
              "userAvatarUrl": userImageUrl,
              "status": "approved",
              "trackingPermission": trackingPermissionStatus,
            });
          }

          readDataAndSetDataLocally(user); // Directly call the method
        }
      }
    } catch (error) {
      print("Google Sign-In Error: $error");
      // Handle error
    }
  }


  Future readDataAndSetDataLocally(User currentUser) async
  {
    await FirebaseFirestore.instance.collection("users")
        .doc(currentUser.uid)
        .get()
        .then((snapshot) async {
      if (snapshot.exists) {
        if (snapshot.data()!["status"] == "approved") {
          await sharedPreferences!.setString("uid", currentUser.uid);
          await sharedPreferences!.setString(
              "email", snapshot.data()!["email"]);
          await sharedPreferences!.setString("name", snapshot.data()!["name"]);
          await sharedPreferences!.setString(
              "photoUrl", snapshot.data()!["userAvatarUrl"]);
          await sharedPreferences!.setString(
              "phone", snapshot.data()!["phone"]);
          await sharedPreferences!.setString(
              "address", snapshot.data()!["address"]);

          Navigator.pop(context);
          Navigator.push(
              context, MaterialPageRoute(builder: (c) => const HomeScreen()));
        } else {
          firebaseAuth.signOut();
          Navigator.pop(context);
          Fluttertoast.showToast(
              msg: "Admin has blocked your account. \n\nMail here: polskoydm@gmail.com");
        }
      }
      else {
        firebaseAuth.signOut();
        Navigator.pop(context);
        Navigator.push(
            context, MaterialPageRoute(builder: (c) => const AuthScreen()));

        showDialog(
            context: context,
            builder: (c) {
              return ErrorDialog(
                message: "No record found.",
              );
            }
        );
      }
    });
  }





  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 30),

            ElevatedButton.icon(
              onPressed: _signInWithGoogle,
              icon: Icon(Icons.mail), // Replace with Google icon
              label: Text("Sign in with Google"),
              style: ElevatedButton.styleFrom(
                primary: Colors.black, // Set button background color to black
              ),
            ),

            SizedBox(height: 10),

            // Conditional rendering of the Apple Sign-In button
            if (Platform.isIOS) // Only display on iOS
              ElevatedButton.icon(
                onPressed: () {
                  appleSign();
                },
                icon: Icon(Icons.apple), // Replace with Apple icon
                label: Text("Sign in with Apple"),
                style: ElevatedButton.styleFrom(
                  primary: Colors.black, // Set button background color to black
                ),
              ),

            SizedBox(height: 20),

            Text(
              "Or sign in with email",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),

            SizedBox(height: 10),

            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: "Email",
                      prefixIcon: Icon(Icons.email),
                    ),
                  ),
                  TextFormField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: "Password",
                      prefixIcon: Icon(Icons.lock),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center, // Center buttons horizontally
              children: [
                ElevatedButton(
                  onPressed: formValidation,
                  child: Text("Login"),
                ),
                SizedBox(width: 20), // Add space between buttons
                ElevatedButton(
                  onPressed: () {
                    DefaultTabController.of(context)!.animateTo(1);
                  },
                  style: ElevatedButton.styleFrom(
                    primary: Colors.red, // Set button background color to red
                  ),
                  child: Text("Sign Up"),
                ),
              ],
            ),
            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}