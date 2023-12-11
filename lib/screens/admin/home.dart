import 'package:flutter/material.dart';

class AdminHomePage extends StatelessWidget {
  final String userEmail;

  const AdminHomePage({Key? key, required this.userEmail}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home Page - Customer'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome, $userEmail!'),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
