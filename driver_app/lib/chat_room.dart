import 'package:driver_app/my_list.dart';
import 'package:driver_app/widgets/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:maps_launcher/maps_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
class ChatRoomScreen extends StatefulWidget {
  final Map<String, dynamic> chatRoom;

  ChatRoomScreen({required this.chatRoom});

  @override
  _ChatRoomScreenState createState() => _ChatRoomScreenState();
}



class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;



  @override
  void initState() {
    super.initState();
    createChatRoomIfNotExists();
  }


  bool isPickedUp = false;


  void _handlePickUp() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Order Details'),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Are you sure you want to mark this order as picked up?'),
              SizedBox(height: 10.0),

              // Display order items with images
              for (var item in widget.chatRoom['userCart'])
                Column(
                  children: [
                    Row(
                      children: [
                        Image.network(
                          'https://polskoydm.pythonanywhere.com/static/uploads/${item['image']}',
                          width: 50,
                          height: 50,
                        ),
                        SizedBox(width: 10.0),
                        Text('${item['name']} - ${item['quantity']}'),
                      ],
                    ),
                    Text('\$${widget.chatRoom['total']}'), // Display the total price
                    SizedBox(height: 10.0),
                  ],
                ),
            ],
          ),

          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Ready to Go'),
              onPressed: () async {
                // Send a GET request to mark the order as picked up
                try {
                  final response = await http.get(
                    Uri.parse(
                        'https://polskoydm.pythonanywhere.com/orderpickup/${widget
                            .chatRoom['roomName']}'),
                  );

                  print('API Response: ${response.body}'); // Print the response

                  if (response.statusCode == 200) {
                    // The request was successful, and the order has been marked as picked up
                    // You can update the UI accordingly

                    // Close the dialog
                    Navigator.of(context).pop();

                    // Update the UI or perform any other necessary actions
                    setState(() {
                      isPickedUp = true;
                    });
                    MapsLauncher.launchQuery(widget
                        .chatRoom['userAddress']);
                  } else {
                    // Handle the case where the request was not successful
                    // You can display an error message or take appropriate action
                    print(
                        'Failed to mark the order as picked up. Status code: ${response
                            .statusCode}');

                    // Close the dialog
                    Navigator.of(context).pop();
                  }
                } catch (e) {
                  // Handle any exceptions that occur during the request
                  print('Error marking the order as picked up: $e');

                  // Close the loading indicator
                  Navigator.of(context).pop();

                  // Close the dialog
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }



  void _handleDropOff() async {
    // Retrieve the user's email from SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userEmail = prefs.getString("email") ??
        ""; // Provide a default value if the email is not found

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmation'),
          content: Text(
              'Are you sure you want to mark this order as Completed?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Confirm'),
              onPressed: () async {
                // Make an API request to mark the order as done
                final response = await http.get(
                  Uri.parse(
                      'https://polskoydm.pythonanywhere.com/orderdone/${widget
                          .chatRoom['roomName']}?email=$userEmail'), // Include email as a query parameter
                );

                if (response.statusCode == 200) {
                  // Order marked as done successfully
                  // Navigate to the home screen
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                        builder: (BuildContext context) => MyOrderPage()),
                  );
                } else {
                  // Handle the error if the API request fails
                }
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
    final bool isUser = sender == 'user';
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
              color: Colors.black,
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
        iconTheme: IconThemeData(color: Colors.black), // Set the icon color to white
        title: Text(
          widget.chatRoom['roomName'],
          style: TextStyle(
            color: Colors.black, // Set the text color to white
          ),
        ),

        actions: <Widget>[
          if (!widget.chatRoom['status'].toLowerCase().contains("done"))
          // Conditionally display the "Pick Up" button
            if (!isPickedUp)
              TextButton(
                onPressed: () {
                  // Add your logic for handling the "Pick Up" action here
                  _handlePickUp();
                },
                child: Text(
                  "Pick Up",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18.0,
                  ),
                ),
              ),
          if (isPickedUp)
            TextButton(
              onPressed: () {
                // Add your logic for handling the "Drop Off" action here
                _handleDropOff();
              },
              child: Text(
                "Drop Off",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18.0,
                ),
              ),
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
                    launch("tel:${widget.chatRoom['userPhone']}");
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
                        'sender': 'driver',
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