import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditBankScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Bank Information'),
      ),
      body: BankInfoList(),
    );
  }
}

class BankInfoList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _getBankInfoStream(context),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return AddNewBankInfo();
        }
        return ListView.builder(
          itemCount: snapshot.data?.docs.length,
          itemBuilder: (context, index) {
            var doc = snapshot.data?.docs[index];
            return ListTile(
              title: Text(doc?['bankName']),
              subtitle: Text(doc?['transitNumber'] + ', ' + doc?['branch']),
              trailing: IconButton(
                icon: Icon(Icons.delete),
                onPressed: () => _deleteBankInfo(context, doc?.id),
              ),
            );
          },
        );
      },
    );
  }

  Stream<QuerySnapshot> _getBankInfoStream(BuildContext context) async* {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userEmail = prefs.getString('email');

    if (userEmail == null) {
      print('User email not found in shared preferences.');
      return;
    }

    yield* FirebaseFirestore.instance
        .collection('banks')
        .where('userEmail', isEqualTo: userEmail)
        .snapshots();
  }

  void _deleteBankInfo(BuildContext context, String? docId) async {
    try {
      await FirebaseFirestore.instance.collection('banks').doc(docId).delete();
      print('Bank information deleted from Firebase');
    } catch (e) {
      print('Error deleting bank information: $e');
      // Handle error as needed
    }
  }
}

class AddNewBankInfo extends StatelessWidget {
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _transitNumberController = TextEditingController();
  final TextEditingController _branchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _bankNameController,
            decoration: InputDecoration(
              labelText: 'Bank Name',
              prefixIcon: Icon(Icons.account_balance),
            ),
          ),
          SizedBox(height: 20),
          TextFormField(
            controller: _transitNumberController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Transit Number',
              prefixIcon: Icon(Icons.format_list_numbered),
            ),
          ),
          SizedBox(height: 20),
          TextFormField(
            controller: _branchController,
            decoration: InputDecoration(
              labelText: 'Branch',
              prefixIcon: Icon(Icons.location_on),
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              _saveBankInfo(context);
            },
            style: ButtonStyle(
              side: MaterialStateProperty.all(BorderSide(color: Colors.black)),
              backgroundColor: MaterialStateProperty.all(Colors.white),
              elevation: MaterialStateProperty.all(0), // Remove elevation
            ),
            child: Text('Save', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  void _saveBankInfo(BuildContext context) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? uid = prefs.getString('uid');

      if (uid == null) {
        print('User UID not found in shared preferences.');
        return;
      }

      String bankName = _bankNameController.text;
      String transitNumber = _transitNumberController.text;
      String branch = _branchController.text;

      // Reference to the user's document
      DocumentReference userRef = FirebaseFirestore.instance.collection('users').doc(uid);

      // Update user's document with bank information
      await userRef.set({
        'bankName': bankName,
        'transitNumber': transitNumber,
        'branch': branch,
      }, SetOptions(merge: true)); // Use merge to only update provided fields

      // Clear text fields after saving
      _bankNameController.clear();
      _transitNumberController.clear();
      _branchController.clear();

      // Show success message or navigate to another screen
      // For now, let's print a success message
      print('Bank information saved to user document in Firebase');
    } catch (e) {
      print('Error saving bank information: $e');
      // Handle error as needed
    }
  }
}
