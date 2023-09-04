import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:order_app/authentication/auth_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';




class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController nameController = TextEditingController();

  Future<void> _registerWithEmailPassword() async {
    try {
      final String email = emailController.text.trim();
      final String password = passwordController.text;
      final String name = nameController.text;

      final UserCredential authResult = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = authResult.user;

      if (user != null) {
        await user.sendEmailVerification(); // Send verification email

        String userImageUrl = "https://cdn.pixabay.com/photo/2017/11/10/05/48/user-2935527_1280.png";
        String userEmail = user.email ?? "";
        String userName = name;

        await saveDataToFileStore(user.uid, userEmail, userName, userImageUrl);

        // Redirect to a screen indicating verification pending
        Navigator.push(context, MaterialPageRoute(builder: (c) => AuthScreen()));
        // Show a notification message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "A verification email has been sent to your email address. Please verify your email before proceeding.",
            ),
          ),
        );
        // Listen for changes in the user's authentication state
        final Stream<User?> userStream = _auth.userChanges();
        await for (final updatedUser in userStream) {
          if (updatedUser != null && updatedUser.uid == user.uid) {
            // Check if the user's email is verified
            if (updatedUser.emailVerified) {
              // Update the user's status to "approved" in Firestore
              await FirebaseFirestore.instance.collection("users").doc(user.uid).update({
                "status": "approved",
              });
            }
          }
        }
      }
    } catch (error) {
      print("Registration Error: $error");
      // Handle registration error
    }
  }

  Future<void> saveDataToFileStore(String uid, String userEmail, String userName, String userImageUrl) async {

    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    await sharedPreferences.setString("uid", uid);
    await sharedPreferences.setString("email", userEmail);
    await sharedPreferences.setString("name", userName);
    await sharedPreferences.setString("photoUrl", userImageUrl);
    bool trackingPermissionStatus = sharedPreferences!.getBool("tracking") ?? false;

    FirebaseFirestore.instance.collection("users").doc(uid).set({
      "uid": uid,
      "email": userEmail,
      "name": userName,
      "userAvatarUrl": userImageUrl,
      "status": "disabled",
      "phone": "Add Phone Number",
      "address": "Add Delivery Address",
      "trackingPermission": trackingPermissionStatus,


    });




  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            // Name Text Field
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: "Name",
                prefixIcon: Icon(Icons.person),
              ),
            ),

            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: "Email",
                prefixIcon: Icon(Icons.email),
              ),
            ),
            SizedBox(height: 10),
            // Password Text Field
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: "Password",
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            SizedBox(height: 20),

            // Row for buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Register Button
                ElevatedButton(
                  onPressed: _registerWithEmailPassword,
                  child: Text("Sign Up"),
                ),

              ],
            ),
          ],
        ),
      ),
    );
  }
}


void main() {
  runApp(MaterialApp(
    home: RegisterScreen(),
  ));
}
