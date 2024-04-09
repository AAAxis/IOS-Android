import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:order_app/authentication/auth_screen.dart';
import 'package:order_app/global/global.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:order_app/mainScreens/chat_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

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

  void updateBalance(String newBalance) {
    setState(() {
      sharedPreferences!.setString("money", newBalance);
    });
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


  String selectedOption = '';
  void launchURLWithParams() async {
    final String baseUrl = 'polskoydm.pythonanywhere.com'; // Remove 'https://' from the base URL
    final String total = selectedOption;
    final String email = sharedPreferences!.getString("email") ?? "No Email";

    final urlWithParams = Uri.https(baseUrl, '/addmoney', {
      'total': total,
      'email': email,
    });

    final urlString = urlWithParams.toString();

    print('URL: $urlString');

    if (await canLaunch(urlString)) {
      print('Launching URL...');
      final result = await launch(urlString);
      if (result) {
        print('URL launched successfully');
      } else {
        print('Failed to launch the URL');
      }
    } else {
      print('Could not launch the URL: $urlString');
    }
  }

  Future<void> fetchBalance(String email) async {
    final apiUrl = 'https://polskoydm.pythonanywhere.com/balance'; // Replace with your API endpoint
    final url = Uri.parse('$apiUrl?email=$email');

    print('Requesting API URL: $url'); // Print the URL before making the request

    final response = await http.get(url);

    if (response.statusCode == 200) {
      // Successful API response
      final responseData = json.decode(response.body); // Parse the JSON response

      if (responseData.containsKey("balance")) {
        final updatedBalance = responseData["balance"];
        print('API Response: $updatedBalance'); // Print the response

        updateBalance(updatedBalance.toString()); // Update the balance in shared preferences as a string
      }
    } else {
      // Handle API error
      print('Failed to fetch balance: ${response.statusCode}');
    }
  }





  void _showAddMoneyDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: Text('Add Money'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Column(
                  children: [
                    RadioListTile<String>(
                      title: Text('\$100.00'),
                      value: '100',
                      groupValue: selectedOption,
                      onChanged: (String? value) {
                        setState(() {
                          selectedOption = value!;
                        });
                      },
                    ),
                    RadioListTile<String>(
                      title: Text('\$200.00'),
                      value: '200',
                      groupValue: selectedOption,
                      onChanged: (String? value) {
                        setState(() {
                          selectedOption = value!;
                        });
                      },
                    ),
                    RadioListTile<String>(
                      title: Text('\$300.00'),
                      value: '300',
                      groupValue: selectedOption,
                      onChanged: (String? value) {
                        setState(() {
                          selectedOption = value!;
                        });
                      },
                    ),
                  ],
                ),
                if (selectedOption.isNotEmpty) // Show the "Checkout" button if an option is selected
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          launchURLWithParams(); // Send data to your API
                          Navigator.of(context).pop(); // Close the dialog
                        },
                        child: Text('Checkout'),
                      ),
                    ],
                  ),
              ],
            ),
          );
        });
      },
    );
  }


  @override
  Widget build(BuildContext context) {


    return Scaffold(
      body: ListView(
        children: [
          // Credit Card View
          Container(
            margin: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue, // Customize the background color
              borderRadius: BorderRadius.circular(15), // Adjust the radius value as needed
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), // Add left and right padding
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Billa Balance',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                      Text(
                        '\$${sharedPreferences!.getString("money") ?? "0"}', // Display the balance amount with a dollar sign
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      )

                    ],
                  ),
                ),
                const SizedBox(height: 110),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.refresh,
                          size: 34, // Adjust the size as needed
                          color: Colors.white, // Set the icon color to match the background color
                        ),
                        onPressed: () async {
                          final email = sharedPreferences!.getString("email") ?? "No Email";
                          await fetchBalance(email);
                        },
                      ),
                      ElevatedButton(
                        onPressed: () {
                          // Add your "Top-up" button functionality here
                          _showAddMoneyDialog();
                        },
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all(Colors.green),
                          padding: MaterialStateProperty.all(EdgeInsets.all(0)), // Remove default button padding
                        ),
                        child: Text(
                          'Top-up',
                          style: TextStyle(color: Colors.white, fontSize: 16), // Adjust text style as needed
                        ),
                      ),
                    ],
                  ),
                )

              ],
            ),
          ),


          Container(
            padding: const EdgeInsets.only(top: 2, bottom: 10),
            child: Column(
              children: const [
                SizedBox(height: 10),
              ],
            ),
          ),

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
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home, color: Colors.white,),
            title: GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text("Edit Addrss"),
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
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.history, color: Colors.white),
            title: const Text(
              "Order History",
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              Navigator.push(
                  context, MaterialPageRoute(builder: (c) => ChatScreen()));
            },
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
            leading: Icon(Icons.delete, color: Colors.red),
            title: Text(
              "Delete Profile",
              style: TextStyle(color: Colors.white),
            ),
            onTap: () async {
              final FirebaseAuth _auth = FirebaseAuth.instance;
              final User? user = _auth.currentUser;
              if (user != null && user.email != null) {
                // Show a confirmation dialog
                bool confirmDelete = await showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text("Confirm"),
                      content: const Text("Do you really want to delete the account data?"),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context, false); // Return false if the user cancels
                          },
                          child: const Text("Cancel"),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context, true); // Return true if the user confirms
                          },
                          child: const Text("Delete"),
                        ),
                      ],
                    );
                  },
                );

                if (confirmDelete == true) {
                  try {
                    // Delete user profile data from Firestore
                    await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();
                    // Delete user account
                    await user.delete();

                    // Clear preferences
                    signOutAndClearPrefs(context);


                    // Open link
                    final String email = user.email!;
                    final url = 'https://polskoydm.pythonanywhere.com/delete?email=$email'; // Replace with the URL you want to open
                    await launch(url); // Launch the URL

                    // Navigate to sign-in screen or any other screen
                  } catch (error) {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text("Error"),
                          content: Text("An error occurred while deleting the profile: $error"),
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
                }
              } else {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text("Error"),
                      content: const Text("User information not available."),
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
