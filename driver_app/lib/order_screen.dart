import 'dart:convert';
import 'package:driver_app/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:maps_launcher/maps_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import the SharedPreferences package

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Your App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: OrdersScreen(),
    );
  }
}

class OrdersScreen extends StatefulWidget {
  @override
  _OrderScreenState createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrdersScreen> {
  List<Order> orders = [];

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    final apiUrl = 'https://polskoydm.pythonanywhere.com/assigned';
    print('Fetching orders from API: $apiUrl');

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<Order> fetchedOrders = (data as List)
            .map((orderData) => Order.fromJson(orderData))
            .toList();

        setState(() {
          orders = fetchedOrders;
        });
      } else {
        throw Exception('Failed to load order data');
      }
    } catch (e) {
      print('Error fetching data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order Details'),
      ),
      body: ListView.builder(
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return OrderCard(order: order);
        },
      ),
    );
  }
}

class OrderCard extends StatefulWidget {
  final Order order;

  OrderCard({required this.order});

  @override
  _OrderCardState createState() => _OrderCardState();
}

class _OrderCardState extends State<OrderCard> {
  bool isExpanded = false;
  bool isPickedUp = false;
  bool isCompleted = false; // Initialize as false


  void _handlePickUp() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Order Details'),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('ID: ${widget.order.id}'),

              // Display order items
              for (var item in widget.order.cart)
                Text('${item['name']} - ${item['quantity']} x \$${item['price']}'),
              SizedBox(height: 10.0),

              Text('Are you sure you want to mark this order as picked up?'),
              SizedBox(height: 10.0),

            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Confirm'),
              onPressed: () async {
                // Send a GET request to mark the order as picked up
                try {
                  final response = await http.get(
                    Uri.parse(
                        'https://polskoydm.pythonanywhere.com/orderpickup/${widget.order.id}'),
                  );

                  print('API Response: ${response.body}'); // Print the response

                  if (response.statusCode == 200) {
                    // The request was successful, and the order has been marked as picked up
                    // You can update the UI accordingly

                    // Close the dialog
                    Navigator.of(context).pop();

                    // Update the UI or perform any other necessary actions
                    setState(() {
                      isPickedUp = true;
                    });
                  } else {
                    // Handle the case where the request was not successful
                    // You can display an error message or take appropriate action
                    print(
                        'Failed to mark the order as picked up. Status code: ${response.statusCode}');

                    // Close the dialog
                    Navigator.of(context).pop();
                  }
                } catch (e) {
                  // Handle any exceptions that occur during the request
                  print('Error marking the order as picked up: $e');

                  // Close the loading indicator
                  Navigator.of(context).pop();

                  // Close the dialog
                  Navigator.of(context).pop();
                }
              },
            ),

          ],
        );
      },
    );
  }

  void _showStoreOnMap() {
    // Use the Maps Launcher package to open the store location on a map.
    MapsLauncher.launchQuery(widget.order.start_point);
  }

  void _showUserOnMap() {
    // Use the Maps Launcher package to open the store location on a map.
    MapsLauncher.launchQuery(widget.order.address);
  }

  void _showCompletedDialog() async {
    // Retrieve the user's email from SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userEmail = prefs.getString("user_email") ?? ""; // Provide a default value if the email is not found

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmation'),
          content: Text('Are you sure you want to mark this order as Completed?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Confirm'),
              onPressed: () async {
                // Make an API request to mark the order as done
                final response = await http.get(
                  Uri.parse('https://polskoydm.pythonanywhere.com/orderdone/${widget.order.id}?email=$userEmail'), // Include email as a query parameter
                );

                if (response.statusCode == 200) {
                  // Order marked as done successfully
                  // Navigate to the home screen
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (BuildContext context) => MyHomePage()),
                  );
                } else {
                  // Handle the error if the API request fails
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4.0,
      margin: EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: ClipOval(
              child: Image.network(
                'https://polskoydm.pythonanywhere.com/static/images/chat.jpg',
                width: 50,
                height: 50,
                fit: BoxFit.cover,
              ),
            ),
            title: Text(
              '${widget.order.name}',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: InkWell(
              onTap: () {
                setState(() {
                  isExpanded = !isExpanded;
                });
              },
              child: Row(
                children: [
                  Text(
                    '25 min Delivery',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 4.0),

                ],
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isPickedUp && !isCompleted)
                  Text(
                    'Assigned',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                if (isPickedUp && !isCompleted)
                  Text(
                    'Picked Up',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                if (isCompleted)
                  Text(
                    'Completed',
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                SizedBox(width: 15.0),
                Icon(
                  Icons.link,
                ),
              ],
            ),
          ),

          // Show different UI based on the order status
          if (!isCompleted)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isPickedUp)
                  Row(
                    children: [
                      Container(
                        margin: EdgeInsets.all(10.0),
                        child: ElevatedButton(
                          onPressed: () {
                            _handlePickUp();
                          },
                          style: ElevatedButton.styleFrom(
                            primary: Colors.blue,
                          ),
                          child: Text('Pick Up'),
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.all(10.0),
                        child: ElevatedButton(
                          onPressed: () {
                            _showStoreOnMap();
                          },
                          style: ElevatedButton.styleFrom(
                            primary: Colors.black, // Change the color to black
                          ),
                          child: Text('Location'),
                        ),
                      ),
                    ],
                  ),

                if (isPickedUp && !isCompleted)
                  Row(
                    children: [
                      Container(
                        margin: EdgeInsets.all(10.0),
                        child: ElevatedButton(
                          onPressed: () {
                            _showCompletedDialog();
                          },
                          style: ElevatedButton.styleFrom(
                            primary: Colors.green,
                          ),
                          child: Text('Complete'),
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.all(10.0),
                        child:
                        ElevatedButton(
                          onPressed: () async {
                            Navigator.of(context).pop();
                            _showUserOnMap();
                          },
                          child: Text('Show Destination'),
                        ),
                      )
                    ],
                  ),

              ],
            ),

        ],
      ),
    );
  }
}


class Order {
  final String id;
  final double total;
  final String address;
  final String email;
  final String name;
  final List<Map<String, dynamic>> cart;
  final String status;
  final String store_name;
  final String start_point;

  Order({
    required this.id,
    required this.total,
    required this.address,
    required this.email,
    required this.name,
    required this.cart,
    this.status = 'pending',
    required this.store_name,
    required this.start_point,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      total: json['total'],
      address: json['address'],
      email: json['email'],
      name: json['name'],
      cart: List<Map<String, dynamic>>.from(json['cart']),
      status: json['status'],
      store_name: json['store_name'],
      start_point: json['start_point'],
    );
  }
}
