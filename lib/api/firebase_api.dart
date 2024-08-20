/*import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:todo/main.dart';

class FirebaseApi {
  // create a new instance
  final _firebaseMessaging = FirebaseMessaging.instance;
  //function to initialize notification
  Future<void> initNotification() async {
    await _firebaseMessaging.requestPermission();
    //fetch the FCM token for this device
    final fCMToken = await _firebaseMessaging.getToken();

    //print the token (normallly you would send this to your server )
    print('FCM: $fCMToken');
    initNotification();
  }

  //function to handle received messages
  void handleMessage(RemoteMessage? message) {
    if (message == null) return;
    //navigate to new screen when message is recived
    navigatorKey.currentState?.pushNamed(
      '/notification',
      arguments: message,
    );
  }

  Future initPushNotification() async {
    FirebaseMessaging.instance.getInitialMessage().then(handleMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(handleMessage);
  }
}
*/
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:todo/main.dart';

class FirebaseApi {
  // Create a new instance of FirebaseMessaging
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // Function to initialize notification
  Future<void> initNotification() async {
    // Request permission to show notifications
    await _firebaseMessaging.requestPermission();

    // Fetch the FCM token for this device
    final fCMToken = await _firebaseMessaging.getToken();

    // Print the token (normally you would send this to your server)
    print('FCM: $fCMToken');
  }

  // Function to handle received messages
  void handleMessage(RemoteMessage? message) {
    if (message == null) return;

    // Navigate to the new screen when a message is received
    navigatorKey.currentState?.pushNamed(
      '/notification',
      arguments: message,
    );
  }

  // Function to initialize push notification listeners
  Future<void> initPushNotification() async {
    // Handle the case when the app is launched from a terminated state
    FirebaseMessaging.instance.getInitialMessage().then(handleMessage);

    // Handle messages when the app is in the background and the user taps on the notification
    FirebaseMessaging.onMessageOpenedApp.listen(handleMessage);

    // Optionally, handle foreground messages if you want to display an in-app alert
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // Handle the message or show a notification using a package like flutter_local_notifications
     });
  }
}
