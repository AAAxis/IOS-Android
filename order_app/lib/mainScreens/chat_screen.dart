import 'package:order_app/mainScreens/chat_room.dart';
import 'package:flutter/material.dart';
import 'package:maps_launcher/maps_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController messageController = TextEditingController();
  String selectedChatRoom = '';
  String userPhone = ''; // Store the user's phone number
  List<Map<String, dynamic>> chatRooms = [];

  @override
  void initState() {
    super.initState();
    fetchChats();
  }

  Widget _buildIconForStatus(String status) {
    switch (status) {
      case 'assigned':
        return Icon(Icons.store);
      case 'done':
        return Icon(Icons.check);
      default:
        return Icon(Icons.error); // Return a default icon or handle other cases as needed
    }
  }

  Future<void> fetchChats() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userQuery = prefs.getString("email") ?? "";
    final apiUrl = 'https://polskoydm.pythonanywhere.com/history?email=$userQuery';

    print('Fetching data from API. URL: $apiUrl');

    try {
      final response = await http.get(Uri.parse(apiUrl));

      print('API Response: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        if (data.isNotEmpty) {
          setState(() {
            chatRooms = List<Map<String, dynamic>>.from(data.map((chatData) {
              String chatId = chatData['id'];

              // Create a map for the chat room, including driver and user names
              Map<String, dynamic> chatRoom = {
                'roomName': chatId,
                'lastMessage': "Order status",
                'userName': chatData['name'],
                'userPhone': chatData['user_phone'],
                'userTotal': chatData['total'].toString(),
                'driverPhone': chatData['driver_phone'],
                'userCart': chatData['cart'],
                'storeName': chatData['store_name'],
                'userAddress': chatData['address'],
                'startPoint': chatData['start_point'],
                'status': chatData['status'],
              };

              return chatRoom;
            }).where((chatRoom) =>
            chatRoom != null)); // Filter out null chat rooms
          });
        } else {
          // Handle the case where no chat data is available
          print('No chat data available.');
        }
      } else {
        // Handle API request error
        print('API Request Error: ${response.body}');
      }
    } catch (error) {
      // Handle API request error
      print('API Request Error: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          'My Chats',
          style: TextStyle(
            fontSize: 25.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: chatRooms.isEmpty
          ? Center(
        child: Card(
          elevation: 2.0,
          margin: EdgeInsets.all(26.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "You don't have open conversations, Login or Sign up to start messaging",
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      )
          : Column(
        children: [
          Expanded(
            child: Container(
              height: MediaQuery.of(context).size.height,
              child: ListView.builder(
                itemCount: chatRooms.length,
                itemBuilder: (context, index) {
                  Map<String, dynamic> chatRoom = chatRooms[index];
                  return Card(
                    elevation: 2.0,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage('https://i.pinimg.com/564x/ba/fd/69/bafd6939587fc13452f170cae8dc3ad8.jpg'),
                      ),
                      title: Text(chatRoom['storeName']),
                      subtitle: Text(chatRoom['lastMessage'] + " " + chatRoom['status']),
                      trailing: GestureDetector(
                        onTap: () {
                          switch (chatRoom['status'].toLowerCase()) {
                            case 'assigned':
                              MapsLauncher.launchQuery(chatRoom['startPoint']);
                              break;
                            case 'done':
                            // Handle the "done" status action here or leave it empty
                              break;
                            default:
                              break;
                          }
                        },
                        child: chatRoom['status'].toLowerCase() == 'done'
                            ? Icon(Icons.done, color: Colors.green)
                            : _buildIconForStatus(chatRoom['status'].toLowerCase()),
                      ),
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (BuildContext context) {
                            return Container(
                              height: MediaQuery.of(context).size.height * 0.7,
                              child: ChatRoomScreen(chatRoom: chatRoom),
                            );
                          },
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
