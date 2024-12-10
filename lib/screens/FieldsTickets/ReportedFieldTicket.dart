import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:todo/screens/config/config_service.dart';
import 'package:todo/screens/tickets/ticketDetails.dart';

class FieldReportedScreen extends StatefulWidget {
  final String token;
  final String? email;

  const FieldReportedScreen({super.key, required this.token, this.email});

  @override
  _FieldReportedScreenState createState() => _FieldReportedScreenState();
}

class _FieldReportedScreenState extends State<FieldReportedScreen> {
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
    await configService.loadConfig();
    setState(() {});
  }

  var address = ConfigService().adresse;
  var port = ConfigService().port;

  Future<void> fetchAssignedTickets() async {
    setState(() {
      isLoading = true;
    });
    try {
      final response = await http.get(
        Uri.parse(
            '$address:$port/api/ticketht/assigned/field/mobile?status=REPORTED'), // 'ASSIGNED' doit être entre guillemets
        headers: {
          'Authorization': 'Bearer ${widget.token}',
        },
      );
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData != null) {
          setState(() {
            tickets = responseData
                .where((ticket) => ticket['status'] == 'REPORTED')
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Reported Tickets',
          style: TextStyle(
            color: Color.fromRGBO(209, 77, 90, 1),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
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
                    'No reported tickets found.',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                  ),
                )
              : ListView.builder(
                  itemCount: tickets.length,
                  itemBuilder: (context, index) {
                    var ticket = tickets[index];
                    return GestureDetector(
                      onTap: () {
                        // Navigation vers TicketDetailsScreen avec l'ID du ticket ou d'autres détails
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TicketDetailScreenTech(
                              ticketId: tickets[index]['_id'],
                              ticket: null,
                            ),
                          ),
                        );
                      },
                      child: Card(
                        margin: const EdgeInsets.all(10),
                        color: const Color.fromRGBO(231, 236, 250, 1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Ticket ID
                              Text(
                                "Ticket ID: ${ticket['reference'] ?? 'N/A'}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 5),

                              // Status
                              Text(
                                "Status: ${ticket['status'] ?? 'N/A'}",
                                style: const TextStyle(
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 5),

                              // Agence
                              Text(
                                "Agence: ${ticket['agence']?['agence'] ?? 'N/A'}",
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 5),

                              // Report Details Section
                              const SizedBox(height: 10),
                              Text(
                                "Report Details",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const Divider(color: Colors.grey),

                              // Reporting note assigned (if available)
                              if (ticket['reporting_note_assigned'] != null &&
                                  ticket['reporting_note_assigned'].isNotEmpty)
                                ExpansionTile(
                                  title: const Text(
                                    "Report Accepted",
                                    style:
                                        TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  children: [
                                    for (var i = 0;
                                        i <
                                            ticket['reporting_note_assigned']
                                                .length;
                                        i++)
                                      ListTile(
                                        title: Text(
                                          "Note ${i + 1}: ${ticket['reporting_note_assigned'][i]}",
                                        ),
                                      ),
                                  ],
                                ),

                              // Reporting note solve (if available)
                              if (ticket['reporting_note_solve'] != null &&
                                  ticket['reporting_note_solve'].isNotEmpty)
                                ExpansionTile(
                                  title: const Text(
                                    "Report Handled",
                                    style:
                                        TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  children: [
                                    for (var i = 0;
                                        i <
                                            ticket['reporting_note_solve']
                                                .length;
                                        i++)
                                      ListTile(
                                        title: Text(
                                          "Note ${i + 1}: ${ticket['reporting_note_solve'][i]}",
                                        ),
                                      ),
                                  ],
                                ),

                              // Reporting note arrived (if available)
                              if (ticket['reporting_note_arrived'] != null &&
                                  ticket['reporting_note_arrived'].isNotEmpty)
                                ExpansionTile(
                                  title: const Text(
                                    "Report Arrived",
                                    style:
                                        TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  children: [
                                    for (var i = 0;
                                        i <
                                            ticket['reporting_note_arrived']
                                                .length;
                                        i++)
                                      ListTile(
                                        title: Text(
                                          "Note ${i + 1}: ${ticket['reporting_note_arrived'][i]}",
                                        ),
                                      ),
                                  ],
                                ),

                              const SizedBox(height: 10),

                              // Waiting button
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        // handleReportTicket(ticket['_id']);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color.fromARGB(
                                            255, 134, 134, 134),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                      child: const Text(
                                        'Waiting for Restarting Date..',
                                        style: TextStyle(color: Colors.white),
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
                  },
                ),
    );
  }
}
