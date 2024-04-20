import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxi_app/mainScreens/bank.dart';
import 'package:taxi_app/mainScreens/law_support.dart';
import 'package:intl/intl.dart';


class TransactionDialog extends StatelessWidget {
  final List<Map<String, dynamic>> transactions;

  TransactionDialog({required this.transactions});

  @override
  Widget build(BuildContext context) {
    // Inside the build method of your AlertDialog widget
    return AlertDialog(
      title: Text('Transactions'),
      content: SingleChildScrollView(
        scrollDirection: Axis.horizontal, // Allow horizontal scrolling
        child: SingleChildScrollView(
          child: DataTable(
            columns: [
              DataColumn(label: Text('Provider')),
              DataColumn(label: Text('Amount')),
              DataColumn(label: Text('Date')), // New column
              DataColumn(label: Text('Deliveries Complated')),
            ],
            rows: transactions.map((transaction) {
              // Format the timestamp into a readable date format
              String formattedDate = DateFormat('dd MMM').format(transaction['timestamp'].toDate());


              return DataRow(cells: [
                DataCell(Text(transaction['provider'].toString())),
                DataCell(Text('\$${transaction['money']}')),
                DataCell(Text(formattedDate)),
                // Modified line to include the dollar sign
                DataCell(Text(transaction['deliveryCompleted'].toString())), // New cell for the provider column
              ]);
            }).toList(),
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('Close'),
        ),
      ],
    );
  }

}

class ThirdScreen extends StatefulWidget {


  @override
  _ThirdScreenState createState() => _ThirdScreenState();
}



class _ThirdScreenState extends State<ThirdScreen> {
  String buttonText = 'Balance'; // Default text for balance button
  String ratingButtonText = 'Rating'; // Default text for rating button

  List<Map<String, dynamic>> _transactions = [
    {'money': '1996', 'rating': '88'}
  ]; // Sample transactions data

  @override
  void initState() {
    super.initState();
    // Fetch transactions when the screen is initialized
    if (_transactions.isNotEmpty) {
      int balance = int.parse(_transactions.last['money']);
      buttonText = 'Balance - $balance';
      int rating = int.parse(_transactions.last['rating']);
      ratingButtonText = 'Rating - $rating';
    } else {
      buttonText = 'No transactions available';
      ratingButtonText = 'No rating available';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Balance'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Credit Card Placeholder
            Container(
              padding: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.0),
                color: Colors.black87, // Set card color to black
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Icon for Mastercard
                      Row(
                        children: [
                          // Icon for Mastercard
                          Icon(
                            Icons.credit_card,
                            color: Colors.white, // Mastercard's color
                            size: 30,
                          ),
                          SizedBox(width: 10), // Add some space between the icon and text
                          // Text for the balance amount
                          Text(
                            '\$${_transactions.last['money']}', // Display balance amount
                            style: TextStyle(
                              color: Colors.white, // Text color
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),


                    ],
                  ),
                  SizedBox(height: 100),
                  Text(
                    '**** **** **** 5488',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),

                  FutureBuilder<String>(
                    future: _getName(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        return Text(
                          '${snapshot.data}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        );
                      } else {
                        return SizedBox();
                      }
                    },
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),
            // Button blocks
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    // Fetch transaction data from Firestore
                    await fetchTransactions();
                    // Show dialog with transaction table
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return TransactionDialog(transactions: _transactions);
                      },
                    );
                  },
                  icon: Icon(Icons.list),
                  label: Text('Transactions'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black, side: BorderSide(color: Colors.black), // Border color
                    padding: EdgeInsets.all(16.0), // Button padding
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Navigate to Edit Bank Screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => EditBankScreen()),
                    );
                  },
                  icon: Icon(Icons.money),
                  label: Text('Edit Bank'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black, side: BorderSide(color: Colors.black), // Border color
                    padding: EdgeInsets.all(16.0), // Button padding
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Navigate to Law Support Screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SendMessagePage()),
                    );
                  },
                  icon: Icon(Icons.support),
                  label: Text('Law Support'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black, side: BorderSide(color: Colors.black), // Border color
                    padding: EdgeInsets.all(16.0), // Button padding
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: Icon(Icons.star),
                  label: Text(ratingButtonText),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black, side: BorderSide(color: Colors.black), // Border color
                    padding: EdgeInsets.all(16.0), // Button padding
                  ),
                ),
              ),
            ),


          ],
        ),
      ),
    );
  }

  // Function to fetch transaction data from Firestore
  Future<void> fetchTransactions() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userId = prefs.getString('uid') ?? '';

    if (userId.isNotEmpty) {
      // Reference to the user's document in Firestore
      DocumentReference userRef = FirebaseFirestore.instance.collection('users').doc(userId);

      // Fetch data from the "transactions" subcollection under the user's document
      QuerySnapshot querySnapshot = await userRef.collection('transactions').get();

      // Extract data from documents
      _transactions = querySnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    }
  }

  // Function to get name from shared preferences
  Future<String> _getName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('name') ?? 'Unknown';
  }
}
void main() {
  runApp(MaterialApp(
    home: ThirdScreen(),
  ));
}
