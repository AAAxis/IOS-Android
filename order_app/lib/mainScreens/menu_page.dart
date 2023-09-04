import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'details_page.dart';
import 'payment_page.dart';// Adjust the path based on your actual file structure

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

  Future<List<Map<String, dynamic>>> fetchProducts() async {
    final response = await http.get(Uri.parse('https://polskoydm.pythonanywhere.com/${widget.storeId}/shop'));
    if (response.statusCode == 200) {
      final List<dynamic> responseData = json.decode(response.body);
      return List<Map<String, dynamic>>.from(responseData);
    } else {
      throw Exception('Failed to load products');
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Details'),
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
            return ListView.builder(
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return ListTile(
                  title: Text(product['name']),
                  subtitle: Text(product['description']),
                  trailing: ElevatedButton(
                    onPressed: () => _addToCart(product),
                    child: Text('Add'),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetailsPage(product: product),
                      ),
                    );
                  },
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: isCartEmpty() ? null : () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CartPage(cartItems: _cartItems)),
          );
        },
        child: Icon(Icons.shopping_cart),
      ),
    );
  }
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






class CartPage extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;

  CartPage({required this.cartItems});

  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {


  double total = 0;

  @override
  void initState() {
    super.initState();
    calculateTotalPrice();
  }

  void calculateTotalPrice() {
    total = 0;
    for (var item in widget.cartItems) {
      total += item['price'] * item['quantity'];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cart'),
      ),
      body: ListView.builder(
        itemCount: widget.cartItems.length,
        itemBuilder: (context, index) {
          final cartItem = widget.cartItems[index];
          return ListTile(
            title: Text(cartItem['name']),
            subtitle: Text(
                'Quantity: ${cartItem['quantity']} x \$${cartItem['price']}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () {
                    setState(() {
                      cartItem['quantity']++;
                      calculateTotalPrice();
                    });
                  },
                ),
                IconButton(
                  icon: Icon(Icons.remove),
                  onPressed: () {
                    setState(() {
                      if (cartItem['quantity'] > 1) {
                        cartItem['quantity']--;
                        calculateTotalPrice();
                      }
                    });
                  },
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Total: \$${total.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween, // Align buttons to the left and right
                children: [
                  ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) =>
                            AlertDialog(
                              title: Text('Clear Cart'),
                              content: Text(
                                  'Are you sure you want to clear the cart?'),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    widget.cartItems
                                        .clear(); // Use widget.cartItems
                                    calculateTotalPrice(); // Update the total
                                    Navigator.of(context)
                                        .pop(); // Close the dialog
                                    Navigator.of(context).pop();
                                  },
                                  child: Text('Yes'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context)
                                        .pop(); // Close the dialog
                                  },
                                  child: Text('No'),
                                ),
                              ],
                            ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      primary: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: Text(
                        'Clear Cart',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      bool orderPlaced =
                      await placeOrder(context, widget.cartItems, total);
                      if (orderPlaced) {
                        // Print the data before navigating
                        print('Sending data to PaymentPage:');
                        print('orderId: $orderId');
                        print('cartItems: ${widget.cartItems}');
                        print('total: $total');

                        // Order was successfully placed, navigate to the payment page
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PaymentPage(
                              orderId: orderId, // Pass orderId to PaymentPage
                              cartItems: widget.cartItems,
                              total: total,
                            ),
                          ),
                        );
                      } else {
                        // Handle the case where the order placement failed
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      primary: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: Text(
                        'Checkout',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),


    );
  }
}