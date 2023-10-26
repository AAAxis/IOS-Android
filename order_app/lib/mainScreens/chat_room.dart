import 'dart:convert';
import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:maps_launcher/maps_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'discover_screen.dart';

class ChatRoomScreen extends StatefulWidget {
  final Map<String, dynamic> chatRoom;

  ChatRoomScreen({required this.chatRoom});

  @override
  _ChatRoomScreenState createState() => _ChatRoomScreenState();
}



class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Order> orders = [];


  @override
  void initState() {
    super.initState();
    createChatRoomIfNotExists();
  }



  void _handlePickUp() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(  // Return the AlertDialog widget here
          title: Text('Order Details'),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [

              SizedBox(height: 10.0),

              // Display order items with images
              for (var item in widget.chatRoom['userCart'])
                Row(
                  children: [
                    Image.network(
                      'https://polskoydm.pythonanywhere.com/static/uploads/${item['image']}',
                      width: 50,         // Adjust the width as needed
                      height: 50,        // Adjust the height as needed
                    ),
                    SizedBox(width: 10.0),
                    Text('${item['name']} - ${item['quantity']} x \$${item['price']}'),

                  ],
                ),
              SizedBox(height: 20.0),
              Text('Total: \$' + widget.chatRoom['userTotal']),

            ],
          ),

          actions: <Widget>[
            TextButton(
              child: Text('Ok'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),

          ],
        );
      },
    );
  }


  void createChatRoomIfNotExists() async {
    // Check if the chat room exists in Firestore
    String chatRoomId = widget.chatRoom['roomName'];
    DocumentSnapshot chatRoomDoc =
    await _firestore.collection('chat_rooms').doc(chatRoomId).get();

    if (!chatRoomDoc.exists) {
      // Create the chat room in Firestore
      await _firestore.collection('chat_rooms').doc(chatRoomId).set({
        'roomName': chatRoomId,
        // Add other necessary fields here
      });
    }
  }

  Widget buildMessageWidget(String sender, String text) {
    final bool isUser = sender == 'driver';
    final Color userColor = Colors.blue;
    final Color driverColor = Colors.green;
    final double elevation = 2.0; // Adjust the elevation as needed

    final Color messageColor = isUser ? userColor : driverColor;

    return Container(
      alignment: isUser ? Alignment.centerLeft : Alignment.centerRight,
      child: Card(
        elevation: elevation,
        margin: EdgeInsets.all(10.0),
        color: messageColor,
        shape: RoundedRectangleBorder(
          borderRadius: isUser
              ? BorderRadius.only(
            topLeft: Radius.circular(16.0),
            topRight: Radius.circular(16.0),
            bottomRight: Radius.circular(16.0),
          )
              : BorderRadius.only(
            topLeft: Radius.circular(16.0),
            topRight: Radius.circular(16.0),
            bottomLeft: Radius.circular(16.0),
          ),
        ),
        child: Container(
          padding: EdgeInsets.all(14.0),
          child: Text(
            text,
            style: TextStyle(
              fontSize: (16.0),
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chatRoom['roomName']),
        actions: <Widget>[
          if (!widget.chatRoom['status'].toLowerCase().contains("done"))
          // Conditionally display the "Pick Up" button

              TextButton(
                onPressed: () {
                  // Add your logic for handling the "Pick Up" action here
                  _handlePickUp();
                },
                child: Row(
                  children: [
                    Icon(
                      Icons.archive, // Replace with the desired icon (e.g., Icons.shopping_cart)
                      color: Colors.white, // Set the icon color
                      size: 18.0, // Set the icon size
                    ),
                    SizedBox(width: 8.0), // Add spacing between the icon and text

                  ],
                )

              ),

        ],
      ),
      body: Column(
        children: <Widget>[
          // Add your additional data here (e.g., items and user address)

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Center(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.home, size: 24.0), // Add the home icon here
                        SizedBox(width: 8.0), // Add some spacing between the icon and text
                        Text(
                          widget.chatRoom['userAddress'],
                          style: TextStyle(fontSize: 16.0),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          // Add your chat functionality here (e.g., messages, text input, etc.)
          Expanded(
            child: StreamBuilder(
              stream: _firestore
                  .collection('chat_rooms')
                  .doc(widget.chatRoom['roomName'])
                  .collection('messages')
                  .orderBy('timestamp')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return CircularProgressIndicator();
                }

                List<QueryDocumentSnapshot<Map<String, dynamic>>>? messages =
                    snapshot.data?.docs;
                List<Widget> messageWidgets = [];

                for (var message in messages!) {
                  String text = message['text'];
                  String sender = message['sender'];

                  // Create a widget to display each message
                  Widget messageWidget = buildMessageWidget(sender, text);

                  messageWidgets.add(messageWidget);
                }

                return ListView(
                  children: messageWidgets,
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.phone),
                  onPressed: () {
                    // Add your logic to call the user's cell phone here
                    launch("tel:${widget.chatRoom['driverPhone']}");
                  },
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () {
                    // Send the message to Firestore
                    String text = messageController.text.trim();
                    if (text.isNotEmpty) {
                      _firestore
                          .collection('chat_rooms')
                          .doc(widget.chatRoom['roomName'])
                          .collection('messages')
                          .add({
                        'sender': 'user',
                        // You can change the sender as needed
                        'text': text,
                        'timestamp': FieldValue.serverTimestamp(),
                      });
                      messageController.clear();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}