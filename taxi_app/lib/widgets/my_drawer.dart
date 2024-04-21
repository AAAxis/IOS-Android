import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:taxi_app/authentication/auth_screen.dart';
import 'package:taxi_app/global/global.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';


import 'package:http/http.dart' as http;

class MyDrawerPage extends StatefulWidget {
  @override
  _MyDrawerPageState createState() => _MyDrawerPageState();
}

class _MyDrawerPageState extends State<MyDrawerPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>(); // Initialize formKey



  @override
  void initState() {
    super.initState();

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


  void updateAddress(String newAddress) {
    setState(() {
      sharedPreferences!.setString("address", newAddress);
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
      appBar: AppBar(
        title: Text('My Profile'),
      ),
      body: ListView(
        children: [
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                fit: BoxFit.cover,
                // Use AssetImage to load the image from assets
                image: AssetImage('images/profile.png'),
              ),
            ),
          ),


          SizedBox(height: 20), // Adding space between the two containers
          ListTile(
            leading: const Icon(Icons.email, color: Colors.black),
            title: Text(
              FirebaseAuth.instance.currentUser?.email ?? "No Email",
              style: const TextStyle(color: Colors.black),
            ),
          ),

          ListTile(
            leading: const Icon(Icons.person, color: Colors.black),
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
                          decoration:
                          const InputDecoration(labelText: "Name"),
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
                              final user =
                                  FirebaseAuth.instance.currentUser;
                              if (user != null) {
                                final userDocRef = FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(user.uid);
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
                    style: TextStyle(color: Colors.black),
                  ),
                ],
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.location_city, color: Colors.black),
            title: GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text("Edit Delivery Area"),
                      content: Form(
                        key: formKey,
                        child: TextFormField(
                          controller: addressController,
                          decoration:
                          const InputDecoration(labelText: "Address"),
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return 'Please enter your City';
                            }
                            return null;
                          },
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () async {
                            if (formKey.currentState?.validate() ?? false) {
                              final newAddress = addressController.text;
                              final user =
                                  FirebaseAuth.instance.currentUser;
                              if (user != null) {
                                final userDocRef = FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(user.uid);
                                await userDocRef.update({'address': newAddress});
                                updateAddress(newAddress);
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
                    sharedPreferences!.getString("address") ?? "No Address",
                    style: TextStyle(color: Colors.black),
                  ),
                ],
              ),
            ),
          ),

          ListTile(
            leading: const Icon(Icons.phone, color: Colors.black),
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
                          decoration:
                          const InputDecoration(labelText: "Phone Number"),
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
                              final user =
                                  FirebaseAuth.instance.currentUser;
                              if (user != null) {
                                final userDocRef = FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(user.uid);
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
                    sharedPreferences!.getString("phone") ??
                        "No Phone Number",
                    style: TextStyle(color: Colors.black),
                  ),
                ],
              ),
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5), // Adjust padding as needed
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
            leading: Icon(Icons.delete, color: Colors.red),
            title: Text(
              "Delete Profile",
              style: TextStyle(color: Colors.black),
            ),
            onTap: () async {
              // Clear preferences
              signOutAndClearPrefs(context);

              String email = FirebaseAuth.instance.currentUser?.email ?? "No Email";
              // Encode the email address to handle special characters
              String encodedEmail = Uri.encodeComponent(email);

              var response = await http.delete(Uri.parse('https://polskoydm.pythonanywhere.com/delete?email=$encodedEmail'));

              if (response.statusCode == 200) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Delete User Data Request sent"),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Failed to delete account data"),
                  ),
                );
              }
            },
          ),

        ],
      ),
    );
  }
}
