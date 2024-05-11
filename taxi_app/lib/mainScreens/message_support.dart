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

  Future<void> _deleteMessage(String messageId) async {
    try {
      await FirebaseFirestore.instance
          .collection('contractors')
          .doc(_chatRoomId)
          .collection('messages')
          .doc(messageId)
          .delete();
    } catch (e) {
      print('Error deleting message: $e');
      // Handle error accordingly
    }
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        backgroundImage: AssetImage(
                            'images/profile.png'), // Placeholder image
                        radius: 24,
                      ),
                      SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Support', // Placeholder name
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '+16474724580', // Placeholder phone number
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 30),
            Expanded(
              child: StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('contractors')
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
                      messages =
                          data?.docs.cast<QueryDocumentSnapshot<Map<String, dynamic>>>();
                    }
                  }

                  return ListView.builder(
                    reverse: false,
                    itemCount: messages?.length ?? 0,
                    itemBuilder: (context, index) {
                      final message = messages?[index];
                      if (message != null) {
                        final String text = message['text'];
                        final String sender = message['sender'];
                        final String messageId = message.id;

                        return Dismissible(
                          key: Key(messageId),
                          direction: DismissDirection.horizontal,
                          background: Container(
                            color: Colors.red,
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            alignment: Alignment.centerLeft,
                            child: Icon(Icons.delete, color: Colors.white),
                          ),
                          onDismissed: (direction) {
                            _deleteMessage(messageId);
                          },
                          child: _buildMessageWidget(sender, text),
                        );
                      } else {
                        return SizedBox();
                      }
                    },
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
                            .collection('contractors')
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
