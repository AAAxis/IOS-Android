import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart'; // Import the FirebaseAuth class


class Order {
  final dynamic id; // Change the type to dynamic
  final double total;
  final String address;
  final String email;
  final String name;
  final List<dynamic> cart;
  final String status;

  Order({
    required this.id,
    required this.total,
    required this.address,
    required this.email,
    required this.name,
    required this.cart,
    required this.status,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'], // Keep the 'id' field as it is
      total: json['total'],
      address: json['address'],
      email: json['email'],
      name: json['name'],
      cart: json['cart'],
      status: json['status'],
    );
  }
}



class OrderHistoryPage extends StatefulWidget {

  @override
  _OrderHistoryPageState createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  final String userEmail =
      FirebaseAuth.instance.currentUser?.email ?? "No Email"; // Get the user's email

  Future<List<Order>> fetchOrderHistory() async {
    final response = await http.get(
      Uri.parse('https://polskoydm.pythonanywhere.com/history?email=${userEmail}'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> responseData = json.decode(response.body);
      return responseData.map((orderData) => Order.fromJson(orderData)).toList();
    } else {
      throw Exception('Failed to load order history');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order History'),
      ),
      body: FutureBuilder<List<Order>>(
        future: fetchOrderHistory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No order history available.'));
          } else {
            final orders = snapshot.data!;
            return ListView.builder(
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return ListTile(
                  title: Text('Order ID: ${order.id.toString()}'),
                  subtitle: Text('Total: \$${order.total.toStringAsFixed(2)}'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OrderDetailsPage(order: order),
                      ),
                    );
                  },
                );
              },
            );
          }
        },
      ),
    );
  }
}

class OrderDetailsPage extends StatelessWidget {
  final Order order;

  OrderDetailsPage({required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order Details'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Order ID: ${order.id}'),
          Text('Total: \$${order.total.toStringAsFixed(2)}'),
          // Display more order details here
        ],
      ),
    );
  }
}
