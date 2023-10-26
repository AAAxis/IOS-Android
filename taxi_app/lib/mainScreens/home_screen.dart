import 'package:flutter/material.dart';
import 'package:taxi_app/widgets/my_drawer.dart';
import 'map_page.dart';

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      drawer: MyDrawerPage(), // Add your custom drawer widget here
      body: PageView(
        children: [
          MapScreen(),
        ],
      ),
    );
  }
}