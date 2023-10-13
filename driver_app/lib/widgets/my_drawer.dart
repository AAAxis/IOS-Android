import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:driver_app/authentication/auth_screen.dart';
import 'package:driver_app/global/global.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class MyDrawerPage extends StatefulWidget {
  @override
  _MyDrawerPageState createState() => _MyDrawerPageState();
}

class _MyDrawerPageState extends State<MyDrawerPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>(); // Initialize formKey


  @override
  void initState() {
    super.initState();
  }

  Future<void> _showEarningsDialog(BuildContext context) async {
    try {
      final apiUrl = 'https://polskoydm.pythonanywhere.com/driver_info';
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('email') ?? 'N/A';

      final Uri uri = Uri.parse('$apiUrl?email=$email'); // Create the URI
      print('Request URL: ${uri.toString()}'); // Print the URL

      final response = await http.get(uri);
      print('Response: ${response.body}'); // Print the response body

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final status = data['status'];
        final money = data['money'];
        await sharedPreferences!.setString('status', status);
        await sharedPreferences!.setInt('money', money);

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Earnings'),
              content: SingleChildScrollView(  // Wrap content in SingleChildScrollView
                child: Column(
                  children: [

                    Text('My Balance: $money'),
                    // Add more earnings content here as needed
                    // If the content exceeds the available space, it will become scrollable.
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('Close'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      } else {
        await sharedPreferences!.setString('status', "disabled");
        throw Exception('Failed to load driver info');
      }
    } catch (e) {
      // Handle any exceptions that occur during the request
      print('Error fetching user info: $e');
      // You can add error handling logic here, e.g., showing an error message to the user.
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
          Container(
            padding: const EdgeInsets.only(top: 25, bottom: 10),
            child: Column(
              children: const [
                SizedBox(height: 10),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.email, color: Colors.white),
            title: Text(
              FirebaseAuth.instance.currentUser?.email ?? "No Email",
              style: const TextStyle(color: Colors.white),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person, color: Colors.white,),
            title: GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text("Edit Name"),
                      content: Form(
                        key: formKey,
                        child: TextFormField(
                          controller: nameController,
                          decoration: const InputDecoration(labelText: "Name"),
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return 'Please enter your name';
                            }
                            return null;
                          },
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () async {
                            if (formKey.currentState?.validate() ?? false) {
                              final newName = nameController.text;
                              final user = FirebaseAuth.instance.currentUser;
                              if (user != null) {
                                final userDocRef = FirebaseFirestore.instance.collection('drivers').doc(user.uid);
                                await userDocRef.update({'name': newName});
                                updateName(newName);
                              }
                              Navigator.pop(context);
                            }
                          },
                          child: const Text("Save"),
                        ),
                      ],
                    );
                  },
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    sharedPreferences!.getString("name") ?? "No Name",
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),


          ListTile(
            leading: const Icon(Icons.phone, color: Colors.white,),
            title: GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text("Edit Phone Number"),
                      content: Form(
                        key: formKey,
                        child: TextFormField(
                          controller: phoneController,
                          decoration: const InputDecoration(labelText: "Phone Number"),
                          validator: (value) {
                            if (!isPhoneNumberValid(value)) {
                              return 'Please enter a valid phone number';
                            }
                            return null;
                          },
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () async {
                            if (formKey.currentState?.validate() ?? false) {
                              final newPhone = phoneController.text;
                              final user = FirebaseAuth.instance.currentUser;
                              if (user != null) {
                                final userDocRef = FirebaseFirestore.instance.collection('drivers').doc(user.uid);
                                await userDocRef.update({'phone': newPhone});
                                updatePhone(newPhone);
                              }
                              Navigator.pop(context);
                            }
                          },
                          child: const Text("Save"),
                        ),
                      ],
                    );
                  },
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    sharedPreferences!.getString("phone") ?? "No Phone Number",
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.money, color: Colors.white),
            title: GestureDetector(
              onTap: () {
                // Show earnings dialog when the ListTile is tapped
                _showEarningsDialog(context);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Earnings',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.exit_to_app, color: Colors.white),
            title: const Text(
              "Sign Out",
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              signOutAndClearPrefs(context);
            },
          ),


          const Divider(
            height: 10,
            color: Colors.grey,
            thickness: 2,
          ),

          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text(
              "Delete Profile",
              style: TextStyle(color: Colors.white),
            ),
            onTap: () async {
              const url = 'https://www.wheels.works/about'; // Replace with the URL you want to open
              if (await launch(url)) {
                await launch(url);
              } else {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text("Error"),
                      content: const Text("Unable to open the link."),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text("OK"),
                        ),
                      ],
                    );
                  },
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.language, color: Colors.white),
            title: const Text(
              "Language: English",
              style: TextStyle(color: Colors.white),
            ),
          ),



        ],
      ),
    );
  }
}
