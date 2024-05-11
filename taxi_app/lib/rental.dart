
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
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
  await launch(url);
}

class _RentalScreenState extends State<RentalScreen> {
  late Stream<QuerySnapshot> _rentalsStream;

  @override
  void initState() {
    super.initState();
    // Initialize stream to listen for changes in user's rentals
    _rentalsStream = FirebaseFirestore.instance
        .collection('contractors')
        .doc(user!.uid)
        .collection('rentals')
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rental Options'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Image.asset(
            'images/moto.png',
            fit: BoxFit.cover,
            height: 300.0,
            width: MediaQuery.of(context).size.width,
          ),
          SizedBox(height: 20),
          _buildStartApplicationButton(), // Call method to build the button
          SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _rentalsStream,
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text('No rentals found.'),
                  );
                }

                // Display rentals in a ListView
                return ListView(
                  children: snapshot.data!.docs.map((DocumentSnapshot document) {
                    Map<String, dynamic> rental = document.data() as Map<String, dynamic>;
                    // Convert 'date' string to DateTime object
                    DateTime rentalDate = DateTime.parse(rental['date']);
                    // Format date to display only date without time
                    String formattedDate = '${rentalDate.day}/${rentalDate.month}/${rentalDate.year}';
                    return ListTile(
                      leading: Image.asset(
                        'images/honda.png', // Replace 'your_fixed_image.jpg' with your actual image path
                        width: 80, // Adjust width as needed
                        height: 50, // Adjust height as needed
                        fit: BoxFit.cover, // Adjust fit as needed
                      ),
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(rental['type']),
                          Text('Location: ${rental['location']}'),
                        ],
                      ),
                      subtitle: Text('Date: $formattedDate'),
                    );
                  }).toList(),
                );

              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartApplicationButton() {
    if (_rentalsStream != null) {
      return StreamBuilder<QuerySnapshot>(
        stream: _rentalsStream,
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
            // If there are existing rentals, hide the button
            return SizedBox.shrink(); // Return an empty SizedBox to hide
          } else {
            // If there are no existing rentals, show the button
            return Center(
              child: OutlinedButton(
                onPressed: _openBottomSheet,
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                  textStyle: TextStyle(fontSize: 14),
                ),
                child: Text('Start Application'),
              ),
            );
          }
        },
      );
    } else {
      // Default behavior, show the button
      return Center(
        child: OutlinedButton(
          onPressed: _openBottomSheet,
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            textStyle: TextStyle(fontSize: 14),
          ),
          child: Text('Start Application'),
        ),
      );
    }
  }

  // Other methods remain unchanged

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
                          'Check Availability',
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
                          suffixIcon: Icon(Icons.directions_bike),
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
                            if (pickedDate != null &&
                                pickedDate != _selectedDate) {
                              setState(() {
                                _selectedDate = pickedDate;
                              });
                            }
                          },
                          decoration: InputDecoration(
                            hintText: '${_selectedDate?.toLocal()}'.split(' ')[0],
                            border: InputBorder.none,
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
                                      _launchURL('https://theholylabs.com/privacy');
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
                        // Close the bottom sheet
                        Navigator.pop(context);

                        if (_selectedLocation != null &&
                            _selectedDate != null &&
                            _termsAndConditionsAccepted) {
                          _submitData(context);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Please select location, date, and verify terms and conditions.',
                              ),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                      ),
                      child: Text(
                        'Apply',
                        style: TextStyle(color: Colors.white),
                      ),
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

  void _submitData(BuildContext context) async {
    try {
      // Check if the user is signed in
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Formulate your rental data
        Map<String, dynamic> rentalData = {
          'type': _selectedVehicleType,
          'location': _selectedLocation,
          'date': _selectedDate?.toIso8601String(),
          // Add other data fields as needed
        };

        // Access Firestore instance and add rental data to user's subcollection
        await FirebaseFirestore.instance
            .collection('contractors')
            .doc(user.uid)
            .collection('rentals')
            .add(rentalData);

        print('Rental data submitted to Firestore');


        // Display a snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Application submitted successfully!'),
          ),
        );
      } else {
        // User is not signed in, handle accordingly
        print('User is not signed in');
      }
    } catch (e) {
      print('Error submitting data to Firestore: $e');
    }
  }
}
