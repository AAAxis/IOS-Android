import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver_app/chat_room.dart';
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
    String userQuery = prefs.getString("phone") ?? "";
    final apiUrl = 'https://polskoydm.pythonanywhere.com/my_chats?phone=$userQuery';

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
                  'lastMessage': "Pick Up from",
                  'userName': chatData['name'],
                  'userPhone': chatData['user_phone'],
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 37.0, left: 15.0), // Adjust the padding as needed
            child: Align(
              alignment: Alignment.topLeft,
              child: Text(
                'My Chats',
                style: TextStyle(
                  fontSize: 35.0, // Adjust the font size as needed
                  fontWeight: FontWeight.bold, // Adjust the font weight as needed
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: MediaQuery.of(context).size.height,
              child: ListView.builder(
                itemCount: chatRooms.length,
                itemBuilder: (context, index) {
                  Map<String, dynamic> chatRoom = chatRooms[index];
                  // Customize the chat room UI based on your data
                  return Card(
                    elevation: 2.0, // Adjust the elevation as needed
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage('https://i.pinimg.com/564x/ba/fd/69/bafd6939587fc13452f170cae8dc3ad8.jpg'),
                      ),
                      title: Text(chatRoom['userName']),
                      subtitle: Text(chatRoom['lastMessage'] + " " + chatRoom['storeName']),
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
                            ? Icon(Icons.done, color: Colors.green) // Display a checkmark icon when status is "done"
                            : _buildIconForStatus(chatRoom['status'].toLowerCase()),
                      ),

                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (BuildContext context) {
                            return Container(
                              height: MediaQuery.of(context).size.height * 0.7, // Adjust the height as needed
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