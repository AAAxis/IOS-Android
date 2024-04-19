import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore package
import 'package:intl/intl.dart'; // Import intl package for date formatting
import 'package:awesome_notifications/awesome_notifications.dart'; // Import Awesome Notifications package
import 'package:shared_preferences/shared_preferences.dart'; // Import shared_preferences package

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  late Stream<QuerySnapshot> _notificationsStream; // Define a stream of notifications
  Set<String> _readNotifications = {}; // Set to store IDs of read notifications

  @override
  void initState() {
    super.initState();
    _requestNotificationPermission();
    _initializeNotificationsStream(); // Initialize the stream// Request permission for notifications
    _loadReadNotifications(); // Load read notifications from shared preferences
  }

  void _initializeNotificationsStream() {
    _notificationsStream = FirebaseFirestore.instance
        .collection('notifications')
        .orderBy('time', descending: true)
        .snapshots();

    _notificationsStream.listen((snapshot) {
      snapshot.docChanges.forEach((change) {
        if (change.type == DocumentChangeType.added) {
          final notificationData = change.doc.data() as Map<String, dynamic>;
          final id = change.doc.id;
          final title = notificationData['title'] ?? '';
          final body = notificationData['body'] ?? '';
          final time = notificationData['time']?.toDate() ?? DateTime.now();

          // Check if the notification time is in the future
          if (time.isAfter(DateTime.now())) {
            // Schedule a notification only if it's in the future
            _scheduleNotification(id, title, body, time);
          } else {
            // If the notification is in the past, mark it as read
            setState(() {
              _readNotifications.add(id);
            });
          }
        }
      });
    });
  }

  void _requestNotificationPermission() {
    AwesomeNotifications().requestPermissionToSendNotifications();
  }

  Future<void> _loadReadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final readIds = prefs.getStringList('readNotifications') ?? [];
    setState(() {
      _readNotifications = readIds.toSet();
    });
  }

  Future<void> _saveReadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList('readNotifications', _readNotifications.toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _notificationsStream, // Use the stream
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final documents = snapshot.data!.docs; // Extract documents from snapshot
            final filteredDocuments = documents.where((doc) {
              final notificationData = doc.data() as Map<String, dynamic>;
              final time = notificationData['time']?.toDate() ?? DateTime.now();
              return time.isBefore(DateTime.now()); // Filter out future notifications
            }).toList();
            return ListView.builder(
              itemCount: filteredDocuments.length,
              itemBuilder: (context, index) {
                final notificationData = filteredDocuments[index].data() as Map<String, dynamic>; // Explicitly cast notification to Map<String, dynamic>
                final id = filteredDocuments[index].id; // Extract notification id
                final title = notificationData['title'] ?? ''; // Extract title
                final body = notificationData['body'] ?? ''; // Extract body
                final time = notificationData['time']?.toDate() ?? DateTime.now(); // Convert Firebase Timestamp to DateTime

                final formattedTime = DateFormat('MMM dd, yyyy hh:mm a').format(time); // Format time to display without seconds
                final isRead = _readNotifications.contains(id); // Check if notification is read

                return ListTile(
                  leading: Icon(
                    isRead ? Icons.mail_outline : Icons.mail, // Use different icon based on read status
                    color: isRead ? Colors.grey : Colors.blue,
                  ),
                  title: Text(title),
                  subtitle: Text(formattedTime), // Display formatted time (date and time without seconds)
                  onTap: () {
                    _showNotificationDialog(body);
                    setState(() {
                      _toggleReadStatus(id); // Toggle read status locally
                    });
                  },
                );
              },
            );
          }
        },
      ),
    );
  }

  Future<void> _showNotificationDialog(String body) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Notification'),
          content: SingleChildScrollView(
            child: Text(body),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _toggleReadStatus(String id) {
    if (_readNotifications.contains(id)) {
      _readNotifications.remove(id); // Mark as unread
    } else {
      _readNotifications.add(id); // Mark as read
    }
    _saveReadNotifications(); // Save read notifications to shared preferences
  }

  void _scheduleNotification(String id, String title, String body, DateTime notificationTime) async {
    final now = DateTime.now();
    if (notificationTime.isAfter(now)) {
      final notificationId = _generateNotificationId(id); // Generate a valid notification ID
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: notificationId,
          channelKey: 'alerts',
          title: title,
          body: body,
        ),
        schedule: NotificationCalendar(
          weekday: notificationTime.weekday,
          hour: notificationTime.hour,
          minute: notificationTime.minute,
        ),
      );
    }
  }

  int _generateNotificationId(String id) {
    // Generate a unique integer ID based on the string ID
    final uniqueId = id.hashCode.abs();
    return uniqueId;
  }

}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: NotificationScreen(),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AwesomeNotifications().initialize(
    'resource://drawable/logo',
    [
      NotificationChannel(
        channelKey: 'alerts',
        channelName: 'Alerts',
        channelDescription: 'Notification channel for basic notifications',
        defaultColor: Color(0xFF9D50DD),
        ledColor: Colors.white,
      )
    ],
  );
  runApp(MyApp());
}

