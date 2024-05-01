import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver_app/MyOrder.dart';
import 'package:driver_app/widgets/balance.dart';
import 'package:driver_app/widgets/navigation_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';


class HomeTabPage extends StatefulWidget {
  static final CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  @override
  _HomeTabPageState createState() => _HomeTabPageState();
}

class _HomeTabPageState extends State<HomeTabPage> {
  Completer<GoogleMapController> _controllerGoogleMap = Completer();
  late GoogleMapController newGoogleMapController;

  Color driverStatusColor = Colors.green;
  String driverStatusText = "Go Online";
  String appBarTitle = "";


  @override
  void initState() {
    super.initState();
    // Request location permissions when the widget initializes
    requestLocationPermission();
    // Listen to changes in driver status
    listenToDriverStatus();
    // Check if there is a current task stored in SharedPreferences

  }

  Future<void> checkForCurrentTask() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? currentTask = prefs.getString('current_task');

    // Check if currentTask contains any data other than 'false'
    if (currentTask != null && currentTask != 'searching') {
      // Open the bottom sheet with order details
      showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return Container(
            // Adjust the height and styling of the bottom sheet as per your requirement
            height: MediaQuery.of(context).size.height * 0.8,
            child: OrderScreen(),
          );
        },
      );
    }
  }




  Future<void> requestLocationPermission() async {
    // Request location permissions
    PermissionStatus permissionStatus = await Permission.location.request();
    if (permissionStatus.isDenied) {
      // Permission denied, handle accordingly
      // You can show a message to the user explaining why you need location permissions
    }
  }

  void listenToDriverStatus() {
    // Get the current user's UID
    String uid = FirebaseAuth.instance.currentUser!.uid;

    // Listen to changes in the driver's status in Firestore where status is "assigned"
    FirebaseFirestore.instance.collection('drivers').doc(uid).snapshots().listen((snapshot) async {
      if (snapshot.exists) {
        // Get the status from the snapshot
        String status = snapshot.get('status');


        setState(() {
          bool isDriverAvailable = status == 'online';
          bool isAssigned = status == 'assigned';

          if (isDriverAvailable) {
            locatePosition();

            // Delay showing the dialog by 5 seconds
            Future.delayed(Duration(seconds: 5), () {
              showOrdersDialog();
            });

            driverStatusColor = Colors.red;
            driverStatusText = "Go Offline";
          } else if (isAssigned) {
            // Show assigned dialog when the driver is assigned a task
            checkForCurrentTask();
            driverStatusColor = Colors.orange;
            driverStatusText = "Assigned";
          } else {
            driverStatusColor = Colors.green;
            driverStatusText = "Go Online";
          }
        });

      }
    });
  }

  int currentOrderIndex = 0;

  Future<void> showOrdersDialog() async {
    // Fetch orders collection from Firestore

      QuerySnapshot ordersSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('status', isEqualTo: 'ready') // Filter by status 'paid'
          .get();

      // Check if there are any paid orders
      if (ordersSnapshot.docs.isEmpty) {
        // No paid orders to display
        return;
      }

    // Get the current order
    DocumentSnapshot document = ordersSnapshot.docs[currentOrderIndex];
    Map<String, dynamic> data = document.data() as Map<String, dynamic>;
    String documentId = document.id; // Accessing the document ID

    bool orderAccepted = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("New Order"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Order ID: $documentId"), // Displaying the document ID
              Text("Store: ${data['store']}"),
              Text("Name: ${data['name']}"),
            ],
          ),
          actions: <Widget>[
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                // Pass the order ID to the function
                changeStatusToAssigned(documentId);
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.black,
              ),
              child: Text('Accept'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context); // Close the dialog
                // Add a delay before displaying the next order
                await Future.delayed(Duration(seconds: 4));
                setState(() {
                  // Increment currentOrderIndex to display the next order
                  currentOrderIndex++;
                  // Check if all orders are processed, reset index if necessary
                  if (currentOrderIndex >= ordersSnapshot.docs.length) {
                    currentOrderIndex = 0;
                  }
                });
                // Show the next order dialog
                showOrdersDialog();
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.black,
                backgroundColor: Colors.white,
              ),
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<void> changeStatusToAssigned(String orderId) async {


    String uid = FirebaseAuth.instance.currentUser!.uid;

    // Store the orderId in shared preferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_task', orderId);
    await prefs.setString('status', 'assigned');

    await FirebaseFirestore.instance.collection('drivers').doc(uid).update({
      'current_task': orderId, // Assign driver to order
      'status': 'assigned', // Assign driver to order

    });

    // Update the order status and assign driver in Firestore
    await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
      'driver': uid, // Assign driver to order
      'status': 'assigned', // Update order status
    });


  }

  void locatePosition() async {
    // Get the current user's location
    var position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    // Define the new camera position
    CameraPosition newPosition = CameraPosition(
      target: LatLng(position.latitude, position.longitude),
      zoom: 17.0,
    );

    // Move the camera to the new position
    newGoogleMapController.animateCamera(
      CameraUpdate.newCameraPosition(newPosition),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Map Screen'),

        leading: IconButton(
          icon: Icon(Icons.zoom_in_map),
          onPressed: () {
            // Implement your filtering logic here
          },
        ),


      ),
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            myLocationButtonEnabled: true,
            initialCameraPosition: HomeTabPage._kGooglePlex,
            myLocationEnabled: true,
            onMapCreated: (GoogleMapController controller) {
              _controllerGoogleMap.complete(controller);
              newGoogleMapController = controller;
            },
          ),
          Positioned(
            top: 10.0, // Adjust the position of the notification
            left: 10,
            right: 10,
            child: Container(
              height: 100.0, // Height of the notification
              padding: EdgeInsets.all(15.0), // Padding inside the notification
              color: Colors.white.withOpacity(1.0), // Adjust the background color and opacity
              child: StreamBuilder(
                stream: FirebaseFirestore.instance.collection('notifications').snapshots(),
                builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (!snapshot.hasData) {
                    return CircularProgressIndicator(); // Show a loading indicator while data is loading
                  }
                  // Get the last notification document from the snapshot
                  var documents = snapshot.data!.docs;
                  if (documents.isEmpty) {
                    return Text('No notifications'); // Show a message if there are no notifications
                  }
                  var lastNotification = documents.last;
                  var title = lastNotification['title']; // Assuming 'title' is the field containing the notification title
                  var body = lastNotification['body']; // Assuming 'body' is the field containing the notification body
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 20.0, // Adjust the font size of the title
                          fontWeight: FontWeight.bold, // Apply bold font weight to the title
                        ),
                      ),
                      SizedBox(height: 10.0), // Add some space between the title and body texts
                      Expanded(
                        child: Text(
                          body,
                          style: TextStyle(
                            fontSize: 16.0, // Adjust the font size of the body
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          Positioned(
            top: 150.0,
            left: 16.0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SizedBox(
                  width: 40.0,
                  height: 40.0,
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: IconButton(
                      icon: Icon(Icons.attach_money),
                      color: Colors.black,
                      onPressed: () {
                        // Handle map settings button press
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (c) => PaymentScreen()),
                        );
                        // You can show a bottom sheet or navigate to a settings screen
                      },
                    ),
                  ),
                ),
                SizedBox(height: 8.0),
                SizedBox(
                  width: 40.0,
                  height: 40.0,
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: IconButton(
                      icon: Icon(Icons.help_outline),
                      color: Colors.black,
                      onPressed: () {
                        // Handle help icon press
                        // URL with token appended
                        String url = 'https://theholylabs.com';


                        launch(url);
                        // You can show a dialog or navigate to a help screen
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 180.0,
              width: double.infinity,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: ElevatedButton(
                      onPressed: () {
                        if (driverStatusText == "Go Online") {
                          makeDriverOnlineNow(context);
                        } else if (driverStatusText == "Go Offline") {
                          makeDriverOfflineNow(context);
                        } else {
                          showModalBottomSheet(
                            context: context,
                            builder: (BuildContext context) {
                              return Container(
                                // Adjust the height and styling of the bottom sheet as per your requirement
                                height:
                                MediaQuery.of(context).size.height * 0.8,
                                child: OrderScreen(),
                              );
                            },
                          );
                        }
                      },
                      child: Text(
                        driverStatusText, // Use driverStatusText instead of hardcoding button text
                        style: TextStyle(
                          fontSize: 16.0,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                        driverStatusColor, // Use driverStatusColor for button color
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void makeDriverOnlineNow(BuildContext context) async {
    // Get the current user's UID
    String uid = FirebaseAuth.instance.currentUser!.uid;

    // Get the current location
    var position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    // Fetch user's approval status from Firestore
    DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
        .collection('drivers')
        .doc(uid)
        .get();

    // Check if user is approved
    bool isApproved = userSnapshot.exists && userSnapshot['approval'] == true;

    // If approved, update the driver's status and location in Firestore
    if (isApproved) {
      await FirebaseFirestore.instance.collection('drivers').doc(uid).update({
        'status': 'online',
        'location': GeoPoint(position.latitude, position.longitude),
      }).then((value) {
        // Show a snack notification once update is completed
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Driver is now online')),
        );
      }).catchError((error) {
        // Handle errors if any
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error')),
        );
      });
    } else {
      // If not approved, display a snack to inform the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please update Name and Phone')),
      );
    }
  }

  void makeDriverOfflineNow(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    prefs.setString('status', 'offline');
    prefs.setString('current_task', 'searching');

    FirebaseFirestore.instance
        .collection('drivers')
        .doc(prefs.getString("uid")!) // Assuming 'uid' uniquely identifies the driver
        .update({
      'status': 'offline',
      'current_task': 'searching', // Assuming you want to set 'current_task' to boolean false, not string 'false'
    }).then((value) {
      // Show a snack notification once update is completed
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Driver is now offline')),
      );

      // Navigate to the MainScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainScreen()),
      );
    }).catchError((error) {
      // Handle errors if any
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    });
  }
}
