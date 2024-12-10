import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:todo/screens/config/config_service.dart';

class ListeFournisseursScreen extends StatefulWidget {
  final String token;

  const ListeFournisseursScreen({super.key, required this.token});

  @override
  _ListeFournisseursScreenState createState() =>
      _ListeFournisseursScreenState();
}

class _ListeFournisseursScreenState extends State<ListeFournisseursScreen> {
  List<dynamic> fournisseurs = [];
  bool isLoading = true;

  final String address = ConfigService().adresse;
  final String port = ConfigService().port;

  @override
  void initState() {
    super.initState();
    fetchFournisseurs();
  }

  Future<void> fetchFournisseurs() async {
    setState(() {
      isLoading = true;
    });
    try {
      final response =
          await http.get(Uri.parse('$address:$port/api/marque/list'));
      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);
        setState(() {
          fournisseurs = responseData.isNotEmpty ? responseData : [];
        });
      } else {
        _showErrorDialog('Failed to load fournisseurs: ${response.statusCode}');
      }
    } catch (error) {
      _showErrorDialog('Error fetching fournisseurs: $error');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<List<dynamic>> fetchModeles(String marqueId) async {
    try {
      final response = await http
          .get(Uri.parse('$address:$port/api/marque/$marqueId/modeles'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Failed to load modeles: ${response.statusCode}');
        return [];
      }
    } catch (error) {
      print('Error fetching modeles: $error');
      return [];
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Fournisseurs',
          style: TextStyle(color: Color.fromRGBO(209, 77, 90, 1), fontSize: 24),
        ),
        backgroundColor: const Color.fromRGBO(231, 236, 250, 1),
        toolbarHeight: 60,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchFournisseurs,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : fournisseurs.isEmpty
              ? const Center(child: Text('No Fournisseurs found'))
              : RefreshIndicator(
                  onRefresh: fetchFournisseurs,
                  child: ListView.builder(
                    itemCount: fournisseurs.length,
                    itemBuilder: (context, index) {
                      final fournisseur = fournisseurs[index];

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 15),
                        elevation: 8,
                        shadowColor: Colors.grey.withOpacity(0.5),
                        color: Colors.grey[200], // Light gray background
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ExpansionTile(
                          title: Text(
                            fournisseur['name'] ?? 'Unknown Name',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color:
                                  Color.fromRGBO(209, 77, 90, 1), // Title color
                            ),
                          ),
                          childrenPadding:
                              const EdgeInsets.symmetric(horizontal: 16.0),
                          onExpansionChanged: (bool expanded) async {
                            if (expanded) {
                              final String? fournisseurId = fournisseur['_id'];
                              if (fournisseurId != null) {
                                setState(() {
                                  fournisseur['isLoadingModeles'] = true;
                                });

                                List<dynamic> modeles =
                                    await fetchModeles(fournisseurId);

                                setState(() {
                                  fournisseur['modeles'] = modeles;
                                  fournisseur['isLoadingModeles'] = false;
                                });
                              } else {
                                print('Invalid fournisseur id');
                              }
                            }
                          },
                          children: fournisseur['isLoadingModeles'] == true
                              ? const [
                                  Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  )
                                ]
                              : fournisseur['modeles'] != null &&
                                      fournisseur['modeles'].isNotEmpty
                                  ? fournisseur['modeles']
                                      .map<Widget>((modele) {
                                      return ListTile(
                                        title: Text(
                                          "Modele: ${modele['name'] ?? 'Unknown Model'}",
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Color.fromRGBO(
                                                209, 77, 90, 1), // Model color
                                          ),
                                        ),
                                        subtitle: Text(
                                          "Screen Type: ${modele['modele_ecran'] ?? 'Unknown Screen Type'}",
                                          style: const TextStyle(
                                            color: Colors.grey,
                                          ),
                                        ),
                                      );
                                    }).toList()
                                  : const [
                                      ListTile(
                                          title: Text('No modeles available')),
                                    ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
