import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    // Your existing login code...
  }

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
