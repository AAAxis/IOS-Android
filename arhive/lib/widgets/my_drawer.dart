
import 'package:flutter/material.dart';
import 'package:order_app/authentication/auth_screen.dart';
import 'package:order_app/global/global.dart';
import 'package:order_app/mainScreens/home_screen.dart';
import 'package:order_app/mainScreens/history_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

class MyDrawer extends StatefulWidget {
  @override
  _MyDrawerState createState() => _MyDrawerState();
}

class _MyDrawerState extends State<MyDrawer> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();




  void updatePhotoUrl(String newPhotoUrl) {
    setState(() {
      sharedPreferences!.setString("photoUrl", newPhotoUrl);
    });
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

  @override
  void dispose() {
    nameController.dispose();
    addressController.dispose();
    phoneController.dispose();
    super.dispose();
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
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Material(
                      borderRadius: const BorderRadius.all(Radius.circular(80)),
                      elevation: 10,
                      child: Padding(
                        padding: const EdgeInsets.all(1.0),
                        child: Container(
                          height: 160,
                          width: 160,
                          child: CircleAvatar(
                            backgroundImage: NetworkImage(
                              sharedPreferences!.getString("photoUrl")!,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: InkWell(
                        onTap: () async {
                          final picker = ImagePicker();
                          final pickedFile = await picker.getImage(source: ImageSource.gallery);

                          if (pickedFile != null) {
                            final user = FirebaseAuth.instance.currentUser;
                            if (user != null) {
                              final storageRef = FirebaseStorage.instance.ref().child('user_images/${user.uid}.jpg');
                              final imageFile = File(pickedFile.path);

                              // Upload the selected image to Firebase Storage
                              final uploadTask = storageRef.putFile(imageFile);
                              final snapshot = await uploadTask.whenComplete(() => null);

                              // Get the download URL of the uploaded image
                              final downloadUrl = await snapshot.ref.getDownloadURL();

                              // Update user's photoUrl in Firestore
                              final userDocRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
                              await userDocRef.update({'userAvatarUrl': downloadUrl});

                              // Update user's photoUrl in SharedPreferences
                              updatePhotoUrl(downloadUrl);
                            }
                          }
                          Navigator.pop(context); // Close the dialog
                        },

                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.blue,
                          ),
                          child: Icon(
                            Icons.edit,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
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
                      content: TextField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: "Name"),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () async {
                            final newName = nameController.text;
                            final user = FirebaseAuth.instance.currentUser;
                            if (user != null) {
                              final userDocRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
                              await userDocRef.update({'name': newName});
                              updateName(newName);
                            }
                            Navigator.pop(context);
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
                      content: TextField(
                        controller: addressController,
                        decoration: const InputDecoration(labelText: "Address"),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () async {
                            final newAddress = addressController.text;
                            final user = FirebaseAuth.instance.currentUser;
                            if (user != null) {
                              final userDocRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
                              await userDocRef.update({'address': newAddress});
                              updateAddress(newAddress);
                            }
                            Navigator.pop(context);
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
                      content: TextField(
                        controller: phoneController,
                        decoration: const InputDecoration(labelText: "Phone Number"),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () async {
                            final newPhone = phoneController.text;
                            final user = FirebaseAuth.instance.currentUser;
                            if (user != null) {
                              final userDocRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
                              await userDocRef.update({'phone': newPhone});
                              updatePhone(newPhone);
                            }
                            Navigator.pop(context);
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
            leading: const Icon(Icons.history, color: Colors.black,),
            title: const Text(
              "History",
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
