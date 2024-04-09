import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UploadScreen extends StatefulWidget {
  @override
  _UploadScreenState createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  TextEditingController typeController = TextEditingController();
  TextEditingController priceController = TextEditingController();
  TextEditingController itemNameController = TextEditingController();
  File? _imageFile;
  bool _uploading = false;
  late String userEmail;

  @override
  void initState() {
    super.initState();
    _getUserEmail();
  }

  Future<void> _getUserEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userEmail = prefs.getString('email') ?? '';
  }

  Future<void> _uploadImage(BuildContext context) async {
    setState(() {
      _uploading = true;
    });

    FirebaseStorage storage = FirebaseStorage.instance;
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    Reference reference = storage.ref().child('images/$fileName');
    UploadTask uploadTask = reference.putFile(_imageFile!);

    try {
      TaskSnapshot taskSnapshot = await uploadTask;
      String downloadUrl = await taskSnapshot.ref.getDownloadURL();

      // Save data to Firestore with timestamp
      await FirebaseFirestore.instance.collection('bills').add({
        'type': typeController.text,
        'itemName': itemNameController.text,
        'price': double.parse(priceController.text),
        'image_url': downloadUrl,
        'email': userEmail,
        'timestamp': Timestamp.now(),
      });

      // Clear controllers and image after saving
      typeController.clear();
      itemNameController.clear();
      priceController.clear();
      setState(() {
        _imageFile = null;
        _uploading = false;
      });

      // Navigate back to the display screen
      Navigator.pop(context);

    } catch (error) {
      setState(() {
        _uploading = false;
      });
      print("Error uploading image: $error");
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Upload Bill'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            GestureDetector(
              onTap: () async {
                final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
                if (pickedFile != null) {
                  setState(() {
                    _imageFile = File(pickedFile.path);
                  });
                }
              },
              child: Container(
                height: 200,
                color: Colors.grey[300],
                child: Center(
                  child: _imageFile == null
                      ? Icon(Icons.add, size: 50)
                      : Image.file(_imageFile!, height: 200),
                ),
              ),
            ),
            SizedBox(height: 20.0),
            TextField(
              controller: typeController,
              decoration: InputDecoration(
                labelText: 'Type (Gas, Repair, Equipment)',
                prefixIcon: Icon(Icons.category), // Icon for the type field
              ),
            ),
            TextField(
              controller: itemNameController,
              decoration: InputDecoration(
                labelText: 'Item Name',
                prefixIcon: Icon(Icons.shopping_basket), // Icon for the item name field
              ),
            ),
            TextField(
              controller: priceController,
              decoration: InputDecoration(
                labelText: 'Price',
                prefixIcon: Icon(Icons.attach_money), // Icon for the price field
              ),
              keyboardType: TextInputType.number,
            ),

            SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: _uploading
                  ? null
                  : () {
                if (_imageFile != null) {
                  _uploadImage(context); // Pass the context here
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please select an image.'),
                    ),
                  );
                }
              },
              child: _uploading ? CircularProgressIndicator() : Text('Upload'),
            ),

          ],
        ),
      ),
    );
  }
}

class DisplayScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bills'),
      ),
      body: FutureBuilder<String>(
        future: _getUserEmail(),
        builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final String userEmail = snapshot.data!;
          return StreamBuilder(
            stream: FirebaseFirestore.instance
                .collection('bills')
                .where('email', isEqualTo: userEmail)
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (snapshot.data!.docs.isNotEmpty) {
                return ListView(
                  children: snapshot.data!.docs.map((DocumentSnapshot document) {
                    Map<String, dynamic> data = document.data() as Map<String, dynamic>;
                    return ListTile(
                      title: Text('Type: ${data['type']}'),
                      subtitle: Text('Item Name: ${data['itemName']}, Price: \$${data['price']}'),
                      leading: Image.network(data['image_url']),
                      trailing: IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () {
                          _editBill(context, document.id, data);
                        },
                      ),
                    );
                  }).toList(),
                );
              } else {
                return Center(child: Text('No bills uploaded yet.'));
              }
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => UploadScreen()),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }

  Future<String> _getUserEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('email') ?? '';
  }

  void _editBill(BuildContext context, String documentId, Map<String, dynamic> data) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditScreen(documentId: documentId, data: data),
      ),
    );
  }
}

class EditScreen extends StatefulWidget {
  final String documentId;
  final Map<String, dynamic> data;

  EditScreen({required this.documentId, required this.data});

  @override
  _EditScreenState createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> {
  TextEditingController typeController = TextEditingController();
  TextEditingController itemNameController = TextEditingController();
  TextEditingController priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    typeController.text = widget.data['type'];
    itemNameController.text = widget.data['itemName'];
    priceController.text = widget.data['price'].toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Bill'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SizedBox(
              height: 200,
              child: Image.network(
                widget.data['image_url'], // Displaying the image from the URL
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: typeController,
              decoration: InputDecoration(
                labelText: 'Type (Gas, Repair, Equipment)',
                prefixIcon: Icon(Icons.category),
              ),
            ),
            TextField(
              controller: itemNameController,
              decoration: InputDecoration(
                labelText: 'Item Name',
                prefixIcon: Icon(Icons.shopping_basket),
              ),
            ),
            TextField(
              controller: priceController,
              decoration: InputDecoration(
                labelText: 'Price',
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () {
                    _updateBill(context);
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.black),
                  ),
                  child: Text(
                    'Save Changes',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
                SizedBox(width: 20),
                OutlinedButton(
                  onPressed: () {
                    _removeBill(context);
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.red),
                  ),
                  child: Text(
                    'Remove Record',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _updateBill(BuildContext context) async {
    await FirebaseFirestore.instance.collection('bills').doc(widget.documentId).update({
      'type': typeController.text,
      'itemName': itemNameController.text,
      'price': double.parse(priceController.text),
    });
    Navigator.pop(context);
  }

  void _removeBill(BuildContext context) async {
    await FirebaseFirestore.instance.collection('bills').doc(widget.documentId).delete();
    Navigator.pop(context);
  }
}

void main() {
  runApp(MaterialApp(
    home: DisplayScreen(),
  ));
}
