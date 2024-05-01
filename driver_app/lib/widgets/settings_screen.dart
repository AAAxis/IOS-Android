import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver_app/widgets/navigation_bar.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:driver_app/authentication/auth_screen.dart';
import 'package:driver_app/global/global.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MySettings extends StatefulWidget {
  @override
  _MySettingsState createState() => _MySettingsState();
}

class _MySettingsState extends State<MySettings> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

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
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (c) => MainScreen()),
            );
          },
        ),
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
                image: NetworkImage(
                    'https://img.freepik.com/free-vector/businessman-character-avatar-isolated_24877-60111.jpg'),
              ),
            ),
          ),
          SizedBox(height: 20),
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
                      title: const Text("Edit Profile"),
                      content: Form(
                        key: formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextFormField(
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
                            TextFormField(
                              controller: phoneController,
                              decoration: const InputDecoration(
                                  labelText: "Phone Number"),
                              validator: (value) {
                                if (!isPhoneNumberValid(value)) {
                                  return 'Please enter a valid phone number';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () async {
                            if (formKey.currentState?.validate() ?? false) {
                              final newName = nameController.text;
                              final newPhone = phoneController.text;
                              final user =
                                  FirebaseAuth.instance.currentUser;
                              if (user != null) {
                                final userDocRef = FirebaseFirestore.instance
                                    .collection('drivers')
                                    .doc(user.uid);
                                await userDocRef.update({
                                  'name': newName,
                                  'phone': newPhone,
                                  'approval': true, // Setting approval to true
                                });
                                updateName(newName);
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
                    sharedPreferences!.getString("name") ?? "No Name",
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
                      title: const Text("Edit Profile"),
                      content: Form(
                        key: formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextFormField(
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
                            TextFormField(
                              controller: phoneController,
                              decoration: const InputDecoration(
                                  labelText: "Phone Number"),
                              validator: (value) {
                                if (!isPhoneNumberValid(value)) {
                                  return 'Please enter a valid phone number';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () async {
                            if (formKey.currentState?.validate() ?? false) {
                              final newName = nameController.text;
                              final newPhone = phoneController.text;
                              final user =
                                  FirebaseAuth.instance.currentUser;
                              if (user != null) {
                                final userDocRef = FirebaseFirestore.instance
                                    .collection('drivers')
                                    .doc(user.uid);
                                await userDocRef.update({
                                  'name': newName,
                                  'phone': newPhone,
                                  'approval': true, // Setting approval to true
                                });
                                updateName(newName);
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
                    style: TextStyle(color: Colors.black),
                  ),
                ],
              ),
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
              signOutAndClearPrefs(context);

              String email =
                  sharedPreferences!.getString("email") ?? "No email";
              String encodedEmail = Uri.encodeComponent(email);

              try {
                var response = await http.post(
                  Uri.parse(
                      'https://polskoydm.pythonanywhere.com/delete'),
                  body: {'email': encodedEmail},
                );

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
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("An error occurred: $e"),
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
