import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Import http package
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:taxi_app/mainScreens/documents.dart';
import 'package:taxi_app/mainScreens/home_screen.dart';
import 'package:taxi_app/mainScreens/navigation.dart';
import 'package:url_launcher/url_launcher.dart';

class RentalScreen extends StatefulWidget {
  @override
  _RentalScreenState createState() => _RentalScreenState();
}

String? _selectedLocation = 'Get-Moto Tel Aviv'; // Set default location to Tel Aviv
DateTime? _selectedDate = DateTime.now(); // Set default date to today
String? _selectedVehicleType = 'Honda PCX 2023'; // New field for vehicle type
bool _termsAndConditionsAccepted = false;
User? user = FirebaseAuth.instance.currentUser;


// Function to launch the URL
void _launchURL(String url) async {
  if (await launch(url)) {
    await launch(url);
  } else {
    throw 'Could not launch $url';
  }
}


class _RentalScreenState extends State<RentalScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rental Motorcycle'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Image.asset(
            'images/moto.png',
            fit: BoxFit.cover,
            height: 300.0,
            width: MediaQuery.of(context).size.width, // Ensure image takes full width
          ),
        // Assuming you have access to FirebaseAuth instance



          Flexible(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance.collection('driver_license')
                  .where('user_email', isEqualTo: user?.email) // Filter by user's email
                  .snapshots(),
              builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'We collect driver license for our rental service to provide you with the best experience and ensure your safety. Thank you for your cooperation!',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => DriverLicenseScreen()),
                            );
                          },
                          child: Text('Add Document'),
                        ),
                        SizedBox(height: 16),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (BuildContext context, int index) {
                    DocumentSnapshot document = snapshot.data!.docs[index];
                    Map<String, dynamic> data = document.data() as Map<String, dynamic>;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            '    Please select a driver license to continue',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        ListTile(
                          onTap: () {
                            _openBottomSheet();
                          },
                          leading: Image.network(
                            data['image_url'],
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          ),
                          title: Text('Number: ${data['number']}'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Name: ${data['name']}'),
                              Text('DOB: ${data['dob']}'),
                            ],
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () {
                              _deleteDocument(document.id);
                            },
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return FractionallySizedBox(
          heightFactor: 0.6, // Set height to 60% of the screen height
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 5,
                  spreadRadius: 5,
                ),
              ],
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title and Close Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Reservation',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                    // Location Dropdown
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Pickup Location:',
                          suffixIcon: Icon(Icons.location_on),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedLocation,
                            isDense: true,
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedLocation = newValue;
                              });
                            },
                            items: ['Get-Moto Haifa', 'Get-Moto Tel Aviv']
                                .map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16.0),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Vehicle Type:',
                          suffixIcon: Icon(Icons.directions_bike), // You can change the icon accordingly
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedVehicleType,
                            isDense: true,
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedVehicleType = newValue;
                              });
                            },
                            items: [
                              'Honda PCX 2023', // Add more vehicle types here
                            ].map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                    // Calendar Selection
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Select Date:',
                        ),
                        child: TextFormField(
                          readOnly: true,
                          onTap: () async {
                            final DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate!,
                              firstDate: DateTime.now(),
                              lastDate: DateTime(DateTime.now().year + 1),
                            );
                            if (pickedDate != null && pickedDate != _selectedDate) {
                              setState(() {
                                _selectedDate = pickedDate;
                              });
                            }
                          },
                          decoration: InputDecoration(
                            hintText: '${_selectedDate?.toLocal()}'.split(' ')[0],
                            border: InputBorder.none, // Remove the border
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16.0),
                    // Checkbox for terms and conditions
                    Row(
                      children: [
                        StatefulBuilder(
                          builder: (BuildContext context, StateSetter setState) {
                            return Checkbox(
                              value: _termsAndConditionsAccepted,
                              onChanged: (bool? value) {
                                setState(() {
                                  _termsAndConditionsAccepted = value ?? false;
                                });
                              },
                            );
                          },
                        ),
                        Flexible(
                          child: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: 'I understand ',
                                  style: TextStyle(color: Colors.black),
                                ),
                                TextSpan(
                                  text: 'terms and conditions',
                                  style: TextStyle(
                                    color: Colors.blue,
                                    decoration: TextDecoration.underline,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      _launchURL('https://theholylabs.com/privacy'); // Replace the URL with your terms and conditions URL
                                    },
                                ),
                              ],
                            ),
                          ),
                        ),

                      ],
                    ),
                    SizedBox(height: 16.0),
                    ElevatedButton(
                      onPressed: () {
                        if (_selectedLocation != null &&
                            _selectedDate != null &&
                            _termsAndConditionsAccepted) {
                          _submitData(); // Call function to submit data
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Please select location, date, and verify age.'),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black, // Change button color to black
                      ),
                      child: Text('Apply', style: TextStyle(color: Colors.white)), // Change text color to white
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _submitData() async {
    try {
      // Get the current user's email from Firebase Auth
      User? user = FirebaseAuth.instance.currentUser;
      String? email = user?.email;

      // Check if the user is signed in
      if (email != null) {
        // Formulate your API request payload here
        Map<String, dynamic> requestData = {
          'email': email,
          'type': _selectedVehicleType,
          'location': _selectedLocation,
          'date': _selectedDate?.toIso8601String(),
          // Add other data fields as needed
        };

        // Perform the API request
        var response = await http.post(
          Uri.parse('https://polskoydm.pythonanywhere.com/rental'),
          body: jsonEncode(requestData),
          headers: {'Content-Type': 'application/json'},
        );

        // Check response status
        if (response.statusCode == 200) {
          // Request successful, handle response data here
          print('API Request Successful');
          print('Response: ${response.body}');
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => Navigation()),
          );
          // You can also navigate or show a success message here
        } else {
          // Request failed, handle error
          print('API Request Failed');
          print('Response Code: ${response.statusCode}');
          print('Response Body: ${response.body}');

          // Handle error accordingly, e.g., show a snackbar
        }
      } else {
        // User is not signed in, handle accordingly
        print('User is not signed in');
        // You may want to navigate the user to sign in or show an error message
      }
    } catch (e) {
      print('Error submitting data: $e');
      // Handle error accordingly, e.g., show a snackbar
    }
  }

  Future<void> _deleteDocument(String documentId) async {
    try {
      await FirebaseFirestore.instance.collection('driver_license').doc(documentId).delete();
    } catch (e) {
      print('Error deleting document: $e');
      // Handle error accordingly, e.g., show a snackbar
    }
  }
}