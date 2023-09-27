import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccountPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Account Page'),
      ),
      body: FutureBuilder<String?>(
        // Use FutureBuilder with a nullable String
        future: _getUserEmail(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          } else {
            final userEmail = snapshot.data;
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('User Email: ${userEmail ?? "N/A"}'),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      _clearPrefs(); // Clear SharedPreferences
                      Navigator.pop(context); // Navigate back
                    },
                    child: Text('Log Out'),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Future<String?> _getUserEmail() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_email');
  }

  Future<void> _clearPrefs() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
