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
  List<Chat> chats = [];

  @override
  void initState() {
    super.initState();
    fetchChats();
  }

  Future<void> fetchChats() async {
    final apiUrl = 'https://polskoydm.pythonanywhere.com/done';
    try {
      // Print response and link inside the future
      print('Fetching orders from API: $apiUrl');

      final response = await http.get(Uri.parse(apiUrl));

      print('Response: $response');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<Chat> fetchedChats = (data as List)
            .map((orderData) => Chat.fromJson(orderData))
            .toList();

        setState(() {
          chats = fetchedChats;
        });
      } else {
        throw Exception('Failed to load order data');
      }
    } catch (e) {
      print('Error fetching data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null, // Remove the app bar
      body: ListView.builder(
        itemCount: chats.length,
        itemBuilder: (context, index) {
          final order = chats[index];
          return ChatCard(chat: order);
        },
      ),
    );
  }
}

class ChatCard extends StatelessWidget {
  final Chat chat;

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
              '${chat.messages}',
              style: TextStyle(fontWeight: FontWeight.normal),
            ),
          ),
        ],
      ),
    );
  }
}

class Chat {
  final String id;
  final double total;
  final String address;
  final String email;
  final String name;
  final List<Map<String, dynamic>> cart;
  final String status;
  final String store_name;
  final String start_point;
  final String messages; // Add this line

  Chat({
    required this.id,
    required this.total,
    required this.address,
    required this.email,
    required this.name,
    required this.cart,
    this.status = 'pending',
    required this.store_name,
    required this.start_point,
    required this.messages, // Add this line
  });

  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['id'],
      total: json['total'],
      address: json['address'],
      email: json['email'],
      name: json['name'],
      cart: List<Map<String, dynamic>>.from(json['cart']),
      status: json['status'],
      store_name: json['store_name'],
      start_point: json['start_point'],
      messages: json['messages'],
    );
  }
}
