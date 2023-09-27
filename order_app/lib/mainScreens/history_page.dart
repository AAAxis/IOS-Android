import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:maps_launcher/maps_launcher.dart';

class Order {
  final dynamic id;
  final double total;
  final String address;
  final String email;
  final String storeId;
  final String name;
  final List<dynamic> cart;
  final String status;

  Order({
    required this.id,
    required this.total,
    required this.storeId,
    required this.address,
    required this.email,
    required this.name,
    required this.cart,
    required this.status,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      total: json['total'].toDouble(),
      address: json['address'],
      storeId: json['store_id'].toString(),
      email: json['email'],
      name: json['name'],
      cart: json['cart'],
      status: json['status'],
    );
  }
}

class Store {
  final String name;
  final String email;
  final String file;
  final String address;
  final String token;

  Store({
    required this.name,
    required this.email,
    required this.file,
    required this.address,
    required this.token,
  });

  factory Store.fromJson(Map<String, dynamic> json) {
    return Store(
      name: json['name'],
      email: json['email'],
      file: json['file'],
      address: json['address'],
      token: json['token'],
    );
  }
}

class OrderHistoryPage extends StatefulWidget {
  @override
  _OrderHistoryPageState createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  String? userEmail;

  @override
  void initState() {
    super.initState();
    final currentUser = FirebaseAuth.instance.currentUser;
    userEmail = currentUser?.email ?? "No Email";
  }

  Future<List<Order>> fetchOrderHistory() async {
    final apiUrl = 'https://polskoydm.pythonanywhere.com/history?email=${userEmail}';
    print('Fetching order history from API: $apiUrl');

    final response = await http.get(Uri.parse(apiUrl));

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
            return OrderSlider(orders: orders);
          }
        },
      ),
    );
  }
}

class OrderSlider extends StatefulWidget {
  final List<Order> orders;

  OrderSlider({required this.orders});

  @override
  _OrderSliderState createState() => _OrderSliderState();
}

class _OrderSliderState extends State<OrderSlider> {
  int currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            itemCount: widget.orders.length,
            controller: PageController(
              initialPage: currentPage,
            ),
            onPageChanged: (int page) {
              setState(() {
                currentPage = page;
              });
            },
            itemBuilder: (context, index) {
              final order = widget.orders[index];
              return FutureBuilder<Store>(
                // Fetch the store data for the order
                future: fetchStoreData(order.storeId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else {
                    final store = snapshot.data;
                    return OrderDetails(order: order, store: store!);
                  }
                },
              );
            },
          ),
        ),
        Text(
          'Page ${currentPage + 1} of ${widget.orders.length}',
          style: TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  Future<Store> fetchStoreData(String storeId) async {
    final apiUrl = 'https://polskoydm.pythonanywhere.com/store/$storeId';
    print('Fetching store data from API: $apiUrl');

    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final store = Store.fromJson(data);
      return store;
    } else {
      throw Exception('Failed to load store data');
    }
  }
}


class OrderDetails extends StatelessWidget {
  final Order order;
  final Store store;

  OrderDetails({required this.order, required this.store});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 200, // Set the height of the image container
          decoration: BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(
                  'https://polskoydm.pythonanywhere.com/static/uploads/${store.file}'),
              fit: BoxFit.cover, // Ensure the image covers the entire container
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                store.name,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8.0),
              Text(
                'Email: ${order.email}',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                'Address: ${order.address}',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                'Total: ${order.total}',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16.0),
              Text(
                'Delivery: 25 min', // You can replace this with actual delivery time
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () {
                  _openGoogleMaps(store.address);
                },
                child: Text('View Store Location'),
              ),
              SizedBox(height: 16.0),
              Text(
                'Order Items:',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8.0),
              ListView.builder(
                shrinkWrap: true,
                itemCount: order.cart.length,
                itemBuilder: (context, index) {
                  final item = order.cart[index];
                  return ListTile(
                    leading: Image.network(
                        'https://polskoydm.pythonanywhere.com/static/uploads//${item['image']}' // Replace with the actual image URL
                    ),
                    title: Text(item['name']),
                    subtitle: Text('Quantity: ${item['quantity']}'),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Function to open Google Maps
  void _openGoogleMaps(String address) {
    MapsLauncher.launchQuery(address);
  }
}

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Order History App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: OrderHistoryPage(),
    );
  }
}
