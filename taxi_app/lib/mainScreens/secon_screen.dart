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
      appBar: AppBar(
        title: Row(
          children: [
            Text(isSaved ? 'Saved Slots' : 'Schedule'),
            Spacer(),
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
      body: isSaved ? SavedScheduleList() : SlotList(), // Display SavedScheduleList or SlotList based on isSaved value
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
      title: Text(data['day']),
      subtitle: Row(
        children: [
          Expanded(
            child: Text('Clock In: ${data['clockIn']}'),
          ),
          Expanded(
            child: Text('Clock Out: ${data['clockOut']}'),
          ),
          IconButton(
            icon: Icon(Icons.archive),
            onPressed: () {
              _moveToSaved(context, data);
            },
          ),
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
      title: Text(data['day']),
      subtitle: Row(
        children: [
          Expanded(
            child: Text('Clock In: ${data['clockIn']}'),
          ),
          Expanded(
            child: Text('Clock Out: ${data['clockOut']}'),
          ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () {
              _deleteSchedule(context, docId);
            },
          ),
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
