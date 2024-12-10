import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:todo/screens/FieldsTickets/ReportedFieldTicket.dart';
import 'package:todo/screens/FieldsTickets/solvingTicketModalField.dart';
import 'package:todo/screens/tickets/ticketDetails.dart';
import 'package:todo/screens/config/config_service.dart';
import 'package:todo/utils/toast.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

class FieldLoadingScreen extends StatefulWidget {
  final String token;
  final String? email;

  const FieldLoadingScreen({super.key, required this.token, this.email});

  @override
  _FieldLoadingScreenState createState() => _FieldLoadingScreenState();
}

class _FieldLoadingScreenState extends State<FieldLoadingScreen> {
  final ConfigService configService = ConfigService();
  String imageBase64 = '';
  bool isImageUploaded = false;
  String imageError = '';
  bool isLoading = false;
  String lat = '';
  String long = '';
  String uploadMessage = '';
  List<dynamic> tickets = [];

  @override
  void initState() {
    super.initState();
    _loadConfiguration();
    fetchAssignedTickets();
  }

  Future<void> _loadConfiguration() async {
    await configService.loadConfig(); // Charge la configuration
    setState(() {
      // Met à jour l'interface si nécessaire
    });
  }

  Future<String> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Utils.showToast("Location services are disabled. Opening settings...");
      await Geolocator.openLocationSettings();
      return "Location services are disabled. Click on start again";
    }

    // Check location permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Utils.showToast("Location permissions are denied.");
        return "Location permissions are denied.";
      }
    }

    if (permission == LocationPermission.deniedForever) {
      Utils.showToast("Location permissions are permanently denied.");
      return "Location permissions are permanently denied.";
    }

    // Get current position
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      String lat = '${position.latitude}';
      String long = '${position.longitude}';
      return 'Latitude: $lat, Longitude: $long';
    } catch (e) {
      Utils.showToast("Failed to get location: $e");
      return "Failed to get location.";
    }
  }

  int attemptCount = 0;
  // Future<void> fetchAssignedTickets() async {
  //   setState(() {
  //     isLoading = true;
  //   });
  //   try {
  //     final response = await http.get(
  //       Uri.parse('$address:$port/api/ticketht/assigned/field'),
  //       headers: {
  //         'Authorization': 'Bearer ${widget.token}',
  //       },
  //     );
  //     if (response.statusCode == 200) {
  //       final responseData = json.decode(response.body);
  //       if (responseData != null) {
  //         setState(() {
  //           tickets = responseData
  //               .where((ticket) => ticket['status'] == 'HANDLED')
  //               .toList();
  //           isLoading = false;
  //         });
  //       } else {
  //         throw Exception('Response data is null');
  //       }
  //     } else {
  //       throw Exception('Failed to handled tickets: ${response.statusCode}');
  //     }
  //   } catch (error) {
  //     print('Error fetching alerts: $error');
  //     setState(() {
  //       isLoading = false;
  //     });
  //   }
  // }
  Future<void> fetchAssignedTickets() async {
    var address = ConfigService().adresse;
    var port = ConfigService().port;
    setState(() {
      isLoading = true;
    });

    // Démarrer le chronomètre pour mesurer la durée de la requête
    final stopwatch = Stopwatch()..start();

    try {
      final response = await http.get(
        Uri.parse(
            '$address:$port/api/ticketht/assigned/field/mobile?status=HANDLED'), // 'ASSIGNED' doit être entre guillemets
        headers: {
          'Authorization': 'Bearer ${widget.token}',
        },
      );
      // Arrêter le chronomètre après la réponse
      stopwatch.stop();
      final duration = stopwatch.elapsed;

      // Vérifier si la réponse a pris plus de 3 secondes
      if (duration.inMilliseconds > 5000) {
        // Si la réponse a pris trop de temps
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Lenteur détectée'),
              content: Text(
                  'La réponse du serveur prend plus de temps que prévu (${duration.inSeconds} secondes). Veuillez patienter.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
      }

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData != null) {
          setState(() {
            tickets = responseData
                .where((ticket) => ticket['status'] == 'HANDLED')
                .toList();
            isLoading = false;
          });
        } else {
          // Si les données sont nulles ou invalides
          throw Exception('Les données de la réponse sont nulles');
        }
      } else {
        // En cas d'erreur de statut HTTP
        throw Exception(
            'Échec du chargement des tickets: ${response.statusCode}');
      }
    } catch (error) {
      print('Erreur lors de la récupération des tickets: $error');
      setState(() {
        isLoading = false;
      });

      // Afficher un message spécifique si une erreur est survenue mais que la réponse est bien arrivée
      if (stopwatch.isRunning) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Erreur d\'affichage'),
              content: Text(
                  'La réponse du serveur a été reçue, mais elle est trop longue à traiter. Veuillez réessayer plus tard.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
      }
    }
  }

  Future<double> calculateDistance(double startLatitude, double startLongitude,
      double endLatitude, double endLongitude) async {
    return Geolocator.distanceBetween(
        startLatitude, startLongitude, endLatitude, endLongitude);
  }

  Future<bool> checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false; // Location permissions are denied
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false; // Location permissions are permanently denied
    }

    return true; // Location permissions are granted
  }

  Future<void> checkAndRequestPermissions() async {
    final status = await Permission.phone.status;
    if (!status.isGranted) {
      await Permission.phone.request();
    }
  }

// Fonction pour vérifier la distance avant d'afficher le dialogue
  Future<void> handleStart(BuildContext context, String ticketId, String token,
      double ticketLatitude, double ticketLongitude) async {
    bool hasLocationPermission = await checkLocationPermission();

    if (!hasLocationPermission) {
      print('Location permission denied');
      return;
    }

    // Demande la position actuelle de l'utilisateur
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    // Affiche la position actuelle dans la console
    print(
        'Position actuelle : Latitude: ${position.latitude}, Longitude: ${position.longitude}');

    // Affiche la position extraite du ticket dans la console
    print(
        'Position du ticket : Latitude: $ticketLatitude, Longitude: $ticketLongitude');

    // Calcule la distance entre la position actuelle et celle du ticket
    double distance = await calculateDistance(
      position.latitude,
      position.longitude,
      ticketLatitude,
      ticketLongitude,
    );

    if (distance < 1700) {
      // Si la distance est inférieure à 1700 mètres, afficher le dialogue
      showSimpleHelloDialog(
          context, ticketId, token, ticketLatitude, ticketLongitude);
    } else {
      // Sinon, afficher un message d'erreur
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Erreur de localisation'),
            content: Text(
                'Vous n\'êtes pas au bon site. Veuillez vérifier votre position.'),
            actions: [
              TextButton(
                child: Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }

    // Continuer normalement sans la vérification de position
    // showSimpleHelloDialog(
    //     context, ticketId, token, ticketLatitude, ticketLongitude);
  }

  void showSimpleHelloDialog(BuildContext context, String ticketId,
      String token, double ticketLatitude, double ticketLongitude) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleHelloDialogField(
          ticketId: ticketId,
          token: token,
          ticketLatitude: ticketLatitude, // Passez la latitude ici
          ticketLongitude: ticketLongitude, // Passez la longitude ici
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Handled Tickets',
          style: TextStyle(color: Color.fromRGBO(209, 77, 90, 1), fontSize: 24),
        ),
        backgroundColor: const Color.fromRGBO(231, 236, 250, 1),
        toolbarHeight: 60,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchAssignedTickets,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : tickets.isEmpty
              ? const Center(
                  child: Text(
                    'No handled tickets found.',
                    style: TextStyle(fontSize: 20),
                  ),
                )
              : ListView.builder(
                  itemCount: tickets.length,
                  itemBuilder: (context, index) {
                    return Card(
                      margin: const EdgeInsets.all(10),
                      color: const Color.fromRGBO(
                          231, 236, 250, 1), // Couleur de fond de la carte
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            15), // Arrondi des bords de la carte
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ListTile(
                              title: Text(
                                tickets[index]['reference'] ?? 'N/A',
                                style: const TextStyle(
                                  fontWeight:
                                      FontWeight.w600, // Poids de la police
                                  fontSize: 18, // Taille de la police
                                ),
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        TicketDetailScreenTech(
                                      ticketId: tickets[index]['_id'],
                                      ticket: null,
                                    ),
                                  ),
                                );
                              },
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Text(
                                        "Status: ",
                                        style: TextStyle(
                                          fontWeight: FontWeight
                                              .bold, // Poids de la police
                                        ),
                                      ),
                                      Text(
                                        tickets[index]['status'] ?? 'N/A',
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(
                                height:
                                    10), // Add spacing between text and buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      String ticketId = tickets[index]['_id'];
                                      String token = widget.token;

                                      // Vérifiez que l'équipement et les coordonnées ne sont pas null
                                      var equipement =
                                          tickets[index]['equipement'];
                                      if (equipement != null &&
                                          equipement['latitude'] != null &&
                                          equipement['longitude'] != null) {
                                        double ticketLatitude =
                                            equipement['latitude'];
                                        double ticketLongitude =
                                            equipement['longitude'];

                                        // Appeler la fonction handleStart si les coordonnées sont disponibles
                                        handleStart(context, ticketId, token,
                                            ticketLatitude, ticketLongitude);
                                      } else {
                                        // Affiche un message si les coordonnées sont manquantes
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              title: Text(
                                                  'Coordonnées manquantes'),
                                              content: Text(
                                                  'Les coordonnées GPS de l\'équipement ne sont pas disponibles.'),
                                              actions: [
                                                TextButton(
                                                  child: Text('OK'),
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                  },
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color.fromARGB(
                                          255, 10, 196, 81),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: const Text(
                                      'Solved',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),

                                const SizedBox(
                                    width: 10), // Add spacing between buttons
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      handleReportTicket(tickets[index]['_id']);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color.fromARGB(255,
                                          126, 126, 126), // Couleur du bouton
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                            10), // Bouton avec coins arrondis
                                      ),
                                    ),
                                    child: const Text(
                                      'Report',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  var address = ConfigService().adresse;
  var port = ConfigService().port;
  Future<void> handleReportTicket(String ticketId) async {
    String reportingNoteSolve = '';
    String reportImg = '';
    bool isReasonError = false;
    bool isImageError = false;
    bool isSubmitting = false;

    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('Reporter le ticket'),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text('Pourquoi voulez-vous reporter le ticket ?'),
                      TextField(
                        onChanged: (value) {
                          setState(() {
                            reportingNoteSolve = value;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Raison du report',
                          errorText: isReasonError
                              ? 'La raison du report est obligatoire'
                              : null,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed:
                            (isSubmitting || isLoading || isImageUploaded)
                                ? null
                                : uploadImage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: (isSubmitting || isImageUploaded)
                              ? Colors.grey
                              : const Color.fromARGB(255, 176, 190, 173),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: isLoading
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text('Processing',
                                      style: TextStyle(color: Colors.white)),
                                ],
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.upload, color: Colors.white),
                                  const SizedBox(width: 8),
                                  Text(
                                    isImageUploaded
                                        ? 'Fiche uploaded'
                                        : 'Upload Fiche Intervention',
                                    style: TextStyle(
                                      color: isImageUploaded
                                          ? Colors.green
                                          : Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                      if (isImageUploaded)
                        const Padding(
                          padding: EdgeInsets.only(top: 8.0),
                          child: Text(
                            'Fiche intervention uploadée avec succès !',
                            style: TextStyle(color: Colors.green),
                          ),
                        ),
                      if (isImageError)
                        const Padding(
                          padding: EdgeInsets.only(top: 8.0),
                          child: Text(
                            'La fiche intervention est obligatoire',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(false);
                    setState(() {
                      isImageUploaded = false;
                      imageBase64 = '';
                    });
                  },
                  child: const Text('Annuler'),
                ),
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          setState(() {
                            isReasonError = reportingNoteSolve.isEmpty;
                            isImageError = !isImageUploaded;
                            isSubmitting = true;
                          });

                          if (isReasonError || isImageError) {
                            setState(() {
                              isSubmitting = false;
                            });
                            return;
                          }

                          reportImg = imageBase64;

                          try {
                            final response = await http.post(
                              Uri.parse(
                                  '$address:$port/api/ticket/ReportingSolve/$ticketId'),
                              headers: {
                                'Authorization': 'Bearer ${widget.token}',
                                'Content-Type': 'application/json',
                              },
                              body: json.encode({
                                'ticketId': ticketId,
                                'reporting_note_solve': reportingNoteSolve,
                                'report_img': reportImg,
                              }),
                            );

                            if (response.statusCode == 200) {
                              Navigator.of(context).pop(true);
                            } else {
                              print(
                                  "Erreur lors de l'envoi: ${response.statusCode} - ${response.body}");
                              Navigator.of(context).pop(false);
                            }
                          } catch (e) {
                            print("Erreur: $e");
                            Navigator.of(context).pop(false);
                          } finally {
                            setState(() {
                              isSubmitting = false;
                            });
                          }
                        },
                  child: const Text('Envoyer'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true) {
      fetchAssignedTickets();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => FieldReportedScreen(
            token: widget.token,
          ),
        ),
      );
    }
  }

  /* handle report recente
  Future<void> handleReportTicket(String ticketId) async {
    String reportingNoteSolve = '';
    String reportImg = ''; // Utilisation de l'image encodée
    bool isReasonError = false; // Gérer l'affichage de l'erreur pour la raison
    bool isImageError = false; // Gérer l'affichage de l'erreur pour l'image
    bool isSubmitting =
        false; // État pour gérer l'envoi de la requête (éviter les doublons)

    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('Reporter le ticket'),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text('Pourquoi voulez-vous reporter le ticket ?'),
                      TextField(
                        onChanged: (value) {
                          setState(() {
                            reportingNoteSolve = value;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Raison du report',
                          errorText: isReasonError
                              ? 'La raison du report est obligatoire'
                              : null, // Affiche l'erreur si nécessaire
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: isSubmitting || isImageUploaded
                            ? null
                            : uploadImage, // Désactiver si en cours de soumission ou si l'image est uploadée
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isImageUploaded || isSubmitting
                              ? Colors.grey
                              : const Color.fromARGB(255, 176, 190, 173),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.upload, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              isImageUploaded
                                  ? 'Fiche uploaded'
                                  : 'Upload Fiche Intervention',
                              style: TextStyle(
                                color: isImageUploaded
                                    ? Colors.green
                                    : Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isImageUploaded)
                        const Padding(
                          padding: EdgeInsets.only(top: 8.0),
                          child: Text(
                            'Fiche intervention uploadée avec succès !',
                            style: TextStyle(color: Colors.green),
                          ),
                        ),
                      if (isImageError)
                        const Padding(
                          padding: EdgeInsets.only(top: 8.0),
                          child: Text(
                            'La fiche intervention est obligatoire',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(false);
                    setState(() {
                      isImageUploaded =
                          false; // Réinitialiser l'état de l'image
                      imageBase64 = ''; // Réinitialiser l'image encodée
                    });
                  },
                  child: const Text('Annuler'),
                ),
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          // Validation des champs
                          setState(() {
                            isReasonError = reportingNoteSolve.isEmpty;
                            isImageError = !isImageUploaded;
                            isSubmitting =
                                true; // Désactiver le bouton pendant l'envoi
                          });

                          // Si une erreur est présente, on ne procède pas
                          if (isReasonError || isImageError) {
                            setState(() {
                              isSubmitting =
                                  false; // Réactiver le bouton en cas d'erreur
                            });
                            return;
                          }

                          // Assurez-vous que `reportImg` contient l'image encodée
                          reportImg = imageBase64;

                          try {
                            // Envoi de la requête HTTP pour mettre à jour le ticket
                            final response = await http.post(
                              Uri.parse(
                                  '$address:$port/api/ticket/ReportingSolve/$ticketId'), // Corriger le chemin
                              headers: {
                                'Authorization': 'Bearer ${widget.token}',
                                'Content-Type': 'application/json',
                              },
                              body: json.encode({
                                'ticketId': ticketId,
                                'reporting_note_solve':
                                    reportingNoteSolve, // Enlever les crochets
                                'report_img': reportImg, // Enlever les crochets
                              }),
                            );

                            // Vérification de la réponse du serveur
                            if (response.statusCode == 200) {
                              Navigator.of(context).pop(true);
                            } else {
                              print(
                                  "Erreur lors de l'envoi: ${response.statusCode} - ${response.body}");
                              Navigator.of(context).pop(false);
                            }
                          } catch (e) {
                            print("Erreur: $e");
                            Navigator.of(context).pop(false);
                          } finally {
                            setState(() {
                              isSubmitting =
                                  false; // Réactiver le bouton après l'envoi
                            });
                          }
                        },
                  child: const Text('Envoyer'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true) {
      fetchAssignedTickets(); // Actualiser la liste des tickets
    }
  } */

  // Future<void> handleReportTicket(String ticketId) async {
  //   String reportingNoteSolve = '';
  //   String reportImg = ''; // Utilisation de l'image encodée
  //   bool isReasonError = false; // Gérer l'affichage de l'erreur pour la raison
  //   bool isImageError = false; // Gérer l'affichage de l'erreur pour l'image

  //   final result = await showDialog<bool>(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return StatefulBuilder(
  //         builder: (BuildContext context, StateSetter setState) {
  //           return AlertDialog(
  //             title: const Text('Reporter le ticket'),
  //             content: SizedBox(
  //               width: double.maxFinite,
  //               child: SingleChildScrollView(
  //                 child: Column(
  //                   mainAxisSize: MainAxisSize.min,
  //                   crossAxisAlignment: CrossAxisAlignment.start,
  //                   children: <Widget>[
  //                     const Text('Pourquoi voulez-vous reporter le ticket ?'),
  //                     TextField(
  //                       onChanged: (value) {
  //                         setState(() {
  //                           reportingNoteSolve = value;
  //                         });
  //                       },
  //                       decoration: InputDecoration(
  //                         hintText: 'Raison du report',
  //                         errorText: isReasonError
  //                             ? 'La raison du report est obligatoire'
  //                             : null, // Affiche l'erreur si nécessaire
  //                       ),
  //                     ),
  //                     const SizedBox(height: 16),
  //                     ElevatedButton(
  //                       onPressed: isImageUploaded
  //                           ? null
  //                           : uploadImage, // Désactiver si l'image est uploadée
  //                       style: ElevatedButton.styleFrom(
  //                         backgroundColor: isImageUploaded
  //                             ? Colors.grey
  //                             : const Color.fromARGB(255, 176, 190, 173),
  //                         shape: RoundedRectangleBorder(
  //                           borderRadius: BorderRadius.circular(10),
  //                         ),
  //                       ),
  //                       child: Row(
  //                         mainAxisSize: MainAxisSize.min,
  //                         children: [
  //                           const Icon(Icons.upload, color: Colors.white),
  //                           const SizedBox(width: 8),
  //                           Text(
  //                             isImageUploaded
  //                                 ? 'Fiche uploaded'
  //                                 : 'Upload Fiche Intervention',
  //                             style: TextStyle(
  //                               color: isImageUploaded
  //                                   ? Colors.green
  //                                   : Colors.white,
  //                             ),
  //                           ),
  //                         ],
  //                       ),
  //                     ),
  //                     if (isImageUploaded)
  //                       const Padding(
  //                         padding: EdgeInsets.only(top: 8.0),
  //                         child: Text(
  //                           'Fiche intervention uploadée avec succès !',
  //                           style: TextStyle(color: Colors.green),
  //                         ),
  //                       ),
  //                     if (isImageError)
  //                       const Padding(
  //                         padding: EdgeInsets.only(top: 8.0),
  //                         child: Text(
  //                           'La fiche intervention est obligatoire',
  //                           style: TextStyle(color: Colors.red),
  //                         ),
  //                       ),
  //                   ],
  //                 ),
  //               ),
  //             ),
  //             actions: [
  //               TextButton(
  //                 onPressed: () {
  //                   Navigator.of(context).pop(false);
  //                   setState(() {
  //                     isImageUploaded =
  //                         false; // Réinitialiser l'état de l'image
  //                     imageBase64 = ''; // Réinitialiser l'image encodée
  //                   });
  //                 },
  //                 child: const Text('Annuler'),
  //               ),
  //               TextButton(
  //                 onPressed: () async {
  //                   // Validation des champs
  //                   setState(() {
  //                     isReasonError = reportingNoteSolve.isEmpty;
  //                     isImageError = !isImageUploaded;
  //                   });

  //                   // Si une erreur est présente, on ne procède pas
  //                   if (isReasonError || isImageError) {
  //                     return;
  //                   }

  //                   // Assurez-vous que `reportImg` contient l'image encodée
  //                   reportImg = imageBase64;

  //                   // Envoi de la requête HTTP pour mettre à jour le ticket
  //                   final response = await http.post(
  //                     Uri.parse(
  //                         '$address:$port/api/ticket/ReportingSolve/$ticketId'), // Corriger le chemin
  //                     headers: {
  //                       'Authorization': 'Bearer ${widget.token}',
  //                       'Content-Type': 'application/json',
  //                     },
  //                     body: json.encode({
  //                       'ticketId': ticketId,
  //                       'reporting_note_solve':
  //                           reportingNoteSolve, // Enlever les crochets
  //                       'report_img': reportImg, // Enlever les crochets
  //                     }),
  //                   );

  //                   // Vérification de la réponse du serveur
  //                   if (response.statusCode == 200) {
  //                     Navigator.of(context).pop(true);
  //                   } else {
  //                     print(
  //                         "Erreur lors de l'envoi: ${response.statusCode} - ${response.body}");
  //                     Navigator.of(context).pop(false);
  //                   }
  //                 },
  //                 child: const Text('Envoyer'),
  //               ),
  //             ],
  //           );
  //         },
  //       );
  //     },
  //   );

  //   if (result == true) {
  //     fetchAssignedTickets(); // Actualiser la liste des tickets
  //   }
  // }

  Future<void> uploadImage() async {
    setState(() {
      isLoading = true; // Indiquer que le traitement est en cours
    });

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) {
      setState(() {
        isLoading = false;
        imageError = 'Aucune image sélectionnée.';
      });
      return;
    }

    final file = File(pickedFile.path);

    // Lire les octets de l'image
    final imageBytes = await file.readAsBytes();

    // Décoder l'image
    img.Image? originalImage = img.decodeImage(imageBytes);

    if (originalImage == null) {
      setState(() {
        isLoading = false;
        imageError = 'Impossible de décoder l\'image.';
      });
      return;
    }

    // Redimensionner l'image à 640x480
    img.Image resizedImage =
        img.copyResize(originalImage, width: 640, height: 480);

    // Convertir l'image en RGB si ce n'est pas déjà le cas
    if (resizedImage.channels != 3) {
      img.Image rgbImage = img.Image(resizedImage.width, resizedImage.height);
      for (int y = 0; y < resizedImage.height; y++) {
        for (int x = 0; x < resizedImage.width; x++) {
          int pixel = resizedImage.getPixel(x, y);
          rgbImage.setPixel(x, y, pixel);
        }
      }
      resizedImage = rgbImage;
      print('L\'image a été convertie en RGB (24 bits).');
    } else {
      print('Profondeur de couleur correcte: ${resizedImage.channels} canaux.');
    }

    // Réduire la taille de l'image si nécessaire
    int quality = 100;
    List<int> resizedImageBytes;
    do {
      resizedImageBytes = img.encodeJpg(resizedImage, quality: quality);

      int imageSizeInKB = (resizedImageBytes.length / 1024).floor();
      print('Taille de l\'image avec qualité $quality: ${imageSizeInKB} Ko');

      if (imageSizeInKB > 100) {
        quality = quality > 20 ? quality - 5 : quality - 1;
      } else {
        break;
      }

      if (quality <= 0) {
        print(
            'Impossible de réduire la taille à moins de 100 Ko sans perte excessive de qualité.');
        break;
      }
    } while (resizedImageBytes.length > 100 * 1024);

    // Convertir en Base64
    imageBase64 = base64Encode(resizedImageBytes);

    setState(() {
      isImageUploaded = true; // L'image est maintenant uploadée
      uploadMessage = 'Fiche uploaded.'; // Message de succès
      imageError = ''; // Réinitialisation de l'erreur
      isLoading = false; // Arrêt du chargement
    });
  }

/*  recente function
  Future<void> uploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;

    final file = File(pickedFile.path);
    final imageBytes = await file.readAsBytes();
    imageBase64 = base64Encode(imageBytes);

    setState(() {
      isImageUploaded = true;
      uploadMessage = 'Fiche uploaded .';
      imageError = ''; // Réinitialisation de l'erreur
    });
  }
*/
  // Future<void> handleReportTicket(String ticketId) async {
  //   String reportingNoteSolve = '';
  //   String reportImg = ''; // Utilisation de l'image encodée
  //   bool isReasonError = false; // Gérer l'affichage de l'erreur pour la raison
  //   bool isImageError = false; // Gérer l'affichage de l'erreur pour l'image

  //   final result = await showDialog<bool>(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return StatefulBuilder(
  //         builder: (BuildContext context, StateSetter setState) {
  //           return AlertDialog(
  //             title: const Text('Reporter le ticket'),
  //             content: SizedBox(
  //               width: double.maxFinite,
  //               child: SingleChildScrollView(
  //                 child: Column(
  //                   mainAxisSize: MainAxisSize.min,
  //                   crossAxisAlignment: CrossAxisAlignment.start,
  //                   children: <Widget>[
  //                     const Text('Pourquoi voulez-vous reporter le ticket ?'),
  //                     TextField(
  //                       onChanged: (value) {
  //                         setState(() {
  //                           reportingNoteSolve = value;
  //                         });
  //                       },
  //                       decoration: InputDecoration(
  //                         hintText: 'Raison du report',
  //                         errorText: isReasonError
  //                             ? 'La raison du report est obligatoire'
  //                             : null, // Affiche l'erreur si nécessaire
  //                       ),
  //                     ),
  //                     const SizedBox(height: 16),
  //                     ElevatedButton(
  //                       onPressed: isImageUploaded
  //                           ? null
  //                           : uploadImage, // Désactiver si l'image est uploadée
  //                       style: ElevatedButton.styleFrom(
  //                         backgroundColor: isImageUploaded
  //                             ? Colors.grey
  //                             : const Color.fromARGB(255, 176, 190, 173),
  //                         shape: RoundedRectangleBorder(
  //                           borderRadius: BorderRadius.circular(10),
  //                         ),
  //                       ),
  //                       child: Row(
  //                         mainAxisSize: MainAxisSize.min,
  //                         children: [
  //                           const Icon(Icons.upload, color: Colors.white),
  //                           const SizedBox(width: 8),
  //                           Text(
  //                             isImageUploaded
  //                                 ? 'Fiche uploaded'
  //                                 : 'Upload Fiche Intervention',
  //                             style: TextStyle(
  //                               color: isImageUploaded
  //                                   ? Colors.green
  //                                   : Colors.white,
  //                             ),
  //                           ),
  //                         ],
  //                       ),
  //                     ),
  //                     if (isImageUploaded)
  //                       const Padding(
  //                         padding: EdgeInsets.only(top: 8.0),
  //                         child: Text(
  //                           'Fiche intervention uploadée avec succès !',
  //                           style: TextStyle(color: Colors.green),
  //                         ),
  //                       ),
  //                     if (isImageError)
  //                       const Padding(
  //                         padding: EdgeInsets.only(top: 8.0),
  //                         child: Text(
  //                           'La fiche intervention est obligatoire',
  //                           style: TextStyle(color: Colors.red),
  //                         ),
  //                       ),
  //                   ],
  //                 ),
  //               ),
  //             ),
  //             actions: [
  //               TextButton(
  //                 onPressed: () {
  //                   Navigator.of(context).pop(false);
  //                   setState(() {
  //                     isImageUploaded =
  //                         false; // Réinitialiser le statut de l'image
  //                     imageBase64 = ''; // Réinitialiser l'image encodée
  //                   });
  //                 },
  //                 child: const Text('Annuler'),
  //               ),
  //               TextButton(
  //                 onPressed: () async {
  //                   // Validation des champs
  //                   setState(() {
  //                     isReasonError = reportingNoteSolve.isEmpty;
  //                     isImageError = !isImageUploaded;
  //                   });

  //                   if (!isReasonError && !isImageError) {
  //                     // Assurez-vous que `reportImg` contient l'image encodée
  //                     reportImg = imageBase64;

  //                     final response = await http.post(
  //                       Uri.parse(
  //                           '$address:$port/api/api/ticket/ReportingSolve/$ticketId'),
  //                       headers: {
  //                         'Authorization': 'Bearer ${widget.token}',
  //                         'Content-Type': 'application/json',
  //                       },
  //                       body: json.encode({
  //                         'status': 'REPORTED',
  //                         'ticketId': ticketId,
  //                         'reporting_note_solve': reportingNoteSolve,
  //                         'report_img': reportImg,
  //                       }),
  //                     );

  //                     // Vérification de la réponse
  //                     if (response.statusCode == 200) {
  //                       Navigator.of(context).pop(true);
  //                     } else {
  //                       print(
  //                           "Erreur lors de l'envoi: ${response.statusCode} - ${response.body}");
  //                       Navigator.of(context).pop(false);
  //                     }
  //                   }
  //                 },
  //                 child: const Text('Envoyer'),
  //               ),

  //             ],
  //           );
  //         },
  //       );
  //     },
  //   );

  //   if (result == true) {
  //     fetchAssignedTickets(); // Actualiser la liste des tickets
  //   }
  // }

  // Future<void> uploadImage() async {
  //   final picker = ImagePicker();
  //   final pickedFile = await picker.pickImage(source: ImageSource.gallery);

  //   if (pickedFile == null) return;

  //   final file = File(pickedFile.path);
  //   final imageBytes = await file.readAsBytes();
  //   imageBase64 = base64Encode(imageBytes);

  //   setState(() {
  //     isImageUploaded = true;
  //     uploadMessage = 'Fiche uploaded .';
  //     imageError = '';
  //     // Mise à jour de l'état pour désactiver le bouton
  //   });
  // }

  // Future<void> uploadImage() async {
  //   try {
  //     final result = await FilePicker.platform.pickFiles(
  //       type: FileType.image,
  //       allowMultiple: false,
  //     );

  //     if (result != null && result.files.isNotEmpty) {
  //       final file = result.files.first;

  //       final bytes = File(file.path!).readAsBytesSync();
  //       setState(() {
  //         imageBase64 = base64Encode(bytes);
  //         isImageUploaded = true;
  //       });
  //       print("Image uploadée avec succès");
  //     }
  //   } catch (e) {
  //     print('Erreur lors de la sélection de l\'image : $e');
  //   }
  // }

  // Future<void> handleReportTicket(String ticketId) async {
  //   String reportingNoteSolve = '';
  //   String reportImg = ''; // Utilisation de l'image encodée

  //   final result = await showDialog<bool>(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         title: const Text('Reporting Ticket ?'),
  //         content: SizedBox(
  //           width: double.maxFinite,
  //           child: SingleChildScrollView(
  //             child: Column(
  //               mainAxisSize: MainAxisSize.min,
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: <Widget>[
  //                 const Text('Pourquoi voulez-vous reporter le ticket ?'),
  //                 TextField(
  //                   onChanged: (value) {
  //                     reportingNoteSolve = value;
  //                   },
  //                   decoration: const InputDecoration(
  //                     hintText: 'Raison du report',
  //                   ),
  //                 ),
  //                 const SizedBox(height: 16),
  //                 ElevatedButton(
  //                   onPressed: isImageUploaded
  //                       ? null
  //                       : uploadImage, // Disable if image uploaded
  //                   style: ElevatedButton.styleFrom(
  //                     backgroundColor: isImageUploaded
  //                         ? Colors.grey
  //                         : const Color.fromARGB(255, 176, 190, 173),
  //                     shape: RoundedRectangleBorder(
  //                       borderRadius: BorderRadius.circular(10),
  //                     ),
  //                   ),
  //                   child: const Row(
  //                     mainAxisSize: MainAxisSize.min,
  //                     children: [
  //                       Icon(Icons.upload, color: Colors.white),
  //                       SizedBox(width: 8),
  //                       Text('Upload Fiche Intervention',
  //                           style: TextStyle(color: Colors.white)),
  //                     ],
  //                   ),
  //                 ),
  //                 if (isImageUploaded)
  //                   const Padding(
  //                     padding: EdgeInsets.only(top: 8.0),
  //                     child: Text(
  //                       'Image uploaded successfully!',
  //                       style: TextStyle(color: Colors.green),
  //                     ),
  //                   ),
  //               ],
  //             ),
  //           ),
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: () {
  //               Navigator.of(context).pop(false);
  //               setState(() {
  //                 isImageUploaded =
  //                     false; // Réinitialisation du statut de l'image
  //                 imageBase64 = ''; // Réinitialisation du contenu de l'image
  //               });
  //             },
  //             child: const Text('Annuler'),
  //           ),
  //           TextButton(
  //             onPressed: () async {
  //               final response = await http.post(
  //                 Uri.parse(
  //                     '$address:$port/api/api/ticket/ReportingSolve/$ticketId'), // wrong url
  //                 headers: {
  //                   'Authorization': 'Bearer ${widget.token}',
  //                   'Content-Type': 'application/json',
  //                 },
  //                 body: json.encode({
  //                   'ticketId': ticketId,
  //                   'reporting_note_solve': reportingNoteSolve,
  //                   'report_img': reportImg,
  //                 }),
  //               );

  //               if (response.statusCode == 200) {
  //                 Navigator.of(context).pop(true);
  //               } else {
  //                 Navigator.of(context).pop(false);
  //               }
  //             },
  //             child: const Text('Envoyer'),
  //           ),
  //         ],
  //       );
  //     },
  //   );

  //   if (result == true) {
  //     fetchAssignedTickets(); // Actualiser la liste des tickets
  //   }
  // }

  // Future<void> uploadImage() async {
  //   try {
  //     final result = await FilePicker.platform.pickFiles(
  //       type: FileType.image,
  //       allowMultiple: false,
  //     );

  //     if (result != null && result.files.isNotEmpty) {
  //       final file = result.files.first;

  //       final bytes = File(file.path!).readAsBytesSync();
  //       setState(() {
  //         imageBase64 = base64Encode(bytes);
  //         isImageUploaded = true;
  //       });
  //       print("image uplaoded succeffulyy ");
  //     }
  //   } catch (e) {
  //     print('Error picking image: $e');
  //   }
  // }
}
