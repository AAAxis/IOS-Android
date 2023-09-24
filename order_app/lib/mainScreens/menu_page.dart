import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'details_page.dart';
import 'payment_page.dart';

class MenuPage extends StatefulWidget {
  final String storeId;

  MenuPage({required this.storeId});

  @override
  _MenuPageState createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  final List<Map<String, dynamic>> _cartItems = [];

  bool isCartEmpty() {
    return _cartItems.isEmpty;
  }

  String orderId = ''; // Initialize orderId

  Future<bool> placeOrder(BuildContext context, List<Map<String, dynamic>> cartItems, double total) async {
    final List<Map<String, dynamic>> items = cartItems.map((item) {
      return {
        'product_id': item['id'],
        'quantity': item['quantity'],
      };
    }).toList();

    final Map<String, dynamic> requestData = {
      'items': items,
      'total': total,
    };

    print('Sending request data: $requestData'); // Print the request data

    final response = await http.post(
      Uri.parse('https://polskoydm.pythonanywhere.com/checkout'), // Replace with your API URL
      headers: {'Content-Type': 'application/json'},
      body: json.encode(requestData),
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      final String orderMessage = responseData['message'];
      orderId = responseData['order_id']; // Set the orderId variable
      print('Order placed successfully. Order ID: $orderId');
      return true; // Return true for success
    } else {
      final responseData = json.decode(response.body);
      final String errorMessage = responseData['error_message'];
      print('Order placement failed. Error: $errorMessage');
      return false; // Return false for failure
    }
  }

  double calculateTotalPrice() {
    double total = 0;
    for (var item in _cartItems) {
      total += item['price'] * item['quantity'];
    }
    return total;
  }

  void _addToCart(Map<String, dynamic> product) {
    setState(() {
      final existingItemIndex = _cartItems.indexWhere((item) => item['id'] == product['id']);

      if (existingItemIndex != -1) {
        _cartItems[existingItemIndex]['quantity']++;
      } else {
        product['quantity'] = 1;
        _cartItems.add(product);
      }
    });
  }

  void _removeFromCart(Map<String, dynamic> product) {
    setState(() {
      final existingItemIndex = _cartItems.indexWhere((item) => item['id'] == product['id']);

      if (existingItemIndex != -1) {
        if (_cartItems[existingItemIndex]['quantity'] > 1) {
          _cartItems[existingItemIndex]['quantity']--;
        } else {
          _cartItems.removeAt(existingItemIndex);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Menu'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No products available.'));
          } else {
            final products = snapshot.data!;
            return GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10.0,
                crossAxisSpacing: 10.0,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetailsPage(product: product),
                      ),
                    );
                  },
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Stack(
                      children: [
                        Container(
                          height: 150,
                          decoration: BoxDecoration(
                            borderRadius:
                            BorderRadius.vertical(top: Radius.circular(10.0)),
                            image: DecorationImage(
                              image: NetworkImage(
                                'https://polskoydm.pythonanywhere.com/static/uploads/${product['image']}',
                              ),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 5,
                          left: 5,
                          child: Container(
                            padding: EdgeInsets.all(5),
                            color: Colors.white.withOpacity(0.7),
                            child: Text(
                              product['name'],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 35,
                          right: 5,
                          child: Container(
                            padding: EdgeInsets.all(0),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: Icon(
                                    Icons.remove,
                                    color: Colors.white,
                                  ),
                                  onPressed: () => _removeFromCart(product),
                                ),
                                Text(
                                  (_cartItems
                                      .where((item) => item['id'] == product['id'])
                                      .fold<int>(
                                    0,
                                        (previousValue, element) => previousValue + element['quantity'] as int,
                                  )
                                  ).toString(),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                ),

                                IconButton(
                                  icon: Icon(
                                    Icons.add,
                                    color: Colors.white,
                                  ),
                                  onPressed: () => _addToCart(product),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: isCartEmpty()
            ? null
            : () async {
          final success = await placeOrder(
            context,
            _cartItems,
            calculateTotalPrice(),
          );
          if (success) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PaymentPage(
                  orderId: orderId, // Use the orderId obtained from placeOrder
                  cartItems: _cartItems,
                  total: calculateTotalPrice(),
                ),
              ),
            );
          } else {
            print('Failed to place the order.');
          }
        },
        child: Icon(Icons.shopping_cart),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> fetchProducts() async {
    final response = await http
        .get(Uri.parse('https://polskoydm.pythonanywhere.com/${widget.storeId}/shop'));
    if (response.statusCode == 200) {
      final List<dynamic> responseData = json.decode(response.body);
      return List<Map<String, dynamic>>.from(responseData);
    } else {
      throw Exception('Failed to load products');
    }
  }
}
