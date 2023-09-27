import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'home_page.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController codeController = TextEditingController();

  bool isCodeFieldVisible = false;
  String emailMessage = '';
  String codeErrorMessage = '';

  Future<void> _storeEmail(String email) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_email', email);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: phoneController,
              decoration: InputDecoration(
                labelText: 'Mobile Number',
              ),
            ),
            SizedBox(height: 16.0),
            Visibility(
              visible: isCodeFieldVisible,
              child: TextField(
                controller: codeController,
                obscureText: true, // Set this property to true
                decoration: InputDecoration(
                  labelText: 'Code',
                  errorText: codeErrorMessage,
                ),
              ),
            ),

            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () async {
                if (isCodeFieldVisible) {
                  final String code = codeController.text.trim();

                  if (code.isNotEmpty) {
                    final Uri checkPasswordUrl = Uri.parse('https://polskoydm.pythonanywhere.com/checkpassword');
                    final Map<String, dynamic> requestBody = {
                      'password': code,
                    };

                    final checkPasswordResponse = await http.post(
                      checkPasswordUrl,
                      body: json.encode(requestBody),
                      headers: {'Content-Type': 'application/json'},
                    );

                    if (checkPasswordResponse.statusCode == 200) {
                      final Map<String, dynamic> checkPasswordJsonResponse =
                      json.decode(checkPasswordResponse.body);
                      final bool isPasswordCorrect = checkPasswordJsonResponse['isPasswordCorrect'];

                      if (isPasswordCorrect) {
                        // Store the email in SharedPreferences
                        await _storeEmail(emailMessage);

                        // Navigate to the HomePage
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HomePage(),
                          ),
                        );
                      } else {
                        setState(() {
                          codeErrorMessage = 'Invalid code entered.';
                        });
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('An error occurred while checking the code.'),
                        ),
                      );
                    }
                  } else {
                    setState(() {
                      codeErrorMessage = 'Please enter a valid code.';
                    });
                  }
                } else {
                  final String phone = phoneController.text.trim();

                  if (isValidPhone(phone)) {
                    final encodedPhone = Uri.encodeComponent(phone);
                    final Uri url = Uri.parse(
                        'https://polskoydm.pythonanywhere.com/login_driver?mobile=$encodedPhone');

                    try {
                      final response = await http.get(url);

                      if (response.statusCode == 200) {
                        final Map<String, dynamic> jsonResponse =
                        json.decode(response.body);
                        final String email = jsonResponse['email'];

                        setState(() {
                          isCodeFieldVisible = true;
                          emailMessage = email; // Store email from the first response
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('We sent your code to $email'),
                          ),
                        );
                      } else {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: Text('API Error'),
                              content: Text('An error occurred while sending the request.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text('OK'),
                                ),
                              ],
                            );
                          },
                        );
                      }
                    } catch (e) {
                      print('Exception: $e');
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: Text('Network Error'),
                            content: Text('An error occurred while making the request.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text('OK'),
                              ),
                            ],
                          );
                        },
                      );
                    }
                  } else {
                    setState(() {
                      codeErrorMessage = 'Please enter a valid code.';
                    });
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                primary: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(isCodeFieldVisible ? 'Submit Code' : 'Continue with phone'),
            ),
            SizedBox(height: 16.0),
          ],
        ),
      ),
    );
  }

  bool isValidPhone(String phone) {
    final RegExp phoneRegExp = RegExp(
      r'^\+(?:[0-9] ?){6,14}[0-9]$',
      caseSensitive: false,
      multiLine: false,
    );

    return phoneRegExp.hasMatch(phone);
  }
}

void main() {
  runApp(MaterialApp(
    home: LoginPage(),
  ));
}
