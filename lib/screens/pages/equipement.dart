import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:todo/screens/pages/equipementDetails.dart';
import 'package:todo/screens/config/config_service.dart';

class EquipementScreen extends StatefulWidget {
  @override
  _EquipementScreenState createState() => _EquipementScreenState();
}

class _EquipementScreenState extends State<EquipementScreen> {
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
    try {
      final response =
          await http.get(Uri.parse('$address:$port/api/equi/list'));
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
        title: Text(
          'Equipements',
          style: TextStyle(color: Colors.white, fontSize: 24),
        ),
        backgroundColor: Color.fromRGBO(209, 77, 90, 1),
        toolbarHeight: 60,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView.builder(
                itemCount: equipements.length,
                itemBuilder: (context, index) {
                  final equipement = equipements[index];

                  return GestureDetector(
                    onTap: () {
                      if (equipement != null && equipement['_id'] != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EquipmentDetailScreen(
                                equipmentId: equipement['_id']),
                          ),
                        );
                      } else {
                        print('Error: Equipment ID is null');
                      }
                    },
                    child: Container(
                      width: 400,
                      height: 180,
                      child: Card(
                        color: Color(0xFFF2D5D5),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Stack(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Numero Serie: ${equipement['numero_serie'] ?? 'N/A'}',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                      'Client: ${equipement['client']['name'] ?? 'N/A'}'),
                                  Text(
                                      'Agence: ${equipement['agence']['agence'] ?? 'N/A'}'),
                                  Text(
                                      'Model: ${equipement['modele']['name'] ?? 'N/A'}'),
                                  Text(
                                    'Type: ${equipement['type'] ?? 'N/A'}',
                                  ),
                                  Text(
                                    'Client: ${equipement['client']['name'] ?? 'N/A'}',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
