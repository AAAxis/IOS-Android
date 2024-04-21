import 'package:flutter/material.dart';

class YourScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('QR Code'),
      ),
      body: Center(
        child: Image.network(
          'https://polskoydm.pythonanywhere.com/static/qrcode_theholylabs.com.png',
          width: 300, // Adjust width as needed
          height: 300, // Adjust height as needed
        ),
      ),
    );
  }
}
