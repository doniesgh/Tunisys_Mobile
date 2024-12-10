// import 'dart:convert';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:todo/api/firebase_api.dart';
// import 'package:todo/components/text_field.dart';
// import 'package:todo/main.dart';
// import 'package:todo/screens/Manager/homeManager.dart';
// import 'package:http/http.dart' as http;
// import 'package:todo/screens/config/config.dart';
// import 'package:todo/screens/coordinatrice/homeCordinatrice.dart';
// import 'package:todo/screens/home_screen.dart';
// import 'package:todo/utils/toast.dart';
// import 'package:todo/screens/config/config_service.dart';
// import 'package:package_info_plus/package_info_plus.dart';
// import 'package:camera_gallery_image_picker/camera_gallery_image_picker.dart';
// import 'package:device_info_plus/device_info_plus.dart';
// import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo/api/firebase_api.dart';
import 'package:todo/components/text_field.dart'; // Import de votre composant
import 'package:flutter/services.dart'
    hide TextInput; // Masque le TextInput de Flutter
import 'package:todo/main.dart';
import 'package:todo/screens/Manager/homeManager.dart';
import 'package:http/http.dart' as http;
import 'package:todo/screens/config/config.dart';
import 'package:todo/screens/coordinatrice/homeCordinatrice.dart';
import 'package:todo/screens/home_screen.dart';
import 'package:todo/utils/toast.dart';
import 'package:todo/screens/config/config_service.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:camera_gallery_image_picker/camera_gallery_image_picker.dart';
import 'package:device_info_plus/device_info_plus.dart';

// Reste du code...

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

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
  String appVersion = ''; // Store app version
  String buildNumber = ''; // Store build number
  String version = '';
  String appName = '';
  String packageName = '';
  String _androidId = '';
  //String? deviceId;
  String _deviceId = '';
  DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
    _initPrefs();
    _getFcmToken();
    _getAndroidId();
  }

  void _initPrefs() async {
    prefs = await SharedPreferences.getInstance();
  }

  Future<void> _getAndroidId() async {
    const platform = MethodChannel('com.example.todo/device');
    try {
      final String androidId = await platform.invokeMethod('getAndroidId');
      _deviceId = androidId; // Stockez l'Android ID
    } on PlatformException catch (e) {
      print("Erreur lors de la récupération de l'Android ID : ${e.message}");
    }
  }

  // Future<void> _getDeviceID() async {
  //   AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
  //   setState(() {
  //     _deviceId = androidInfo.id; // Obtenez l'ID Android
  //   });
  //   print("Device ID: $_deviceId"); // Affichez l'ID dans la console
  // }
  // Future<void> _getDeviceID() async {
  //   try {
  //     AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
  //     setState(() {
  //       _deviceId = androidInfo.id ?? ""; // Récupérer l'ID Android
  //     });
  //     print("Device ID: $_deviceId");
  //   } catch (e) {
  //     print("Erreur lors de l'extraction de l'ID de l'appareil : $e");
  //     Utils.showToast("Erreur : Impossible de récupérer l'ID de l'appareil.");
  //   }
  //}
  // Future<void> _getDeviceID() async {
  //   try {
  //     AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
  //     setState(() {
  //       _deviceId = androidInfo.id ?? ""; // Récupérer l'ID Android
  //     });
  //     print("Device ID: $_deviceId");
  //   } catch (e) {
  //     print("Erreur lors de l'extraction de l'ID de l'appareil : $e");
  //     Utils.showToast("Erreur : Impossible de récupérer l'ID de l'appareil.");
  //   }
  // }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      appName = info.appName; // Nom de l'application
      packageName = info.packageName; // Nom du package
      version = info.version; // Version de l'application
      buildNumber = info.buildNumber; // Numéro de build
    });
  }

  Future<void> _getFcmToken() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    fcmToken = await messaging.getToken();
    if (fcmToken == null || fcmToken!.isEmpty) {
      print("Error: FCM Token is invalid or not retrieved.");
      return; // Gérer le cas où le token FCM n'est pas disponible
    }
    print("FCM Token: $fcmToken");
  }

  Future<void> login() async {
    try {
      // Récupérer les informations de l'application, y compris la version
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String currentVersion = packageInfo.version; // Version de l'app

      // Assurez-vous que l'ID de l'appareil est récupéré avant de procéder
      await _getAndroidId();
      if (_deviceId.isEmpty) {
        Utils.showToast("Erreur : DeviceId extrait de l'appareil est vide.");
        return;
      }

      // Vérifiez que les champs email et mot de passe ne sont pas vides
      if (emailController.text.isNotEmpty &&
          passwordController.text.isNotEmpty) {
        await _getFcmToken(); // Récupère le token FCM

        // Stocker la version dans SharedPreferences
        prefs.setString('appVersion', currentVersion);

        var loginBody = {
          "email": emailController.text,
          "password": passwordController.text,
          "fcmToken": fcmToken,
          "deviceId": _deviceId, // Utilisation de l'ID de l'appareil
          "appVersion": currentVersion, // Envoyer la version dans la requête
        };

        print("Tentative de connexion avec les données : $loginBody");
        Utils.showToast("Connexion en cours...");

        var address = ConfigService().adresse;
        var port = ConfigService().port;
        var url = "$address:$port/api/user/loginMob";

        var response = await http.post(
          Uri.parse(url),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(loginBody),
        );

        print("Réponse reçue avec le code de statut : ${response.statusCode}");

        if (response.statusCode == 200) {
          var responseData = jsonDecode(response.body);
          print("Connexion réussie, données reçues : $responseData");

          var myToken = responseData["token"];
          var email = responseData["email"];
          var role = responseData["role"];
          var id = responseData["id"];
          var storedAppVersion = responseData[
              "appVersion"]; // Version stockée dans la base de données
          Utils.showToast("Connexion réussie");

          // Comparer la version dans la base de données et la version actuelle
          if (storedAppVersion != currentVersion) {
            // Si les versions sont différentes, redirigez vers la page de connexion
            Utils.showToast(
                "Une mise à jour est disponible. Veuillez vous reconnecter.");
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => LoginScreen()),
            );
          } else {
            // Sinon, enregistrez les informations de l'utilisateur dans les préférences
            prefs.setString("token", myToken);
            prefs.setString("email", email);
            prefs.setString("role", role);
            prefs.setString("id", id);

            // Redirection selon le rôle de l'utilisateur
            if (role == "COORDINATRICE") {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      HomeCordinatrice(token: myToken, email: email),
                ),
              );
            } else if (role == "MANAGER") {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      HomeManager(token: myToken, email: email),
                ),
              );
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      HomeScreen(token: myToken, email: email, id: id),
                ),
              );
            }
          }
        } else {
          var errorData = jsonDecode(response.body);
          Utils.showToast("Erreur 03 : ${errorData['error']}");
        }
      } else {
        Utils.showToast("Veuillez remplir tous les champs.");
      }
    } catch (error) {
      print("Erreur pendant la connexion : $error");
      Utils.showToast("Une erreur s'est produite. Veuillez réessayer.");
    }
  }

/*
  Future<void> login() async {
    try {
      // Assurez-vous que l'ID de l'appareil est récupéré avant de procéder
      await _getAndroidId();
      if (_deviceId.isEmpty) {
        Utils.showToast("Erreur : DeviceId extrait de l'appareil est vide.");
        return;
      }

      // Vérifiez que les champs email et mot de passe ne sont pas vides
      if (emailController.text.isNotEmpty &&
          passwordController.text.isNotEmpty) {
        await _getFcmToken(); // Récupère le token FCM

        // Récupérer la version de l'application stockée dans SharedPreferences
        String currentVersion =
            version; // Utilisez la version actuelle de l'app
        prefs.setString('appVersion',
            currentVersion); // Stocker la version dans SharedPreferences

        var loginBody = {
          "email": emailController.text,
          "password": passwordController.text,
          "fcmToken": fcmToken,
          "deviceId": _deviceId, // Utilisation de l'ID de l'appareil
          "appVersion": currentVersion, // Envoyer la version dans la requête
        };

        print("Tentative de connexion avec les données : $loginBody");
        Utils.showToast("Connexion en cours...");

        var address = ConfigService().adresse;
        var port = ConfigService().port;
        var url = "$address:$port/api/user/loginMob";

        var response = await http.post(
          Uri.parse(url),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(loginBody),
        );

        print("Réponse reçue avec le code de statut : ${response.statusCode}");

        if (response.statusCode == 200) {
          var responseData = jsonDecode(response.body);
          print("Connexion réussie, données reçues : $responseData");

          var myToken = responseData["token"];
          var email = responseData["email"];
          var role = responseData["role"];
          var id = responseData["id"];
          var storedAppVersion = responseData[
              "appVersion"]; // Version stockée dans la base de données
          Utils.showToast("Connexion réussie");

          // Comparer la version dans la base de données et la version actuelle
          if (storedAppVersion != currentVersion) {
            // Si les versions sont différentes, redirigez vers la page de connexion
            Utils.showToast(
                "Une mise à jour est disponible. Veuillez vous reconnecter.");
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => LoginScreen()),
            );
          } else {
            // Sinon, enregistrez les informations de l'utilisateur dans les préférences
            prefs.setString("token", myToken);
            prefs.setString("email", email);
            prefs.setString("role", role);
            prefs.setString("id", id);

            // Redirection selon le rôle de l'utilisateur
            if (role == "COORDINATRICE") {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      HomeCordinatrice(token: myToken, email: email),
                ),
              );
            } else if (role == "MANAGER") {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      HomeManager(token: myToken, email: email),
                ),
              );
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      HomeScreen(token: myToken, email: email, id: id),
                ),
              );
            }
          }
        } else {
          var errorData = jsonDecode(response.body);
          Utils.showToast("Erreur 03 : ${errorData['error']}");
        }
      } else {
        Utils.showToast("Veuillez remplir tous les champs.");
      }
    } catch (error) {
      print("Erreur pendant la connexion : $error");
      Utils.showToast("Une erreur s'est produite. Veuillez réessayer.");
    }
  } */

  // Future<void> login() async {
  //   try {
  //     // Assurez-vous que l'ID de l'appareil est récupéré avant de procéder
  //     await _getAndroidId();
  //     if (_deviceId.isEmpty) {
  //       Utils.showToast("Erreur : DeviceId extrait de l'appareil est vide.");

  //       return;
  //     }

  //     // Vérifiez que les champs email et mot de passe ne sont pas vides
  //     if (emailController.text.isNotEmpty &&
  //         passwordController.text.isNotEmpty) {
  //       await _getFcmToken(); // Récupère le token FCM

  //       var loginBody = {
  //         "email": emailController.text,
  //         "password": passwordController.text,
  //         "fcmToken": fcmToken,
  //         "deviceId": _deviceId, // Utilisation de l'ID de l'appareil
  //       };

  //       print("Tentative de connexion avec les données : $loginBody");
  //       Utils.showToast("Connexion en cours...");

  //       var address = ConfigService().adresse;
  //       var port = ConfigService().port;
  //       var url = "$address:$port/api/user/loginMob";

  //       var response = await http.post(
  //         Uri.parse(url),
  //         headers: {"Content-Type": "application/json"},
  //         body: jsonEncode(loginBody),
  //       );

  //       print("Réponse reçue avec le code de statut : ${response.statusCode}");

  //       if (response.statusCode == 200) {
  //         var responseData = jsonDecode(response.body);
  //         print("Connexion réussie, données reçues : $responseData");

  //         var myToken = responseData["token"];
  //         var email = responseData["email"];
  //         var role = responseData["role"];
  //         var id = responseData["id"];
  //         var deviceId = responseData["deviceId"];
  //         Utils.showToast("Connexion réussie");

  //         // Enregistrer les informations de l'utilisateur dans les préférences
  //         prefs.setString("token", myToken);
  //         prefs.setString("email", email);
  //         prefs.setString("role", role);
  //         prefs.setString("id", id);

  //         // Redirection selon le rôle de l'utilisateur
  //         if (role == "COORDINATRICE") {
  //           Navigator.pushReplacement(
  //             context,
  //             MaterialPageRoute(
  //               builder: (context) =>
  //                   HomeCordinatrice(token: myToken, email: email),
  //             ),
  //           );
  //         } else if (role == "MANAGER") {
  //           Navigator.pushReplacement(
  //             context,
  //             MaterialPageRoute(
  //               builder: (context) => HomeManager(token: myToken, email: email),
  //             ),
  //           );
  //         } else {
  //           Navigator.pushReplacement(
  //             context,
  //             MaterialPageRoute(
  //               builder: (context) =>
  //                   HomeScreen(token: myToken, email: email, id: id),
  //             ),
  //           );
  //         }
  //       } else {
  //         var errorData = jsonDecode(response.body);
  //         Utils.showToast("Erreur 03 : ${errorData['error']}");
  //       }
  //     } else {
  //       Utils.showToast("Veuillez remplir tous les champs.");
  //     }
  //   } catch (error) {
  //     print("Erreur pendant la connexion : $error");
  //     Utils.showToast("Une erreur s'est produite. Veuillez réessayer.");
  //   }
  // }

// void updateFcmToken() async {
//   // Récupérer le token FCM lorsque disponible
//   String? token = await FirebaseMessaging.instance.getToken();

//   if (token != null) {
//     // Envoyer le token au backend pour le mettre à jour
//     await updateTokenInBackend(token);
//   }
// }

// void updateFcmToken() async {
//   // Récupérer le token FCM lorsque disponible
//   String? token = await FirebaseMessaging.instance.getToken();

//   if (token != null) {
//     // Envoyer le token au backend pour le mettre à jour
//     await updateTokenInBackend(token);
//   }
// }

// Future<void> updateTokenInBackend(String token) async {
//   try {
//     await http.post(
//       Uri.parse("https://votre-backend.com/update-fcm-token"),
//       body: jsonEncode({"fcmToken": token}),
//       headers: {"Content-Type": "application/json"},
//     );
//     print("FCM token mis à jour avec succès");
//   } catch (e) {
//     print("Erreur lors de la mise à jour du FCM token: $e");
//   }
// }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Utils.showToast("Location services are disabled. Opening settings...");
      await Geolocator.openLocationSettings();
      return;
    }

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
      resizeToAvoidBottomInset:
          false, // Empêche le redimensionnement de l'interface utilisateur
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 100.0),
                    child: Image.asset(
                      'assets/logo2.png',
                      width: 250,
                      height: 180,
                    ),
                  ),
                  const SizedBox(height: 40),
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
                    child: const Text(
                      'Login',
                      style: TextStyle(color: Colors.white), // Couleur du texte
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFEF0000), // Couleur de fond
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        child: const Icon(
                          Icons.settings,
                          color: Colors.red, // Couleur de l'icône
                          size: 30,
                        ),
                      ),
                      const SizedBox(
                          width: 3), // Espacement entre l'icône et le texte
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ConfigScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'Configuration',
                          style:
                              TextStyle(color: Colors.red), // Couleur du texte
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                      height:
                          120), // Espace supplémentaire pour éviter le débordement
                ],
              ),
            ),
            // Image fixée en bas
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.all(
                    16.0), // Ajuste le padding si nécessaire
                child: Image.asset(
                  'assets/HI_TSS.png', // Remplace par le chemin de ton image
                  width: 110, // Ajuste la taille de l'image si nécessaire
                  height: 70,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
