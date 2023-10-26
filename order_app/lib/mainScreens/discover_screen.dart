import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:order_app/global/global.dart';
import 'package:order_app/splashScreen/splash_screen.dart';
import 'menu_page.dart';
import 'package:carousel_slider/carousel_slider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}


class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> restaurants = [];
  List<Map<String, dynamic>> filteredRestaurants = [];
  TextEditingController searchController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();


  Future<void> fetchData() async {
    final response =
    await http.get(Uri.parse('https://polskoydm.pythonanywhere.com/'));
    if (response.statusCode == 200) {
      final List<dynamic> responseData = json.decode(response.body);
      setState(() {
        restaurants = List<Map<String, dynamic>>.from(responseData);
      });
    } else {
      throw Exception('Failed to load data');
    }
  }

  void restrictBlockedUsersFromUsingApp() async {
    await FirebaseFirestore.instance
        .collection("users")
        .doc(firebaseAuth.currentUser!.uid)
        .get()
        .then((snapshot) {
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
      key: _scaffoldKey,
      appBar: AppBar(
        elevation: 0.0, // Remove the divider
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Colors.white],
              begin: FractionalOffset(0.0, 0.0),
              end: FractionalOffset(1.0, 0.0),
              stops: [0.0, 1.0],
              tileMode: TileMode.clamp,
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              "Delivery",
              style: TextStyle(
                fontSize: 35.0,
                fontWeight: FontWeight.normal,
                color: Colors.black,
                fontFamily: 'Signatra', // Use the 'Cupertino' font
              ),
            ),
          ),
        ],
        leading: IconButton(
          icon: Icon(
            Icons.search,
            color: Colors.black, // Customize the icon color
          ),
          onPressed: () {
            showSearch(
              context: context,
              delegate: RestaurantSearchDelegate(restaurants),
            );
          },
        ),
      ),


      body: Column(
        children: [
          SizedBox(height: 16.0), // Add space

          // Add the CarouselSlider widget here
          CarouselSlider(
            items: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12.0), // Adjust the radius as needed
                    child: Image.network(
                      'https://media.istockphoto.com/id/1309352410/photo/cheeseburger-with-tomato-and-lettuce-on-wooden-board.jpg?s=612x612&w=0&k=20&c=lfsA0dHDMQdam2M1yvva0_RXfjAyp4gyLtx4YUJmXgg=',
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 120,
                    ),
                  ),
                  Positioned(
                    top: 8.0, // Adjust the top position as needed
                    left: 8.0, // Adjust the right position as needed
                    child: Text(
                      'Hamburger',
                      style: TextStyle(
                        fontSize: 16.0, // Adjust the font size as needed
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12.0), // Adjust the radius as needed
                    child: Image.network(
                      'https://media.istockphoto.com/id/1176929581/photo/chopstick-holding-sushi-rolls-set-with-salmon-and-cream-cheese-and-cuccumber-on-black-slate.jpg?s=612x612&w=0&k=20&c=ctmjAzHzxnVSzvBruJt__oucuqn6g-V1Jadv-PRwLj8=',
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 120,
                    ),
                  ),
                  Positioned(
                    top: 8.0, // Adjust the top position as needed
                    right: 8.0, // Adjust the right position as needed
                    child: Text(
                      'Sushi',
                      style: TextStyle(
                        fontSize: 16.0, // Adjust the font size as needed
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12.0), // Adjust the radius as needed
                    child: Image.network(
                      'https://thumbs.dreamstime.com/b/espresso-coffee-cup-beans-vintage-table-90374872.jpg',
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 120,
                    ),
                  ),
                  Positioned(
                    top: 8.0, // Adjust the top position as needed
                    left: 8.0, // Adjust the right position as needed
                    child: Text(
                      'Coffee',
                      style: TextStyle(
                        fontSize: 16.0, // Adjust the font size as needed
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              // Add more items in a similar structure
            ],
            options: CarouselOptions(
              height: 120,
              aspectRatio: 16 / 9,
              viewportFraction: 0.8,
              initialPage: 0,
              enableInfiniteScroll: true,
              reverse: false,
              autoPlay: true,
              autoPlayInterval: Duration(seconds: 3),
              autoPlayAnimationDuration: Duration(milliseconds: 800),
              autoPlayCurve: Curves.fastOutSlowIn,
              enlargeCenterPage: true,
              scrollDirection: Axis.horizontal,
            ),
          ),


          SizedBox(height: 16.0), // Add a SizedBox for spacing

          Expanded(
            child: ListView.builder(
              itemCount: filteredRestaurants.isNotEmpty
                  ? filteredRestaurants.length
                  : restaurants.length,
              itemBuilder: (context, index) {
                final restaurant = filteredRestaurants.isNotEmpty
                    ? filteredRestaurants[index]
                    : restaurants[index];
                final imageUrl =
                    'https://polskoydm.pythonanywhere.com/static/uploads/${restaurant['file']}';

                return Card(
                  child: ListTile(
                    contentPadding: EdgeInsets.all(16.0),
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(restaurant['name']),
                        Text(restaurant['address']),
                      ],
                    ),
                    leading: Image.network(
                      imageUrl,
                      width: 80.0,
                      height: 80.0,
                      fit: BoxFit.cover,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MenuPage(
                            storeId: restaurant['token'].toString(),
                          ),
                        ),
                      );
                    },
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

class RestaurantSearchDelegate extends SearchDelegate<String> {
  final List<Map<String, dynamic>> restaurants;

  RestaurantSearchDelegate(this.restaurants);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    final queryLower = query.toLowerCase();
    final filteredRestaurants = restaurants.where((restaurant) =>
    restaurant['name'].toLowerCase().contains(queryLower) ||
        restaurant['address'].toLowerCase().contains(queryLower));

    return ListView.builder(
      itemCount: filteredRestaurants.length,
      itemBuilder: (context, index) {
        final restaurant = filteredRestaurants.elementAt(index);
        final imageUrl =
            'https://polskoydm.pythonanywhere.com/static/uploads/${restaurant['file']}';

        return Card(
          child: ListTile(
            contentPadding: EdgeInsets.all(16.0),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(restaurant['name']),
                Text(restaurant['address']),
              ],
            ),
            leading: Image.network(
              imageUrl,
              width: 80.0,
              height: 80.0,
              fit: BoxFit.cover,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MenuPage(
                    storeId: restaurant['token'].toString(),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
