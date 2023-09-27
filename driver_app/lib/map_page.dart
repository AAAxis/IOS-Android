import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MapScreen(),
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
  final String storeId;
  double? latitude;
  double? longitude;
  String? fullAddress; // Store the full address

  Order({
    required this.id,
    required this.total,
    required this.address,
    required this.email,
    required this.name,
    required this.cart,
    this.status = 'pending',
    required this.storeId,
    this.latitude,
    this.longitude,
    this.fullAddress,
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

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController mapController;
  final LatLng _center = const LatLng(49.28276133580664, -123.120749655962);
  Set<Marker> _markers = {};
  List<Order> orders = [];

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _zoomToFirstOrder();
  }

  void _zoomToFirstOrder() {
    if (orders.isNotEmpty) {
      final firstOrder = orders.first;
      final zoomLevel = 16.0; // You can adjust the zoom level as needed

      mapController.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(firstOrder.latitude!, firstOrder.longitude!),
          zoomLevel,
        ),
      );
    }
  }

  Future<void> fetchOrders() async {
    final apiUrl = 'https://polskoydm.pythonanywhere.com/history';
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

        // Fetch store data for each order
        for (final order in fetchedOrders) {
          if (order.latitude == null || order.longitude == null) {
            final location = await getLocationFromAddress(order.address);
            if (location != null) {
              order.latitude = location.latitude;
              order.longitude = location.longitude;
              order.fullAddress = location.fullAddress; // Store the full address
            }
          }
        }

        setState(() {
          orders = fetchedOrders;

          _markers = Set.from(
            fetchedOrders
                .where((order) => order.latitude != null && order.longitude != null)
                .map((order) => Marker(
              markerId: MarkerId(order.id),
              position: LatLng(order.latitude!, order.longitude!),
              infoWindow: InfoWindow(
                title: order.name,
                snippet: order.fullAddress ?? order.address,
              ),
            )),
          );
        });

        _zoomToFirstOrder(); // Zoom to the first order after loading
      } else {
        print('Failed to load order data. Status Code: ${response.statusCode}');
        throw Exception('Failed to load order data');
      }
    } catch (e) {
      print('Error fetching data: $e');
    }
  }

  Future<LocationData?> getLocationFromAddress(String address) async {
    final apiKey = 'AIzaSyA1Cn3fZigsdTv-4iBocFqo7cWk2Q5I1MA'; // Replace with your API key
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
          return LocationData(latitude: lat, longitude: lng, fullAddress: fullAddress);
        }
      }
    } catch (e) {
      print('Error geocoding address: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Google Map Example'),
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _center,
              zoom: 11.0,
            ),
            markers: _markers,
          ),
          Positioned(
            left: 16.0,
            bottom: 16.0,
            child: FloatingActionButton(
              onPressed: () {
                fetchOrders();
              },
              child: Icon(Icons.refresh),
            ),
          ),
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
