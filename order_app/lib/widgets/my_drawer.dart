import 'package:flutter/material.dart';
import 'package:order_app/authentication/auth_screen.dart';
import 'package:order_app/global/global.dart';
import 'package:order_app/mainScreens/home_screen.dart';
import 'package:order_app/mainScreens/history_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class MyDrawer extends StatefulWidget {
  @override
  _MyDrawerState createState() => _MyDrawerState();
}

class _MyDrawerState extends State<MyDrawer> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>(); // Initialize formKey

  @override
  void initState() {
    super.initState();
  }

  void deleteUserDataFromFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Delete user data from Firestore
      final userDocRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      await userDocRef.delete();

      // Sign out the user
      await FirebaseAuth.instance.signOut();

      // Navigate to the authentication screen
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AuthScreen()));
    }
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

  Future<void> signOutAndClearPrefs(BuildContext context) async {
    // Sign out the user
    await FirebaseAuth.instance.signOut();

    // Clear SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    // Navigate to the AuthScreen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => AuthScreen()),
    );
  }

  bool isPhoneNumberValid(String? value) {
    if (value == null) return false;
    final RegExp regex = RegExp(r'^\+\d{11}$');
    return regex.hasMatch(value);
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          Container(
            padding: const EdgeInsets.only(top: 25, bottom: 10),
            child: Column(
              children: [
                const SizedBox(height: 10,),
              ],
            ),
          ),
          const SizedBox(height: 12,),

          ListTile(
            leading: const Icon(Icons.person, color: Colors.black,),
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
                                final userDocRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
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

          // Display user's email
          ListTile(
            leading: const Icon(Icons.email, color: Colors.black,),
            title: Text(
              FirebaseAuth.instance.currentUser?.email ?? "No Email",
              style: TextStyle(color: Colors.black),
            ),
          ),

          ListTile(
            leading: const Icon(Icons.location_on, color: Colors.black,),
            title: GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text("Edit Address"),
                      content: Form(
                        key: formKey,
                        child: TextFormField(
                          controller: addressController,
                          decoration: const InputDecoration(labelText: "Address"),
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return 'Please enter your address';
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
                              final user = FirebaseAuth.instance.currentUser;
                              if (user != null) {
                                final userDocRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
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
                  if (sharedPreferences!.getString("address") == null)
                    const Text(
                      "Add Address",
                      style: TextStyle(color: Colors.blue),
                    ),
                ],
              ),
            ),
          ),

          ListTile(
            leading: const Icon(Icons.phone, color: Colors.black,),
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
                                final userDocRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
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
                    style: TextStyle(color: Colors.black),
                  ),
                ],
              ),
            ),
          ),

          // Other list items

          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text(
              "Delete Account",
              style: TextStyle(color: Colors.red),
            ),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text("Delete Account"),
                    content: const Text("Are you sure you want to delete your account? This action cannot be undone."),
                    actions: [
                      TextButton(
                        onPressed: () {
                          deleteUserDataFromFirestore();
                        },
                        child: const Text("Delete"),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text("Cancel"),
                      ),
                    ],
                  );
                },
              );
            },
          ),

          const Divider(
            height: 10,
            color: Colors.grey,
            thickness: 2,
          ),

          ListTile(
            leading: const Icon(Icons.home, color: Colors.black,),
            title: const Text(
              "Home",
              style: TextStyle(color: Colors.black),
            ),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (c) => const HomeScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.language, color: Colors.black,),
            title: const Text(
              "Language: English (Canada)",
              style: TextStyle(color: Colors.black),
            ),
          ),

          ListTile(
            leading: const Icon(Icons.smartphone, color: Colors.black),
            title: const Text(
              "Contact Us",
              style: TextStyle(color: Colors.black),
            ),
            onTap: () async {
              const url = 'https://www.wheels.works'; // Replace with the URL you want to open
              if (await canLaunch(url)) {
                await launch(url);
              } else {
                // Handle the case where the URL can't be launched, e.g., show an error message.
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
            leading: const Icon(Icons.takeout_dining, color: Colors.black,),
            title: const Text(
              "Recent Orders",
              style: TextStyle(color: Colors.black),
            ),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (c) => OrderHistoryPage())); // Replace `HistoryScreen()` with your actual history page
            },
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
          )
        ],
      ),
    );
  }
}
