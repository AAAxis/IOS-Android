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
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchChats();
  }

  Future<void> fetchChats() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userQuery = prefs.getString("phone") ?? "";
    final apiUrl =
        'https://polskoydm.pythonanywhere.com/my_chats?phone=$userQuery';

    print('Fetching data from API. URL: $apiUrl');

    try {
      // Simulate delay for demonstration purposes
      await Future.delayed(Duration(milliseconds: 100));
      setState(() {
        _isLoading = true;
      });

      final response = await http.get(Uri.parse(apiUrl));

      print('API Response: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        if (data.isNotEmpty) {
          setState(() {
            // Clear the chatRooms list before adding new data
            chatRooms.clear();
            chatRooms.addAll(
                List<Map<String, dynamic>>.from(data.map((chatData) {
                  String chatId = chatData['id'];

                  Map<String, dynamic> chatRoom = {
                    'roomName': chatId,
                    'lastMessage': "Pick Up from",
                    'userName': chatData['name'],
                    'total': chatData['total'],
                    'userPhone': chatData['user_phone'],
                    'userCart': chatData['cart'],
                    'storeName': chatData['store_name'],
                    'userAddress': chatData['address'],
                    'startPoint': chatData['start_point'],
                    'status': chatData['status'],
                  };

                  return chatRoom;
                }).where((chatRoom) => chatRoom != null)));
          });
        } else {
          print('No chat data available.');
        }
      } else {
        print('API Request Error: ${response.body}');
      }
    } catch (error) {
      print('API Request Error: $error');
    } finally {
      // Simulate delay for demonstration purposes
      await Future.delayed(Duration(seconds: 1));

      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat Screen'),
        leading: IconButton(
          icon: Icon(Icons.refresh),
          onPressed: fetchChats,
        ),
      ),
      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(),
      )
          : chatRooms.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'No orders. Try Refresh page',
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      )
          : Container(
        height: MediaQuery.of(context).size.height,
        child: ListView.builder(
          itemCount: chatRooms.length,
          itemBuilder: (context, index) {
            Map<String, dynamic> chatRoom = chatRooms[index];
            return Card(
              elevation: 2.0,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(
                      'https://i.pinimg.com/564x/ba/fd/69/bafd6939587fc13452f170cae8dc3ad8.jpg'),
                ),
                title: Text(chatRoom['userName']),
                subtitle: Text(chatRoom['lastMessage'] +
                    " " +
                    chatRoom['storeName']),
                trailing: GestureDetector(
                  onTap: () {
                    switch (chatRoom['status'].toLowerCase()) {
                      case 'assigned':
                        MapsLauncher.launchQuery(
                            chatRoom['startPoint']);
                        break;
                      case 'done':
                      // Handle the "done" status action here or leave it empty
                        break;
                      default:
                        break;
                    }
                  },
                  child: chatRoom['status'].toLowerCase() == 'done'
                      ? Icon(Icons.check_box, color: Colors.green)
                      : _buildIconForStatus(
                      chatRoom['status'].toLowerCase()),
                ),
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (BuildContext context) {
                      return Container(
                        height: MediaQuery.of(context).size.height *
                            0.7,
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
    );
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
}
