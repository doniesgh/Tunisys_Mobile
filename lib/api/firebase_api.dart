import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser Firebase
  await Firebase.initializeApp();

  // Initialiser les notifications
  await NotificationService.initialize();

  // Initialiser Firebase Messaging pour gérer les messages en arrière-plan
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialiser les notifications push
  await NotificationService.initPushNotification();
}

// Gestion des messages reçus en arrière-plan
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  NotificationService.showNotification(message);
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin
      _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  // Configuration du canal de notification Android
  static final AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'your_default_channel_id', // ID du canal
    'Your Channel Name', // Nom du canal
    description: 'Description du canal', // Description
    importance: Importance.max, // Notifications en grand (heads-up)
    playSound: true, // Activer le son
    enableLights: true, // Activer les lumières LED
    enableVibration: true, // Activer la vibration
  );

  // Initialisation des notifications locales
  static Future<void> initialize() async {
    // Paramètres Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Paramètres iOS
    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();

    // Paramètres globaux d'initialisation
    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    // Initialiser Flutter Local Notifications
    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Créer un canal de notification pour Android
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
  }

  // Demander la permission pour les notifications sur iOS
  static Future<void> requestNotificationPermission() async {
    final status = await Permission.notification.request();
    if (status.isGranted) {
      print("Permission de notification accordée");
    } else {
      print("Permission de notification refusée");
    }
  }

  // Afficher la notification
  static Future<void> showNotification(RemoteMessage message) async {
    String notificationTitle = message.notification?.title ?? 'No Title';
    String notificationBody = message.notification?.body ?? 'No Body';
    print('Afficher la notification:');
    print('Titre: $notificationTitle');
    print('Message: $notificationBody');
    // Détails de la notification
    NotificationDetails notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'your_default_channel_id',
        'Your Channel Name',
        channelDescription: 'Your Channel Description',
        importance: Importance.max, // Notifications en grand (heads-up)
        priority: Priority.high,
        playSound: true,
        styleInformation:
            BigTextStyleInformation(notificationBody), // Style plus visible
        fullScreenIntent: true, // Affiche en grand
        ticker: 'Notification',
      ),
      iOS: DarwinNotificationDetails(),
    );

    print('Notification ID: 0');
    print('Title: $notificationTitle');
    print('Body: $notificationBody');

    await _flutterLocalNotificationsPlugin.show(
      0, // Identifiant unique de la notification
      notificationTitle,
      notificationBody,
      notificationDetails,
    );
  }

  // Initialiser Firebase Messaging et gérer les messages
  static Future<void> initPushNotification() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Demander la permission pour les notifications iOS
    await requestNotificationPermission();

    // Récupérer le token FCM
    String? token = await messaging.getToken();
    print('FCM Token: $token');

    // Gérer les messages lorsque l'application est lancée
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        // Message reçu lorsque l'application est terminée et relancée
        NotificationService.showNotification(message);
      }
    });

    // Appuie sur l'application en premier plan
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("Message reçu pendant que l'application est au premier plan.");
      NotificationService.showNotification(message);

      // Si vous souhaitez naviguer vers une route spécifique
      if (message.data.containsKey('screen')) {
        String route = message.data['screen'];
        navigatorKey.currentState?.pushNamed(route);
      }
    });

    // Appuie sur l'application en arrière-plan
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      String type = message.data['type'];
      String screen = message.data['screen'];

      switch (type) {
        case 'Rappel':
          navigatorKey.currentState?.pushNamed(screen);
          break;
        default:
          navigatorKey.currentState?.pushNamed('/default');
          break;
      }
    });
  }
}








// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:flutter/material.dart'; // Ajoutez cette ligne si ce n'est pas déjà fait
// import 'package:permission_handler/permission_handler.dart';

// // Initialisation de Firebase Messaging et des notifications locales

// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   // Initialiser Firebase
//   await Firebase.initializeApp();

//   // Initialiser les notifications
//   await NotificationService.initialize();

//   // Initialiser Firebase Messaging pour gérer les messages en arrière-plan
//   FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
// }

// // Gestion des messages reçus en arrière-plan
// Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   await Firebase.initializeApp();
//   NotificationService.showNotification(message);
// }

// final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// // Service de notification
// class NotificationService {
//   static final FlutterLocalNotificationsPlugin
//       _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

//   // Configuration du canal de notification Android
//   static final AndroidNotificationChannel _channel = AndroidNotificationChannel(
//     // 'high_importance_channel', // ID du canal
//     // 'High Importance Notifications', // Nom du canal
//     // description: 'This channel is used for important notifications.',
//     'your_default_channel_id', // ID du canal
//     'Your Channel Name', // Nom du canal
//     description: 'Description du canal', // Description
//     importance: Importance.high,
//   );

//   // Initialisation des notifications locales
//   static Future<void> initialize() async {
//     // Paramètres Android
//     const AndroidInitializationSettings initializationSettingsAndroid =
//         AndroidInitializationSettings('@mipmap/ic_launcher');

//     // Paramètres iOS
//     final DarwinInitializationSettings initializationSettingsIOS =
//         DarwinInitializationSettings();

//     // Paramètres globaux d'initialisation
//     final InitializationSettings initializationSettings =
//         InitializationSettings(
//       android: initializationSettingsAndroid,
//       iOS: initializationSettingsIOS,
//     );

//     // Initialiser Flutter Local Notifications
//     await _flutterLocalNotificationsPlugin.initialize(initializationSettings);

//     // Créer un canal de notification pour Android
//     await _flutterLocalNotificationsPlugin
//         .resolvePlatformSpecificImplementation<
//             AndroidFlutterLocalNotificationsPlugin>()
//         ?.createNotificationChannel(_channel);
//   }

//   Future<void> requestNotificationPermission() async {
//     final status = await Permission.notification.request();
//     if (status.isGranted) {
//       print("Permission de notification accordée");
//     } else {
//       print("Permission de notification refusée");
//     }
//   }

//   // Afficher la notification
//   static Future<void> showNotification(RemoteMessage message) async {
//     String notificationTitle = message.notification?.title ?? 'No Title';
//     String notificationBody = message.notification?.body ?? 'No Body';

//     // Détails de la notification
//     NotificationDetails notificationDetails = NotificationDetails(
//       android: AndroidNotificationDetails(
//         // _channel.id, // Id du canal
//         // _channel.name, // Nom du canal
//         // channelDescription: _channel.description,
//         'your_default_channel_id',
//         'Your Channel Name',
//         channelDescription: 'Your Channel Description',
//         //   importance: Importance.high,
//         //   priority: Priority.high,
//         importance: Importance.max, // Changer à max pour heads-up
//         priority: Priority.max,
//         playSound: true,
//         styleInformation: BigTextStyleInformation(
//             notificationBody), // Pour un style plus visible
//         fullScreenIntent: true, // Affiche en grand, idéal pour heads-up
//       ),
//       iOS: DarwinNotificationDetails(),
//     );
//     print('Notification ID: 0');
//     print('Title: $notificationTitle');
//     print('Body: $notificationBody');

//     print('Channel ID: your_default_channel_id');
//     await _flutterLocalNotificationsPlugin.show(
//       0, // Identifiant unique de la notification
//       notificationTitle,
//       notificationBody,
//       notificationDetails,
//     );
//   }

//   // Initialiser Firebase Messaging
//   static Future<void> initPushNotification() async {
//     FirebaseMessaging messaging = FirebaseMessaging.instance;

//     // Demander la permission pour les notifications iOS
//     NotificationSettings settings = await messaging.requestPermission(
//       alert: true,
//       badge: true,
//       sound: true,
//     );

//     if (settings.authorizationStatus == AuthorizationStatus.authorized) {
//       print('User granted permission');
//     } else {
//       print('User declined or has not accepted permission');
//     }

//     // Récupérer le token FCM
//     String? token = await messaging.getToken();
//     print('FCM Token: $token');

//     // Gérer les messages en arrière-plan et lorsque l'application est lancée
//     FirebaseMessaging.instance.getInitialMessage().then((message) {
//       if (message != null) {
//         // Message reçu lorsque l'application est terminée et relancée
//         NotificationService.showNotification(message);
//       }
//     });

//     //appuie sur app est en prmeier niveau
//     FirebaseMessaging.onMessage.listen((RemoteMessage message) {
//       print("Message reçu pendant que l'application est au premier plan.");
//       NotificationService.showNotification(message); // Affiche la notification

//       // Si vous souhaitez naviguer vers une route spécifique
//       if (message.data.containsKey('screen')) {
//         String route = message.data['screen'];
//         navigatorKey.currentState?.pushNamed(route);
//       }
//     });

//     // appuie sur app en background
//     FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
//       if (message.data.isNotEmpty && message.data.containsKey('screen')) {
//         String route = message.data['screen'];
//         print('Navigating to route: $route');
//         navigatorKey.currentState?.pushNamed(route);
//       } else {
//         print('Navigating to default route');
//         navigatorKey.currentState?.pushNamed('/default');
//       }
//     });
//   }
// }
