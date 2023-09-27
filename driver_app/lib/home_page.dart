import 'package:driver_app/map_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:maps_launcher/maps_launcher.dart';
import 'account_page.dart';
import 'navigation_widget.dart'; // Import your account page

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Your App', // Replace with your app's title
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => HomePage(),
        '/account': (context) => AccountPage(),
        '/map': (context) => MapScreen(),
      },

    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Order> orders = [];
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    fetchOrders(); // Fetch orders when the page loads
  }

  Future<Store> fetchStoreData(String storeId) async {
    final apiUrl = 'https://polskoydm.pythonanywhere.com/store/$storeId';
    print('Fetching store data from API: $apiUrl');

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final store = Store.fromJson(data);
        return store;
      } else {
        throw Exception('Failed to load store data');
      }
    } catch (e) {
      print('Error fetching store data: $e');
      throw e;
    }
  }

  Future<void> fetchOrders() async {
    final apiUrl = 'https://polskoydm.pythonanywhere.com/history';
    print('Fetching orders from API: $apiUrl');

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<Order> fetchedOrders = (data as List)
            .map((orderData) => Order.fromJson(orderData))
            .toList();

        // Fetch store data for each order
        for (final order in fetchedOrders) {
          final store = await fetchStoreData(order.storeId);
          order.store = store;
        }

        setState(() {
          orders = fetchedOrders; // Update the orders list with fetched data
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
      appBar: null, // Set the appBar to null to remove the top app bar
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return OrderDetails(order: order);
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          // Handle bottom navigation item taps here
          setState(() {
            currentIndex = index;
          });
        },
      ),
    );
  }
}



class OrderDetails extends StatelessWidget {
  final Order order;

  OrderDetails({required this.order});

  @override
  Widget build(BuildContext context) {
    final store = order.store;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 200,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(
                  'https://polskoydm.pythonanywhere.com/static/uploads/${store?.file ?? 'default_image.jpg'}'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                store?.name ?? 'Store Name', // Provide a default name
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8.0),
              Text(
                'Delivery Timer: 25 min', // You can replace this with actual delivery time
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () {
                  _openGoogleMaps(store?.address ?? '');
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
                      'https://polskoydm.pythonanywhere.com/static/uploads/${item['image']}',
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
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

class Order {
  final String id;
  final double total;
  final String address;
  final String email;
  final String name;
  final List<Map<String, dynamic>> cart;
  final String status;
  final String storeId;
  Store? store;

  Order({
    required this.id,
    required this.total,
    required this.address,
    required this.email,
    required this.name,
    required this.cart,
    this.status = 'pending',
    required this.storeId,
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
      storeId: json['store_id'].toString(),
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
