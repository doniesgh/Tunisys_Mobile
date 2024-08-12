import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // Import this for RemoteMessage

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  _NotificationScreenState createState() =>
      _NotificationScreenState(); // Implementing createState
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  Widget build(BuildContext context) {
    final message = ModalRoute.of(context)!.settings.arguments as RemoteMessage;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: TextStyle(color: Colors.white, fontSize: 24),
        ),
        backgroundColor: Color.fromRGBO(209, 77, 90, 1),
        toolbarHeight: 60,
      ),
      body: Column(
        children: [
          Text(message.notification!.title ?? 'No Title'),
          Text(message.notification!.body ?? 'No Body'),
        ],
      ),
    );
  }
}
