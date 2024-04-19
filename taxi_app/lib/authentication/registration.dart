import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxi_app/global/global.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:taxi_app/mainScreens/home_screen.dart';
import 'package:taxi_app/mainScreens/navigation.dart';

class MultiStepRegistrationScreen extends StatefulWidget {
  @override
  _MultiStepRegistrationScreenState createState() =>
      _MultiStepRegistrationScreenState();
}

class _MultiStepRegistrationScreenState
    extends State<MultiStepRegistrationScreen> {
  PageController _pageController = PageController(initialPage: 0);

  TextEditingController _emailController =  TextEditingController();
  TextEditingController _nameController = TextEditingController();
  TextEditingController _phoneController = TextEditingController();
  String? _selectedEmploymentType;
  String? _selectedCity = "Tel Aviv";

  int _currentPage = 0;


  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _nameController.dispose();
    _pageController.dispose();
    super.dispose();

  }


  Future<void> _sendRegistrationData() async {
    final email = _emailController.text.trim();
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final employmentType = _selectedEmploymentType;
    final city = _selectedCity;

    final data = {
      'email': email,
      'name': name,
      'phone': phone,
      'employmentType': employmentType,
      'city': city,
    };

    print('Sending data: $data');

    try {
      final response = await http.post(
        Uri.parse('https://polskoydm.pythonanywhere.com/generate-pdf-and-send-email'),
        body: json.encode(data),
        headers: {'Content-Type': 'application/json'},
      );

      print('Response: ${response.body}');

      if (response.statusCode == 200) {
        // Update status and city in Firestore
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final userDocRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
          await userDocRef.update({'status': _selectedEmploymentType});
        }
      } else {
        // Handle failure
        throw Exception('Failed to send registration data. Status code: ${response.statusCode}');
      }
    } catch (e) {
      // Handle error
      print('Error: $e');
      throw Exception('Failed to send registration data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Registration'),
      ),
      body: PageView(
        controller: _pageController,
        physics: NeverScrollableScrollPhysics(),
        onPageChanged: (int page) {
          setState(() {
            _currentPage = page;
          });
        },
        children: [
          _buildFirstPage(),
          _buildSecondPage(),

        ],
      ),
    );
  }
  Widget _buildFirstPage() {
    // Get SharedPreferences values
    String email = sharedPreferences!.getString("email") ?? "No Email";
    String name = sharedPreferences!.getString("name") ?? "No Name";
    String phone = sharedPreferences!.getString("phone") ?? "No Phone";

    // Set controller text to SharedPreferences values
    _emailController.text = email;
    _nameController.text = name;
    _phoneController.text = phone;

    void updateName(String newName) {
      setState(() {
        sharedPreferences!.setString("name", newName);
      });
    }

    void updateAddress(String? newAddress) {
      if (newAddress != null) {
        setState(() {
          sharedPreferences!.setString("address", newAddress);
        });
      }
    }
    void updatePhone(String newPhone) {
      setState(() {
        sharedPreferences!.setString("phone", newPhone);
      });
    }


    return _buildPage(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          TextField(
            controller: _nameController,
            onTap: () {
              if (_nameController.text == "Add Full Name") {
                _nameController.clear();
              }
            },
            onChanged: (value) {
              if (value.trim().isEmpty) {
                setState(() {
                  _nameController.text = "Add Full Name";
                  _nameController.selection = TextSelection.fromPosition(
                    TextPosition(offset: _nameController.text.length),
                  );
                });
              }
            },
            decoration: InputDecoration(
              labelText: 'Full Name',
              prefixIcon: Icon(Icons.person),
            ),
          ),
          SizedBox(height: 20.0),
          TextField(
            controller: _phoneController,
            onTap: () {
              _phoneController.clear();
            },
            decoration: InputDecoration(
              labelText: 'Phone',
              prefixIcon: Icon(Icons.phone),
            ),
          ),
          SizedBox(height: 20.0),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Delivery City',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 10),
                DropdownButton<String>(
                  value: _selectedCity,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedCity = newValue;
                    });
                  },
                  items: [
                    'Haifa',
                    'Tel Aviv',
                    'Bat Yam',
                    'Holon',
                    'Ramat Gan',
                    'Netanya',
                  ].map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),

              ],
            ),
          ),
          SizedBox(height: 20.0),
          ElevatedButton(
            onPressed: () async {
              if (_nameController.text.trim().isEmpty || _nameController.text == "Add Full Name") {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: Text('Invalid Name'),
                      content: Text('Please enter a valid name.'),
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
                return;
              }

              if (validatePhone(_phoneController.text)) {
                final newPhone = _phoneController.text;
                final newName = _nameController.text;
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  final userDocRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
                  await userDocRef.update({'phone': newPhone, 'name': newName, 'address': _selectedCity});
                  updatePhone(newPhone);
                  updateName(newName);
                  updateAddress(_selectedCity);
                }

                // Proceed to the next step
                _pageController.nextPage(
                  duration: Duration(milliseconds: 300),
                  curve: Curves.ease,
                );
              } else {
                // Show an error message indicating that the phone number is invalid
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: Text('Invalid Phone Number'),
                      content: Text('Please enter a valid phone number.'),
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
            },
            child: Text('Next'),
          ),
        ],
      ),
    );
  }

  bool _isSelectionMade2 = false;

  Widget _buildSecondPage() {
    return _buildPage(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            'Employment Type',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Radio(
                value: 'contractor',
                groupValue: _selectedEmploymentType,
                onChanged: (value) {
                  setState(() {
                    _selectedEmploymentType = value.toString();
                    _isSelectionMade2 = true; // Set selection made to true
                  });
                },
              ),
              Text('Contractor'),
              SizedBox(width: 20),
              Radio(
                value: 'self-employed',
                groupValue: _selectedEmploymentType,
                onChanged: (value) {
                  setState(() {
                    _selectedEmploymentType = value.toString();
                    _isSelectionMade2 = true; // Set selection made to true
                  });
                },
              ),
              Text('Self-employed'),
            ],
          ),
          SizedBox(height: 20),
          Card(
            child: ListTile(
              leading: Icon(Icons.work),
              title: Text('Contractor'),
              subtitle:
              Text('As a contractor, you work for different clients on a project basis.'),
            ),
          ),
          SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: Icon(Icons.business),
              title: Text('Self-employed'),
              subtitle: Text('As a self-employed individual, you run your own business.'),
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isSelectionMade2
                ? () async {
              if (_selectedEmploymentType != null) {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.setString('status', _selectedEmploymentType!); // Add ! to assert non-null

                if (_selectedEmploymentType == 'contractor') {
                  // Navigate to the Contractor page
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => Navigation()),
                  );
                } else {
                  // Navigate to the Navigation page
                  _sendRegistrationData();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => MyHomePage()),
                  );
                }
              }
            }
                : null, // Disable button if selection is not made
            child: Text('Next'),
          ),

        ],
      ),
    );
  }


  // Your existing helper methods...

  Widget _buildPage({required Widget child}) {
    return Container(
      padding: EdgeInsets.all(20.0),
      child: child,
    );
  }



  bool validatePhone(String text) {
    // Regex pattern for phone number validation
    // This pattern assumes a phone number with the format +16474724580
    String phonePattern = r'^\+[1-9]\d{10}$'; // Assuming a 10-digit phone number after the country code
    RegExp regExp = RegExp(phonePattern);
    return regExp.hasMatch(text);
  }




}

void main() {
  runApp(MaterialApp(
    home: MultiStepRegistrationScreen(),
  ));
}


