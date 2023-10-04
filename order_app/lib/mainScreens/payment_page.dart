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
  TextEditingController addressController = TextEditingController();

  Future<void> _displayUserInfo(BuildContext context) async {
    final name = sharedPreferences!.getString("name") ?? "No Name";
    final email = sharedPreferences!.getString("email") ?? "No Email";
    final address = sharedPreferences!.getString("address") ?? "";

    setState(() {
      addressController.text = address; // Set the initial value of the address
    });

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

                final apiUrl =
                    'https://polskoydm.pythonanywhere.com/payment/${widget
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

  void _clearCart(BuildContext context) {
    setState(() {
      widget.cartItems.clear();
      // You can also reset the total or perform any other necessary actions here.
    });
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => HomeScreen(),
      ),
    );
  }

  bool isUserAuthenticated() {
    return firebaseAuth.currentUser != null;
  }

  // ...

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
          Image.network(
            'https://polskoydm.pythonanywhere.com/static/images/map.png',
            height: 250,
            fit: BoxFit.cover,
          ),
          // Always display the address section
          InkWell(
            onTap: () => _displayUserInfo(context),
            child: Container(
              color: Colors.yellow[200],
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.home),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      sharedPreferences!.getString("address") ?? "No Address",
                      style: TextStyle(
                        fontSize: 18,
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Icon(Icons.edit),
                ],
              ),
            ),
          ),

          // Display cart items
          Expanded(
            child: ListView.builder(
              itemCount: widget.cartItems.length,
              itemBuilder: (context, index) {
                final cartItem = widget.cartItems[index];
                return ListTile(
                  title: Text(cartItem['name']),
                  subtitle: Text('Quantity: ${cartItem['quantity']}'),
                  trailing: Text('\$${cartItem['price'] * cartItem['quantity']}'),
                );
              },
            ),
          ),

          // Clear cart button
          Align(
            alignment: Alignment.center,
            child: ElevatedButton(
              onPressed: () => _clearCart(context),
              style: ElevatedButton.styleFrom(
                primary: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.clear, size: 18),
                  SizedBox(width: 5),
                  Text(
                    'Clear Cart',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),

          Divider(),

          // Display total
          ListTile(
            title: Text('Total'),
            trailing: Text('\$${widget.total.toStringAsFixed(2)}'),
          ),
          SizedBox(height: 20),

          // Conditionally display the "Proceed to Payment" button
          isUserAuthenticated
              ? Container(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: hasAddress
                  ? () async {
                final url =
                    'https://polskoydm.pythonanywhere.com/create-checkout-session/${widget.orderId}';
                if (await canLaunch(url)) {
                  await launch(url);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HomeScreen(),
                    ),
                  );
                } else {
                  print('Could not launch $url');
                }
              }
                  : null,
              style: ElevatedButton.styleFrom(
                primary: Colors.black,
                shape: RoundedRectangleBorder(),
                fixedSize: Size.fromHeight(60), // Set button height
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 15),
                child: Text(
                  'Proceed to Payment',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 25,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          )
              : SizedBox(), // Hide the button if the user is not logged in
        ],
      ),
      bottomNavigationBar: isUserAuthenticated
          ? null
          : Container(
        padding: EdgeInsets.all(16),
        color: Colors.black,
        child: ElevatedButton(
          onPressed: () async {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => MergedLoginScreen()),
            );
          },
          style: ElevatedButton.styleFrom(
            primary: Colors.black, // Make the button black
            shape: RoundedRectangleBorder(),
            fixedSize: Size.fromHeight(60), // Set button height
          ),
          child: Text('Login'),
        ),
      ),
    );
  }

}