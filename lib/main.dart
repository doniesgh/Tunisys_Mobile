import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo/api/firebase_api.dart';
import 'package:todo/screens/pages/notification.dart';
import 'package:todo/screens/Manager/alerteManager.dart';
import 'package:todo/screens/Manager/historiqueManager.dart';
import 'package:todo/screens/Manager/homeManager.dart';
import 'package:todo/screens/auth/login_screen.dart';
import 'package:todo/screens/coordinatrice/homeCordinatrice.dart';
import 'package:todo/screens/home_screen.dart';
import 'package:todo/screens/tickets/phoneAssigned.dart';
import 'package:todo/screens/tickets/phoneaccepted.dart';
import 'package:todo/screens/tickets/phonearrived.dart';
import 'package:todo/screens/tickets/phonedeparture.dart';
import 'package:todo/screens/tickets/phoneloading.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:device_preview/device_preview.dart';
final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirebaseApi().initNotification();
  await FirebaseApi().initPushNotification();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('token');
  String? email = prefs.getString('email');
  String? id = prefs.getString('id');
  String? userRole = prefs.getString('role');
  // Debugging output
  print(
      "Retrieved from SharedPreferences - Token: $token, Email: $email, Role: $userRole, Id: $id");
  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
      builder: (context) =>
          MyApp(token: token, email: email, userRole: userRole, id: id),
    ),
  );
}

class MyApp extends StatelessWidget {
  final String? token;
  final String? email;
  final String? userRole;
  final String? id;

  const MyApp(
      {Key? key,
      required this.token,
      required this.email,
      required this.id,
      required this.userRole})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    //bool isTokenExpired = token == null || JwtDecoder.isExpired(token!);
    bool isCoordinatrice = userRole == "COORDINATRICE";
    bool isManager = userRole == "MANAGER";
    final Map<String, WidgetBuilder> coordinatorRoutes = {
      '/assignedphone': (context) => PhoneAssignedScreen(token: token!),
      '/notification': (context) => NotificationScreen(),
      '/acceptedphone': (context) => PhoneAcceptedScreen(token: token!),
      '/departurephone': (context) => PhoneDepartureScreen(token: token!),
      '/arrivedphone': (context) => PhoneArrivedScreen(token: token!),
      '/loadingphone': (context) => PhoneLoadingScreen(token: token!),
    };

    final Map<String, WidgetBuilder> managerRoutes = {
      '/alertemanager': (context) => AlerteManagerScreen(token: token!),
      '/historique': (context) => HistoriqueManagerScreen(token: token!),
      '/notification': (context) => NotificationScreen(),
    };

    final Map<String, WidgetBuilder> appRoutes = {};
    if (isCoordinatrice) {
      appRoutes.addAll(coordinatorRoutes);
    } else if (isManager) {
      appRoutes.addAll(managerRoutes);
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tunisys',
      navigatorKey: navigatorKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(255, 185, 6, 6)),
        useMaterial3: true,
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      routes: appRoutes,
      home: token == null
          ? const LoginScreen()
          : isCoordinatrice
              ? HomeCordinatrice(
                  token: token!,
                  email: email!,
                )
              : isManager
                  ? HomeManager(
                      token: token!,
                      email: email!,
                    )
                  : HomeScreen(
                      token: token!,
                      email: email!,
                      id: id!,
                    ),
    );
  }
}
