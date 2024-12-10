import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:todo/screens/FieldsTickets/AcceptedFieldTicket.dart';
import 'dart:convert';
import 'package:todo/screens/config/config_service.dart';
import 'package:todo/screens/tickets/ticketDetails.dart';

class FieldTransferedScreen extends StatefulWidget {
  final String token;
  final String? email;

  const FieldTransferedScreen({super.key, required this.token, this.email});

  @override
  _FieldTransferedScreenState createState() => _FieldTransferedScreenState();
}

class _FieldTransferedScreenState extends State<FieldTransferedScreen> {
  final ConfigService configService = ConfigService();
  bool isLoading = false;
  List<dynamic> tickets = [];

  @override
  void initState() {
    super.initState();
    _loadConfiguration();
    fetchTransferedTickets();
  }

  Future<void> _loadConfiguration() async {
    await configService.loadConfig(); // Charge la configuration
    setState(() {
      // Met à jour l'interface si nécessaire
    });
  }

  var address = ConfigService().adresse;
  var port = ConfigService().port;
  // Future<void> fetchTransferedTickets() async {
  //   var address = ConfigService().adresse;
  //   var port = ConfigService().port;
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
  //               .where((ticket) =>
  //                   ticket['status'] != null &&
  //                   ticket['status'] == 'TRANSFERED')
  //               .toList();
  //           isLoading = false;
  //         });
  //       } else {
  //         throw Exception('Response data is null');
  //       }
  //     } else {
  //       throw Exception('Failed to load tickets: ${response.statusCode}');
  //     }
  //   } catch (error) {
  //     print('Error fetching alerts: $error');
  //     setState(() {
  //       isLoading = false;
  //     });
  //   }
  // }
  Future<void> fetchTransferedTickets() async {
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
            '$address:$port/api/ticketht/assigned/field/mobile?status=TRANSFERED'), // 'ASSIGNED' doit être entre guillemets
        headers: {
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      // Arrêter le chronomètre après la réponse
      stopwatch.stop();
      final duration = stopwatch.elapsed;

      // Vérifier si la réponse a pris plus de 5 secondes
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
                .where((ticket) =>
                    ticket['status'] != null &&
                    ticket['status'] == 'TRANSFERED')
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
            'Échec du chargement des tickets : ${response.statusCode}');
      }
    } catch (error) {
      print('Erreur lors de la récupération des tickets: $error');
      setState(() {
        isLoading = false;
      });

      // Vérifiez si le chronomètre est toujours en cours d'exécution (indiquant une lenteur)
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

      // Afficher un message spécifique si une erreur est survenue
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Erreur de récupération des tickets'),
            content: Text(
                'Une erreur est survenue lors de la récupération des tickets. Veuillez réessayer plus tard.'),
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

  Future<void> handleAcceptTicket(String ticketId) async {
    try {
      final response = await http.put(
        Uri.parse('$address:$port/api/ticket/accepted/$ticketId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'status': 'ACCEPTED'}),
      );

      if (response.statusCode == 200) {
        // Si la requête est réussie, naviguer vers l'écran suivant
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => FieldAcceptedScreen(
              token: widget.token,
            ),
          ),
        );
      } else {
        // Afficher un modal d'erreur si la requête échoue
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
      // Afficher un modal d'erreur en cas d'exception
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
          'Transfered Tickets',
          style: TextStyle(color: Color.fromRGBO(209, 77, 90, 1), fontSize: 24),
        ),
        backgroundColor: const Color.fromRGBO(231, 236, 250, 1),
        toolbarHeight: 60,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchTransferedTickets,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : tickets.isEmpty
              ? const Center(
                  child: Text(
                    'No transfered tickets found.',
                    style: TextStyle(fontSize: 20),
                  ),
                )
              : Container(
                  constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context)
                          .size
                          .height), // Set constraints here
                  child: ListView.builder(
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
                                title: Text(
                                  tickets[index]['reference'] ?? 'N/A',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 18,
                                    color: Color.fromRGBO(50, 50, 50, 1),
                                  ),
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
                              _buildActionButtons(tickets[index]),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildClientInfo(Map<String, dynamic> ticket) {
    print('Phone techncien : ${ticket['technicien_transfer']}');
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
        _buildRow(
          "Help desk: ",
          ticket['technicien_transfer'] is Map //technicien twali
              ? "${ticket['technicien_transfer']['firstname']} ${ticket['technicien_transfer']['lastname']}"
              : 'Non spécifié',
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
              if (ticket['agence']['contacts'].isNotEmpty &&
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
        )
      ],
    );
  }

  Widget _buildDateAndNote(Map<String, dynamic> ticket) {
    print('Transfering time: ${ticket['transfering_time']}');

    // Vérifiez si les champs sont vides ou nuls pour les notes
    bool hasTransfereNotePhone = ticket['transfere_note_phone'] != null &&
        (ticket['transfere_note_phone'] is List &&
                ticket['transfere_note_phone'].isNotEmpty ||
            ticket['transfere_note_phone'] is String &&
                ticket['transfere_note_phone'].isNotEmpty);

    bool hasRaisonTransfert = ticket['raison_transfert'] != null &&
        (ticket['raison_transfert'] is List &&
                ticket['raison_transfert'].isNotEmpty ||
            ticket['raison_transfert'] is String &&
                ticket['raison_transfert'].isNotEmpty);

    // Vérifiez si la date 'transfering_time' est non nulle et non vide
    bool hasTransferingTime = ticket['transfering_time'] != null &&
        ticket['transfering_time'].isNotEmpty;

    // Si tous les champs sont vides, retournez un conteneur vide
    if (!hasTransfereNotePhone && !hasRaisonTransfert && !hasTransferingTime) {
      return SizedBox.shrink(); // Conteneur vide
    }

    // Affiche les widgets seulement si au moins un des champs a du contenu
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Affichage des notes
          if (hasTransfereNotePhone) ...[
            Text(
              "Note helpdesk:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4.0),
            Container(
              width: double.infinity,
              child: Text(
                ticket['transfere_note_phone'] is List
                    ? ticket['transfere_note_phone'].join(", ")
                    : ticket['transfere_note_phone'],
                softWrap: true,
                textAlign: TextAlign.start,
                style: TextStyle(fontSize: 16),
              ),
            ),
            SizedBox(height: 8.0), // Espace entre les sections
          ],
          if (hasRaisonTransfert) ...[
            Text(
              "Note Coordinatrice:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4.0),
            Container(
              width: double.infinity,
              child: Text(
                ticket['raison_transfert'] is List
                    ? ticket['raison_transfert'].join(", ")
                    : ticket['raison_transfert'],
                softWrap: true,
                textAlign: TextAlign.start,
                style: TextStyle(fontSize: 16),
              ),
            ),
            SizedBox(height: 8.0), // Espace entre les sections
          ],

          // Affichage de la date si elle existe
          if (hasTransferingTime) ...[
            Text(
              "Transferring Date:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4.0),
            Text(
              formatDate(ticket['transfering_time']),
              style: TextStyle(fontSize: 16),
            ),
          ],
        ],
      ),
    );
  }

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

  String formatDate(String isoDate) {
    DateTime parsedDate = DateTime.parse(isoDate);
    // Format date as 'dd/MM/yyyy HH:mm'
    return DateFormat('HH:mm dd/MM/yyyy').format(parsedDate.toLocal());
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

  Widget _buildActionButtons(Map<String, dynamic> ticket) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const SizedBox(width: 30),
          ElevatedButton.icon(
            onPressed: () {
              handleAcceptTicket(ticket['_id']);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFB6B9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            ),
            icon: const Icon(Icons.done, color: Colors.white),
            label: const Text(
              'Accept',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
