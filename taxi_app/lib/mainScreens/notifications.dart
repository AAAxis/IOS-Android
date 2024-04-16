import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

class Notify {
  static Future<List<ReceivedNotification>> fetchNotifications() async {
    final response = await http.get(Uri.parse('https://polskoydm.pythonanywhere.com/fetch_notifications'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => ReceivedNotification.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load notifications');
    }
  }
}

class ReceivedNotification {
  final int id;
  final String title;
  final String body;
  final String time;

  ReceivedNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
  });

  factory ReceivedNotification.fromJson(Map<String, dynamic> json) {
    return ReceivedNotification(
      id: json['id'],
      title: json['title'],
      body: json['body'],
      time: json['time'], // Assuming time is also returned from the API
    );
  }

  bool isPastTime() {
    final now = DateTime.now();
    final notificationTime = DateTime.parse(time);
    return notificationTime.isBefore(now); // Check if notification time is before current time
  }
}


class _NotificationScreenState extends State<NotificationScreen> {
  late Future<List<ReceivedNotification>> _notificationsFuture;
  late SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    _initializePreferences();
    _requestNotificationPermission();
    _notificationsFuture = Notify.fetchNotifications();
    _initializeNotifications();
  }


  void _requestNotificationPermission() {
    AwesomeNotifications().requestPermissionToSendNotifications();
  }

  void _initializePreferences() async {
    _prefs = await SharedPreferences.getInstance();
  }

  void _initializeNotifications() async {

    await AwesomeNotifications().initialize(
      'resource://drawable/logo',
      [
        NotificationChannel(
          channelKey: 'basic_channel',
          channelName: 'Basic notifications',
          channelDescription: 'Notification channel for basic notifications',
          defaultColor: Color(0xFF9D50DD),
          ledColor: Colors.white,
        )
      ],
    );
  }

  void _scheduleNotification(String title, String body, DateTime notificationTime) async {
    final now = DateTime.now();
    if (notificationTime.isAfter(now)) {
      final id = notificationTime.millisecondsSinceEpoch % 2147483647; // Limit id within 32-bit integer range
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: id,
          channelKey: 'basic_channel',
          title: title,
          body: body,
        ),
        schedule: NotificationCalendar(
          weekday: notificationTime.weekday,
          hour: notificationTime.hour,
          minute: notificationTime.minute,
          second: notificationTime.second,
          millisecond: notificationTime.millisecond,
        ),
      );
    }
  }

  void _markAsRead(int notificationId) {
    _prefs.setBool('notification_$notificationId', true);
  }

  bool _isNotificationRead(int notificationId) {
    return _prefs.getBool('notification_$notificationId') ?? false;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
      ),
      body: FutureBuilder<List<ReceivedNotification>>(
        future: _notificationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final notifications = snapshot.data!;
            final now = DateTime.now();
            final pastNotifications = notifications.where((notification) => notification.isPastTime()).toList();
            final futureNotifications = notifications.where((notification) => !notification.isPastTime()).toList();
            futureNotifications.forEach((notification) {
              _scheduleNotification(notification.title, notification.body, DateTime.parse(notification.time));
            });

            return ListView.builder(
              itemCount: pastNotifications.length,
              itemBuilder: (context, index) {
                final notification = pastNotifications[index];
                final bool isRead = _isNotificationRead(notification.id);
                return ListTile(
                  leading: Icon(
                    isRead ? Icons.mail_outline : Icons.mail,
                    color: isRead ? Colors.grey : Colors.blue,
                  ),
                  title: Text(notification.title),
                  subtitle: Text(notification.time.substring(11, 16)),
                  onTap: () {
                    _showNotificationDialog(notification.body);
                    _markAsRead(notification.id);
                    setState(() {});
                  },
                );
              },
            );
          }
        },
      ),
    );
  }
}

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: NotificationScreen(),
    );
  }
}

void main() {
  runApp(MyApp());
}