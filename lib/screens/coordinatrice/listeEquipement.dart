import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:todo/screens/config/config_service.dart';
import 'package:todo/screens/coordinatrice/equipementDetails.dart';

class ListeEquipementScreen extends StatefulWidget {
  final String token;

  const ListeEquipementScreen({super.key, required this.token});

  @override
  _ListeEquipementScreenState createState() => _ListeEquipementScreenState();
}

class _ListeEquipementScreenState extends State<ListeEquipementScreen> {
  List<dynamic> equipements = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchEquipements();
  }

  var address = ConfigService().adresse;
  var port = ConfigService().port;

  Future<void> fetchEquipements() async {
    setState(() {
      isLoading = true;
    });
    try {
      final response = await http.get(
        Uri.parse('$address:$port/api/equi/list'),
      );
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData != null) {
          setState(() {
            equipements = responseData;
            isLoading = false;
          });
        } else {
          throw Exception('Response data is null');
        }
      } else {
        throw Exception('Failed to load equipements: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching equipements: $error');
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
          'Équipements',
          style: TextStyle(color: Color.fromRGBO(209, 77, 90, 1), fontSize: 24),
        ),
        backgroundColor: const Color.fromRGBO(231, 236, 250, 1),
        toolbarHeight: 60,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchEquipements,
            color: Colors.white, // Icon color
          ),
        ],
      ),
      body: Container(
        color: const Color.fromRGBO(
            231, 236, 250, 1), // Background color for the body
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : equipements.isEmpty
                ? const Center(child: Text('No équipements found'))
                : RefreshIndicator(
                    onRefresh: fetchEquipements,
                    child: ListView.builder(
                      itemCount: equipements.length,
                      itemBuilder: (context, index) {
                        final equipement = equipements[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 15),
                          elevation: 4,
                          color: Colors.white, // Card background color
                          child: ListTile(
                            title: Text(
                              'Numéro de série: ${equipement['numero_serie'] ?? 'N/A'}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                      top: 4.0, bottom: 4.0),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.devices,
                                          size: 16,
                                          color: Color.fromRGBO(
                                              209, 77, 90, 1)), // Icon color
                                      const SizedBox(width: 8),
                                      Text(
                                          'Type: ${equipement['type'] ?? 'N/A'}'),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    const Icon(Icons.person,
                                        size: 16,
                                        color: Color.fromRGBO(
                                            209, 77, 90, 1)), // Icon color
                                    const SizedBox(width: 8),
                                    Text(
                                        'Client: ${equipement['client']['name'] ?? 'N/A'}'),
                                  ],
                                ),
                                Row(
                                  children: [
                                    const Icon(Icons.business,
                                        size: 16,
                                        color: Color.fromRGBO(
                                            209, 77, 90, 1)), // Icon color
                                    const SizedBox(width: 8),
                                    Text(
                                        'Agence: ${equipement['agence']['agence'] ?? 'N/A'}'),
                                  ],
                                ),
                              ],
                            ),
                            trailing: const Icon(Icons.info_outline,
                                color: Color.fromRGBO(
                                    209, 77, 90, 1)), // Icon color
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EquipmentDetailScreen(
                                    equipementId: equipement['_id'],
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
      ),
    );
  }
}
