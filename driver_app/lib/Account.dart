import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver_app/addcar.dart';
import 'package:driver_app/admin.dart';
import 'package:driver_app/notification.dart';
import 'package:driver_app/addbank.dart';
import 'package:driver_app/widgets/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:driver_app/authentication/auth_screen.dart';
import 'package:driver_app/global/global.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class AccountPage extends StatefulWidget {
  @override
  _AccountPageState createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController codeController = TextEditingController();



  final GlobalKey<FormState> formKey = GlobalKey<FormState>(); // Initialize formKey


  @override
  void initState() {
    super.initState();
  }


  Future<void> loginMerchant() async {

    final enteredCode = codeController.text.trim();

    try {
      DocumentSnapshot merchantSnapshot =
      await FirebaseFirestore.instance.collection("merchants").doc(enteredCode).get();

      if (merchantSnapshot.exists) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('siteToken', enteredCode);
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (c) => AdminPage()),
        );
      } else {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('Verification Failed'),
              content: Text('Merchant site not found. Please enter a valid verification code.'),
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
      // Handle errors
      print('Error: $e');
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('An error occurred. Please try again later.'),
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


  Future<void> signOutAndClearPrefs(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => MergedLoginScreen()),
    );
  }

  bool isPhoneNumberValid(String? value) {
    if (value == null) return false;
    final RegExp regex = RegExp(r'^\+\d{11}$');
    return regex.hasMatch(value);
  }


  void updateName(String newName) {
    setState(() {
      sharedPreferences!.setString("name", newName);
    });
  }

  void updatePhone(String newPhone) {
    setState(() {
      sharedPreferences!.setString("phone", newPhone);
    });
  }


  @override
  Widget build(BuildContext context) {


    return Scaffold(
      body: ListView(
        children: [
          SizedBox(height: 22.0),
          Image.asset(
            "images/profile.png",
            width: 400.0,
            height: 250.0,
          ),
          SizedBox(height: 20.0),
          ListTile(
            leading: const Icon(Icons.account_circle, color: Colors.black),
            title: const Text(
              "My Profile",
              style: TextStyle(color: Colors.black),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (c) => MySettings()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.add_business_outlined, color: Colors.black),
            title: const Text(
              "My Store",
              style: TextStyle(color: Colors.black),
            ),
            onTap: () async {
              String? siteToken = sharedPreferences!.getString("siteToken");
              if (siteToken != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AdminPage()),
                );
              } else {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: Text('Connect to Store'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextFormField(
                            controller: codeController,
                            decoration: InputDecoration(
                              labelText: 'Merchant Code',
                            ),
                            validator: (value) {
                              // Code validation
                              if (value == null || value.isEmpty) {
                                return 'Please enter the verification code';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 18),
                          GestureDetector(
                            onTap: () {
                              // Navigate to the sign-up page when tapped
                              // Open the sign-up website when tapped
                              const url = 'https://polskoydm.pythonanywhere.com/merchant_register'; // Replace with your website URL
                              launch(url);
                            },
                            child: Text(
                              "I Don't have Merchant Code",
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            // Add your logic to verify email and code here
                            loginMerchant();
                          },
                          child: Text('Submit'),
                        ),
                      ],
                    );
                  },
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.directions_car_sharp, color: Colors.black),
            title: const Text(
              "Vehicle Info",
              style: TextStyle(color: Colors.black),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (c) => CarInfoList()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.money_outlined, color: Colors.black),
            title: const Text(
              "Payout Method",
              style: TextStyle(color: Colors.black),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (c) => BankInfoList()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.notification_add_outlined, color: Colors.black),
            title: const Text(
              "Notifications",
              style: TextStyle(color: Colors.black),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (c) => NotificationScreen()),
              );
            },
          ),


          ListTile(
            leading: const Icon(Icons.language, color: Colors.black),
            title: const Text(
              "Language: English",
              style: TextStyle(color: Colors.black),
            ),
          ),

          const Divider(
            height: 10,
            color: Colors.grey,
            thickness: 2,
          ),

          ListTile(
            leading: const Icon(Icons.exit_to_app, color: Colors.black),
            title: const Text(
              "Sign Out",
              style: TextStyle(color: Colors.black),
            ),
            onTap: () {
              signOutAndClearPrefs(context);
            },
          ),




        ],
      ),
    );
  }
}