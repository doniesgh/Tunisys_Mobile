import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo/api/firebase_api.dart';
import 'package:todo/components/text_field.dart';
import 'package:todo/screens/Manager/homeManager.dart';
import 'package:http/http.dart' as http;
import 'package:todo/screens/config/config.dart';
import 'package:todo/screens/coordinatrice/homeCordinatrice.dart';
import 'package:todo/screens/home_screen.dart';
import 'package:todo/utils/toast.dart';
import 'package:todo/screens/config/config_service.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  late SharedPreferences prefs;
  String? errorMessage;
  String? fcmToken;
  String lat = '';
  String long = '';
  String locationMessage = 'Current location of the User';

  @override
  void initState() {
    super.initState();
    _initPrefs();
    _getFcmToken();
  }

  void _initPrefs() async {
    prefs = await SharedPreferences.getInstance();
  }

  Future<void> _getFcmToken() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    fcmToken = await messaging.getToken();
    print("FCM Token: $fcmToken");
  }

  Future<void> login() async {
    try {
      if (emailController.text.isNotEmpty &&
          passwordController.text.isNotEmpty) {

        await _getFcmToken();
        var loginBody = {
          "email": emailController.text,
          "password": passwordController.text,
          "fcmToken": fcmToken, // Include the FCM token in the request
        };

        print("Attempting to log in with body: $loginBody");
        Utils.showToast("Logging in...");
        var address = ConfigService().adresse;
        var port = ConfigService().port;
        var url = "$address:$port/api/user/login";

        var response = await http.post(
          Uri.parse(url),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(loginBody),
        );

        // Logging the response status code
        print("Received response with status code: ${response.statusCode}");

        if (response.statusCode == 200) {
          var responseData = jsonDecode(response.body);

          // Logging the response data
          print("Login successful, response data: $responseData");

          var myToken = responseData["token"];
          var email = responseData["email"];
          var role = responseData["role"];
          var id = responseData["id"];

          Utils.showToast("Logged in successfully");
          Utils.showToast(email);
          Utils.showToast(id);
          Utils.showToast(role);

          // Logging the token, email, and role
          print("Token: $myToken, Email: $email, Role: $role, Id: $id");

          prefs.setString("token", myToken);
          prefs.setString("email", email);
          prefs.setString("role", role);
          prefs.setString("id", id);

          // Redirect based on role
          if (role == "COORDINATRICE") {
            print("Redirecting to HomeCordinatrice");
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    HomeCordinatrice(token: myToken, email: email),
              ),
            );
          } else if (role == "MANAGER") {
            print("Redirecting to HomeManager");
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => HomeManager(token: myToken, email: email),
              ),
            );
          } else {
            print("Redirecting to HomeScreen");
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    HomeScreen(token: myToken, email: email, id: id),
              ),
            );
          }
        } else {
          var errorResponse = jsonDecode(response.body);

          // Logging the error response
          print("Login failed, error response: $errorResponse");

          Utils.showToast("Login failed: ${errorResponse['error']}");
          setState(() {
            errorMessage = errorResponse['error'];
          });
        }
      } else {
        Utils.showToast("Please fill all the fields");
      }
    } catch (e) {
      // Logging the exception
      print("Error occurred during login: $e");
      Utils.showToast("Error: $e");
    }
  }
/*
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Utils.showToast("Location services are disabled.");
      return;
    }

    // Check location permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Utils.showToast("Location permissions are denied.");
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      Utils.showToast("Location permissions are permanently denied.");
      return;
    }

    // Get current position
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      setState(() {
        lat = '${position.latitude}';
        long = '${position.longitude}';
        locationMessage = 'Latitude : $lat, longitude : $long';
      });
      print('Current position: $lat, $long');
    } catch (e) {
      Utils.showToast("Failed to get location: $e");
    }
  }
*/
Future<void> _getCurrentLocation() async {
  bool serviceEnabled;
  LocationPermission permission;

  // Check if location services are enabled
  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    Utils.showToast("Location services are disabled. Opening settings...");
    await Geolocator.openLocationSettings(); // Open device location settings
    return; // Exit the function and wait for the user to enable it
  }

  // Check location permission
  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      Utils.showToast("Location permissions are denied.");
      return;
    }
  }

  if (permission == LocationPermission.deniedForever) {
    Utils.showToast("Location permissions are permanently denied.");
    return;
  }

  // Get current position
  try {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    setState(() {
      lat = '${position.latitude}';
      long = '${position.longitude}';
      locationMessage = 'Latitude: $lat, Longitude: $long';
    });
    print('Current position: $lat, $long');
  } catch (e) {
    Utils.showToast("Failed to get location: $e");
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 100.0),
                child: Image.asset(
                  'assets/tu.png',
                  width: 220,
                  height: 150,
                ),
              ),
              const SizedBox(height: 100),
              TextInput(
                controller: emailController,
                label: "Email",
              ),
              TextInput(
                controller: passwordController,
                label: "Password",
                isPass: true,
              ),
              ElevatedButton(
                onPressed: login,
                child: const Text('Login'),
              ),
              ElevatedButton(
                onPressed: () {
                  _getCurrentLocation();
                },
                child: const Text('Get current location'),
              ),
              Text(locationMessage),
              if (errorMessage != null)
                Text(
                  errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Server configuration : "),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ConfigScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'Configuration',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
