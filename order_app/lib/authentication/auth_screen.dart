import 'package:flutter/material.dart';
import 'package:order_app/authentication/login.dart';
import 'package:order_app/authentication/register.dart';




class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(

          automaticallyImplyLeading: false,
          title: const Text("Good Morning",
            style: TextStyle(
                fontSize: 35,
                color: Colors.white,
            ),
          ),
          centerTitle: true,
        ),
        body: Container(
            child: TabBarView(
              children: [
                LoginScreen(),
                RegisterScreen(),
              ],
            )
        ),
      ),
    );
  }
}
