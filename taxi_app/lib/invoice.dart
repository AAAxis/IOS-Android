import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxi_app/authentication/auth_screen.dart';
import 'package:url_launcher/url_launcher.dart';

import 'global/global.dart';


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Invoice Generator',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            textStyle: TextStyle(fontSize: 16),
            padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.blue,
            side: BorderSide(color: Colors.blue),
            padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Colors.blue,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        ),
      ),
      home: InvoiceGenerator(),
    );
  }
}

class InvoiceGenerator extends StatefulWidget {
  @override
  _InvoiceGeneratorState createState() => _InvoiceGeneratorState();
}

class _InvoiceGeneratorState extends State<InvoiceGenerator> with SingleTickerProviderStateMixin {
  bool _uploadingImage = false;

  File? _pickedImage;
  late SharedPreferences _prefs;
  late TabController _tabController;
  String? _imageUrl;

  List<TextEditingController> itemNameControllers = []; // Define itemNameControllers here

  TextEditingController businessNameController = TextEditingController();
  TextEditingController businessLocationController = TextEditingController();
  TextEditingController businessPhoneController = TextEditingController();

  TextEditingController customerNameController = TextEditingController();
  TextEditingController customerLocationController = TextEditingController();
  TextEditingController customerPhoneController = TextEditingController();
  TextEditingController totalController = TextEditingController();

  TextEditingController emailController = TextEditingController();
  List<Map<String, String>> items = [{'itemName': '', 'quantity': '1'}];
  String selectedDate = '';



  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 2, vsync: this);

    // Adding a delay of 1 second (adjust the duration as needed)
    Future.delayed(Duration(seconds: 1), () {
      _initSharedPreferences();
    });
  }






  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }


  Future<void> _pickImage() async {
    final pickedImageFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedImageFile != null) {
      setState(() {
        _pickedImage = File(pickedImageFile.path);
      });
      // Upload the picked image to Firebase Storage
      _uploadImageToFirebase(); // No need to await here
    }
  }
  Future<String?> _uploadImageToFirebase() async {
    if (_pickedImage == null) {
      return null; // Return null if no image is picked
    }

    try {
      final firebase_storage.Reference storageReference = firebase_storage.FirebaseStorage.instance
          .ref()
          .child('logo_images')
          .child('image_${DateTime.now().millisecondsSinceEpoch}.jpg');

      // Upload the image file
      final uploadTask = storageReference.putFile(_pickedImage!);

      // Wait for the upload task to complete
      final taskSnapshot = await uploadTask;

      // Get the download URL of the uploaded image
      final imageUrl = await storageReference.getDownloadURL();

      setState(() {
        _imageUrl = imageUrl; // Update the _imageUrl variable
      });

      return imageUrl; // Return the image URL
    } catch (e) {
      print('Error uploading image to Firebase Storage: $e');
      return null;
    }
  }

  Future<void> _initSharedPreferences() async {
    setState(() {
      businessNameController.text = sharedPreferences!.getString("name") ?? "No Name";
      businessLocationController.text = sharedPreferences!.getString("address") ?? "No Address";
      businessPhoneController.text = sharedPreferences!.getString("phone") ?? "No Phone";
      customerNameController.text = '';
      customerLocationController.text = '';
      customerPhoneController.text = '+972';
      totalController.text = '5';
      emailController.text = sharedPreferences!.getString("email") ?? "No Email";
      selectedDate = DateTime.now().toIso8601String().split('T')[0]; // Prefill selectedDate with today's date
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Invoice Generator'),
        leading: IconButton(
          icon: Icon(Icons.library_books_sharp),
          onPressed: () {
           // This pops the current route off the navigator stack
          },
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Form'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Invoice tab content
          Container(
            padding: EdgeInsets.all(20.0),
            child: SingleChildScrollView(
              child: Column(

                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 10.0),

                  SizedBox(height: 10.0),
                  _buildSellerTile(),
                  _buildTile(
                    title: 'Add Customer',
                   // Set initiallyExpanded to true
                    children: [
                      _buildTextField('Customer Name', customerNameController),
                      _buildTextField('Customer Location', customerLocationController),
                      _buildTextFieldWithoutPrefix('Customer Phone', customerPhoneController)

                    ],
                  ),
                  _buildTile(
                    title: 'Add Products',
                    children: [
                      SizedBox(height: 20.0),
                      Row(
                        children: [


                          Expanded(
                            child: TextField(
                              controller: totalController,
                              keyboardType: TextInputType.number, // Set keyboard type to numeric
                              decoration: InputDecoration(labelText: 'Total'),
                            ),
                          ),


                          IconButton(
                            icon: Icon(Icons.add),
                            onPressed: () {
                              setState(() {
                                int total = int.tryParse(totalController.text) ?? 0;
                                total++;
                                totalController.text = total.toString();
                              });
                            },
                          ),
                        ],
                      ),
                      ...items.asMap().entries.map((entry) => _buildItemRow(entry.value, entry.key)).toList(),
                      _buildAddItemButton(),

                    ],
                  ),
                  _buildTileWithImagePicker(
                    title: 'Options',
                    children: [
                        _buildTextField('Email', emailController),
                      _buildDateTextField('Date', selectedDate, context),

                    ],
                  ),
                  SizedBox(height: 20.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: _uploadingImage ? null : _saveData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _uploadingImage ? Colors.grey : Colors.black,
                        ),
                        child: _uploadingImage
                            ? SizedBox(
                          width: 24.0,
                          height: 24.0,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                            : Text(
                          'Generate PDF',
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ),

                    ],
                  ),
                ],
              ),
            ),
          ),

          // History tab content
          HistoryScreen(),
        ],
      ),
    );
  }

  Widget _buildTile({required String title, required List<Widget> children}) {
    return ExpansionTile(
      title: Text(
        title,
        style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
      ),
      initiallyExpanded: true,
      children: [
        ...children,
      ],
    );
  }

  Widget _buildSellerTile() {
    return _buildTile(
      title: 'Seller Info',
      children: [
        SellerInfoWidget(
          businessName: businessNameController.text,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SellerEditScreen(
                  // Pass necessary data to the edit screen
                  businessName: businessNameController.text,
                  businessLocation: businessLocationController.text,
                  businessPhone: businessPhoneController.text,
                  onSave: (String newName, String newLocation, String newPhone) {
                    setState(() {
                      businessNameController.text = newName;
                      businessLocationController.text = newLocation;
                      businessPhoneController.text = newPhone;
                    });
                  },
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
    );
  }

  Widget _buildTextFieldWithoutPrefix(String label, TextEditingController controller) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(labelText: label),
          ),
        ),
      ],
    );
  }



  Widget _buildDateTextField(String label, String date, BuildContext context) {
    return InkWell(
      onTap: () => _selectDate(context),
      child: IgnorePointer(
        child: TextField(
          controller: TextEditingController(text: date),
          decoration: InputDecoration(labelText: label),
        ),
      ),
    );
  }
  Widget _buildItemRow(Map<String, String> item, int index) {
    TextEditingController itemNameController =
    TextEditingController(text: item['itemName']);
    int quantity = int.tryParse(item['quantity'] ?? '1') ?? 1;

    // Ensure the itemNameControllers list has enough controllers for all items
    while (itemNameControllers.length <= index) {
      itemNameControllers.add(TextEditingController());
    }

    // Update the controller for the current item
    itemNameControllers[index].text = item['itemName'] ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              flex: 4,
              child: TextField(
                controller: itemNameControllers[index],
                onChanged: (value) {
                  setState(() {
                    items[index]['itemName'] = value;
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Item Name',
                  labelStyle: TextStyle(color: Colors.black),
                ),
                style: TextStyle(color: Colors.black),
                textInputAction: TextInputAction.next,
              ),
            ),
            SizedBox(width: 10.0),
            Expanded(
              child: DropdownButtonFormField<int>(
                value: quantity,
                decoration: InputDecoration(
                  labelText: 'Quantity',
                  labelStyle: TextStyle(color: Colors.black),
                ),
                items: List.generate(5, (index) => index + 1)
                    .map((quantity) => DropdownMenuItem<int>(
                  value: quantity,
                  child: Text(
                    quantity.toString(),
                    style: TextStyle(color: Colors.black),
                  ),
                ))
                    .toList(),
                style: TextStyle(color: Colors.black),
                onChanged: (int? value) {
                  setState(() {
                    items[index]['quantity'] = value.toString();
                  });
                },
              ),
            ),
            IconButton(
              icon: Icon(Icons.remove_circle),
              onPressed: () {
                setState(() {
                  items.removeAt(index);
                  itemNameControllers.removeAt(index);
                });
              },
            ),
          ],
        ),
        SizedBox(height: 10.0),

      ],
    );
  }


  Widget _buildAddItemButton() {
    return TextButton(
      onPressed: () {
        setState(() {
          // Initialize a new item with only 'quantity' set to a default value
          items.add({'itemName': '', 'quantity': '1'});
          // Add a corresponding itemNameController to the itemNameControllers list
          itemNameControllers.add(TextEditingController());
        });

      },
      child: Text('Add Item'),
    );
  }


  Widget _buildTileWithImagePicker({required String title, required List<Widget> children}) {
    return ExpansionTile(
      title: Text(
        title,
        style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
      ),
      children: [
        ...children,

        SizedBox(height: 20.0),
        ElevatedButton(
          onPressed: () async {
            await _pickImage();
          },
          child: Text('Pick Logo'),
        ),
        SizedBox(height: 20.0),
        if (_uploadingImage) // Display the animation only if uploading is in progress
          Center(
            child: CircularProgressIndicator(),
          ),
        if (_imageUrl != null) // Check if image URL is available
          Container(
            width: 150, // Set the desired width
            height: 150, // Set the desired height
            child: Image.network(_imageUrl!), // Display the selected image using Image.network
          ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      setState(() {
        selectedDate = pickedDate.toIso8601String().split('T')[0]; // Extracting only date part
      });
    }
  }

  bool _isValidEmail(String email) {
    final RegExp regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return regex.hasMatch(email);
  }

  bool _isValidPhone(String phone) {
    final RegExp regex = RegExp(r'^\+\d{11}$');
    return regex.hasMatch(phone);
  }



  Future<void> _saveData() async {
    if (!_validateFields()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    if (!_isValidEmail(emailController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid email')),
      );
      return;
    }

    if (!_isValidPhone(businessPhoneController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid phone number')),
      );
      return;
    }

    setState(() {
      _uploadingImage = true;
    });

    try {
      String imageUrl = ''; // Initialize imageUrl variable

      if (_pickedImage != null) {
        // If image is picked, upload it to Firebase Storage and get the URL
        imageUrl = await _uploadImageToFirebase() ?? '';
      } else {
        // If image is not picked, use the online logo URL
        imageUrl = 'https://polskoydm.pythonanywhere.com/static/images/logo-color.png'; // Replace this with your online logo URL
      }

      String? uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User not authenticated. Please log in.')),
        );
        // Navigate to login page
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
        return;
      }

      Map<String, dynamic> invoiceData = {
        'businessName': businessNameController.text,
        'businessLocation': businessLocationController.text,
        'businessPhone': businessPhoneController.text,
        'customerName': customerNameController.text,
        'customerLocation': customerLocationController.text,
        'total': double.parse(totalController.text), // Include the total amount
        'customerPhone': customerPhoneController.text,
        'email': emailController.text,
        'selectedDate': selectedDate,
        'user': uid,
        'status':'open',
        'items': items,
        'imageUrl': imageUrl, // Include the image URL in invoice data
      };

      final DocumentReference docRef = await FirebaseFirestore.instance.collection('contractors').doc(uid).collection('invoices').add(invoiceData);

      // Get the document ID after adding the data
      final String docId = docRef.id;

      // Pass the document ID along with the invoice data
      await _sendInvoice(docId, invoiceData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invoice Generated Successfully')),
      );

      customerNameController.clear();
      customerLocationController.clear();
      customerPhoneController.clear();
      items.clear();
      _tabController.animateTo(1);

      // Index 1 corresponds to the History tab
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send invoice. Error: $e')),
      );
    } finally {
      setState(() {
        _uploadingImage = false;
      });
    }
  }

  Future<void> _sendInvoice(String invoiceId, Map<String, dynamic> invoiceData) async {
    try {
      // Trigger the API call to send the invoice data
      final String apiUrl = 'https://polskoydm.pythonanywhere.com/generate-pdf-and-send-email';
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({
          ...invoiceData, // Pass invoice data
          'invoiceId': invoiceId, // Pass the document ID
        }),
      );

      if (response.statusCode == 200) {
        // Handle successful API response
        print('Invoice sent successfully');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invoice sent successfully')),
        );
      } else {
        // Handle API call failure
        print('Failed to send invoice. Status code: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send invoice. Status code: ${response.statusCode}')),
        );
      }
    } catch (e) {
      // Handle API call exception
      print('Error sending invoice: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending invoice: $e')),
      );
    }
  }


  bool _validateFields() {
    if (businessNameController.text.isEmpty ||
        businessLocationController.text.isEmpty ||
        businessPhoneController.text.isEmpty ||
        customerNameController.text.isEmpty ||
        customerLocationController.text.isEmpty ||
        customerPhoneController.text.isEmpty ||
        totalController.text.isEmpty ||
        emailController.text.isEmpty ||
        selectedDate.isEmpty) {
      return false;
    }
    for (var item in items) {
      if (item['itemName']!.isEmpty) {
        return false;
      }
    }
    return true;
  }

}

class SellerEditScreen extends StatelessWidget {
  final String businessName;
  final String businessLocation;
  final String businessPhone;
  final Function(String, String, String) onSave;

  const SellerEditScreen({
    required this.businessName,
    required this.businessLocation,
    required this.businessPhone,
    required this.onSave,
  });



  @override
  Widget build(BuildContext context) {
    TextEditingController newNameController = TextEditingController(text: businessName);
    TextEditingController newLocationController = TextEditingController(text: businessLocation);
    TextEditingController newPhoneController = TextEditingController(text: businessPhone);


    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Seller'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: newNameController,
              decoration: InputDecoration(labelText: 'Business Name'),
            ),
            TextField(
              controller: newLocationController,
              decoration: InputDecoration(labelText: 'Business Location'),
            ),
            TextField(
              controller: newPhoneController,
              decoration: InputDecoration(labelText: 'Business Phone'),
              keyboardType: TextInputType.phone, // Set keyboard type to phone
                  ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                onSave(newNameController.text, newLocationController.text, newPhoneController.text);
                Navigator.pop(context);
              },
              child: Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

class SellerInfoWidget extends StatelessWidget {
  final String businessName;
  final VoidCallback onTap;

  const SellerInfoWidget({
    required this.businessName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        businessName.isEmpty ? 'Add New' : businessName,
        style: TextStyle(color: businessName.isEmpty ? Colors.grey : null),
      ),
      leading: Icon(Icons.business),
      onTap: onTap,
    );
  }
}

class HistoryScreen extends StatefulWidget {
  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late SharedPreferences _prefs;
  String? _uid;

  @override
  void initState() {
    super.initState();
    _initSharedPreferences();
  }

  Future<void> _initSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _uid = FirebaseAuth.instance.currentUser?.uid;
    });
  }


  @override
  Widget build(BuildContext context) {
    return _uid != null
        ? StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('contractors')
          .doc(_uid)
          .collection('invoices')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator(); // Show loading indicator while fetching data
        }
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Text('No records found'),
          );
        }
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final docId = docs[index].id; // Retrieve the document ID
            final status = data['status'];

            // Determine the icon and whether it's clickable based on the status
            Widget trailingIcon;
            bool clickable = true;

            if (status == 'paid') {
              trailingIcon = IconButton(
                icon: Icon(Icons.money),
                onPressed: () async {

                },
              );
            } else {
              trailingIcon = IconButton(
                icon: Icon(Icons.language),
                onPressed: () async {
                  final url =
                      'https://polskoydm.pythonanywhere.com/invoice-payment?uid=$_uid&doc=$docId&email=${data['email']}&total=${data['total']}';

                  final response = await http.get(Uri.parse('$url'));

                  if (response.statusCode == 200) {
                    final sessionUrl = jsonDecode(response.body)['sessionUrl'];

                    await launch(sessionUrl);
                  } else {
                    print('Failed to trigger API: ${response.statusCode}');
                  }
                },
              );
            }

            // Build the ListTile
            return ListTile(
              title: Text('Invoice $docId'),
              subtitle: Text('Customer: ${data['customerName']}, Total: ${data['total']} '),
              onTap: clickable
                  ? () {
                // Handle tapping on invoice item if needed
              }
                  : null,
              trailing: trailingIcon,
            );
          },
        );


      },
    )
        : Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('User not authenticated, please sign in'),
          ElevatedButton(
            onPressed: () {
              // Navigate to the login screen
              // You need to replace 'LoginScreen()' with your actual login screen widget
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            },
            child: Text('Sign In'),
          ),
        ],
      ),
    );
  }
}

