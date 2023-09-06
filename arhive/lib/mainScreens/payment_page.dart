import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:order_app/mainScreens/home_screen.dart';
import '../authentication/auth_screen.dart';
import '../global/global.dart';

class PaymentPage extends StatefulWidget {
  final String orderId;
  final List<Map<String, dynamic>> cartItems;
  final double total;

  PaymentPage({
    required this.orderId,
    required this.cartItems,
    required this.total,
  });

  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  bool hasAddress = false;

  Future<void> _displayUserInfo(BuildContext context) async {
    final TextEditingController addressController = TextEditingController();

    final name = sharedPreferences!.getString("name") ?? "No Name";
    final email = sharedPreferences!.getString("email") ?? "No Email";
    final address = sharedPreferences!.getString("address") ?? "No Address";

    addressController.text = address; // Set the initial value of the address

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('User Information'),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Name: $name'),
              TextField(
                controller: addressController,
                decoration: InputDecoration(labelText: 'Address'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final updatedAddress = addressController.text;

                // Send the updated address, email, and name to your API
                final requestData = {
                  'address': updatedAddress,
                  'email': email,
                  'name': name,
                };

                final apiUrl = 'https://polskoydm.pythonanywhere.com/payment/${widget
                    .orderId}';
                final response = await http.post(
                  Uri.parse(apiUrl),
                  headers: {'Content-Type': 'application/json'},
                  body: json.encode(requestData),
                );

                // Print what you send
                print('Sending request to: $apiUrl');
                print('Sending request data: $requestData');

                if (response.statusCode == 200) {
                  Navigator.of(context).pop();
                  setState(() {
                    hasAddress = true;
                  });
                } else {
                  // Print error message if response indicates an error
                  final responseData = json.decode(response.body);
                  final String errorMessage = responseData['error_message'];
                  print('Error message: $errorMessage');
                }
              },
              child: Text('OK'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isUserAuthenticated = firebaseAuth.currentUser != null;

    return Scaffold(
      appBar: AppBar(
        title: Text('Payment'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: widget.cartItems.length,
              itemBuilder: (context, index) {
                final cartItem = widget.cartItems[index];
                return ListTile(
                  title: Text(cartItem['name']),
                  subtitle: Text('Quantity: ${cartItem['quantity']}'),
                  trailing: Text(
                      '\$${cartItem['price'] * cartItem['quantity']}'),
                );
              },
            ),
          ),
          SizedBox(height: 20),
          Container(
            alignment: Alignment.center,
            child: SizedBox(
              width: 100, // Set a fixed width for the button
              child: RawMaterialButton(
                onPressed: isUserAuthenticated
                    ? hasAddress
                    ? null
                    : () => _displayUserInfo(context)
                    : () {
                  // Navigate to the login screen when the user is not authenticated
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          AuthScreen(), // Replace with your login screen
                    ),
                  );
                },
                fillColor: Colors.red, // Set button color to red
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                      20), // Set rounded corners
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    isUserAuthenticated ? 'Add Address' : 'Login',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14, // Adjust font size
                      color: Colors.white, // Set text color to white
                    ),
                  ),
                ),
              ),
            ),
          ),
          Divider(),
          ListTile(
            title: Text('Total'),
            trailing: Text('\$${widget.total.toStringAsFixed(2)}'),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: hasAddress
                ? () async {
              final url =
                  'https://polskoydm.pythonanywhere.com/create-checkout-session/${widget
                  .orderId}';
              if (await canLaunch(url)) {
                // Launch the URL
                await launch(url);

                // After the link is closed, navigate to a different page
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        HomeScreen(), // Replace with the desired page
                  ),
                );
              } else {
                // Handle the case where the URL can't be launched.
                print('Could not launch $url');
              }
            }
                : null,
            child: Text('Proceed to Payment'),
          ),
        ],
      ),
    );
  }
}