import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'package:order_app/global/global.dart';
import 'package:order_app/splashScreen/splash_screen.dart';
import 'package:order_app/widgets/my_drawer.dart';
import 'menu_page.dart'; // Adjust the path based on your actual file structure

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> restaurants = [];

  // Function to fetch data from your API.
  Future<void> fetchData() async {
    final response = await http.get(
        Uri.parse('https://polskoydm.pythonanywhere.com/'));
    if (response.statusCode == 200) {
      final List<dynamic> responseData = json.decode(response.body);
      setState(() {
        restaurants = List<Map<String, dynamic>>.from(responseData);
      });
    } else {
      throw Exception('Failed to load data');
    }
  }

  restrictBlockedUsersFromUsingApp() async {
    await FirebaseFirestore.instance.collection("users")
        .doc(firebaseAuth.currentUser!.uid)
        .get().then((snapshot) {
      if (snapshot.data()!["status"] != "approved") {
        firebaseAuth.signOut();
        Fluttertoast.showToast(msg: "You have been Blocked");
        Navigator.push(
            context, MaterialPageRoute(builder: (c) => MySplashScreen()));
      } else {
        Fluttertoast.showToast(msg: "Login Successful");
      }
    });
  }

  @override
  void initState() {
    super.initState();
    fetchData();
    restrictBlockedUsersFromUsingApp();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.blue,
                Colors.blue,
              ],
              begin: FractionalOffset(0.0, 0.0),
              end: FractionalOffset(1.0, 0.0),
              stops: [0.0, 1.0],
              tileMode: TileMode.clamp,
            ),
          ),
        ),
        title: const Text(
          "Delivery",
          style: TextStyle(fontSize: 35, fontFamily: "Signatra"),
        ),
        centerTitle: true,
      ),
      drawer: firebaseAuth.currentUser != null ? MyDrawer() : null,
      // Conditionally show the drawer
      body: ListView.builder(
        itemCount: restaurants.length,
        itemBuilder: (context, index) {
          final restaurant = restaurants[index];
          return Card(
            child: ListTile(
              title: Text(restaurant['name']),
              subtitle: Text(restaurant['address']),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        MenuPage(storeId: restaurant['token']
                            .toString()), // Convert integer to string
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

}
