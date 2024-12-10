import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:todo/screens/config/config_service.dart';

class ListeAgenceScreen extends StatefulWidget {
  final String token;
  final String clientId;
  final String clientName;

  const ListeAgenceScreen({
    super.key,
    required this.token,
    required this.clientId,
    required this.clientName,
  });

  @override
  _ListeAgenceScreenState createState() => _ListeAgenceScreenState();
}

class _ListeAgenceScreenState extends State<ListeAgenceScreen> {
  List<dynamic> agences = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAgences();
  }

  var address = ConfigService().adresse;
  var port = ConfigService().port;

  Future<void> fetchAgences() async {
    setState(() {
      isLoading = true;
    });
    try {
      final response = await http.get(
        Uri.parse('$address:$port/api/client/${widget.clientId}/agences'),
      );
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData != null) {
          setState(() {
            agences = responseData;
            isLoading = false;
          });
        } else {
          throw Exception('Response data is null');
        }
      } else {
        throw Exception('Failed to load agences: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching agences: $error');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.clientName} Agences',
          style: const TextStyle(
              color: Color.fromRGBO(209, 77, 90, 1), fontSize: 24),
        ),
        backgroundColor: const Color.fromRGBO(231, 236, 250, 1),
        toolbarHeight: 60,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchAgences,
            color: Colors.white,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : agences.isEmpty
              ? const Center(child: Text('No agences found'))
              : RefreshIndicator(
                  onRefresh: fetchAgences,
                  child: ListView.builder(
                    itemCount: agences.length,
                    itemBuilder: (context, index) {
                      final agence = agences[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 15,
                        ),
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        color: Colors.grey[200], // Light gray background
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                agence['agence'] ?? 'Non rempli',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color.fromRGBO(209, 77, 90, 1),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.location_on,
                                      color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Adresse: ${agence['adresse'] ?? 'Non rempli'}',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.map, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Localisation: ${agence['localisation'] ?? 'Non rempli'}',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Contacts:',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color.fromRGBO(209, 77, 90, 1),
                                ),
                              ),
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: agence['contacts']?.length ?? 0,
                                itemBuilder: (context, contactIndex) {
                                  final contact =
                                      agence['contacts'][contactIndex];
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 4.0),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.person,
                                            color: Colors.grey),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Name: ${contact['name'] ?? 'Non rempli'}',
                                                style: const TextStyle(
                                                    fontSize: 16),
                                              ),
                                              Text(
                                                'Phone: ${contact['phone'] ?? 'Non rempli'}',
                                                style: const TextStyle(
                                                    fontSize: 16),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
