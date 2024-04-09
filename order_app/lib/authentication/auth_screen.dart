import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:order_app/mainScreens/discover_screen.dart';
import 'package:order_app/mainScreens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_apple_sign_in/the_apple_sign_in.dart';
import 'package:http/http.dart' as http;
import '../global/global.dart';
import '../widgets/error_dialog.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;
final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);

class MergedLoginScreen extends StatefulWidget {
  const MergedLoginScreen({Key? key}) : super(key: key);

  @override
  _MergedLoginScreenState createState() => _MergedLoginScreenState();
}

class _MergedLoginScreenState extends State<MergedLoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController codeController = TextEditingController();

  bool _isEmailSent = false;
  String? verificationCode;


  Future<void> sendEmail() async {
    final email = emailController.text.trim();

    if (email.isEmpty || !isValidEmail(email)) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Invalid Email'),
            content: Text('Please enter a valid email address.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(
            'https://polskoydm.pythonanywhere.com/global_auth?email=$email'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          _isEmailSent = true;
          verificationCode = data['verification_code'];
        });
      } else {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('Failed to Send Email'),
              content: Text('Unable to send email. Please try again later.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('An error occurred while sending the email: $e'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-]+(\.[\w-]+)*@[\w-]+(\.[\w-]+)+$');
    return emailRegex.hasMatch(email);
  }


  void verify() async {
    final enteredCode = codeController.text;
    bool trackingPermissionStatus = sharedPreferences!.getBool("tracking") ?? false;

    if (enteredCode == verificationCode) {
      final email = emailController.text.trim();
      final password = "passwordless";

      try {
        UserCredential userCredential;

        // Attempt to create a user account
        try {
          userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );

          String uid = userCredential.user?.uid ?? "";
          String userEmail = userCredential.user?.email ?? "";

          // Check if the user exists in Firestore
          DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
              .collection("users")
              .doc(uid)
              .get();

          if (!userSnapshot.exists) {
            // If the user doesn't exist in Firestore, create a new document
            await FirebaseFirestore.instance.collection("users").doc(uid).set({
              "uid": uid,
              "name": "Add Full Name",
              "status": "approved",
              "phone": "Add Phone Number",
              "address": "Add Address",
              "email": userEmail,
              "userAvatarUrl": "https://cdn.pixabay.com/photo/2017/11/10/05/48/user-2935527_1280.png",
              "trackingPermission": trackingPermissionStatus,
            });

            final SharedPreferences prefs = await SharedPreferences.getInstance();
            prefs.setString("email", userEmail);
            showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: Text('Verification Successful'),
                  content: Text('You have successfully verified your email.'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // Add your logic to navigate to the next screen or perform other actions
                        readDataAndSetDataLocally(userCredential.user!);
                      },
                      child: Text('OK'),
                    ),
                  ],
                );
              },
            );
          }


        } catch (e) {
          if (e is FirebaseAuthException) {
            if (e.code == 'email-already-in-use') {
              // Try to sign in the user with the existing credentials
              try {
                userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
                  email: email,
                  password: password,
                );

                // Handle a successful sign-in
                if (userCredential.user != null) {

                  // Continue with your app logic for the authenticated user.
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: Text('Verification Successful'),
                        content: Text('You have successfully verified your email.'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              // Add your logic to navigate to the next screen or perform other actions
                              readDataAndSetDataLocally(userCredential.user!);
                            },
                            child: Text('OK'),
                          ),
                        ],
                      );
                    },
                  );
                }
              } catch (e) {
                // Handle the sign-in error here
                print('Failed to sign in the user: $e');
              }
            } else {
              // Handle other Firebase Authentication errors
              print('Failed to create a user account: $e');
            }
          }
        }
      } catch (e) {
        // Handle errors for Firebase Authentication
        print('Error: $e');
      }
    } else {
      // Verification failed, show an error dialog
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Verification Failed'),
            content: Text('Invalid verification code. Please try again.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
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
          AppleIdCredential? appleCredentials =
              authorizationResult.credential;
          OAuthProvider oAuthProvider = OAuthProvider("apple.com");
          OAuthCredential oAuthCredential = oAuthProvider.credential(
            idToken: String.fromCharCodes(appleCredentials!.identityToken!),
            accessToken:
            String.fromCharCodes(appleCredentials.authorizationCode!),
          );

          UserCredential userCredential = await FirebaseAuth.instance
              .signInWithCredential(oAuthCredential);
          if (userCredential.user != null) {
            String uid = userCredential.user?.uid ?? "";
            String userEmail = userCredential.user?.email ?? "";
            bool trackingPermissionStatus =
                sharedPreferences!.getBool("tracking") ?? false;

            DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
                .collection("users")
                .doc(uid)
                .get();

            if (!userSnapshot.exists) {
              await FirebaseFirestore.instance
                  .collection("users")
                  .doc(uid)
                  .set({
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
              .collection("users")
              .doc(uid)
              .get();

          if (!userSnapshot.exists) {
            bool trackingPermissionStatus =
                sharedPreferences!.getBool("tracking") ?? false;

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

          readDataAndSetDataLocally(user);
        }
      }
    } catch (error) {
      print("Google Sign-In Error: $error");
    }
  }

  Future readDataAndSetDataLocally(User currentUser) async {
    await FirebaseFirestore.instance
        .collection("users")
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
              context, MaterialPageRoute(builder: (c) => MyHomePage()));
        } else {
          _auth.signOut();
          Navigator.pop(context);
          Fluttertoast.showToast(
              msg: "Admin has blocked your account. \n\nMail here: polskoydm@gmail.com");
        }
      } else {
        _auth.signOut();
        Navigator.pop(context);
        Navigator.push(context,
            MaterialPageRoute(builder: (c) => const MergedLoginScreen()));

        showDialog(
          context: context,
          builder: (c) {
            return ErrorDialog(
              message: "No record found.",
            );
          },
        );
      }
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
              Padding(
                padding: EdgeInsets.fromLTRB(0, 8, 0, 0),
                child: Text(
                  "Or Continue with Email",
                  textAlign: TextAlign.start,
                  overflow: TextOverflow.clip,
                  style: TextStyle(
                    fontWeight: FontWeight.w400,
                    fontStyle: FontStyle.normal,
                    fontSize: 14,
                    color: Color(0xff9e9e9e),
                  ),
                ),
              ),

              Padding(
                padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                child: Align(
                  alignment: Alignment(0.0, 0.0),
                  child: TextField(
                    controller: emailController,
                    obscureText: false,
                    textAlign: TextAlign.start,
                    maxLines: 1,
                    style: TextStyle(
                      fontWeight: FontWeight.w400,
                      fontStyle: FontStyle.normal,
                      fontSize: 16,
                      color: Color(0xff000000),
                    ),
                    decoration: InputDecoration(
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4.0),
                        borderSide: BorderSide(color: Color(0xff9e9e9e), width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4.0),
                        borderSide: BorderSide(color: Color(0xff9e9e9e), width: 1),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4.0),
                        borderSide: BorderSide(color: Color(0xff9e9e9e), width: 1),
                      ),
                      labelText: "Email",
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.w400,
                        fontStyle: FontStyle.normal,
                        fontSize: 16,
                        color: Color(0xff9e9e9e),
                      ),
                      filled: true,
                      fillColor: Color(0x00f2f2f3),
                      isDense: false,
                      contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    ),
                  ),
                ),
              ),

              Padding(
                padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                child: Align(
                  alignment: Alignment(0.0, 0.0),
                  child: _isEmailSent
                      ? Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(bottom: 16), // Add padding here
                        child: TextField(
                          controller: codeController,
                          obscureText: false,
                          textAlign: TextAlign.start,
                          maxLines: 1,
                          style: TextStyle(
                            fontWeight: FontWeight.w400,
                            fontStyle: FontStyle.normal,
                            fontSize: 16,
                            color: Color(0xff000000),
                          ),
                          decoration: InputDecoration(
                            disabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4.0),
                              borderSide: BorderSide(color: Color(0xff9e9e9e), width: 1),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4.0),
                              borderSide: BorderSide(color: Color(0xff9e9e9e), width: 1),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4.0),
                              borderSide: BorderSide(color: Color(0xff9e9e9e), width: 1),
                            ),
                            labelText: "Verification Code",
                            labelStyle: TextStyle(
                              fontWeight: FontWeight.w400,
                              fontStyle: FontStyle.normal,
                              fontSize: 16,
                              color: Color(0xff9e9e9e),
                            ),
                            filled: true,
                            fillColor: Color(0x00f2f2f3),
                            isDense: false,
                            contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 16), // Add padding here
                        child: MaterialButton(
                          onPressed: () {
                            // Add your code to handle verification here
                            verify();
                          },
                          color: Color(0xffffffff),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            side: BorderSide(color: Color(0xff9e9e9e), width: 1),
                          ),
                          padding: EdgeInsets.all(16),
                          child: Text(
                            "Submit",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              fontStyle: FontStyle.normal,
                            ),
                          ),
                          textColor: Color(0xff000000),
                          height: 40,
                          minWidth: 140,
                        ),
                      ),
                    ],
                  )
                      : MaterialButton(
                    onPressed: () {
                      // Change _isEmailSent to true when the "Send Code" button is pressed.

                      sendEmail();
                    },
                    color: Color(0xffffffff),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      side: BorderSide(color: Color(0xff9e9e9e), width: 1),
                    ),
                    padding: EdgeInsets.all(16),
                    child: Text(
                      "Send Code",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        fontStyle: FontStyle.normal,
                      ),
                    ),
                    textColor: Color(0xff000000),
                    height: 40,
                    minWidth: 140,
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