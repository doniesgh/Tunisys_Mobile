import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:todo/screens/config/config_service.dart';

class TicketDetailScreen extends StatefulWidget {
  final String ticketId; // Receive ticket ID as a parameter

  TicketDetailScreen({required this.ticketId});

  @override
  _TicketDetailScreenState createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  Map<String, dynamic>? ticket;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchTicketDetails();
  }

  var address = ConfigService().adresse;
  var port = ConfigService().port;
  // Fetch ticket details by ID
  Future<void> fetchTicketDetails() async {
    final url = '$address:$port/api/ticket/${widget.ticketId}';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() {
          ticket = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        print('Failed to load ticket details');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching ticket details: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String formatDate(String? date) {
      if (date == null) return 'Not yet';
      try {
        return DateFormat('yyyy/MM/dd HH:mm').format(DateTime.parse(date));
      } catch (e) {
        return 'Invalid date';
      }
    }

    Uint8List? imageBytes;
    if (ticket != null &&
        ticket!['image'] != null &&
        ticket!['image'] is String) {
      try {
        imageBytes = base64Decode(ticket!['image']);
      } catch (e) {
        print('Error decoding base64 image: $e');
      }
    }
    String formatDateTime(String? dateTimeString) {
      if (dateTimeString == null) return 'Not yet';

      try {
        final dateTime = DateTime.parse(dateTimeString).toLocal();
        return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute}';
      } catch (e) {
        return 'Invalid date';
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Ticket Details',
          style: TextStyle(color: Colors.white, fontSize: 24),
        ),
        backgroundColor: Color.fromRGBO(209, 77, 90, 1),
        toolbarHeight: 60,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ticket == null
              ? Center(child: Text('Failed to load ticket details'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ticket Reference: ${ticket!['reference']?.toString() ?? 'Unknown'}',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text(
                          'Client: ${ticket!['client']?['name']?.toString() ?? 'N/A'}'),
                      Text(
                          'Agence: ${ticket!['agence']?['agence']?.toString() ?? 'N/A'}'),
                      Text(
                          'Agence Adresse: ${ticket!['agence']?['adresse']?.toString() ?? 'N/A'}'),
                      Text(
                          'Agence Localisation: ${ticket!['agence']?['localisation']?.toString() ?? 'N/A'}'),
                      Text(
                          'Agence Gouvernorat: ${ticket!['agence']?['gouvernourat']?.toString() ?? 'N/A'}'),
                      Text(
                          'Equipement: ${ticket!['equipement']?['numero_serie']?.toString() ?? 'N/A'}'),
                      Text(
                          'Service Type: ${ticket!['service_type']?.toString() ?? 'N/A'}'),
                      Text('Type: ${ticket!['type']?.toString() ?? 'N/A'}'),
                      Text('Status: ${ticket!['status']?.toString() ?? 'N/A'}'),
                      Text('Note: ${ticket!['note']?.toString() ?? 'N/A'}'),
                      Text(
                          'QR Code: ${ticket!['codeqrequipement']?.toString() ?? 'N/A'}'),
                      Text(
                          'Solution: ${ticket!['solution']?.toString() ?? 'Not Yet'}'),
                      Text(
                        'receiving Time: ${formatDateTime(ticket!['created_at'])}',
                        style: TextStyle(fontSize: 16),
                      ),
                      Text(
                        'Accepting Time: ${formatDateTime(ticket!['accepting_time'])}',
                        style: TextStyle(fontSize: 16),
                      ),
                      Text(
                        'Starting Time: ${formatDateTime(ticket!['starting_time'])}',
                        style: TextStyle(fontSize: 16),
                      ),
                      Text(
                        'Solving Time: ${formatDateTime(ticket!['solving_time'])}',
                        style: TextStyle(fontSize: 16),
                      ),
                      Text(
                        'Completion Time: ${formatDateTime(ticket!['completion_time'])}',
                        style: TextStyle(fontSize: 16),
                      ),
                      if (ticket!['raison_transfert'] != null) ...[
                        Text(
                          'Raison Transfert: ${ticket!['raison_transfert']?.toString() ?? 'N/A'}',
                          style: TextStyle(fontSize: 16),
                        ),
                        Text(
                          'Technicien Firstname: ${ticket!['technicien_transfer']?['firstname']?.toString() ?? 'N/A'}',
                          style: TextStyle(fontSize: 16),
                        ),
                        Text(
                          'Technicien Lastname: ${ticket!['technicien_transfer']?['lastname']?.toString() ?? 'N/A'}',
                          style: TextStyle(fontSize: 16),
                        ),
                        Text(
                          'Transfering Time: ${formatDateTime(ticket!['transfering_time'])}',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                      if (imageBytes != null) Image.memory(imageBytes!),
                    ],
                  ),
                ),
    );
  }
}

/*
            SizedBox(height: 20),
            Text(
              'Photo Fiche Intervention',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            if (imageBytes != null && imageBytes.isNotEmpty) ...[
              Container(
                constraints: BoxConstraints(
                    maxHeight: 300), // Limite de hauteur pour l'image
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: 0,
                      maxHeight: 300,
                    ),
                    child: Image.memory(
                      imageBytes,
                      fit: BoxFit
                          .contain, // Redimensionner l'image pour la faire tenir dans le conteneur
                    ),
                  ),
                ),
              ),
            ] else ...[
              Text('No image available'),
            ],
            SizedBox(height: 20),
            // Afficher le bouton si le statut est 'APPROVED'
            if (isApproved)
              ElevatedButton(
                onPressed: () {
                  // Code pour télécharger le PDF ou autre action
                },
                child: Text('Download PDF'),
              ),*/

 /*
    Future<void> downloadPdf() async {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  padding: pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.red, width: 2),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Tunisys',
                              style: pw.TextStyle(
                                  fontSize: 25,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.red)),
                          pw.Text('124, Avenue de la liberté'),
                          pw.Text('1002 Tunis-Bélvedére'),
                          pw.Text('Tél : 71 791 699'),
                          pw.Text('Fax : 71 786 188'),
                        ],
                      ),
                      pw.Container(
                        padding: pw.EdgeInsets.all(10),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.red, width: 8),
                        ),
                        child: pw.Text('Fiche Intervention',
                            style: pw.TextStyle(
                                fontSize: 20,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.red)),
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Date :', style: pw.TextStyle(fontSize: 12)),
                          pw.Text(formatDate(ticket['completion_time']),
                              style: pw.TextStyle(fontSize: 15)),
                          pw.SizedBox(height: 10),
                          pw.Text('Numéro :',
                              style: pw.TextStyle(fontSize: 12)),
                          pw.Text(ticket['reference'] ?? "",
                              style: pw.TextStyle(fontSize: 20)),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Container(
                  padding: pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.red, width: 2),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Client', style: pw.TextStyle(fontSize: 20)),
                      pw.Text(ticket['client']?['client'] ?? "",
                          style: pw.TextStyle(fontSize: 18)),
                    ],
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Container(
                        padding: pw.EdgeInsets.all(10),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.red, width: 2),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('Localisation',
                                style: pw.TextStyle(fontSize: 20)),
                            pw.Text(
                                ticket['service_station'] != null
                                    ? '${ticket['service_station'] ?? ''}'
                                    : '',
                                style: pw.TextStyle(fontSize: 18)),
                          ],
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 10),
                    pw.Expanded(
                      child: pw.Container(
                        padding: pw.EdgeInsets.all(10),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.red, width: 2),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('Num série',
                                style: pw.TextStyle(fontSize: 20)),
                            pw.Text(
                                ticket['equipement']?['equipement_sn'] ?? "",
                                style: pw.TextStyle(fontSize: 18)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 10),
                pw.Container(
                  padding: pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.red, width: 2),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Nature panne',
                          style: pw.TextStyle(fontSize: 20)),
                      pw.Text(ticket['service_type'] ?? "",
                          style: pw.TextStyle(fontSize: 18)),
                    ],
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Container(
                  padding: pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.red, width: 2),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Heure', style: pw.TextStyle(fontSize: 20)),
                      pw.SizedBox(height: 10),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('D\'arrivé',
                                  style: pw.TextStyle(fontSize: 18)),
                              pw.Text(formatDate(ticket['accepting_date']),
                                  style: pw.TextStyle(fontSize: 18)),
                            ],
                          ),
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('De cloturage',
                                  style: pw.TextStyle(fontSize: 18)),
                              pw.Text(formatDate(ticket['solving_time']),
                                  style: pw.TextStyle(fontSize: 18)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Container(
                  padding: pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.red, width: 2),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Action envisagé',
                          style: pw.TextStyle(fontSize: 20)),
                      pw.Text(ticket['solution'] ?? "",
                          style: pw.TextStyle(fontSize: 18)),
                    ],
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Container(
                  padding: pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.red, width: 2),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Visa', style: pw.TextStyle(fontSize: 20)),
                      pw.SizedBox(height: 10),
                      pw.Row(
                        children: [
                          pw.Expanded(
                              child: pw.Container(
                                  height: 50,
                                  decoration: pw.BoxDecoration(
                                      border: pw.Border.all(
                                          color: PdfColors.black, width: 2)))),
                          pw.SizedBox(width: 10),
                          pw.Expanded(
                              child: pw.Container(
                                  height: 50,
                                  decoration: pw.BoxDecoration(
                                      border: pw.Border.all(
                                          color: PdfColors.black, width: 2)))),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );

      final bytes = await pdf.save();
      final fileName = 'ticket_${ticket['reference']}.pdf';
      final directory = await getExternalStorageDirectory();
      final filePath = '${directory!.path}/$fileName';
      final File file = File(filePath);
      await file.writeAsBytes(bytes);

      // Open file in external application (platform-specific)
      if (Platform.isAndroid || Platform.isIOS) {
        await OpenFile.open(filePath);
      }
    }
    */
