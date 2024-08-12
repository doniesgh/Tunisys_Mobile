import 'package:firebase_messaging/firebase_messaging.dart';
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
}
