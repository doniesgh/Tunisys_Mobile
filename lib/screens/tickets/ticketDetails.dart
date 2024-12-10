// import 'dart:convert';
// import 'dart:typed_data';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:http/http.dart' as http;
// import 'package:todo/screens/config/config_service.dart';
// import 'package:path_provider/path_provider.dart'; // Pour le téléchargement
// import 'dart:io'; // Pour sauvegarder le fichier

// class TicketDetailScreenTech extends StatefulWidget {
//   final String ticketId;

//   const TicketDetailScreenTech(
//       {super.key, required this.ticketId, required ticket});

//   @override
//   _TicketDetailScreenState createState() => _TicketDetailScreenState();
// }

// class _TicketDetailScreenState extends State<TicketDetailScreenTech> {
//   final ConfigService configService = ConfigService();
//   Map<String, dynamic>? ticket;
//   bool isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _loadConfiguration();
//     fetchTicketDetails();
//   }

//   Future<void> _loadConfiguration() async {
//     await configService.loadConfig(); // Charge la configuration
//     setState(() {
//       // Met à jour l'interface si nécessaire
//     });
//   }

//   var address = ConfigService().adresse;
//   var port = ConfigService().port;

//   Future<void> fetchTicketDetails() async {
//     var address = ConfigService().adresse;
//     var port = ConfigService().port;
//     final url = '$address:$port/api/ticket/${widget.ticketId}';

//     try {
//       final response = await http.get(Uri.parse(url));
//       if (response.statusCode == 200) {
//         setState(() {
//           ticket = jsonDecode(response.body);
//           isLoading = false;
//         });
//       } else {
//         setState(() {
//           isLoading = false;
//         });
//       }
//     } catch (e) {
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }

//   String formatDateTime(String? dateTimeString) {
//     if (dateTimeString == null) return 'Not yet';
//     try {
//       final dateTime = DateTime.parse(dateTimeString).toLocal();
//       return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute}';
//     } catch (e) {
//       return 'Invalid date';
//     }
//   }

//   Future<void> downloadImage(Uint8List bytes, String fileName) async {
//     try {
//       final directory = await getApplicationDocumentsDirectory();
//       final file = File('${directory.path}/$fileName');
//       await file.writeAsBytes(bytes);
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Image téléchargée dans ${file.path}')),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//             content: Text('Erreur lors du téléchargement de l\'image')),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     Uint8List? imageBytes;

//     if (ticket != null &&
//         ticket!['image'] != null &&
//         ticket!['image'] is String) {
//       try {
//         imageBytes =
//             base64Decode(ticket!['image']); // Décodage de l'image en base64
//       } catch (e) {
//         print('Erreur lors du décodage de l\'image : $e');
//       }
//     }

//     // Ajoutez une nouvelle variable pour la seconde image
//     Uint8List? secondImageBytes;
//     if (ticket != null &&
//         ticket!['autre_img'] != null &&
//         ticket!['autre_img'] is String) {
//       try {
//         secondImageBytes =
//             base64Decode(ticket!['autre_img']); // Décodage de la seconde image
//       } catch (e) {
//         print('Erreur lors du décodage de la autre_image  : $e');
//       }
//     }

//     return Scaffold(
//         appBar: AppBar(
//           title: const Text('Ticket Details',
//               style: TextStyle(color: Color(0xFFD14D5A))),
//           backgroundColor: const Color(0xFFE7ECFA),
//         ),
//         body: isLoading
//             ? const Center(child: CircularProgressIndicator())
//             : ticket == null
//                 ? const Center(child: Text('Failed to load ticket details'))
//                 : SingleChildScrollView(
//                     padding: const EdgeInsets.all(10.0),
//                     child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           ListTile(
//                             leading: const Icon(Icons.confirmation_number,
//                                 color: Color.fromRGBO(209, 77, 90, 1)),
//                             title: Text(
//                                 'Ticket Reference: ${ticket!['reference']?.toString() ?? 'Unknown'}',
//                                 style: const TextStyle(
//                                     fontWeight: FontWeight.bold)),
//                           ),
//                           const Divider(),

//                           // Client Information
//                           ListTile(
//                             leading: const Icon(Icons.person,
//                                 color: Color.fromRGBO(209, 77, 90, 1)),
//                             title: const Text('Client Information',
//                                 style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.only(left: 16.0),
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(
//                                     'Client: ${ticket!['client']?['name']?.toString() ?? 'N/A'}'),
//                                 Text(
//                                     'Agence: ${ticket!['agence']?['agence']?.toString() ?? 'N/A'}'),
//                                 Text(
//                                     'Adresse: ${ticket!['agence']?['adresse']?.toString() ?? 'N/A'}'),
//                               ],
//                             ),
//                           ),
//                           const Divider(),

//                           // Equipment Information
//                           ListTile(
//                             leading: const Icon(Icons.devices,
//                                 color: Color.fromRGBO(209, 77, 90, 1)),
//                             title: const Text('Equipment Information',
//                                 style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.only(left: 16.0),
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(
//                                     'Equipement: ${ticket!['equipement']?['numero_serie']?.toString() ?? 'N/A'}'),
//                                 Text(
//                                     'Service Type: ${ticket!['service_type']?.toString() ?? 'N/A'}'),
//                               ],
//                             ),
//                           ),
//                           const Divider(),
//                           ListTile(
//                             leading: const Icon(Icons.note_alt_outlined,
//                                 color: Color.fromRGBO(209, 77, 90, 1)),
//                             title: const Text('Report Details',
//                                 style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                           // Ticket Status & Time
//                           if (ticket!['reporting_note_phone'] != null &&
//                               ticket!['reporting_phone_time'] != null)
//                             Column(
//                               children: List.generate(
//                                 ticket!['reporting_note_phone'].length,
//                                 (index) => Card(
//                                   margin:
//                                       const EdgeInsets.symmetric(vertical: 8),
//                                   elevation: 4,
//                                   child: ListTile(
//                                     title: Text(
//                                       'Report N°${index + 1}',
//                                       style: const TextStyle(
//                                           fontWeight: FontWeight.bold),
//                                     ),
//                                     subtitle: Column(
//                                       crossAxisAlignment:
//                                           CrossAxisAlignment.start,
//                                       children: [
//                                         Text(
//                                             'Note: ${ticket!['reporting_note_phone'][index]}'),
//                                         Text(
//                                             'Date: ${formatDateTime(ticket!['reporting_phone_time'][index])}'),
//                                       ],
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           if (ticket!['restarting_date_phone'] != null)
//                             Column(
//                               children: List.generate(
//                                 ticket!['restarting_date_phone'].length,
//                                 (index) => Card(
//                                   margin:
//                                       const EdgeInsets.symmetric(vertical: 8),
//                                   elevation: 4,
//                                   child: ListTile(
//                                     title: Text(
//                                       'Restart Date #${index + 1}',
//                                       style: const TextStyle(
//                                           fontWeight: FontWeight.bold),
//                                     ),
//                                     subtitle: Text(
//                                         'Date: ${formatDateTime(ticket!['restarting_date_phone'][index])}'),
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ListTile(
//                             leading: const Icon(Icons.access_time,
//                                 color: Color.fromRGBO(209, 77, 90, 1)),
//                             title: const Text('Ticket Status & Time',
//                                 style: TextStyle(fontWeight: FontWeight.bold)),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.only(left: 16.0),
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(
//                                     'Status: ${ticket!['status']?.toString() ?? 'N/A'}'),
//                                 Text(
//                                     'Receiving Time: ${formatDateTime(ticket!['created_at'])}'),
//                                 Text(
//                                     'Starting Time: ${formatDateTime(ticket!['starting_time'])}'),
//                                 Text(
//                                     'Completion Time: ${formatDateTime(ticket!['solving_time'])}'),
//                               ],
//                             ),
//                           ),
//                           const Divider(),

//                           // Section for "Fiche d'intervention images"
//                           // Afficher uniquement si une image est présente
//                           if (ticket != null &&
//                               (ticket!['image'] != null ||
//                                   secondImageBytes != null)) ...[
//                             ListTile(
//                               leading: const Icon(Icons.image,
//                                   color: Color.fromRGBO(209, 77, 90, 1)),
//                               title: const Text('Fiche d\'intervention images',
//                                   style:
//                                       TextStyle(fontWeight: FontWeight.bold)),
//                             ),

//                             // Afficher la première image si elle existe
//                             if (ticket!['image'] != null) ...[
//                               const Padding(
//                                 padding: EdgeInsets.only(top: 4.0),
//                                 child: Text('Image Fiche',
//                                     style: TextStyle(
//                                         fontSize: 16,
//                                         fontWeight: FontWeight.bold)),
//                               ),
//                               Column(
//                                 children: [
//                                   imageBytes != null
//                                       ? Image.memory(imageBytes,
//                                           width: 200, height: 200)
//                                       : Image.network(ticket!['image'],
//                                           width: 200, height: 200),
//                                   ElevatedButton(
//                                     onPressed: () {
//                                       if (imageBytes != null) {
//                                         downloadImage(
//                                             imageBytes, 'ticket_image.png');
//                                       }
//                                     },
//                                     child: const Text('Télécharger Fiche'),
//                                   ),
//                                 ],
//                               ),
//                             ],

//                             // Afficher la deuxième image si elle existe
//                             if (secondImageBytes != null) ...[
//                               const Padding(
//                                 padding: EdgeInsets.only(top: 13.0),
//                                 child: Text('Autre Image',
//                                     style: TextStyle(
//                                         fontSize: 16,
//                                         fontWeight: FontWeight.bold)),
//                               ),
//                               Image.memory(secondImageBytes,
//                                   width: 200, height: 200),
//                             ],
//                           ]
//                         ])));
//   }
// }
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:todo/screens/config/config_service.dart';
import 'package:path_provider/path_provider.dart'; // Pour le téléchargement
import 'dart:io'; // Pour sauvegarder le fichier

class TicketDetailScreenTech extends StatefulWidget {
  final String ticketId;

  const TicketDetailScreenTech(
      {super.key, required this.ticketId, required ticket});

  @override
  _TicketDetailScreenState createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreenTech> {
  final ConfigService configService = ConfigService();
  Map<String, dynamic>? ticket;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConfiguration();
    fetchTicketDetails();
  }

  Future<void> _loadConfiguration() async {
    await configService.loadConfig(); // Charge la configuration
    setState(() {
      // Met à jour l'interface si nécessaire
    });
  }

  var address = ConfigService().adresse;
  var port = ConfigService().port;

  Future<void> fetchTicketDetails() async {
    var address = ConfigService().adresse;
    var port = ConfigService().port;
    final url = '$address:$port/api/ticket/${widget.ticketId}';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() {
          ticket = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  // String formatDateTime(String? dateTimeString) {
  //   if (dateTimeString == null) return 'Not yet';
  //   try {
  //     final dateTime = DateTime.parse(dateTimeString).toLocal();
  //     return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute}';
  //   } catch (e) {
  //     return 'Invalid date';
  //   }
  // }

  String formatDateTime(String? dateTimeString) {
    if (dateTimeString == null) return 'Not yet';
    try {
      final dateTime = DateTime.parse(dateTimeString).toLocal();
      // Utilisation de DateFormat pour un formatage propre
      return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
    } catch (e) {
      return 'Invalid date';
    }
  }

  Future<void> downloadImage(Uint8List bytes, String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(bytes);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image téléchargée dans ${file.path}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Erreur lors du téléchargement de l\'image')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Uint8List? imageBytes;

    if (ticket != null &&
        ticket!['image'] != null &&
        ticket!['image'] is String) {
      try {
        imageBytes =
            base64Decode(ticket!['image']); // Décodage de l'image en base64
      } catch (e) {
        print('Erreur lors du décodage de l\'image : $e');
      }
    }

    if (ticket != null &&
        ticket!['report_img'] != null &&
        ticket!['report_img'] is String) {
      try {
        imageBytes = base64Decode(
            ticket!['report_img']); // Décodage de l'image en base64
      } catch (e) {
        print('Erreur lors du décodage de l\'image : $e');
      }
    }

    // Ajoutez une nouvelle variable pour la seconde image
    Uint8List? secondImageBytes;
    if (ticket != null &&
        ticket!['autre_img'] != null &&
        ticket!['autre_img'] is String) {
      try {
        secondImageBytes =
            base64Decode(ticket!['autre_img']); // Décodage de la seconde image
      } catch (e) {
        print('Erreur lors du décodage de l\'autre_image  : $e');
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ticket Details',
            style: TextStyle(color: Color(0xFFD14D5A))),
        backgroundColor: const Color(0xFFE7ECFA),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ticket == null
              ? const Center(child: Text('Failed to load ticket details'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.confirmation_number,
                            color: Color.fromRGBO(209, 77, 90, 1)),
                        title: Text(
                          'Ticket Reference: ${ticket!['reference']?.toString() ?? 'Unknown'}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const Divider(),

                      // Client Information
                      ListTile(
                        leading: const Icon(Icons.person,
                            color: Color.fromRGBO(209, 77, 90, 1)),
                        title: const Text('Client Information',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                'Client: ${ticket!['client']?['name']?.toString() ?? 'N/A'}'),
                            Text(
                                'Agence: ${ticket!['agence']?['agence']?.toString() ?? 'N/A'}'),
                            Text(
                                'Adresse: ${ticket!['agence']?['adresse']?.toString() ?? 'N/A'}'),
                          ],
                        ),
                      ),
                      const Divider(),

                      // Equipment Information
                      ListTile(
                        leading: const Icon(Icons.devices,
                            color: Color.fromRGBO(209, 77, 90, 1)),
                        title: const Text('Equipment Information',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                'Equipement: ${ticket!['equipement']?['numero_serie']?.toString() ?? 'N/A'}'),
                            Text(
                                'Service Type: ${ticket!['service_type']?.toString() ?? 'N/A'}'),
                          ],
                        ),
                      ),
                      const Divider(),

                      // Report Details
                      ListTile(
                        leading: const Icon(Icons.note_alt_outlined,
                            color: Color.fromRGBO(209, 77, 90, 1)),
                        title: const Text('Report Details',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      if (ticket != null) ...[
                        // Afficher le titre du rapport
                        if (ticket!['reporting_note_solve'] != null &&
                            ticket!['reporting_note_solve'].isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              'Report 1',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                          // Afficher la note du rapport si elle n'est pas vide
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              'Report Note: ${ticket!['reporting_note_solve'][0]}', // Accéder au premier élément de la liste
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                        ],

                        // Afficher la date de résolution si elle est non vide
                        if (ticket!['reporting_SolvedTicket_time'] != null &&
                            ticket!['reporting_SolvedTicket_time']
                                .isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              'Reported Time: ${formatDateTime(ticket!['reporting_SolvedTicket_time'][0])}',
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ],

                      if (ticket!['report_img'] != null &&
                          ticket!['report_img'].isNotEmpty &&
                          ticket!['report_img'][0].isNotEmpty) ...[
                        // Titre avant l'image
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            'Fiche d\'intervention', // Titre avant l'image
                            style: TextStyle(
                              fontSize: 15, // Taille du texte
                            ),
                          ),
                        ),
                        // Affichage de l'image sans découpe, mais avec taille réduite
                        Padding(
                          padding: const EdgeInsets.only(
                              top: 8.0), // Espacement entre le titre et l'image
                          child: Image.memory(
                            base64Decode(ticket!['report_img']
                                [0]), // Décoder l'image base64
                            width: 300, // Largeur de l'image
                            height: 200, // Hauteur de l'image
                            fit: BoxFit
                                .contain, // L'image sera ajustée sans découpe
                          ),
                        ),
                      ],

                      const Divider(),

                      // Ticket Status & Time
                      ListTile(
                        leading: const Icon(Icons.access_time,
                            color: Color.fromRGBO(209, 77, 90, 1)),
                        title: const Text('Ticket Status & Time',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      // Padding(
                      //   padding: const EdgeInsets.only(left: 16.0),
                      //   child: Column(
                      //     crossAxisAlignment: CrossAxisAlignment.start,
                      //     children: [
                      //       Text(
                      //           'Status: ${ticket!['status']?.toString() ?? 'N/A'}'),
                      //       Text(
                      //           'Receiving Time: ${formatDateTime(ticket!['created_at'])}'),
                      //       Text(
                      //           'Accepting Time: ${formatDateTime(ticket!['accepting_time'])}'),
                      //       Text(
                      //           'Departure Time: ${formatDateTime(ticket!['departure_time'])}'),
                      //       Text(
                      //           'Arrived Time: ${formatDateTime(ticket!['arrived_time'])}'),
                      //       Text(
                      //           'Starting Time: ${formatDateTime(ticket!['starting_time'])}'),
                      //       Text(
                      //           'Solving Time: ${formatDateTime(ticket!['solving_time'])}'),
                      //     ],
                      //   ),
                      // ),
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Afficher uniquement si la valeur est présente
                            if (ticket!['status'] != null &&
                                ticket!['status']!.isNotEmpty)
                              Text('Status: ${ticket!['status']}'),

                            if (ticket!['created_at'] != null &&
                                ticket!['created_at']!.isNotEmpty)
                              Text(
                                  'Receiving Time: ${formatDateTime(ticket!['created_at'])}'),

                            if (ticket!['accepting_time'] != null &&
                                ticket!['accepting_time']!.isNotEmpty)
                              Text(
                                  'Accepting Time: ${formatDateTime(ticket!['accepting_time'])}'),

                            if (ticket!['departure_time'] != null &&
                                ticket!['departure_time']!.isNotEmpty)
                              Text(
                                  'Departing Time: ${formatDateTime(ticket!['departure_time'])}'),

                            if (ticket!['arrival_time'] != null &&
                                ticket!['arrival_time']!.isNotEmpty)
                              Text(
                                  'Arriving Time: ${formatDateTime(ticket!['arrival_time'])}'),

                            if (ticket!['starting_time'] != null &&
                                ticket!['starting_time']!.isNotEmpty)
                              Text(
                                  'Starting Time: ${formatDateTime(ticket!['starting_time'])}'),

                            if (ticket!['solving_time'] != null &&
                                ticket!['solving_time']!.isNotEmpty)
                              Text(
                                  'Solving Time: ${formatDateTime(ticket!['solving_time'])}'),
                          ],
                        ),
                      ),
                      const Divider(),

                      // Section for "Fiche d'intervention images"
                      if (ticket!['image'] != null ||
                          secondImageBytes != null) ...[
                        ListTile(
                          leading: const Icon(Icons.image,
                              color: Color.fromRGBO(209, 77, 90, 1)),
                          title: const Text('Fiche d\'intervention images',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        if (ticket!['image'] != null) ...[
                          const Padding(
                            padding: EdgeInsets.only(top: 4.0),
                            child: Text('Image Fiche',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                          Column(
                            children: [
                              imageBytes != null
                                  ? Image.memory(imageBytes,
                                      width: 200, height: 200)
                                  : const CircularProgressIndicator(),
                            ],
                          ),
                        ],
                        if (secondImageBytes != null) ...[
                          const Padding(
                            padding: EdgeInsets.only(top: 4.0),
                            child: Text('Another Image',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                          Column(
                            children: [
                              Image.memory(secondImageBytes!,
                                  width: 200, height: 200),
                            ],
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
    );
  }
}
