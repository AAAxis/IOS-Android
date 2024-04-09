import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fake Notifications',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: NotificationScreen(),
    );
  }
}

class NotificationScreen extends StatelessWidget {
  final List<String> fakeNotifications = [
    "Notification: Account created successfully",
    "Notification: Last login at 2024-04-05 09:00 AM",
    "Notification: Your Document was approved",
    "Notification: Schedule for Next week available",
    "Notification: Yango Deli deposit received: \$1440",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
      ),
      body: ListView.builder(
        itemCount: fakeNotifications.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(fakeNotifications[index]),
            onTap: () {
              // Handle notification tap
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text("Notification Details"),
                    content: Text(fakeNotifications[index]),
                    actions: <Widget>[
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text('Close'),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
