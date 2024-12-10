import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:todo/screens/config/config_service.dart';
import 'package:todo/screens/coordinatrice/listeAgence.dart';

class ListeClientScreen extends StatefulWidget {
  final String token;

  const ListeClientScreen({super.key, required this.token});

  @override
  _ListeClientScreenScreenState createState() =>
      _ListeClientScreenScreenState();
}

class _ListeClientScreenScreenState extends State<ListeClientScreen> {
  List<dynamic> clients = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchClients();
  }

  var address = ConfigService().adresse;
  var port = ConfigService().port;

  Future<void> fetchClients() async {
    setState(() {
      isLoading = true;
    });
    try {
      final response = await http.get(
        Uri.parse('$address:$port/api/client/list'),
      );
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData != null) {
          setState(() {
            clients = responseData;
            isLoading = false;
          });
        } else {
          throw Exception('Response data is null');
        }
      } else {
        throw Exception('Failed to load clients: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching clients: $error');
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
          'Clients',
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
            onPressed: fetchClients,
            color: Color.fromRGBO(209, 77, 90, 1), // Color for refresh icon
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : clients.isEmpty
              ? const Center(
                  child: Text('No clients found',
                      style: TextStyle(fontSize: 18, color: Colors.grey)))
              : RefreshIndicator(
                  onRefresh: fetchClients,
                  child: ListView.builder(
                    itemCount: clients.length,
                    itemBuilder: (context, index) {
                      final client = clients[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 15), // Margin for cards
                        elevation: 5, // Added elevation for shadow effect
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(15), // Rounded corners
                        ),
                        color: Colors
                            .grey[200], // Set card background to light gray
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(
                              15), // Padding inside ListTile
                          title: Text(
                            client['name'],
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color.fromRGBO(
                                  209, 77, 90, 1), // Set title color
                            ),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ListeAgenceScreen(
                                  clientName: client['name'],
                                  clientId: client['_id'],
                                  token: widget.token,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
