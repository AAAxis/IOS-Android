import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../global/global.dart';

void main() {
  runApp(MaterialApp(
    home: ScheduleScreen(),
  ));
}

class ScheduleScreen extends StatefulWidget {
  @override
  _ScheduleScreenState createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  bool isSaved = false;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 50.0, left: 20.0, right: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isSaved ? 'Saved Slots' : 'Schedule',
                  style: TextStyle(fontSize: 27),
                ),
                Switch(
                  value: isSaved,
                  onChanged: (value) {
                    setState(() {
                      isSaved = value;
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: isSaved ? SavedScheduleList() : SlotList(),
          ),
        ],
      ),
    );
  }

}

class SlotList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('schedules').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        List<DocumentSnapshot> documents = snapshot.data!.docs;
        return ListView.builder(
          itemCount: documents.length,
          itemBuilder: (context, index) {
            return SlotRow(data: documents[index].data() as Map<String, dynamic>);
          },
        );
      },
    );
  }
}

class SlotRow extends StatelessWidget {
  final Map<String, dynamic> data;

  SlotRow({required this.data});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        data['day'],
        style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'From: ${data['clockIn']} to ${data['clockOut']}',
                  style: TextStyle(fontSize: 14.0),
                ),
                Text(
                  '${data['provider']}',
                  style: TextStyle(fontSize: 12.0),
                ),

              ],
            ),
          ),

          SizedBox(width: 8.0),
          IconButton(
            icon: Icon(Icons.archive),
            onPressed: () {
              _moveToSaved(context, data);
            },
          ),
         // Add some space between elements

        ],
      ),
    );
  }

  void _moveToSaved(BuildContext context, Map<String, dynamic> data) async {
    try {
      // Retrieve UID from preferences
      String? uid =  sharedPreferences!.getString("uid") ?? "None";// Replace with your method to get UID from preferences

      if (uid != null) {
        // Construct the path to the subcollection
        String subcollectionPath = 'users/$uid/slot';

        // Add the schedule to the subcollection
        await FirebaseFirestore.instance.collection(subcollectionPath).add(data);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Schedule moved to Saved Slots')),
        );
      } else {
        // Handle case where UID is null
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('UID is null, unable to save schedule')),
        );
      }
    } catch (e) {
      print('Error moving schedule: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error moving schedule')),
      );
    }
  }

}

class SavedScheduleList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: Future<String>.value(sharedPreferences!.getString("uid") ?? "None"), // Convert String to Future<String>
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || snapshot.data == "None") {
          return Center(child: Text('Error: Unable to fetch UID'));
        }
        String uid = snapshot.data!;

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('users/$uid/slot').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            List<DocumentSnapshot> documents = snapshot.data!.docs;
            return ListView.builder(
              itemCount: documents.length,
              itemBuilder: (context, index) {
                return SavedScheduleRow(data: documents[index].data() as Map<String, dynamic>, docId: documents[index].id);
              },
            );
          },
        );
      },
    );
  }
}

class SavedScheduleRow extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;

  SavedScheduleRow({required this.data, required this.docId});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        data['day'],
        style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'From: ${data['clockIn']} to ${data['clockOut']}',
                  style: TextStyle(fontSize: 14.0),
                ),
                Text(
                  '${data['provider']}',
                  style: TextStyle(fontSize: 12.0),
                ),

              ],
            ),
          ),

          SizedBox(width: 8.0),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () {
              _deleteSchedule(context, docId);
            },
          ),
          // Add some space between elements

        ],
      ),
    );

  }

  void _deleteSchedule(BuildContext context, String docId) async {
    try {
      // Retrieve UID from preferences
      String? uid = sharedPreferences!.getString("uid");

      if (uid != null) {
        // Construct the path to the document in the subcollection
        String documentPath = 'users/$uid/slot/$docId';

        // Delete the document
        await FirebaseFirestore.instance.doc(documentPath).delete();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Schedule deleted')),
        );
      } else {
        // Handle case where UID is null
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('UID is null, unable to delete schedule')),
        );
      }
    } catch (e) {
      print('Error deleting schedule: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting schedule')),
      );
    }
  }

}
