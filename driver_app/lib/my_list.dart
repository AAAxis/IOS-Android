import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:convert';
import 'global/global.dart';

class MyList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DataListScreen(), // Use DataListScreen directly as the home widget
    );
  }
}

class DataListScreen extends StatefulWidget {
  @override
  _DataListScreenState createState() => _DataListScreenState();
}

class _DataListScreenState extends State<DataListScreen> {
  List<dynamic> dataList = [];
  List<LatLng> coordinates = []; // List to store LatLng coordinates
  bool isLoading = true; // Track loading state

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    final response = await http.get(
        Uri.parse('https://polskoydm.pythonanywhere.com/online'));

    if (response.statusCode == 200) {
      setState(() {
        dataList = json.decode(response.body);
      });
      await fetchCoordinates(); // Fetch coordinates once data is loaded
    } else {
      throw Exception('Failed to load data');
    }
  }

  Future<void> fetchCoordinates() async {
    // Iterate through dataList and fetch coordinates for each address
    for (var item in dataList) {
      final address = item["start_point"];
      try {
        final locations = await locationFromAddress(address);
        if (locations.isNotEmpty) {
          final firstLocation = locations.first;
          coordinates.add(
              LatLng(firstLocation.latitude, firstLocation.longitude));
        }
      } catch (e) {
        print('Error getting coordinates for $address: $e');
        coordinates.add(LatLng(
            0, 0)); // Add default coordinates if unable to get coordinates
      }
    }
    setState(() {
      isLoading =
      false; // Set loading state to false after coordinates are fetched
    }); // Update the state to rebuild the UI with the new coordinates
  }

  void assignDriver(BuildContext context, String orderId) async {
    final userPhone = sharedPreferences!.getString("phone")?.toString();

    final apiUrl = 'https://polskoydm.pythonanywhere.com/assign_driver?orderId=$orderId&user_phone=$userPhone';

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => MyList(),
          ),
        );
      } else {
        print('Failed to fetch order details. Status Code: ${response
            .statusCode}');
      }
    } catch (e) {
      print('Error fetching order details: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Container(
            // This is an empty container
            height: 50, // You can adjust the height as needed for spacing
          ),
          Container(
            height: 500, // Specify the height of the container
            child: CardSwiper(
              cardsCount: dataList.length,
              cardBuilder: (context, index, percentThresholdX,
                  percentThresholdY) {
                final item = dataList[index];
                final latLng = coordinates[index]; // Get coordinates for current card

                // Create a unique key for each GoogleMap widget
                final Key mapKey = UniqueKey();

                return Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        // This is an empty container
                        height: 20, // You can adjust the height as needed for spacing
                      ),
                      ListTile(
                        title: Text('ID: ${item["id"]}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Store Name: ${item["store_name"]}'),

                            Text('Price: ${item["total"]}'),
                          ],
                        ),
                      ),

                      Container(
                        height: 200,
                        child: GoogleMap(
                          key: mapKey, // Use the unique key
                          initialCameraPosition: CameraPosition(
                            target: latLng,
                            zoom: 13,
                          ),
                          markers: Set<Marker>.of([
                            Marker(
                              markerId: MarkerId('start_point_$index'),
                              // Unique marker ID for each card
                              position: latLng,
                              infoWindow: InfoWindow(
                                title: item["start_point"],
                              ),
                            ),
                          ]),
                        ),

                      ),
                      ListTile(
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${item["start_point"]}'),

                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          assignDriver(context, item["id"]);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors
                              .black, // Change the background color to black
                        ),
                        child: Text('Assign', style: TextStyle(
                            color: Colors.white)), // Change text color to white
                      ),

                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
