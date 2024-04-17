
import 'dart:convert';
import 'package:taxi_app/global/global.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxi_app/mainScreens/home_screen.dart';
import 'package:taxi_app/mainScreens/navigation.dart';

import '../global/global.dart';
import '../widgets/error_dialog.dart';

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
  TextEditingController codeController = TextEditingController();
  String? _selectedEmploymentType;
  String? _selectedAccountType;

  String? _selectedCity = "Tel Aviv";
  String? _selectedProviders;

  int _currentPage = 0;
  bool _isEmailSent = false;
  String? verificationCode;


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
    final accountType = _selectedAccountType;
    final providers = _selectedProviders;

    final data = {
      'email': email,
      'name': name,
      'phone': phone,
      'employmentType': employmentType,
      'city': city,
      'accountType': accountType,
      'providers': providers,
    };

    try {
      final response = await http.post(
        Uri.parse('https://polskoydm.pythonanywhere.com/generate-pdf-and-send-email'),
        body: json.encode(data),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        // Handle success

        // Update status to "approved" in Firebase
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final userDocRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
          await userDocRef.update({'status': 'approved'});
        }

        // Update shared preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('status', 'approved');
      } else {
        // Handle failure
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> sendSMS() async {
    final phone = _phoneController.text.trim();

    final response = await http.get(
      Uri.parse(
          'https://polskoydm.pythonanywhere.com/global_sms?phone=$phone'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _isEmailSent = true;
        verificationCode = data['verification_code'];
      });
    }

  }


  Future<void> sendEmail() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Invalid Email'),
            content: Text('Please enter a valid email address.'),
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

    try {
      final response = await http.get(
        Uri.parse(
            'https://polskoydm.pythonanywhere.com/global_auth?email=$email'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _isEmailSent = true;
          verificationCode = data['verification_code'];
        });
      } else {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('Failed to Send Email'),
              content: Text('Unable to send email. Please try again later.'),
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
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('An error occurred while sending the email: $e'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Multi-Step Application'),
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
          _buildThirdPage(),
          _buildFourthPage(),
          _buildSMSVerificationPage(), // Add SMS verification page

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
              prefixIcon: Icon(Icons.person), // Add person icon
            ),
          ),
          SizedBox(height: 20.0),
          TextField(
            controller: _phoneController,
            onTap: () {
              _phoneController.clear(); // Clear the text field when tapped
            },
            decoration: InputDecoration(
              labelText: 'Phone',
              prefixIcon: Icon(Icons.phone), // Add phone icon
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
                SizedBox(width: 10), // Adjust spacing between the label and the DropdownButton if needed
                DropdownButton<String>(
                  value: _selectedCity,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedCity = newValue!;
                    });
                  },
                  items: [
                    'Haifa',
                    'Tel Aviv', // Default value set to "Tel Aviv"
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
                final user =
                    FirebaseAuth.instance.currentUser;
                if (user != null) {
                  final userDocRef = FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid);
                  await userDocRef.update({'phone': newPhone});
                  updatePhone(newPhone);
                  await userDocRef.update({'name': newName});
                  updateName(newName);
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
                value: 'Contractor',
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
                value: 'Self-employed',
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
            onPressed: _isSelectionMade2 ? () {
              // Proceed to the next step
              _pageController.nextPage(
                duration: Duration(milliseconds: 300),
                curve: Curves.ease,
              );
            } : null, // Disable button if selection is not made
            child: Text('Next'),
          ),
        ],
      ),
    );
  }

  bool isSelectionMade3 = false; // Track whether a selection is made

  Widget _buildThirdPage() {

    return _buildPage(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            'Account Type',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Radio(
                value: 'Car',
                groupValue: _selectedAccountType,
                onChanged: (value) {
                  setState(() {
                    _selectedAccountType = value.toString();
                    isSelectionMade3 = true; // Enable the button
                  });
                },
              ),
              Text('Car'),
              SizedBox(width: 20),
              Radio(
                value: 'Motorcycle',
                groupValue: _selectedAccountType,
                onChanged: (value) {
                  setState(() {
                    _selectedAccountType = value.toString();
                    isSelectionMade3 = true; // Enable the button
                  });
                },
              ),
              Text('Motorcycle'),
              SizedBox(width: 20),
              Radio(
                value: 'Bike',
                groupValue: _selectedAccountType,
                onChanged: (value) {
                  setState(() {
                    _selectedAccountType = value.toString();
                    isSelectionMade3 = true; // Enable the button
                  });
                },
              ),
              Text('Bike'),
            ],
          ),
          SizedBox(height: 20),
          Card(
            child: ListTile(
              leading: Icon(Icons.directions_car),
              title: Text('Car'),
              subtitle: Text('Choose this option if you want to register a car account.'),
            ),
          ),
          SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: Icon(Icons.motorcycle),
              title: Text('Motorcycle'),
              subtitle: Text('Choose this option if you want to register a motorcycle account.'),
            ),
          ),
          SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: Icon(Icons.directions_bike),
              title: Text('Bike'),
              subtitle: Text('Choose this option if you want to register a bike account.'),
            ),
          ),
          SizedBox(height: 20),

          ElevatedButton(
            onPressed: isSelectionMade3
                ? () {
              // Proceed to the next step
              _pageController.nextPage(
                duration: Duration(milliseconds: 300),
                curve: Curves.ease,
              );
            }
                : null, // Disable the button if no selection is made
            child: Text('Next'),
          ),
        ],
      ),
    );
  }


  bool _isSelectionMade() {
    return _selectedProviders != null;
  }

  Widget _buildFourthPage() {
    return _buildPage(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            'Select Service',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Radio(
                value: 'Ten Bis',
                groupValue: _selectedProviders,
                onChanged: (value) {
                  setState(() {
                    _selectedProviders = value.toString();
                  });
                },
              ),
              Text('Ten Bis'),
              SizedBox(width: 20),
              Radio(
                value: 'Yango Deli',
                groupValue: _selectedProviders,
                onChanged: (value) {
                  setState(() {
                    _selectedProviders = value.toString();
                  });
                },
              ),
              Text('Yango'),
              SizedBox(width: 20),
              Radio(
                value: 'Japanika',
                groupValue: _selectedProviders,
                onChanged: (value) {
                  setState(() {
                    _selectedProviders = value.toString();
                  });
                },
              ),
              Text('Japanika'),
            ],
          ),
          SizedBox(height: 20),
          Card(
            child: ListTile(
              leading: Icon(Icons.hardware),
              title: Text('Yango'),
              subtitle:
              Text('40 hours a week, Not Limited'),
            ),
          ),
          SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: Icon(Icons.lightbulb_outline),
              title: Text('Japanika'),
              subtitle: Text('20 hours a week, flexible'),
            ),
          ),

          SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: Icon(Icons.lightbulb_outline),
              title: Text('Ten Bis'),
              subtitle: Text('20 hours a week, flexible'),
            ),
          ),


          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isSelectionMade()
                ? () {
              sendEmail();
              // Proceed to the next step or perform any action
              _pageController.nextPage(
                duration: Duration(milliseconds: 300),
                curve: Curves.ease,
              );
            }
                : null, // Disable the button if no selection is made
            child: Text('Next'),
          ),

        ],
      ),
    );
  }

  Widget _buildSMSVerificationPage() {
    return _buildPage(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            'We sent a verification code to your phone',
            style: TextStyle(fontWeight: FontWeight.normal),
          ),
          Image.asset(
            "images/promotion.png", // Replace 'sms_verification_image.png' with your image asset
            height: 220,
            width: 250,
          ),
// Inside your build method or wherever appropriate, use the TextField widget
          TextField(
            controller: codeController, // Assign the controller here
            decoration: InputDecoration(
              labelText: 'Enter 6-digit Code',
            ),
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Text(
                'Resend verification code via ',
                style: TextStyle(
                  fontWeight: FontWeight.normal,
                ),
              ),
              TextButton(
                onPressed: () {
                  sendSMS(); // Call the sendEmail function when the button is pressed
                },
                child: Text(
                  'SMS',
                  style: TextStyle(
                    fontWeight: FontWeight.normal,
                    color: Colors.blue,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton(
                onPressed: () {
                  _sendRegistrationData();
                  // Implement logic to verify the entered code
                  Navigator.pop(context);
                  Navigator.push(
                      context, MaterialPageRoute(builder: (c) => Navigation()));

                },
                child: Text('Submit'),
              ),
            ],
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


