import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:todo/screens/FieldsTickets/LoadingFieldTicket.dart';
import 'package:todo/screens/FieldsTickets/qrCodeScreen.dart';
import 'dart:convert';
import 'package:todo/screens/config/config_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:todo/screens/tickets/ticketDetails.dart';
import 'package:todo/utils/toast.dart';

class FieldArrivedScreen extends StatefulWidget {
  final String token;
  final String? email;

  const FieldArrivedScreen({Key? key, required this.token, this.email})
      : super(key: key);

  @override
  _FieldArrivedScreenState createState() => _FieldArrivedScreenState();
}

class _FieldArrivedScreenState extends State<FieldArrivedScreen> {
  bool isLoading = false;
  List<dynamic> tickets = [];
  String lat = '';
  String long = '';
  String locationMessage = 'Current location of the User';
  @override
  void initState() {
    super.initState();
    fetchAssignedTickets();
  }

  var address = ConfigService().adresse;
  var port = ConfigService().port;
  Future<void> fetchAssignedTickets() async {
    setState(() {
      isLoading = true;
    });
    try {
      final response = await http.get(
        Uri.parse('$address:$port/api/ticketht/assigned/field'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
        },
      );
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData != null) {
          setState(() {
            tickets = responseData
                .where((ticket) => ticket['status'] == 'ARRIVED')
                .toList();
            isLoading = false;
          });
        } else {
          throw Exception('Response data is null');
        }
      } else {
        throw Exception('Failed to load tickets: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching alerts: $error');
      setState(() {
        isLoading = false;
      });
    }
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

/*
  Future<void> handleStartTicket(BuildContext context, String ticketId) async {
    bool hasLocationPermission = await checkLocationPermission();

    if (!hasLocationPermission) {
      showErrorDialog(
        context,
        message:
            "Localisation non autorisée. Veuillez l'autoriser dans les paramètres.",
      );
      return;
    }

    // Fetch current location
    String locationMessage = await _getCurrentLocation();

    // Determine if location is valid
    bool isLocationValid = locationMessage.contains('Latitude') &&
        locationMessage.contains('Longitude');

    // Show confirmation dialog with location details
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Êtes-vous sûr de vouloir commencer ce ticket ?'),
          content: Text('Votre localisation actuelle:\n$locationMessage'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text('Annuler'),
            ),
            TextButton(
              onPressed: isLocationValid
                  ? () {
                      Navigator.of(context).pop(true);
                    }
                  : null, // Disable button if location is invalid
              child: Text('Oui, commencer'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      // QR Scanner
      final qrResult = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => QrScannerScreen()),
      );

      if (qrResult != null && qrResult.isNotEmpty) {
        print('Scanned QR Code: $qrResult');

        try {
          // Fetch ticket data
          final response = await http.get(
            Uri.parse('$address:$port/api/ticket/$ticketId'),
            headers: {'Authorization': 'Bearer ${widget.token}'},
          );

          if (response.statusCode == 200) {
            final ticketData = json.decode(response.body);
            final String codeqrequipement =
                ticketData['codeqrequipement'] ?? '';

            print('Equipment QR Code: $codeqrequipement');

            // If the equipment QR code is empty, assign it to the scanned QR code
            if (codeqrequipement.isEmpty) {
              await updateTicketStatus(context, ticketId, qrResult, qrResult);
            }
            // If the equipment QR code matches the scanned one
            else if (codeqrequipement == qrResult) {
              await updateTicketStatus(context, ticketId, qrResult, null);
            }
            // QR Code mismatch
            else {
              showErrorDialog(context,
                  message:
                      'Le code QR scanné ne correspond pas au code QR de l\'équipement. $qrResult != $codeqrequipement');
            }
          } else {
            showErrorDialog(context,
                message:
                    "Erreur lors de la récupération des données du ticket.");
          }
        } catch (error) {
          showErrorDialog(context,
              message: "Une erreur s'est produite. Veuillez réessayer.");
        }
      } else {
        showErrorDialog(context,
            message: "Scan de QR code annulé ou invalide.");
      }
    }
  }
*/
  Future<void> handleStartTicket(BuildContext context, String ticketId) async {
    bool hasLocationPermission = await checkLocationPermission();

    if (!hasLocationPermission) {
      showErrorDialog(
        context,
        message:
            "Localisation non autorisée. Veuillez l'autoriser dans les paramètres.",
      );
      return;
    }

    // Fetch current location
    Position currentPosition = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    if (currentPosition == null) {
      showErrorDialog(
        context,
        message: "Impossible d'obtenir la localisation actuelle.",
      );
      return;
    }

    // Fetch ticket data to get equipment's coordinates
    final response = await http.get(
      Uri.parse('$address:$port/api/ticket/$ticketId'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );

    if (response.statusCode == 200) {
      final ticketData = json.decode(response.body);
      print(ticketData);
      final double equipmentLat = ticketData['equipement']['latitude'] ?? 0.0;
      final double equipmentLong = ticketData['equipement']['longitude'] ?? 0.0;
      print(equipmentLong);
      print(equipmentLat);
      print(currentPosition.latitude);
      print(currentPosition.longitude);
      // Calculate the distance between user location and equipment location
      double distance = Geolocator.distanceBetween(
        currentPosition.latitude,
        currentPosition.longitude,
        equipmentLat,
        equipmentLong,
      );

      /*if (distance > 20.0) {
        showErrorDialog(
          context,
          message:
              "Vous êtes trop loin de l'équipement. Distance: ${distance.toStringAsFixed(2)} mètres",
        );
        return;
      }
*/
      if (distance > 20.0) {
        showErrorDialog(
          context,
          message:
              "Vous êtes trop loin de l'équipement. Distance: ${distance.toStringAsFixed(2)} mètres",
        );
        return;
      } else if (distance < 2.0) {
        // Petite marge pour les erreurs de précision GPS
        distance = 0.0; // Considérer comme même localisation
      }
      String distanceMessage =
          'Distance de l\'équipement: ${distance.toStringAsFixed(2)} mètres';

      // Show confirmation dialog with location details
      String locationMessage =
          'Latitude: ${currentPosition.latitude}, Longitude: ${currentPosition.longitude}';
      final result = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Commencer ce ticket ?'),
            content: Text(
              'Votre localisation actuelle:\n$locationMessage\n\n$distanceMessage',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
                child: Text('Annuler'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
                child: Text('Oui, commencer'),
              ),
            ],
          );
        },
      );

      if (result == true) {
        await updateTicketStatus(context, ticketId, "", null);
      }
    } else {
      showErrorDialog(context,
          message: "Erreur lors de la récupération des données du ticket.");
    }
  }

// Function to update the ticket status
  Future<void> updateTicketStatus(BuildContext context, String ticketId,
      String qrResult, String? codeqrequipement) async {
    try {
      final updateResponse = await http.put(
        Uri.parse('$address:$port/api/ticket/startedScan/$ticketId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}'
        },
        body: json.encode({
          'status': 'LOADING',
          'codeqrStart': qrResult,
          'codeqrequipement': codeqrequipement ?? qrResult,
          'starting_time': DateTime.now().toIso8601String(),
        }),
      );

      if (updateResponse.statusCode == 200) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Ticket commencé avec succès!'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    fetchAssignedTickets();
                  },
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
      } else {
        showErrorDialog(context,
            message: "Erreur lors de la mise à jour du statut du ticket.");
      }
    } catch (error) {
      showErrorDialog(context,
          message: "Une erreur s'est produite lors de la mise à jour.");
    }
  }

// Error dialog display
  void showErrorDialog(BuildContext context,
      {String message = "Veuillez réessayer plus tard"}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Erreur"),
          content: Text(message),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Arrived',
          style: TextStyle(color: Colors.white, fontSize: 24),
        ),
        backgroundColor: Color.fromRGBO(209, 77, 90, 1),
        toolbarHeight: 60,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: fetchAssignedTickets,
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : tickets.isEmpty
              ? Center(
                  child: Text(
                    'No arrived tickets found.',
                    style: TextStyle(fontSize: 20),
                  ),
                )
              : ListView.builder(
                  itemCount: tickets.length,
                  itemBuilder: (context, index) {
                    return Card(
                      margin: EdgeInsets.all(10),
                      child: ListTile(
                        title: Text(tickets[index]['reference']),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TicketDetailScreen(
                                  ticketId: tickets[index]['_id']),
                            ),
                          );
                        },
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  "Status: ",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(tickets[index]['status']),
                              ],
                            ),
                          ],
                        ),
                        trailing: ElevatedButton(
                          onPressed: () {
                            //handleStartTicket(tickets[index]['_id']);
                            handleStartTicket(context, tickets[index]['_id']);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color.fromARGB(255, 51, 197, 66),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            'Start',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
