import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:todo/screens/config/config_service.dart';
import 'package:intl/intl.dart';
import 'package:todo/screens/coordinatrice/phoneTicketsCoordinatrice/ticketDetails.dart';
import 'package:todo/screens/tickets/ticketDetails.dart';

class HistoriqueScreen extends StatefulWidget {
  final String token;
  const HistoriqueScreen({super.key, required this.token});

  @override
  _HistoriqueScreenState createState() => _HistoriqueScreenState();
}

class _HistoriqueScreenState extends State<HistoriqueScreen>
    with SingleTickerProviderStateMixin {
  final ConfigService configService = ConfigService();
  late TabController _tabController;
  List<dynamic> phoneApprovedHistorique = [];
  List<dynamic> fieldApprovedHistorique = [];
  bool isPhoneApprovedLoading = true;
  bool isFieldApprovedLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadConfiguration();
    fetchAssignedTickets();
    fetchAssignedFieldTickets();
  }

  // String formatDate(String isoDate) {
  //   DateTime parsedDate = DateTime.parse(isoDate);
  //   // Format date as 'dd/MM/yyyy HH:mm'
  //   return DateFormat('dd/MM/yyyy HH:mm').format(parsedDate.toLocal());
  // }

  String formatDate(dynamic dateStr) {
    if (dateStr == null || dateStr.toString().isEmpty) {
      return 'Unknown date';
    }
    try {
      final dateTime = DateTime.parse(dateStr.toString());
      return DateFormat('yyyy-MM-dd HH:mm').format(dateTime.toLocal());
    } catch (e) {
      print('Error parsing date: $dateStr');
      return 'Unknown date';
    }
  }

  Future<void> _loadConfiguration() async {
    await configService.loadConfig();
    setState(() {});
  }

/*
  Future<void> fetchAssignedFieldTickets() async {
    setState(() {
      isFieldApprovedLoading = true;
    });

    var address = ConfigService().adresse;
    var port = ConfigService().port;

    try {
      final response = await http.get(
        Uri.parse('$address:$port/api/ticket/field'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData != null) {
          final today = DateTime.now().toUtc();

          setState(() {
            fieldApprovedHistorique = responseData
                .where((ticket) =>
                    ticket['status'] == 'VALIDATED' &&
                    ticket['validation_time'] != null)
                .where((ticket) {
              final validationTime =
                  DateTime.tryParse(ticket['validation_time']);
              return validationTime != null &&
                  validationTime.year == today.year &&
                  validationTime.month == today.month &&
                  validationTime.day == today.day;
            }).toList();
            isFieldApprovedLoading = false;
            // Afficher le résultat dans la console
            print(
                "Field tickets aujourd'hui pour l'utilisateur field connecté avec état 'VALIDATED':");
            for (var ticket in fieldApprovedHistorique) {
              print(ticket);
            }

            print(response.body);
          });
        } else {
          throw Exception('Response data is null');
        }
      } else {
        throw Exception('Failed to load tickets: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching tickets: $error');
      setState(() {
        isFieldApprovedLoading = false;
      });
    }
  } */

  Future<void> fetchAssignedFieldTickets() async {
    setState(() {
      isFieldApprovedLoading = true;
    });
    var address = ConfigService().adresse;
    var port = ConfigService().port;

    try {
      // final response = await http.get(
      //   Uri.parse('$address:$port/api/ticket/field'),
      //   headers: {
      //     'Authorization': 'Bearer ${widget.token}',
      //   },
      // );
      final response = await http.get(
        Uri.parse(
            '$address:$port/api/ticketht/assigned/field/mobile?status=VALIDATED'), // 'ASSIGNED' doit être entre guillemets
        headers: {
          'Authorization': 'Bearer ${widget.token}',
        },
      );
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData != null) {
          final today = DateTime.now().toUtc();
          setState(() {
            fieldApprovedHistorique = responseData
                .where((ticket) => ticket['validation_time'] != null)
                .where((ticket) {
              final validationTime =
                  DateTime.tryParse(ticket['validation_time']);
              return validationTime != null &&
                  validationTime.year == today.year &&
                  validationTime.month == today.month &&
                  validationTime.day == today.day;
            }).toList();
            isFieldApprovedLoading = false;
          });
          print("Field Tickets Validated Today: $fieldApprovedHistorique");
        } else {
          throw Exception('Response data is null');
        }
      } else {
        throw Exception('Failed to load field tickets: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching field tickets: $error');
      setState(() {
        isFieldApprovedLoading = false;
      });
    }
  }

  Future<void> fetchAssignedTickets() async {
    setState(() {
      isPhoneApprovedLoading = true;
    });
    var address = ConfigService().adresse;
    var port = ConfigService().port;

    try {
      final response = await http.get(
        Uri.parse(
            '$address:$port/api/ticketht/assigned/phone/mobile?status=VALIDATED'), // 'ASSIGNED' doit être entre guillemets
        headers: {
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData != null) {
          final today = DateTime.now().toUtc();
          setState(() {
            phoneApprovedHistorique = responseData
                .where((ticket) =>
                    ticket['status'] == 'VALIDATED' &&
                    ticket['validation_time'] != null)
                .where((ticket) {
              final validationTime =
                  DateTime.tryParse(ticket['validation_time']);
              return validationTime != null &&
                  validationTime.year == today.year &&
                  validationTime.month == today.month &&
                  validationTime.day == today.day;
            }).toList();
            isPhoneApprovedLoading = false;
          });
          print(response.body);
        } else {
          throw Exception('Response data is null');
        }
      } else {
        throw Exception('Failed to load tickets: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching tickets: $error');
      setState(() {
        isPhoneApprovedLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Historique',
          style: TextStyle(color: Color.fromRGBO(209, 77, 90, 1), fontSize: 24),
        ),
        backgroundColor: const Color.fromRGBO(231, 236, 250, 1),
        toolbarHeight: 60,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: Icon(Icons.phone, color: Color.fromRGBO(209, 77, 90, 1)),
              text: 'Phone Validated',
            ),
            Tab(
              icon: Icon(Icons.map, color: Color.fromRGBO(209, 77, 90, 1)),
              text: 'Field Validated',
            ),
          ],
          labelColor: Color.fromRGBO(209, 77, 90, 1),
          unselectedLabelColor: const Color.fromARGB(207, 135, 135, 135),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildHistoriqueList(phoneApprovedHistorique, isPhoneApprovedLoading),
          _buildHistoriqueList(fieldApprovedHistorique, isFieldApprovedLoading),
        ],
      ),
    );
  }

  Widget _buildHistoriqueList(List<dynamic> historique, bool isLoading) {
    return Padding(
      padding: const EdgeInsets.only(top: 5.0),
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : historique.isEmpty
              ? const Center(child: Text('No historique found'))
              : ListView.builder(
                  itemCount: historique.length,
                  itemBuilder: (context, index) {
                    final historiques = historique[index];
                    final solvedAt = historiques['solving_time'] != null
                        ? formatDate(historiques['solving_time'])
                        : (historiques['created_at'] != null
                            ? formatDate(historiques['created_at'])
                            : 'Unknown date');

                    // Formatage des dates

                    final validatedAt = historiques['validation_time'] != null
                        ? formatDate(historiques['validation_time'])
                        : (historiques['created_at'] != null
                            ? formatDate(historiques['created_at'])
                            : 'Unknown date');

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 10.0),
                      color: Colors.white,
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: ListTile(
                        leading: Icon(
                          Icons.task,
                          color: Color.fromRGBO(209, 77, 90, 1),
                        ),
                        title:
                            Text('Numéro Ticket: ${historiques['reference']}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Type Ticket: ${historiques['type']}'),
                            Text('Date Clôture: $solvedAt'),
                            Text(
                                'Date Validation: $validatedAt'), // Affichage de validation_time
                          ],
                        ),
                        // onTap: () {
                        //   // Naviguer vers l'écran TicketDetails
                        //   Navigator.push(
                        //     context,
                        //     MaterialPageRoute(
                        //       builder: (context) => TicketDetailScreenTech(
                        //         ticket: historiques,
                        //         ticketId: '',
                        //       ),
                        //     ),
                        //   );
                        // },
                      ),
                    );
                  },
                ),
    );
  }
}
