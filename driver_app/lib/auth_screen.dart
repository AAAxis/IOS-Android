import 'package:driver_app/home_screen.dart';
import 'package:driver_app/order_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddDriverForm extends StatefulWidget {
  @override
  _AddDriverFormState createState() => _AddDriverFormState();
}

class _AddDriverFormState extends State<AddDriverForm> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  int _currentStep = 0;

  String? serverGeneratedPassword; // Store the server-generated password

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter an email address.';
    }
    final emailRegExp = RegExp(r'^[\w-]+(\.[\w-]+)*@[\w-]+(\.[\w-]+)+$');
    if (!emailRegExp.hasMatch(value)) {
      return 'Invalid email format.';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a phone number.';
    }
    final phoneRegExp = RegExp(r'^\+\d{1,4}[0-9]{6,}$');
    if (!phoneRegExp.hasMatch(value)) {
      return 'Invalid phone number format. (e.g., +16474724580)';
    }
    return null;
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your name.';
    }
    return null;
  }

  Future<void> _sendRequest() async {
    final url = Uri.parse('https://polskoydm.pythonanywhere.com/adddriver');
    print('Sending request to: $url'); // Print the URL before sending the request

    final Map<String, dynamic> requestData = {
      'name': _nameController.text,
      'email': _emailController.text,
      'phone': _phoneController.text,
    };

    final headers = {
      'Content-Type': 'application/json',
    };

    print('Request Body: $requestData');

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(requestData),
    );

    // Print response details
    print('Response Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');

    if (response.statusCode == 200) {
      // Request successful, you can handle the response if needed
      final data = jsonDecode(response.body);
      final message = data['message'];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );

      // Store the server-generated password
      serverGeneratedPassword = data['password'];
    } else {
      // Request failed, show an error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Request failed. Please try again later.'),
        ),
      );
    }
  }

  Future<void> _sendPasswordToBackend(BuildContext context) async {
    final url = Uri.parse('https://polskoydm.pythonanywhere.com/checkpassword');
    print('Sending password to: $url'); // Print the URL before sending the request

    final Map<String, dynamic> requestData = {
      'password': _passwordController.text,
    };

    final headers = {
      'Content-Type': 'application/json',
    };

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(requestData),
    );

    // Print response details
    print('Response Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final isPasswordCorrect = data['isPasswordCorrect'];

      if (isPasswordCorrect == true) {
        // Password is correct, proceed to the next step or screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserDataDisplayScreen(
              name: _nameController.text,
              email: _emailController.text,
              phone: _phoneController.text,
              context: context, // Pass the context here
            ),
          ),
        );
      } else {
        // Password is incorrect, show an error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Incorrect password. Please try again.'),
          ),
        );
      }
    } else {
      // Request failed, show an error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Request failed. Please try again later.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Driver'),
      ),
      body: Stepper(
        currentStep: _currentStep,
        onStepTapped: (step) {
          setState(() {
            _currentStep = step;
          });
        },
        onStepContinue: () async {
          bool isValid = true;

          if (_currentStep == 0) {
            final phoneValidation = _validatePhone(_phoneController.text);
            final nameValidation = _validateName(_nameController.text);

            if (phoneValidation != null || nameValidation != null) {
              isValid = false;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    phoneValidation ?? nameValidation ?? 'Validation error',
                  ),
                ),
              );
            }
          } else if (_currentStep == 1) {
            _sendRequest();
            final emailValidation = _validateEmail(_emailController.text);
            if (emailValidation != null) {
              isValid = false;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(emailValidation),
                ),
              );
            }
          } else if (_currentStep == 2) {
            if (_passwordController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Enter Password"),
                ),
              );
            } else {
              // Password validation succeeded, send the password to the backend
              _sendPasswordToBackend(context); // Pass the context here
            }
          }

          if (isValid) {
            setState(() {
              if (_currentStep < 2) {
                _currentStep++; // Move to the next step
              }
            });
          }
        },
        steps: [
          Step(
            title: Text('Step 1: Phone and Name'),
            content: Column(
              children: [
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(labelText: 'Phone'),
                  validator: _validatePhone,
                ),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: 'Name'),
                  validator: _validateName,
                ),
              ],
            ),
            isActive: _currentStep == 0,
          ),
          Step(
            title: Text('Step 2: Email Verification'),
            content: Column(
              children: [
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(labelText: 'Email'),
                  validator: _validateEmail,
                ),
              ],
            ),
            isActive: _currentStep == 1,
          ),
          Step(
            title: Text('Step 3: Password'),
            content: Column(
              children: [
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(labelText: 'Password'),
                  obscureText: true,
                ),
              ],
            ),
            isActive: _currentStep == 2,
          ),
        ],
      ),
    );
  }
}

class UserDataDisplayScreen extends StatelessWidget {
  final String name;
  final String email;
  final String phone;
  final BuildContext context; // Store the context

  UserDataDisplayScreen({
    required this.name,
    required this.email,
    required this.phone,
    required this.context, // Initialize the context in the constructor
  });

  void applyNow() async {
    // TODO: Replace with your actual backend API endpoint
    final apiUrl = 'https://polskoydm.pythonanywhere.com/driver_apply';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: {
          'name': name,
          'email': email,
          'phone': phone,
        },
      );

      if (response.statusCode == 200) {
        // Successful API request, handle the response as needed
        print('Application submitted successfully');
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MyHomePage()),
        );
      } else {
        // Handle errors, e.g., show an error message to the user
        print('Failed to submit application: ${response.statusCode}');
      }
    } catch (e) {
      // Handle network or other exceptions
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Data Display'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset('images/doc.png'), // Add your image here
            SizedBox(height: 20),
            Text(
              'Hello $name',
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 20),
            Text(
              'We are happy to see you apply for the Driver position at Wheels Delivery.',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),
            Text(
              'Your request will take 24 hours to be processed.',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),
            Text(
              'Email: $email',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 10),
            Text(
              'Phone: $phone',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: applyNow, // Call the applyNow function
              child: Text('Apply Now'),
            ),
          ],
        ),
      ),
    );
  }
}

void main() => runApp(MaterialApp(
  home: AddDriverForm(),
));
