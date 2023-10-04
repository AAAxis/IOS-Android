import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Your App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<Order> chats = [];
  final GlobalKey<ChatModalState> chatModalKey = GlobalKey<ChatModalState>();

  @override
  void initState() {
    super.initState();
    fetchChats();
  }

  Future<void> fetchChats() async {
    final apiUrl = 'https://polskoydm.pythonanywhere.com/done';

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        if (data is List) {
          final List<Order> fetchedChats =
          data.map((chatData) => Order.fromJson(chatData)).toList();
          setState(() {
            chats = fetchedChats;
          });
        } else {
          throw Exception('Failed to load chat data: Invalid response format');
        }
      } else {
        throw Exception('Failed to load chat data');
      }
    } catch (e) {
      print('Error fetching data: $e');
    }
  }

  Future<void> fetchMessagesForOrder(Order order) async {
    final apiUrl = 'https://polskoydm.pythonanywhere.com/get_messages';

    // Create the URL with query parameters
    final url = Uri.parse(apiUrl).replace(
      queryParameters: {
        'chat_id': order.id.toString(),
      },
    );

    print('Fetching messages for chat with ID ${order.id}');

    try {
      final response = await http.get(url);

      // Print the response data
      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        if (data is List) {
          final List<Message> messages =
          data.map((messageData) => Message.fromJson(messageData)).toList();
          setState(() {
            // Update the messages for the selected Order
            order.messages = messages;
          });
        } else {
          throw Exception('Failed to load messages: Invalid response format');
        }
      } else {
        throw Exception('Failed to load messages');
      }
    } catch (e) {
      print('Error fetching messages: $e');
    }
  }

  Future<Message> sendMessage(
      Order chat, String text, DateTime dateTime, String user) async {
    final apiUrl = 'https://polskoydm.pythonanywhere.com/send_message';

    // Create the URL with query parameters
    final url = Uri.parse(apiUrl).replace(
      queryParameters: {
        'chat_id': chat.id.toString(),
        'text': text,
        'user': user,
      },
    );

    print('Sending GET request to API: $url');

    try {
      final response = await http.get(url);

      // Print the response data
      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      final String responseMessage = response.body;

      if (response.statusCode == 200) {
        // Check if the response message indicates success
        if (responseMessage.contains("Message received and stored successfully")) {
          // Message sent successfully, you can handle it accordingly
          // ...

          // Create a new Message object and return it
          final Message sentMessage = Message(
            text: text,
            dateTime: dateTime,
            user: user,
          );

          // Fetch the orders again to refresh the list
          await fetchChats();

          // Update the existing chat modal with new message
          chatModalKey.currentState?.updateMessages(sentMessage);

          return sentMessage;
        } else {
          throw Exception('Failed to send message: Unexpected response');
        }
      } else {
        throw Exception('Failed to send message. Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending message: $e');
      throw e; // Rethrow the exception to handle it in the UI
    }
  }

  void _openChatModal(BuildContext context, Order chat) async {
    int orderIndex = chats.indexOf(chat);

    // Fetch messages for the selected Order before opening the modal
    await fetchMessagesForOrder(chat);

    showDialog(
      context: context, // Use the context provided by the build method
      builder: (BuildContext context) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            height: 700,
            child: ChatModal(
              chat: chat,
              orderIndex: orderIndex,
              onSendMessage: (text, dateTime, user) async {
                try {
                  final sentMessage = await sendMessage(chat, text, dateTime, user);
                  setState(() {
                    chats[orderIndex].messages.add(sentMessage);
                  });
                } catch (e) {
                  // Handle the error, e.g., show an error message to the user
                  print('Error sending message: $e');
                }
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Chats'),
      ),
      body: ListView.builder(
        itemCount: chats.length,
        itemBuilder: (context, index) {
          final chat = chats[index];
          return GestureDetector(
            onTap: () {
              _openChatModal(context, chat);
            },
            child: ChatCard(
              chat: chat,
            ),
          );
        },
      ),
    );
  }
}

class ChatCard extends StatelessWidget {
  final Order chat;

  ChatCard({required this.chat});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4.0,
      margin: EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: ClipOval(
              child: Image.network(
                'https://polskoydm.pythonanywhere.com/static/images/chat.jpg',
                width: 50,
                height: 50,
                fit: BoxFit.cover,
              ),
            ),
            title: Text(
              '${chat.name}',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Tap to open conversation                       00:15',
              style: TextStyle(fontWeight: FontWeight.normal),
            ),
          ),
        ],
      ),
    );
  }
}

class ChatModal extends StatefulWidget {
  final Order chat;
  final int orderIndex;
  final Function(String, DateTime, String) onSendMessage;

  ChatModal(
      {required this.chat, required this.orderIndex, required this.onSendMessage, Key? key})
      : super(key: key);

  @override
  ChatModalState createState() => ChatModalState();
}

class ChatModalState extends State<ChatModal> {
  TextEditingController _textEditingController = TextEditingController();

  // Method to update messages
  void updateMessages(Message newMessage) {
    setState(() {
      widget.chat.messages.add(newMessage);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat with ${widget.chat.name}'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: widget.chat.messages.length,
              itemBuilder: (context, index) {
                final message = widget.chat.messages[index];
                final isDriver = message.user == 'driver'; // Replace with your condition

                return Align(
                  alignment: isDriver ? Alignment.centerLeft : Alignment.centerRight,
                  child: Container(
                    padding: EdgeInsets.all(8.0),
                    margin: EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: isDriver ? Colors.blue : Colors.green, // Customize the colors
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.user,
                          style: TextStyle(
                            color: isDriver ? Colors.white : Colors.black, // Customize the text color
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          message.text,
                          style: TextStyle(
                            color: isDriver ? Colors.white : Colors.black, // Customize the text color
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textEditingController,
                    decoration: InputDecoration(hintText: 'Type your message'),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () {
                    final text = _textEditingController.text;
                    if (text.isNotEmpty) {
                      widget.onSendMessage(text, DateTime.now(), 'user');
                      _textEditingController.clear();
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

class Message {
  final String text;
  final DateTime dateTime;
  final String user;

  Message({
    required this.text,
    required this.dateTime,
    required this.user,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      text: json['text'],
      dateTime: DateTime.parse(json['dateTime']),
      user: json['user'],
    );
  }
}

class Order {
  final String id;
  final double total;
  final String address;
  final String email;
  final String name;
  final List<Map<String, dynamic>> cart;
  final String status;
  final String store_name;
  final String start_point;
  List<Message> messages; // Moved messages list here

  Order({
    required this.id,
    required this.total,
    required this.address,
    required this.email,
    required this.name,
    required this.cart,
    this.status = 'pending',
    required this.store_name,
    required this.start_point,
    required this.messages, // Initialize it as an empty list
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      total: json['total'],
      address: json['address'],
      email: json['email'],
      name: json['name'],
      cart: List<Map<String, dynamic>>.from(json['cart']),
      status: json['status'],
      store_name: json['store_name'],
      start_point: json['start_point'],
      messages: [], // Initialize it as an empty list
    );
  }
}
