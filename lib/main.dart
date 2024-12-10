import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:todo/api/firebase_api.dart';
import 'package:todo/screens/FieldsTickets/AcceptedFieldTicket.dart';
import 'package:todo/screens/Manager/alerteManager.dart';
import 'package:todo/screens/Manager/historiqueManager.dart';
import 'package:todo/screens/Manager/homeManager.dart';
import 'package:todo/screens/auth/login_screen.dart';
import 'package:todo/screens/coordinatrice/alerteCoordinatrice.dart';
import 'package:todo/screens/coordinatrice/homeCordinatrice.dart';
import 'package:todo/screens/coordinatrice/phoneTicketsCoordinatrice/phoneAssigned.dart';
import 'package:todo/screens/coordinatrice/phoneTicketsCoordinatrice/phoneaccepted.dart';
import 'package:todo/screens/coordinatrice/phoneTicketsCoordinatrice/phoneloading.dart';
import 'package:todo/screens/home_screen.dart';
import 'package:todo/screens/home_screen_test.dart';
import 'package:todo/screens/pages/imagescreen.dart';
import 'package:todo/screens/pages/notification.dart';
import 'package:todo/screens/tickets/phonearrived.dart';
import 'package:todo/screens/tickets/phonedeparture.dart';
import 'firebase_options.dart'; // Assurez-vous d'inclure le fichier FirebaseOptions
import 'package:device_preview/device_preview.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
// Global navigator key to manage navigation

// Global navigator key to manage navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService.initialize();

  // Enregistrer le gestionnaire de messages en arrière-plan
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    // Log de réception de la notification
    print("Notification reçue en premier plan:");
    print("Titre: ${message.notification?.title}");
    print("Corps: ${message.notification?.body}");
    print("Données: ${message.data}");
    print("Données supplémentaires: ${message.data}");
    print("=========================");
    // Si tu veux afficher la notification également
    NotificationService.showNotification(message);

    // Log pour navigation si applicable
    if (message.data.containsKey('screen')) {
      String route = message.data['screen'];
      print("Naviguer vers la route: $route");
      navigatorKey.currentState?.pushNamed(route);
    }
  });

  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('token');
  String? email = prefs.getString('email');
  String? id = prefs.getString('id');
  String? userRole = prefs.getString('role');

  runApp(
    MyApp(
      token: token,
      email: email,
      userRole: userRole,
      id: id,
    ),
  );
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Message reçu en arrière-plan: ${message.messageId}');

  if (message.notification != null) {
    print(
        'Notification: ${message.notification!.title}, ${message.notification!.body}');
    // Affichez la notification manuellement en arrière-plan
    await NotificationService.showNotification(message);
  }
}

Timer? _sessionTimer;

void startSessionTimer() {
  print('Session timer started/restarted');
  _sessionTimer?.cancel(); // Annuler tout timer existant
  _sessionTimer = Timer(Duration(hours: 1), () => endSession());
}

Future<void> endSession() async {
  print('Session ended');
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('token');
  await prefs.remove('email');
  await prefs.remove('id');
  await prefs.remove('role');

  if (navigatorKey.currentContext != null) {
    showDialog(
      context: navigatorKey.currentContext!,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Session Terminée'),
          content: Text(
              'Votre session a expiré. Vous serez redirigé vers la page de connexion.'),
        );
      },
    );

    await Future.delayed(Duration(seconds: 4));
    Navigator.of(navigatorKey.currentContext!).pop(); // Ferme la popup
    Navigator.of(navigatorKey.currentContext!)
        .pushReplacementNamed('/loginpage'); // Redirige vers la page de login
  } else {
    print('Context is null, cannot show dialog');
  }
}

class MyApp extends StatefulWidget {
  final String? token;
  final String? email;
  final String? userRole;
  final String? id;

  const MyApp({
    super.key,
    required this.token,
    required this.email,
    required this.id,
    required this.userRole,
  });

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  bool isFirstLaunch = true;

  @override
  void initState() {
    super.initState();
    _checkAppVersion(context); // Vérifier si l'application a été mise à jour
    _checkFirstLaunch();
    WidgetsBinding.instance.addObserver(this);
    startSessionTimer(); // Démarrer le timer dès que l'application est lancée
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sessionTimer?.cancel(); // Annuler le timer lors de la destruction
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // L'application est active, redémarrer le timer
      print('App resumed, restarting session timer');
      startSessionTimer();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // L'application est inactive, annuler le timer
      print('App paused or inactive, canceling session timer');
      _sessionTimer?.cancel();
    }
  }

  Future<void> _checkAppVersion(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedVersion = prefs.getString('appVersion');

    // Récupère la version actuelle de l'application
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String currentVersion = packageInfo.version;

    if (storedVersion != currentVersion) {
      // Si la version stockée est différente de la version actuelle, c'est une mise à jour
      await prefs.setString(
          'appVersion', currentVersion); // Enregistre la nouvelle version

      // Afficher un toast pour indiquer que l'application a été mise à jour
      Fluttertoast.showToast(
        msg: "L'application a été mise à jour. Veuillez vous reconnecter.",
        toastLength: Toast.LENGTH_LONG, // Durée du toast
        gravity: ToastGravity.CENTER, // Position du toast (centre de l'écran)
        timeInSecForIosWeb: 3, // Durée pour iOS / Web
      );

      // Naviguer vers la page de login après un court délai
      await Future.delayed(Duration(seconds: 3)); // Attente pour le toast
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                LoginScreen()), // Remplacez par votre écran de login
      );
    } else {
      // Si la version est la même, vous pouvez rester sur l'écran actuel
      setState(() {
        isFirstLaunch = false;
      });
    }
  }

  Future<void> _checkFirstLaunch() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isFirst = prefs.getBool('isFirstLaunch') ?? true;

    if (isFirst) {
      setState(() {
        isFirstLaunch = true;
      });
      await prefs.setBool('isFirstLaunch', false);
    } else {
      setState(() {
        isFirstLaunch = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isCoordinatrice = widget.userRole == "COORDINATRICE";
    bool isManager = widget.userRole == "MANAGER";
    bool isTechnicien = widget.userRole == "HELPTECH";

    final Map<String, WidgetBuilder> coordinatorRoutes = {
      '/assignedphone': (context) => PhoneAssignedScreen(token: widget.token!),
      '/notification': (context) => const NotificationScreen(
            token: '',
          ),
      '/acceptedphone': (context) => PhoneAcceptedScreen(token: widget.token!),
      '/departurephone': (context) =>
          PhoneDepartureScreen(token: widget.token!),
      '/arrivedphone': (context) => PhoneArrivedScreen(token: widget.token!),
      '/loadingphone': (context) => PhoneLoadingScreen(token: widget.token!),
      '/loginpage': (context) => LoginScreen(),
      '/alert': (context) =>
          AlerteScreen(token: '', userRole: widget.userRole!),
    };

    final Map<String, WidgetBuilder> managerRoutes = {
      '/alertemanager': (context) => AlerteManagerScreen(
            token: widget.token!,
            userRole: '',
          ),
      '/historique': (context) => HistoriqueManagerScreen(token: widget.token!),
      '/notification': (context) => const NotificationScreen(
            token: '',
          ),
    };
    // Routes spécifiques pour le Technicien
    final Map<String, WidgetBuilder> technicienRoutes = {
      '/AcceptedField': (context) => FieldAcceptedScreen(
            token: widget.token!,
          ),
    };

    final Map<String, WidgetBuilder> appRoutes = {};
    if (isCoordinatrice) {
      appRoutes.addAll(coordinatorRoutes);
    } else if (isManager) {
      appRoutes.addAll(managerRoutes);
    } else if (isTechnicien) {
      appRoutes.addAll(technicienRoutes); // Ajout des routes technicien
    }

    return GestureDetector(
      // Détecte n'importe quel tap ou interaction avec l'écran
      onTap: () {
        print('User tapped on screen, restarting session timer');
        startSessionTimer(); // Redémarre le timer à chaque interaction
      },
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Tunisys',
        navigatorKey: navigatorKey,
        //  initialRoute: '/',
        // Utilisez les routes définies
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(255, 185, 6, 6),
          ),
          useMaterial3: true,
          textTheme: GoogleFonts.poppinsTextTheme(),
          scaffoldBackgroundColor: Color.fromRGBO(242, 245, 250, 1),
        ),
        routes: appRoutes,
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/loginpage':
              return MaterialPageRoute(builder: (context) => LoginScreen());
            default:
              return null; // ou une route par défaut
          }
        },
        home: isFirstLaunch
            ? ImageScreen()
            : (widget.token == null
                ? LoginScreen()
                : isCoordinatrice
                    ? HomeCordinatrice(
                        token: widget.token!,
                        email: widget.email ?? '',
                      )
                    : isManager
                        ? HomeCordinatrice(
                            token: widget.token!,
                            email: widget.email ?? '',
                          )
                        : HomeScreenTest(
                            token: widget.token!,
                            email: widget.email ?? '',
                            id: widget.id ?? '',
                          )),
      ),
    );
  }
}
