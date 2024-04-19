import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SendMessagePage extends StatefulWidget {


  @override
  _SendMessagePageState createState() => _SendMessagePageState();
}

class _SendMessagePageState extends State<SendMessagePage> {
  final TextEditingController _messageController = TextEditingController();
   late String _chatRoomId;

  @override
  void initState() {
    super.initState();
    _getChatRoomIdFromPrefs();
  }

  Future<void> _getChatRoomIdFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _chatRoomId = prefs.getString('uid') ?? '';
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat Room'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(_chatRoomId)
                    .collection('messages')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  List<QueryDocumentSnapshot<Map<String, dynamic>>>? messages = [];
                  if (snapshot.hasData) {
                    final data = snapshot.data;
                    if (data is QuerySnapshot) {
                      messages = data?.docs.cast<QueryDocumentSnapshot<Map<String, dynamic>>>();
                    }
                  }

                  List<Widget> messageWidgets = [];

                  for (var message in messages!) {
                    String text = message['text'];
                    String sender = message['sender'];

                    Widget messageWidget = _buildMessageWidget(sender, text);
                    messageWidgets.add(messageWidget);
                  }

                  return ListView(
                    reverse: true,
                    children: messageWidgets,
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.send),
                    onPressed: () {
                      String text = _messageController.text.trim();
                      if (text.isNotEmpty) {
                        FirebaseFirestore.instance
                            .collection('users')
                            .doc(_chatRoomId)
                            .collection('messages')
                            .add({
                          'sender': 'driver',
                          'text': text,
                          'timestamp': FieldValue.serverTimestamp(),
                        });
                        _messageController.clear();
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageWidget(String sender, String text) {
    final bool isUser = sender == 'user';
    final Color userColor = Colors.blue;
    final Color driverColor = Colors.green;
    final double elevation = 2.0;

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
              fontSize: 16.0,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
