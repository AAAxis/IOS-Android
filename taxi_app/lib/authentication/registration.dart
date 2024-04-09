
import 'dart:convert';

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
  TextEditingController _emailController = TextEditingController();
  TextEditingController _nameController = TextEditingController();
  TextEditingController _phoneController = TextEditingController();
  TextEditingController codeController = TextEditingController();
  String? _selectedEmploymentType;
  String? _selectedAccountType;
  bool _interestedInRental = false;
  String? _selectedCity = "Tel Aviv";
  String? _selectedScheduleType;
  List<String> _selectedProviders = [];
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
    final interestedInRental = _interestedInRental;
    final scheduleType = _selectedScheduleType;
    final providers = _selectedProviders;

    final data = {
      'email': email,
      'name': name,
      'phone': phone,
      'employmentType': employmentType,
      'city': city,
      'accountType': accountType,
      'interestedInRental': interestedInRental,
      'scheduleType': scheduleType,
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
        title: Text('Multi-Step Registration'),
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
    return _buildPage(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          TextField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email), // Add email icon
            ),
          ),
          SizedBox(height: 20.0),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Full Name',
              prefixIcon: Icon(Icons.person), // Add person icon
            ),
          ),
          SizedBox(height: 20.0),
          TextField(
            controller: _phoneController,
            decoration: InputDecoration(
              labelText: 'Phone',
              prefixIcon: Icon(Icons.phone), // Add phone icon
            ),
          ),
          SizedBox(height: 20.0),

          ElevatedButton(
            onPressed: () {
              if (_emailController.text.isEmpty ||
                  _nameController.text.isEmpty ||
                  _phoneController.text.isEmpty ||
                  !validateEmail(_emailController.text) ||
                  !validatePhone(_phoneController.text)) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Please fill all fields correctly.'),
                ));
              } else {
                _pageController.nextPage(
                  duration: Duration(milliseconds: 300),
                  curve: Curves.ease,
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
          Row(
            children: [
              Checkbox(
                value: _interestedInRental,
                onChanged: (bool? value) {
                  setState(() {
                    _interestedInRental = value!;
                  });
                },
              ),
              Text('I am interested in rental motorcycle'),
            ],
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
    return _selectedScheduleType != null && _selectedProviders.isNotEmpty;
  }

  Widget _buildFourthPage() {
    return _buildPage(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            'Schedule Type',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Radio(
                value: 'Full Time',
                groupValue: _selectedScheduleType,
                onChanged: (value) {
                  setState(() {
                    _selectedScheduleType = value.toString();
                  });
                },
              ),
              Text('Full Time'),
              SizedBox(width: 20),
              Radio(
                value: 'Part Time',
                groupValue: _selectedScheduleType,
                onChanged: (value) {
                  setState(() {
                    _selectedScheduleType = value.toString();
                  });
                },
              ),
              Text('Part Time'),
            ],
          ),
          SizedBox(height: 20),
          Card(
            child: ListTile(
              leading: Icon(Icons.hardware),
              title: Text('Full Time'),
              subtitle:
              Text('40 hours a week, Not Limited'),
            ),
          ),
          SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: Icon(Icons.lightbulb_outline),
              title: Text('Part Time'),
              subtitle: Text('20 hours a week, flexible'),
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Select Provider',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),

          CheckboxListTile(
            title: Text('TenBis'),
            value: _selectedProviders.contains('TenBis'),
            onChanged: (value) {
              setState(() {
                if (value!) {
                  _selectedProviders.add('TenBis');
                } else {
                  _selectedProviders.remove('TenBis');
                }
              });
            },
          ),

          CheckboxListTile(
            title: Text('Yango Deli'),
            value: _selectedProviders.contains('Yango Deli'),
            onChanged: (value) {
              setState(() {
                if (value!) {
                  _selectedProviders.add('Yango Deli');
                } else {
                  _selectedProviders.remove('Yango Deli');
                }
              });
            },
          ),
          CheckboxListTile(
            title: Text('Japanika'),
            value: _selectedProviders.contains('Japanika'),
            onChanged: (value) {
              setState(() {
                if (value!) {
                  _selectedProviders.add('Japanika');
                } else {
                  _selectedProviders.remove('Japanika');
                }
              });
            },
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isSelectionMade()
                ? () {
              sendSMS();
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
              labelText: 'Enter 4-digit Code',
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
                  sendEmail(); // Call the sendEmail function when the button is pressed
                },
                child: Text(
                  'Email',
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






  bool validateEmail(String text) {

    // Regex pattern for email validation
    // This pattern is a simple one and may not cover all cases.
    // For more accurate validation, consider using a more comprehensive pattern.
    String emailPattern = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
    RegExp regExp = RegExp(emailPattern);
    return regExp.hasMatch(text);
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


