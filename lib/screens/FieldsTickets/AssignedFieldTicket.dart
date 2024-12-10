import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:todo/screens/FieldsTickets/AcceptedFieldTicket.dart';
import 'dart:convert';
import 'package:todo/screens/config/config_service.dart';
import 'package:todo/screens/tickets/ticketDetails.dart';

class FieldAssignedScreen extends StatefulWidget {
  final String token;
  final String? email;

  const FieldAssignedScreen({super.key, required this.token, this.email});

  @override
  _FieldAssignedScreenState createState() => _FieldAssignedScreenState();
}

class _FieldAssignedScreenState extends State<FieldAssignedScreen> {
  final ConfigService configService = ConfigService();
  bool isLoading = false;
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

  var address = ConfigService().adresse;
  var port = ConfigService().port;

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
  //       print(
  //           'Response Data: $responseData'); // Ajoutez un log pour voir la réponse
  //       if (responseData != null) {
  //         setState(() {
  //           // Filtrage des tickets avec un status 'ASSIGNED'
  //           tickets = responseData
  //               .where((ticket) =>
  //                   ticket['status'] != null &&
  //                   ticket['status'].toString().toUpperCase() == 'ASSIGNED')
  //               .toList();

  //           print('Tickets: $tickets'); // Vérifier les tickets après filtrage
  //           isLoading = false;
  //         });
  //       } else {
  //         throw Exception('Response data is null');
  //       }
  //     } else {
  //       throw Exception('Failed to load tickets: ${response.statusCode}');
  //     }
  //   } catch (error) {
  //     print('Error fetching assigned tickets: $error');
  //     setState(() {
  //       isLoading = false;
  //     });
  //   }
  // }
  Future<void> fetchAssignedTickets() async {
    setState(() {
      isLoading = true;
    });

    var address = ConfigService().adresse;
    var port = ConfigService().port;

    // Démarrer un chronomètre pour mesurer la durée de la requête
    final stopwatch = Stopwatch()..start();

    try {
      final response = await http.get(
        Uri.parse(
            '$address:$port/api/ticketht/assigned/field/mobile?status=ASSIGNED'), // 'ASSIGNED' doit être entre guillemets
        headers: {
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      // Arrêter le chronomètre après la réponse
      stopwatch.stop();
      final duration = stopwatch.elapsed;

      // Si la réponse prend plus de 5 secondes, afficher un message de lenteur
      if (duration.inMilliseconds > 5000) {
        print(
            'Warning: Server response took too long: ${duration.inSeconds} seconds');
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Lenteur détectée'),
              content: Text(
                'La réponse du serveur a été reçue, mais elle est trop longue à traiter. Veuillez réessayer plus tard.',
              ),
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
        print('Response Data: $responseData'); // Affiche la réponse brute

        if (responseData != null) {
          setState(() {
            // Stocke les tickets dans l'état
            tickets = responseData;
            print('Tickets: $tickets'); // Affiche les tickets
            isLoading = false;
          });
        } else {
          throw Exception('Les données de la réponse sont nulles');
        }
      }
    } catch (error) {
     print('Error fetching assigned tickets: $error');
      setState(() {
        isLoading = false;
      });

      // Afficher un message d'erreur si la requête échoue
    }
  }

  Future<void> handleAcceptTicket(String ticketId) async {
    try {
      final response = await http.put(
        Uri.parse('$address:$port/api/ticket/accepted/$ticketId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'status': 'ACCEPTED'}),
      );

      if (response.statusCode == 200) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => FieldAcceptedScreen(
              token: widget.token,
            ),
          ),
        );
      } else {
        // Afficher un message d'erreur si l'API échoue
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Erreur lors de l'acceptation du ticket"),
              content: const Text("Veuillez réessayer plus tard"),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
    } catch (error) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Erreur lors de l'acceptation du ticket"),
            content: const Text("Veuillez réessayer plus tard"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Assigned',
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
                    'No assigned tickets found.',
                    style: TextStyle(fontSize: 20),
                  ),
                )
              : ListView.builder(
                  itemCount: tickets.length,
                  itemBuilder: (context, index) {
                    return Card(
                      margin: const EdgeInsets.all(10),
                      color: const Color.fromRGBO(231, 236, 250, 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          children: [
                            ListTile(
                              title: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Text(
                                        "Ticket Number: ",
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 18,
                                          color: Color.fromRGBO(50, 50, 50, 1),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          tickets[index]['reference'] ?? 'N/A',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 18,
                                            color:
                                                Color.fromRGBO(50, 50, 50, 1),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  // Affichage de la note coordinatrice

                                  // Affichage de la planification note
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildClientInfo(tickets[index]),
                                  _buildDateAndNote(tickets[index]),
                                ],
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
                            ),
                            _buildActionButtons(tickets[index], index),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

//////nouvelle version de client info pour resoudre probleme type
  ///
  Widget _buildClientInfo(Map<String, dynamic> ticket) {
    print('Help desk : ${ticket['technicien_transfer']}');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRow(
          "Client: ",
          ticket['client'] is Map && ticket['client']['name'] != null
              ? ticket['client']['name']
              : ticket['client'] ?? 'Non spécifié', // Valeur par défaut
        ),
        _buildRow(
          "Agence: ",
          ticket['agence'] is Map && ticket['agence']['agence'] != null
              ? ticket['agence']['agence']
              : ticket['agence'] ?? 'Non spécifié', // Valeur par défaut
        ),
        // Vérifiez si "Help Desk" contient des informations valides avant de l'afficher
        if (ticket['technicien_transfer'] is Map &&
            ticket['technicien_transfer']['firstname'] != null &&
            ticket['technicien_transfer']['lastname'] != null)
          _buildRow(
            "Help Desk: ",
            "${ticket['technicien_transfer']['firstname']} ${ticket['technicien_transfer']['lastname']}",
          ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Contacts: ",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              // Vérifiez si le champ des contacts est vide
              ticket['agence'] is Map &&
                      ticket['agence']['contacts'] is List &&
                      ticket['agence']['contacts'].isNotEmpty
                  ? Column(
                      children: List.generate(
                        ticket['agence']['contacts'].length,
                        (index) {
                          var contact = ticket['agence']['contacts'][index];

                          // Vérifiez si le contact est un Map et a des valeurs valides
                          if (contact is Map &&
                              contact['name'] != null &&
                              contact['phone'] != null) {
                            // Vérifier si le nom est "CA" ou "CB"
                            if (contact['name'] == "CA" ||
                                contact['name'] == "CB") {
                              return Container(); // Ne rien afficher pour CA ou CB
                            } else {
                              return Row(
                                children: [
                                  Icon(Icons.phone,
                                      size: 16, color: Colors.blue),
                                  SizedBox(width: 8),
                                  Text(
                                    "Chargé DAB : ",
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  Text(
                                    "${contact['phone']}",
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ],
                              );
                            }
                          }
                          return Text(
                              'Contact incomplet'); // Message pour contact incomplet
                        },
                      ),
                    )
                  : Text('Non spécifié'), // Cas où il n'y a pas de contacts

              // Vérifiez si tous les contacts sont "CA" ou "CB"
              if (ticket['agence']['contacts'] is List &&
                  ticket['agence']['contacts'].isNotEmpty &&
                  ticket['agence']['contacts'].every((contact) {
                    return contact is Map &&
                        contact['name'] != null &&
                        (contact['name'] == "CA" || contact['name'] == "CB");
                  }))
                Text(
                  'Aucun contact disponible',
                  style: TextStyle(
                      color: Colors.grey), // Changer la couleur en gris
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateAndNote(Map<String, dynamic> ticket) {
    print('Date de transfert: ${ticket['transfering_time']}');
    print(
        'Raison de transfert: ${ticket['raison_transfert']}'); // Log pour debug

    // Vérifier si 'raison_transfert' existe, est une liste et non vide
    String? raisonTransfert;
    if (ticket.containsKey('raison_transfert') &&
        ticket['raison_transfert'] is List &&
        (ticket['raison_transfert'] as List).isNotEmpty) {
      // Joindre les éléments du tableau avec une virgule ou un autre séparateur
      raisonTransfert = (ticket['raison_transfert'] as List).join(', ');
    }

    return Column(
      children: [
        _buildRow("Note Coordinatrice: ", ticket['note'] ?? 'N/A'),
        if (raisonTransfert !=
            null) // Affiche seulement si raisonTransfert n'est pas null
          _buildRow("Planification Note: ", raisonTransfert),
      ],
    );
  }

  String formatDate(String? dateString) {
    if (dateString == null || dateString == 'N/A') {
      return 'N/A'; // Si la date est absente ou invalide, renvoyer 'N/A'
    }
    try {
      DateTime? parsedDate = DateTime.tryParse(dateString);
      if (parsedDate == null) {
        return 'N/A'; // Si parsing échoue, renvoyer 'N/A'
      }
      return DateFormat('dd/MM/yyyy')
          .format(parsedDate); // Format du jour/mois/année
    } catch (e) {
      return 'N/A'; // Si une erreur se produit pendant le parsing, renvoyer 'N/A'
    }
  }

  String formatTime(String? dateString) {
    if (dateString == null || dateString == 'N/A') {
      return 'N/A'; // Si l'heure est absente ou invalide, renvoyer 'N/A'
    }
    try {
      DateTime? parsedDate = DateTime.tryParse(dateString);
      if (parsedDate == null) {
        return 'N/A'; // Si parsing échoue, renvoyer 'N/A'
      }
      return DateFormat('HH:mm:ss')
          .format(parsedDate); // Format des heures/minutes/secondes
    } catch (e) {
      return 'N/A'; // Si une erreur se produit pendant le parsing, renvoyer 'N/A'
    }
  }

/*
  Widget _buildRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Color.fromRGBO(52, 52, 52, 1),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            color: Color.fromARGB(255, 102, 102, 102),
          ),
        ),
      ],
    );
  } */
  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start, // Assurer l'alignement au début
        children: [
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 14),
              softWrap: true, // Permet le retour à la ligne
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> ticket, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const SizedBox(width: 25),
          // ElevatedButton.icon(
          //   onPressed: () {
          //     handleAcceptTicket(tickets[index]['_id']); // Corriger ici aussi
          //   },
          //   style: ElevatedButton.styleFrom(
          //     backgroundColor: const Color(0xFFFFB6B9),
          //     shape: RoundedRectangleBorder(
          //       borderRadius: BorderRadius.circular(15),
          //     ),
          //     padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          //   ),
          //   icon: const Icon(Icons.play_arrow, color: Colors.white),
          //   label: const Text(
          //     'Accept',
          //     style: TextStyle(color: Colors.white),
          //   ),
          // ),
          ElevatedButton.icon(
            onPressed: () {
              handleAcceptTicket(tickets[index]['_id']);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFB6B9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              minimumSize: Size(120, 40), // Limite la taille minimale
              maximumSize: Size(150, 50), // Limite la taille maximale
            ),
            icon: const Icon(Icons.play_arrow, color: Colors.white),
            label: const Text(
              'Accept',
              style: TextStyle(color: Colors.white),
            ),
          )
        ],
      ),
    );
  }
}
