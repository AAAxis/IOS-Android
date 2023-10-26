import 'package:driver_app/authentication/auth_screen.dart';
import 'package:driver_app/chat_screen.dart';
import 'package:driver_app/widgets/my_drawer.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'global/global.dart';


class Order {
  final String id;
  final double total;
  final String address;
  final String email;
  final String store_name;
  final String start_point;
  final String driver_phone;
  final String name;
  final List<Map<String, dynamic>> cart;
  final String status;
  double? latitude;
  double? longitude;
  String? fullAddress;

  Order({
    required this.id,
    required this.total,
    required this.address,
    required this.email,
    required this.store_name,
    required this.start_point,
    required this.driver_phone,
    required this.name,
    required this.cart,
    this.status = 'pending',
    this.latitude,
    this.longitude,
    this.fullAddress,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      total: json['total'],
      address: json['address'] ?? '', // Handle null value with an empty string
      email: json['email'] ?? '', // Handle null value with an empty string
      store_name: json['store_name'] ?? '', // Handle null value with an empty string
      start_point: json['start_point'] ?? '', // Handle null value with an empty string
      driver_phone: json['driver_phone'] ?? '', // Handle null value with an empty string
      name: json['name'] ?? '', // Handle null value with an empty string
      cart: List<Map<String, dynamic>>.from(json['cart']),
      status: json['status'] ?? '', // Handle null value with an empty string
      latitude: json['latitude']?.toDouble(), // Convert to double or leave as null
      longitude: json['longitude']?.toDouble(), // Convert to double or leave as null
      fullAddress: json['fullAddress'] ?? '', // Handle null value with an empty string
    );
  }
}

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController mapController;
  final LatLng _center = const LatLng(49.28276133580664, -123.120749655962);
  Set<Marker> _markers = {};
  List<Order> orders = [];
  bool isFetchingOrders = false; // Track if orders are being fetched
  bool isStopping = false; // Track if "Stop" button is clicked
// Modify _buildOrderList function

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _zoomToFirstOrder();
  }
  void stopFetchingOrders() {
    setState(() {
      isFetchingOrders = false;
      isStopping = true;
    });

    // Clear markers from the map
    _markers.clear();

    // Zoom out to the starting position
    mapController.animateCamera(
      CameraUpdate.newLatLngZoom(
        _center,
        11.0, // Adjust the zoom level as needed
      ),
    );
  }
  void _zoomToFirstOrder() {
    if (orders.isNotEmpty) {
      final firstOrder = orders.first;
      final zoomLevel = 16.0;

      mapController.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(firstOrder.latitude!, firstOrder.longitude!),
          zoomLevel,
        ),
      );
    }
  }

  Future<void> _getUserInfo() async {
    final apiUrl = 'https://polskoydm.pythonanywhere.com/driver_info';
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('email') ?? 'N/A';

    final Uri uri = Uri.parse('$apiUrl?email=$email'); // Create the URI
    print('Request URL: ${uri.toString()}'); // Print the URL

    final response = await http.get(uri);
    print('Response: ${response.body}'); // Print the response body

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final status = data['status'];

      await sharedPreferences!.setString('status', status);

    } else {
      await sharedPreferences!.setString('status', "disabled");

      throw Exception('Failed to load driver info');
    }
  }
  Future<void> fetchOrders() async {
    final apiUrl = 'https://polskoydm.pythonanywhere.com/online';
    print('Fetching orders from API: $apiUrl');

    try {
      final response = await http.get(Uri.parse(apiUrl));
      print('Server Response: ${response.statusCode} ${response.reasonPhrase}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<Order> fetchedOrders = (data as List)
            .map((orderData) => Order.fromJson(orderData))
            .toList();

        for (final order in fetchedOrders) {
          if (order.latitude == null || order.longitude == null) {
            final location = await getLocationFromAddress(order.start_point);
            if (location != null) {
              order.latitude = location.latitude;
              order.longitude = location.longitude;
              order.fullAddress = location.fullAddress;
            }
          }
        }

        setState(() {
          orders = fetchedOrders;

          _markers = Set.from(
            fetchedOrders
                .where((order) =>
            order.latitude != null && order.longitude != null)
                .map((order) => Marker(
              markerId: MarkerId(order.id),
              position: LatLng(order.latitude!, order.longitude!),
              infoWindow: InfoWindow(
                title: order.store_name,
                snippet: order.fullAddress ?? order.address,
              ),
            )),
          );
        });

        _zoomToFirstOrder();
      } else {
        print('Failed to load order data. Status Code: ${response.statusCode}');
        throw Exception('Failed to load order data');
      }
    } catch (e) {
      print('Error fetching data: $e');
    }
  }
  Future<void> assignDriver(BuildContext context, String orderId) async {
    final userPhone = sharedPreferences!.getString("phone")?.toString();

    final apiUrl = 'https://polskoydm.pythonanywhere.com/assign_driver?orderId=$orderId&user_phone=$userPhone'; // Construct the GET request URL

    // Print the URL for debugging
    print('GET Request URL: $apiUrl');

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('JSON Response: $responseData'); // Print the JSON response
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ChatScreen(),
          ),
        );
      } else {
        print('Failed to fetch order details. Status Code: ${response.statusCode}');
        // You can show an error message to the user here
      }
    } catch (e) {
      print('Error fetching order details: $e');
      // Handle the error and show an error message to the user
    }
  }
  Future<LocationData?> getLocationFromAddress(String address) async {
    final apiKey = 'AIzaSyA1Cn3fZigsdTv-4iBocFqo7cWk2Q5I1MA'; // Replace with your Google Maps API key
    final geocodingUrl =
        'https://maps.googleapis.com/maps/api/geocode/json?address=$address&key=$apiKey';

    print('Geocoding Request URL: $geocodingUrl');

    try {
      final response = await http.get(Uri.parse(geocodingUrl));

      print('Geocoding Response: ${response.statusCode} ${response.reasonPhrase}');
      print('Geocoding Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List<dynamic>;
        if (results.isNotEmpty) {
          final location = results[0]['geometry']['location'];
          final double lat = location['lat'];
          final double lng = location['lng'];
          final fullAddress = results[0]['formatted_address'];
          return LocationData(
              latitude: lat, longitude: lng, fullAddress: fullAddress);
        }
      }
    } catch (e) {
      print('Error geocoding address: $e');
    }
    return null;
  }
  Future<void> setOnlineStatusLocally(bool isOnline) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('online', isOnline);
    print('Online status stored locally');
  }



  Widget _buildOrderList() {
    if (!isFetchingOrders && !isStopping) {
      return SizedBox.shrink(); // Hide the order list when not fetching or stopping
    }

    return AnimatedOpacity(
      opacity: isStopping ? 0.0 : 1.0,
      duration: Duration(milliseconds: 300),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        height: isStopping
            ? 0.0
            : (orders.isNotEmpty ? MediaQuery.of(context).size.height * 0.20 : 0.0),
        child: Container(
          margin: EdgeInsets.only(left: 20.0, right: 20.0, bottom: 15.0),
          color: Colors.white,
          child: ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return ListTile(
                title: Text(order.name),
                subtitle: Text('Deliver to ' + order.address),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        final userEmail = sharedPreferences!.getString("email")?.toString();

                        if (userEmail != null && userEmail.isNotEmpty) {
                          await assignDriver(context, order.id);
                        } else {
                          print('User email is not set. Please set it.');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        primary: Colors.green,
                      ),
                      child: Text(
                        "Confirm",
                        style: TextStyle(
                          color: Colors.white, // Set the text color to white
                        ),
                      ),

                    ),

                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _center,
              zoom: 11.0,
            ),
            markers: _markers,
            compassEnabled: false,
            zoomControlsEnabled: false,
          ),

          Positioned(
            top: 50.0,
            right: 30.0,
            child: Card(
              elevation: 5.0,
              shape: CircleBorder(),
              child: IconButton(
                icon: Icon(
                  Icons.chat,
                  size: 30.0,
                  color: Colors.black,
                ),
                onPressed: () async {
                  // Check if email is available and not empty in SharedPreferences
                  final email = sharedPreferences!.getString("email");
                  if (email != null && email.isNotEmpty) {
                    // Email is available, navigate to the drawer page
                    Navigator.push(context, MaterialPageRoute(builder: (c) => ChatScreen()));
                  } else {
                    // Email is not available, navigate to the login page
                    Navigator.push(context, MaterialPageRoute(builder: (c) => MergedLoginScreen()));
                  }
                },
              ),
            ),
          ),


          Positioned(
            left: 50.0,
            right: 50.0,
            bottom: 210.0,
            child: ElevatedButton(
              onPressed: () {

                _getUserInfo();
                final userStatus = sharedPreferences!.getString("status")?.toString();

                if (userStatus == 'approved') {
                  if (!isStopping) {
                    setState(() {
                      isFetchingOrders = !isFetchingOrders;
                    });
                    mapController.animateCamera(
                      CameraUpdate.newLatLngZoom(
                        _center,
                        11.0, // Adjust the zoom level as needed
                      ),
                    );
                    _markers.clear();
                    setOnlineStatusLocally(false);
                    if (isFetchingOrders) {
                      // Set the online status locally in SharedPreferences to true
                      setOnlineStatusLocally(true);

                      fetchOrders();
                    }
                  }
                } else {
                  Fluttertoast.showToast(
                    msg: 'Admin has not approved your account',
                    toastLength: Toast.LENGTH_LONG,
                    gravity: ToastGravity.BOTTOM,
                    backgroundColor: Colors.red,
                    textColor: Colors.white,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                shape: CircleBorder(),
                padding: EdgeInsets.all(20.0),
                primary: isStopping ? Colors.black : (isFetchingOrders ? Colors.red : Colors.black),
              ),
              child: Column(
                children: [
                  Icon(
                    isStopping ? Icons.power_settings_new : (isFetchingOrders ? Icons.stop : Icons.power_settings_new),
                    color: Colors.white,
                    size: 48,
                  ),

                ],
              ),
            ),
          ),

          Positioned(
            bottom: 0, // Position it at the bottom of the screen
            left: 0, // You can adjust the left position as needed
            right: 0, // You can adjust the right position as needed
            child: _buildOrderList(),
          )
        ],
      ),
    );
  }
}

class LocationData {
  final double latitude;
  final double longitude;
  final String fullAddress;

  LocationData({
    required this.latitude,
    required this.longitude,
    required this.fullAddress,
  });
}




