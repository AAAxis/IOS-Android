import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:taxi_app/authentication/auth_screen.dart';
import 'package:taxi_app/chat_screen.dart';
import 'package:taxi_app/global/global.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
    final String baseUrl = 'polskoydm.pythonanywhere.com';
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
    final apiUrl = 'https://polskoydm.pythonanywhere.com/balance';
    final url = Uri.parse('$apiUrl?email=$email');

    print('Requesting API URL: $url');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);

      if (responseData.containsKey("balance")) {
        final updatedBalance = responseData["balance"];
        print('API Response: $updatedBalance');
        updateBalance(updatedBalance.toString());
      }
    } else {
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
                if (selectedOption.isNotEmpty)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          launchURLWithParams();
                          Navigator.of(context).pop();
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
      appBar: AppBar(
        title: Text('Settings'),
        backgroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          Container(
            margin: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Billa Balance',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                      Text(
                        '\$${sharedPreferences!.getString("money") ?? "0"}',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
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
                          size: 34,
                          color: Colors.white,
                        ),
                        onPressed: () async {
                          final email = sharedPreferences!.getString("email") ?? "No Email";
                          await fetchBalance(email);
                        },
                      ),
                      ElevatedButton(
                        onPressed: () {
                          _showAddMoneyDialog();
                        },
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all(Colors.green),
                          padding: MaterialStateProperty.all(EdgeInsets.all(0)),
                        ),
                        child: Text(
                          'Top-up',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),

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
          ListTile(
            leading: const Icon(Icons.history, color: Colors.black),
            title: const Text(
              "Ride History",
              style: TextStyle(color: Colors.black),
            ),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (c) => ChatScreen()));
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
          ),
          const Divider(
            height: 10,
            color: Colors.grey,
            thickness: 2,
          ),
          ListTile(
            leading: const Icon(Icons.language, color: Colors.black),
            title: const Text(
              "Language: English",
              style: TextStyle(color: Colors.black),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text(
              "Delete Profile",
              style: TextStyle(color: Colors.black),
            ),
            onTap: () async {
              const url = 'https://theholylabs.com/';
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
        ],
      ),
    );
  }
}


