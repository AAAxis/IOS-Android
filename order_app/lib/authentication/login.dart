import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:the_apple_sign_in/the_apple_sign_in.dart';

import '../global/global.dart';
import '../mainScreens/home_screen.dart';
import '../widgets/error_dialog.dart';
import '../widgets/loading_dialog.dart';
import 'auth_screen.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;
final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);

class MergedLoginScreen extends StatefulWidget {
  const MergedLoginScreen({Key? key}) : super(key: key);

  @override
  _MergedLoginScreenState createState() => _MergedLoginScreenState();
}

class _MergedLoginScreenState extends State<MergedLoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  formValidation() {
    if (emailController.text.isNotEmpty && passwordController.text.isNotEmpty) {
      // Login
      loginNow();
    } else {
      showDialog(
        context: context,
        builder: (c) {
          return ErrorDialog(
            message: "Please write email/password.",
          );
        },
      );
    }
  }

  loginNow() async {
    showDialog(
      context: context,
      builder: (c) {
        return LoadingDialog(
          message: "Checking Credentials",
        );
      },
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
        },
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
          AppleIdCredential? appleCredentials =
              authorizationResult.credential;
          OAuthProvider oAuthProvider = OAuthProvider("apple.com");
          OAuthCredential oAuthCredential = oAuthProvider.credential(
            idToken: String.fromCharCodes(appleCredentials!.identityToken!),
            accessToken: String.fromCharCodes(appleCredentials.authorizationCode!),
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
    await FirebaseFirestore.instance.collection("users").doc(currentUser.uid).get().then((snapshot) async {
      if (snapshot.exists) {
        if (snapshot.data()!["status"] == "approved") {
          await sharedPreferences!.setString("uid", currentUser.uid);
          await sharedPreferences!.setString("email", snapshot.data()!["email"]);
          await sharedPreferences!.setString("name", snapshot.data()!["name"]);
          await sharedPreferences!.setString("photoUrl", snapshot.data()!["userAvatarUrl"]);
          await sharedPreferences!.setString("phone", snapshot.data()!["phone"]);
          await sharedPreferences!.setString("address", snapshot.data()!["address"]);

          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (c) => const HomeScreen()));
        } else {
          firebaseAuth.signOut();
          Navigator.pop(context);
          Fluttertoast.showToast(msg: "Admin has blocked your account. \n\nMail here: polskoydm@gmail.com");
        }
      } else {
        firebaseAuth.signOut();
        Navigator.pop(context);
        Navigator.push(context, MaterialPageRoute(builder: (c) => const AuthScreen()));

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
                  "ToDo",
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
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Sign In",
                  textAlign: TextAlign.start,
                  overflow: TextOverflow.clip,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontStyle: FontStyle.normal,
                    fontSize: 24,
                    color: Color(0xff000000),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 16, horizontal: 0),
                child: Align(
                  alignment: Alignment(0.0, 0.0),
                  child: TextField(
                    controller: TextEditingController(text: "john@gmail.com"),
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
              TextField(
                controller: TextEditingController(text: "12345678"),
                obscureText: true,
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
                  labelText: "Password",
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
              Padding(
                padding: EdgeInsets.fromLTRB(0, 8, 0, 0),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    "Forgot Password ?",
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
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(0, 30, 0, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 1,
                      child: MaterialButton(
                        onPressed: () {},
                        color: Color(0xffffffff),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          side: BorderSide(color: Color(0xff9e9e9e), width: 1),
                        ),
                        padding: EdgeInsets.all(16),
                        child: Text(
                          "Sign Up",
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
                    SizedBox(
                      width: 16,
                    ),
                    Expanded(
                      flex: 1,
                      child: MaterialButton(
                        onPressed: () {
                          formValidation();
                        },
                        color: Color(0xff3a57e8),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        padding: EdgeInsets.all(16),
                        child: Text(
                          "Login",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            fontStyle: FontStyle.normal,
                          ),
                        ),
                        textColor: Color(0xffffffff),
                        height: 40,
                        minWidth: 140,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 16, horizontal: 0),
                child: Text(
                  "Or Continue with",
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
              Container(
                margin: EdgeInsets.all(0),
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: Color(0xffffffff),
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(color: Color(0xff9e9e9e), width: 1),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image(
                      image: NetworkImage(
                          "https://cdn3.iconfinder.com/data/icons/logos-brands-3/24/logo_brand_brands_logos_google-256.png"),
                      height: 25,
                      width: 25,
                      fit: BoxFit.cover,
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(16, 0, 0, 0),
                      child: Text(
                        "Google",
                        textAlign: TextAlign.start,
                        overflow: TextOverflow.clip,
                        style: TextStyle(
                          fontWeight: FontWeight.w400,
                          fontStyle: FontStyle.normal,
                          fontSize: 16,
                          color: Color(0xff000000),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
