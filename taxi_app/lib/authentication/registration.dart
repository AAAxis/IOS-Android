import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxi_app/authentication/contractor.dart';
import 'package:taxi_app/mainScreens/home_screen.dart';


class AddDataScreen extends StatefulWidget {
  @override
  _AddDataScreenState createState() => _AddDataScreenState();
}

class _AddDataScreenState extends State<AddDataScreen> {
  String _selectedEmploymentType = 'self-employed';

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            'Employment Type',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Radio(
                value: 'contractor',
                groupValue: _selectedEmploymentType,
                onChanged: (value) {
                  setState(() {
                    _selectedEmploymentType = value.toString();
                  });
                },
              ),
              Text('Contractor'),
              SizedBox(width: 20),
              Radio(
                value: 'self-employed',
                groupValue: _selectedEmploymentType,
                onChanged: (value) {
                  setState(() {
                    _selectedEmploymentType = value.toString();
                  });
                },
              ),
              Text('Self-employed'),
            ],
          ),
          SizedBox(height: 20),
          Card(
            child: ListTile(
              leading: Icon(Icons.work),
              title: Text('Contractor'),
              subtitle:
              Text('As a contractor project based, We request addiction information to open wallet based on your ID'),
            ),
          ),
          SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: Icon(Icons.business),
              title: Text('Self-employed'),
              subtitle: Text('As a self-employed individual, you run your own business.'),
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              if (_selectedEmploymentType == 'contractor') {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  final userDocRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
                  await userDocRef.update({'status': 'contractor'});
                }
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.setString('status', 'contractor');

                // Navigate to the Contractor page
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FirstPage()),
                );
              } else {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  final userDocRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
                  await userDocRef.update({'status': 'self-employed'});
                }
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.setString('status', 'self-employed');

                // Navigate to the MyHomePage page
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MyHomePage()),
                );
              }
            },
            child: Text('Next'),
          ),
        ],
      ),
    );
  }
}
