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
    final arguments = ModalRoute.of(context)?.settings.arguments;

    if (arguments is RemoteMessage) {
      final message = arguments;

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.notification?.title ?? 'No Title',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.0),
            Text(
              message.notification?.body ?? 'No Body',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      );
    } else {
      // If the arguments are not a RemoteMessage, show a fallback message
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Notifications',
            style: TextStyle(color: Colors.white, fontSize: 24),
          ),
          backgroundColor: Color.fromRGBO(209, 77, 90, 1),
          toolbarHeight: 60,
        ),
        body: Center(
          child: Text(
            'No notification data available',
            style: TextStyle(fontSize: 18),
          ),
        ),
      );
    }
  }
}
