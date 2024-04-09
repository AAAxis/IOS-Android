import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
      body: ScheduleList(isSaved: isSaved),
    );
  }
}

class ScheduleList extends StatelessWidget {
  final bool isSaved;

  ScheduleList({required this.isSaved});

  @override
  Widget build(BuildContext context) {
    return isSaved ? SavedScheduleList() : UnsavedScheduleList();
  }
}

class UnsavedScheduleList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 6,
      itemBuilder: (context, index) {
        return ScheduleRow(day: index);
      },
    );
  }
}

class SavedScheduleList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String email = user.email ?? "";
      return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('schedules')
            .where('email', isEqualTo: email)
            .snapshots(),
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
    } else {
      return Center(child: Text('User not authenticated'));
    }
  }
}

class ScheduleRow extends StatelessWidget {
  final int day;

  ScheduleRow({required this.day});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(_getDayName(day)),
      subtitle: Row(
        children: [
          Expanded(
            child: Text('Clock In: 08:00 AM'),
          ),
          Expanded(
            child: Text('Clock Out: 05:00 PM'),
          ),
          IconButton(
            icon: Icon(Icons.send),
            onPressed: () {
              _saveSchedule(context, day);
            },
          ),
        ],
      ),

    );

  }

  String _getDayName(int day) {
    switch (day) {
      case 0:
        return 'Monday';
      case 1:
        return 'Tuesday';
      case 2:
        return 'Wednesday';
      case 3:
        return 'Thursday';
      case 4:
        return 'Friday';
      case 5:
        return 'Saturday';
      default:
        return '';
    }
  }

  void _saveSchedule(BuildContext context, int day) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String email = user.email ?? "";
        Timestamp timestamp = Timestamp.now();
        await FirebaseFirestore.instance.collection('schedules').add({
          'email': email,
          'day': _getDayName(day),
          'clockIn': '08:00 AM',
          'clockOut': '05:00 PM',
          'timestamp': timestamp,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Schedule saved to Firebase')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User not authenticated')),
        );
      }
    } catch (e) {
      print('Error saving schedule: $e');
    }
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
      await FirebaseFirestore.instance.collection('schedules').doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Schedule deleted')),
      );
    } catch (e) {
      print('Error deleting schedule: $e');
    }
  }
}
