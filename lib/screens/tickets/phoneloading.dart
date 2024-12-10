import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:todo/screens/tickets/phonereported.dart';
import 'package:todo/screens/tickets/phonesolved.dart';
import 'package:todo/screens/tickets/phonetransfered.dart';
import 'package:todo/screens/tickets/reportDialog.dart';
import 'package:todo/screens/tickets/ticketDetails.dart';
import 'dart:convert';
import 'solvingTicketModal.dart';
import 'package:todo/screens/config/config_service.dart';

class PhoneLoadingScreen extends StatefulWidget {
  final String token;
  final String? email;

  const PhoneLoadingScreen({super.key, required this.token, this.email});

  @override
  _PhoneLoadingScreenState createState() => _PhoneLoadingScreenState();
}

class _PhoneLoadingScreenState extends State<PhoneLoadingScreen> {
  bool isLoading = false;
  List<dynamic> tickets = [];
  String? selectedReason; // Variable pour stocker la raison sélectionnée
  List<String> reasons = [
    'Client indisponible',
    'Client injoignable',
    'Problème technique',
    'Autre',
  ];
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
        Uri.parse('$address:$port/api/ticketht/assigned/phone'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
        },
      );
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData != null) {
          setState(() {
            tickets = responseData
                .where((ticket) => ticket['status'] == 'HANDLED')
                .toList();
          });
        } else {
          throw Exception('Response data is null');
        }
      } else {
        throw Exception('Failed to load tickets: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching tickets: $error');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void showsolveddialog(BuildContext context, String ticketId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleHelloDialog(ticketId: ticketId, token: widget.token);
      },
    );
  }

  void showreportdialog(BuildContext context, String ticketId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ShowReportDialog(ticketId: ticketId, token: widget.token);
      },
    );
  }

  void showtrasnferdialog(BuildContext context, String ticketId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleHelloDialog(ticketId: ticketId, token: widget.token);
      },
    );
  }

  Future<void> handleTransfereTicket(String ticketId) async {
    String transfere_note_phone =
        ''; // Variable pour stocker la raison du report
    bool showError = false; // Variable pour gérer l'affichage de l'erreur

    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Transfering Ticket ?'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Text('Pourquoi voulez-vous transférer le ticket ?'),
                  TextField(
                    onChanged: (value) {
                      setState(() {
                        transfere_note_phone = value;
                        showError =
                            false; // Masquer l'erreur à chaque modification
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Raison du transfert',
                      hintStyle: TextStyle(
                        color: Colors
                            .grey[400], // Couleur du hint text (gris clair)
                        fontSize: 14, // Taille du texte d'indication
                      ),
                      contentPadding: const EdgeInsets.only(
                          bottom:
                              0), // Espacement pour approcher le hint du bas
                    ),
                  ),
                  if (showError) // Afficher un message d'erreur si le champ est vide
                    const Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Le champ de raison du transfert est requis *',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context)
                        .pop(false); // Annule l'action de transfert
                  },
                  child: const Text('Annuler'),
                ),
                TextButton(
                  onPressed: () async {
                    if (transfere_note_phone.trim().isEmpty) {
                      // Si le champ est vide, afficher l'erreur
                      setState(() {
                        showError = true;
                      });
                      return; // Arrête l'exécution ici
                    }

                    // Si la raison est remplie, fermer le modal et appeler l'API
                    Navigator.of(context).pop(true);

                    try {
                      final response = await http.put(
                        Uri.parse(
                            '$address:$port/api/ticket/transferphone/$ticketId'),
                        headers: {'Content-Type': 'application/json'},
                        body: json.encode({
                          'status': 'TRANSFERED',
                          'transfere_note_phone': transfere_note_phone,
                          'transfere_phone_time':
                              DateTime.now().toIso8601String(),
                        }),
                      );

                      if (response.statusCode == 200) {
                        print("Ticket mis à jour avec succès !");
                        // Redirection directe après succès
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PhoneTransferedScreen(
                              token: widget.token,
                            ),
                          ),
                        );
                      } else {
                        // Gérer les autres codes d'erreur ici
                        print(
                            "Erreur lors de la mise à jour du ticket: ${response.body}");
                        throw Exception('Échec du solve du ticket');
                      }
                    } catch (error) {
                      // Afficher un message d'erreur en cas de problème
                      print(
                          "Erreur lors du solve: $error. Veuillez réessayer plus tard.");
                    }
                  },
                  child: const Text('Transfer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String solutionPhone = ''; // Variable pour stocker la solution du ticket
  bool showError = false; // Variable pour afficher ou masquer l'erreur

  Future<void> handleSolveTicket(String ticketId) async {
    await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Completing Ticket ?'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextField(
                    onChanged: (value) {
                      setState(() {
                        solutionPhone = value;
                        showError =
                            false; // Masquer l'erreur à chaque modification
                      });
                    },
                    decoration: const InputDecoration(
                      hintText: 'Solution',
                    ),
                  ),
                  if (showError) // Afficher l'erreur si le champ est vide
                    const Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Champs solution obligatoire *',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(false); // Annule l'action
                  },
                  child: const Text('Annuler'),
                ),
                TextButton(
                  onPressed: () async {
                    if (solutionPhone.trim().isEmpty) {
                      // Si le champ est vide, afficher l'erreur et ne pas fermer le modal
                      setState(() {
                        showError = true;
                      });
                      return; // Arrête l'exécution ici
                    }

                    // Si la solution est remplie, appeler l'API
                    try {
                      print("Tentative de mise à jour du ticket...");

                      final response = await http.put(
                        Uri.parse('$address:$port/api/ticket/solved/$ticketId'),
                        headers: {'Content-Type': 'application/json'},
                        body: json.encode({
                          'status': 'COMPLETED',
                          'solution_phone': solutionPhone,
                          //   'solving_time': DateTime.now().toIso8601String(),
                        }),
                      );

                      print("Statut de la réponse: ${response.statusCode}");

                      if (response.statusCode == 200) {
                        print("Ticket mis à jour avec succès !");
                        // Redirection directe après succès
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PhoneSolvedScreen(
                              token: widget.token,
                            ),
                          ),
                        );
                      } else {
                        // Gérer les autres codes d'erreur ici
                        print(
                            "Erreur lors de la mise à jour du ticket: ${response.body}");
                        throw Exception('Échec du solve du ticket');
                      }
                    } catch (error) {
                      // Afficher un message d'erreur en cas de problème
                      print(
                          "Erreur lors du solve: $error. Veuillez réessayer plus tard.");
                    }
                  },
                  child: const Text('Solve'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> handleReportTicket(String ticketId) async {
    String reporting_note_phone = ''; // Variable pour la note de report
    bool showErrorReason = false; // Gérer l'erreur pour la raison
    bool showErrorNote = false; // Gérer l'erreur pour la note
    TimeOfDay? selectedTime; // Variable pour stocker l'heure sélectionnée
    String? selectedReason; // Variable pour la raison du report
    String? raison_report_phone;

    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Reporter le ticket ?'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // Les champs de saisie et validations
                    Row(
                      children: [
                        const Text('Raison du report : '),
                        if (showErrorReason && selectedReason == null)
                          const Text(
                            ' *',
                            style: TextStyle(color: Colors.red),
                          ),
                      ],
                    ),
                    DropdownButton<String>(
                      value: selectedReason,
                      hint: const Text('Sélectionnez une raison'),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedReason = newValue;
                          raison_report_phone = newValue;
                          showErrorReason = false;
                        });
                      },
                      items:
                          reasons.map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                    if (showErrorReason && selectedReason == null)
                      const Padding(
                        padding: EdgeInsets.only(top: 4.0),
                        child: Text(
                          'Le champ de raison est obligatoire',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    const SizedBox(height: 16),
                    // Heure du report
                    Row(
                      children: [
                        const Text('Heure du report :'),
                        if (showErrorNote && reporting_note_phone.isEmpty)
                          const Text(
                            ' *',
                            style: TextStyle(color: Colors.red),
                          ),
                      ],
                    ),
                    TextButton(
                      onPressed: () async {
                        final TimeOfDay? picked = await showTimePicker(
                          context: context,
                          initialTime: selectedTime ?? TimeOfDay.now(),
                        );
                        if (picked != null && picked != selectedTime) {
                          setState(() {
                            selectedTime = picked;
                            final now = DateTime.now();
                            final reminderTime = DateTime(now.year, now.month,
                                now.day, picked.hour, picked.minute);
                            reporting_note_phone =
                                reminderTime.toUtc().toIso8601String();
                            showErrorNote = false;
                          });
                        }
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.access_time, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text(
                            selectedTime != null
                                ? 'Rappeler à : ${selectedTime!.format(context)}'
                                : 'Choisir l\'heure',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue),
                          ),
                        ],
                      ),
                    ),
                    if (showErrorNote && reporting_note_phone.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 4.0),
                        child: Text(
                          'Le champ heure report est obligatoire',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context)
                        .pop(false); // Annule l'action de report
                  },
                  child: const Text('Annuler'),
                ),
                TextButton(
                  onPressed: () async {
                    if (selectedReason == null ||
                        reporting_note_phone.trim().isEmpty) {
                      setState(() {
                        showErrorReason = selectedReason == null;
                        showErrorNote = reporting_note_phone.trim().isEmpty;
                      });
                      return; // Arrête l'exécution ici
                    }

                    // Commence la navigation immédiatement après le report
                    Navigator.of(context).pop(true);

                    if (!mounted)
                      return; // Vérifie si le widget est encore monté

                    try {
                      final currentTimeUtc = DateTime.now().toUtc();
                      print('Heure actuelle en UTC: $currentTimeUtc');

                      final response = await http.put(
                        Uri.parse(
                            '$address:$port/api/ticket/ReportPhone/$ticketId'),
                        headers: {'Content-Type': 'application/json'},
                        body: json.encode({
                          'status': 'REPORTED',
                          'reporting_note_phone': reporting_note_phone,
                          'raison_report_phone': raison_report_phone,
                          'reporting_phone_time':
                              DateTime.now().toIso8601String(),
                        }),
                      );

                      if (response.statusCode == 200) {
                        print("Ticket reporté avec succès !");

                        // Naviguer immédiatement vers la nouvelle page
                        if (!mounted) return;
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                PhoneReportedScreen(token: widget.token),
                          ),
                        );
                      } else {
                        print(
                            "Erreur lors du report du ticket: ${response.body}");
                        throw Exception('Échec du report du ticket');
                      }
                    } catch (error) {
                      print(
                          "Erreur lors du report: $error. Veuillez réessayer plus tard.");
                      if (!mounted)
                        return; // Vérifie si le widget est toujours monté
                      if (context.mounted) {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text("Erreur lors du report"),
                              content:
                                  const Text("Veuillez réessayer plus tard"),
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
                  },
                  child: const Text('Reporter'),
                ),
              ],
            );
          },
        );
      },
    );
  }

/*
  Future<void> handleReportTicket(String ticketId) async {
    String reporting_note_phone = ''; // Variable pour la note de report
    bool showErrorReason = false; // Gérer l'erreur pour la raison
    bool showErrorNote = false; // Gérer l'erreur pour la note
    TimeOfDay? selectedTime; // Variable pour stocker l'heure sélectionnée
    String? selectedReason; // Variable pour la raison du report
    String? raison_report_phone;

    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Reporter le ticket ?'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: [
                        const Text('Raison du report : '),
                        if (showErrorReason && selectedReason == null)
                          const Text(
                            ' *',
                            style: TextStyle(color: Colors.red),
                          ),
                      ],
                    ),
                    DropdownButton<String>(
                      value: selectedReason,
                      hint: const Text('Sélectionnez une raison'),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedReason = newValue;
                          raison_report_phone = newValue;
                          showErrorReason = false;
                        });
                      },
                      items:
                          reasons.map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                    if (showErrorReason && selectedReason == null)
                      const Padding(
                        padding: EdgeInsets.only(top: 4.0),
                        child: Text(
                          'Le champ de raison est obligatoire',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('Heure du report :'),
                        if (showErrorNote && reporting_note_phone.isEmpty)
                          const Text(
                            ' *',
                            style: TextStyle(color: Colors.red),
                          ),
                      ],
                    ),
                    TextButton(
                      onPressed: () async {
                        final TimeOfDay? picked = await showTimePicker(
                          context: context,
                          initialTime: selectedTime ?? TimeOfDay.now(),
                        );
                        if (picked != null && picked != selectedTime) {
                          setState(() {
                            selectedTime = picked;
                            final now = DateTime.now();
                            final reminderTime = DateTime(now.year, now.month,
                                now.day, picked.hour, picked.minute);
                            reporting_note_phone =
                                reminderTime.toUtc().toIso8601String();
                            showErrorNote = false;
                          });
                        }
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.access_time, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text(
                            selectedTime != null
                                ? 'Rappeler à : ${selectedTime!.format(context)}'
                                : 'Choisir l\'heure',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue),
                          ),
                        ],
                      ),
                    ),
                    if (showErrorNote && reporting_note_phone.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 4.0),
                        child: Text(
                          'Le champ heure report est obligatoire',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context)
                        .pop(false); // Annule l'action de report
                  },
                  child: const Text('Annuler'),
                ),
                TextButton(
                  onPressed: () async {
                    if (selectedReason == null ||
                        reporting_note_phone.trim().isEmpty) {
                      setState(() {
                        showErrorReason = selectedReason == null;
                        showErrorNote = reporting_note_phone.trim().isEmpty;
                      });
                      return; // Arrête l'exécution ici
                    }
                    Navigator.of(context).pop(true);

                    if (!mounted) return; // Check if widget is still mounted

                    try {
                      final currentTimeUtc = DateTime.now().toUtc();
                      print('Heure actuelle en UTC: $currentTimeUtc');

                      final response = await http.put(
                        Uri.parse(
                            '$address:$port/api/ticket/ReportPhone/$ticketId'),
                        headers: {'Content-Type': 'application/json'},
                        body: json.encode({
                          'status': 'REPORTED',
                          'reporting_note_phone': reporting_note_phone,
                          'raison_report_phone': raison_report_phone,
                          'reporting_phone_time':
                              DateTime.now().toIso8601String(),
                        }),
                      );

                      if (response.statusCode == 200) {
                        print("Ticket reporté avec succès !");
                        if (!mounted)
                          return; // Ensure context is still valid before navigation

                        // Ensure the navigation happens after context is valid
                        Future.delayed(Duration.zero, () {
                          if (mounted) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    PhoneReportedScreen(token: widget.token),
                              ),
                            );
                          }
                        });
                      } else {
                        print(
                            "Erreur lors du report du ticket: ${response.body}");
                        throw Exception('Échec du report du ticket');
                      }
                    } catch (error) {
                      print(
                          "Erreur lors du report: $error. Veuillez réessayer plus tard.");
                      if (!mounted)
                        return; // Ensure context is still valid before showing dialog
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text("Erreur lors du report"),
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
                  },
                  child: const Text('Reporter'),
                ),
              ],
            );
          },
        );
      },
    );
  }
*/

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
                      color: const Color.fromRGBO(231, 236, 250, 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          children: [
                            ListTile(
                              title: Row(
                                children: [
                                  const Text(
                                    "Ticket Number: ",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 18,
                                      color: Color.fromRGBO(50, 50, 50, 1),
                                    ),
                                  ),
                                  Text(
                                    tickets[index]['reference'] ?? 'N/A',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 18,
                                      color: Color.fromRGBO(50, 50, 50, 1),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildClientInfo(tickets[index]),
                                  //    _buildDateAndNote(tickets[index]),
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
                            const SizedBox(height: 10), // Space before buttons

                            // Buttons for Solve, Report, and Transfer
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                // Solve Button
                                ElevatedButton(
                                  onPressed: () {
                                    handleSolveTicket(tickets[index]['_id']);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        const Color.fromARGB(255, 40, 176, 217),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text(
                                    'Solved',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 12),
                                  ),
                                ),
                                // Report Button
                                ElevatedButton(
                                  onPressed: () {
                                    handleReportTicket(tickets[index]['_id']);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color.fromARGB(
                                        255, 136, 139, 138),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text(
                                    'Report',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 12),
                                  ),
                                ),
                                // Transfer Button
                                // Transfer Button
                                ElevatedButton(
                                  onPressed: () {
                                    handleTransfereTicket(
                                        tickets[index]['_id']);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        const Color.fromARGB(255, 224, 60, 219),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                        horizontal: 15), // Adjust padding
                                    minimumSize:
                                        Size(100, 30), // Set minimum size
                                  ),
                                  child: const Text(
                                    'Transfer to field',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12, // Reduce font size
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10), // Space after buttons
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildClientInfo(Map<String, dynamic> ticket) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRow(
          "Client: ",
          ticket['client'] is Map && ticket['client']['name'] != null
              ? ticket['client']['name']
              : 'Non spécifié',
        ),
        _buildRow(
          "Agence: ",
          ticket['agence'] is Map && ticket['agence']['agence'] != null
              ? ticket['agence']['agence']
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

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateAndNote(Map<String, dynamic> ticket) {
    return Column(
      children: [
        _buildRow("Note: ", ticket['note'] ?? 'N/A'),
        _buildRow("Assigned Date: ", formatDate(ticket['created_at'])),
        _buildRow("Assigned Hour: ", formatTime(ticket['created_at'])),
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

  // Widget _buildRow(String label, String value) {
  //   return Padding(
  //     padding: const EdgeInsets.only(top: 4.0),
  //     child: Row(
  //       children: [
  //         Text(
  //           label,
  //           style: const TextStyle(fontWeight: FontWeight.bold),
  //         ),
  //         const SizedBox(width: 5),
  //         Text(value),
  //       ],
  //     ),
  //   );
  // }
}
