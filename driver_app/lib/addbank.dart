import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:driver_app/widgets/navigation_bar.dart';



class BankInfoList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bank Information'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (c) => MainScreen()),
            );
          },
        ),
      ),
      body: Material(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Aligns children to center vertically
          children: [
            SizedBox(height: 22.0),
            Image.asset(
              "images/bank.png",
              width: 400.0,
              height: 250.0,
            ),
            SizedBox(height: 20.0),

            Expanded(
              child: StreamBuilder(
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
                          onPressed: () => _deleteBankInfo(context, doc!.id),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }



  Stream<QuerySnapshot> _getBankInfoStream(BuildContext context) async* {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? uid = prefs.getString('uid');

      if (uid != null) {
        yield* FirebaseFirestore.instance
            .collection('drivers')
            .doc(uid)
            .collection('bank')
            .snapshots();
      }
    } catch (e) {
      print('Error getting bank information stream: $e');
      // Handle error as needed
    }
  }

  void _deleteBankInfo(BuildContext context, String docId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? uid = prefs.getString('uid');

      if (uid != null) {
        await FirebaseFirestore.instance
            .collection('drivers')
            .doc(uid)
            .collection('bank')
            .doc(docId)
            .delete();
        print('Bank information deleted from Firebase');
      } else {
        print('User UID not found in shared preferences.');
      }
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
    return Scaffold(

      body: Material(
        child: ListView(
          padding: EdgeInsets.all(16.0),
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

      // Reference to the 'banks' subcollection under the user document
      CollectionReference userBankCollection = FirebaseFirestore.instance
          .collection('drivers')
          .doc(uid)
          .collection('bank');

      // Add bank information to the 'bank' subcollection under the user document
      await userBankCollection.add({
        'bankName': bankName,
        'transitNumber': transitNumber,
        'branch': branch,
        // Add more fields if needed
      });

      // Clear text fields after saving
      _bankNameController.clear();
      _transitNumberController.clear();
      _branchController.clear();

      // Show success message or navigate to another screen
      // For now, let's print a success message
      print('Bank information saved to user\'s bank collection in Firestore');
    } catch (e) {
      print('Error saving bank information: $e');
      // Handle error as needed
    }
  }
}

