import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:todo/screens/FieldsTickets/FieldTickets.dart';
import 'package:todo/screens/auth/login_screen.dart';
import 'package:todo/screens/config/config_service.dart';
import 'package:todo/screens/pages/alerte.dart';
import 'package:todo/screens/pages/equipement.dart';
import 'package:todo/screens/pages/historique.dart';
import 'package:todo/screens/pages/notification.dart';
import 'package:todo/screens/pages/profile.dart';
import 'package:todo/screens/tickets/phoneTicket.dart';
import 'package:http/http.dart' as http;
import 'package:todo/api/firebase_api.dart';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class HomeScreen extends StatefulWidget {
  final String token;
  final String id;
  final String email;

  const HomeScreen(
      {super.key, required this.token, required this.email, required this.id});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ConfigService configService = ConfigService();
  late final String userId;
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  int _selectedDrawerIndex = 0; // Variable d'état pour le Drawer
  int _selectedIndex = 0;
  int phoneTicketCount = 0;
  int fieldTicketCount = 0;
  int alertCount = 0;
  int historiqueCount = 0;
  bool showStickerPhoneTicket =
      false; // Ajouter cette variable pour l'indicateur
  bool showStickerFieldTicket = false; // Même chose pour FieldTicket
  bool isLoading = false;
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    print("HomeScreen initState called");
    countPhoneTicket();
    countFieldTicket();
    print(widget.token);
    print(widget.email);
    print(widget.id);

    _loadConfiguration();
    NotificationService.initPushNotification();
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      NotificationService.showNotification(message);
    });
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    countPhoneTicket();
    countFieldTicket();
    countAlerts(); // Appelle la fonction pour mettre à jour le compteur
    countHistorique();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    countPhoneTicket(); // Appelle la fonction lorsque le widget change de dépendances
    countFieldTicket();
    countAlerts();

    countHistorique();
  }

  var address = ConfigService().adresse;
  var port = ConfigService().port;
  Future<void> countPhoneTicket() async {
    var address = ConfigService().adresse;
    var port = ConfigService().port;
    print("Widget ID dans homescreen: ${widget.id}");
    print("function count total phone is called on home screen");

    try {
      final response = await http.get(
        Uri.parse('$address:$port/api/ticket/counttotalphone/${widget.id}'),
      );

      if (response.statusCode == 200) {
        print(
            "Phone Count: ${response.body}"); // Affiche le corps de la réponse
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        // Vérifiez que 'totalCount' existe avant de l'utiliser
        if (jsonResponse.containsKey('totalCount')) {
          setState(() {
            phoneTicketCount =
                jsonResponse['totalCount']; // Met à jour le nombre de tickets
          });
        } else {
          print("Clé 'totalCount' non trouvée dans la réponse");
          setState(() {
            phoneTicketCount = 0; // En cas d'erreur
          });
        }
      } else {
        print('Erreur: ${response.statusCode} - ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Erreur: $e');
      setState(() {
        phoneTicketCount = 0; // En cas d'erreur
      });
    }
  }

  Future<void> countAlerts() async {
    var address = ConfigService().adresse;
    var port = ConfigService().port;

    // Remplacez ceci par le moyen d'obtenir votre token d'authentification
    // Exemple de fonction pour récupérer le token

    try {
      final response = await http.get(
        Uri.parse('$address:$port/api/alert/countAlert/${widget.id}'),
        headers: {
          'Authorization':
              'Bearer ${widget.token}', // Ajoutez le token dans les en-têtes
        },
      );

      if (response.statusCode == 200) {
        print("Alerts Count: ${response.body}");
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        if (jsonResponse.containsKey('count')) {
          setState(() {
            alertCount = jsonResponse['count'];
          });
        } else {
          print("Clé 'totalCount' non trouvée dans la réponse");
          setState(() {
            alertCount = 0;
          });
        }
      } else {
        print('Erreur: ${response.statusCode} - ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Erreur: $e');
      setState(() {
        alertCount = 0;
      });
    }
  }

  Future<void> countHistorique() async {
    var address = ConfigService().adresse;
    var port = ConfigService().port;

    // Remplacez ceci par le moyen d'obtenir votre token d'authentification
    // Exemple de fonction pour récupérer le token

    try {
      final response = await http.get(
        Uri.parse('$address:$port/api/ticket/countvalidated/${widget.id}'),
        headers: {
          'Authorization':
              'Bearer ${widget.token}', // Ajoutez le token dans les en-têtes
        },
      );

      if (response.statusCode == 200) {
        print("Historique Count: ${response.body}");
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        if (jsonResponse.containsKey('total')) {
          setState(() {
            historiqueCount = jsonResponse['total'];
          });
        } else {
          print("Clé 'totalCount' non trouvée dans la réponse");
          setState(() {
            historiqueCount = 0;
          });
        }
      } else {
        print('Erreur: ${response.statusCode} - ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Erreur: $e');
      setState(() {
        historiqueCount = 0;
      });
    }
  }

  Future<void> countFieldTicket() async {
    var address = ConfigService().adresse;
    var port = ConfigService().port;
    print("Widget ID dans homescreen: ${widget.id}");
    print("function count total phone is called on home screen");

    try {
      final response = await http.get(
        Uri.parse('$address:$port/api/ticket/counttotalfield/${widget.id}'),
      );

      if (response.statusCode == 200) {
        print(
            "Field Count: ${response.body}"); // Affiche le corps de la réponse
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        // Vérifiez que 'totalCount' existe avant de l'utiliser
        if (jsonResponse.containsKey('totalCount')) {
          setState(() {
            fieldTicketCount =
                jsonResponse['totalCount']; // Met à jour le nombre de tickets
          });
        } else {
          print("Clé 'totalCount' non trouvée dans la réponse");
          setState(() {
            fieldTicketCount = 0; // En cas d'erreur
          });
        }
      } else {
        print('Erreur: ${response.statusCode} - ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Erreur: $e');
      setState(() {
        fieldTicketCount = 0; // En cas d'erreur
      });
    }
  }

  Future<void> _loadConfiguration() async {
    await configService.loadConfig(); // Charge la configuration
    setState(() {
      // Met à jour l'interface si nécessaire
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    switch (index) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NotificationScreen(token: widget.token),
          ),
        );
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                PTicketScreen(token: widget.token, id: widget.id),
          ),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                FieldTicketScreen(token: widget.token, id: widget.id),
          ),
        );
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileScreen(
              token: widget.token,
              email: widget.email,
            ),
          ),
        );
        break;
    }
  }

  void _onDrawerItemTapped(int index) {
    setState(() {
      _selectedDrawerIndex = index;
    });
    switch (index) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                PTicketScreen(token: widget.token, id: widget.id),
          ),
        );
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  FieldTicketScreen(token: widget.token, id: widget.id)),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
        break;
    }
  }

  Future<void> _refresh() async {
    setState(() {
      isLoading = true; // Show loader while refreshing
    });

    try {
      // Simulate a network call or data update
      await Future.delayed(const Duration(seconds: 2));

      // Replace with your actual data fetching logic
      // For example: await fetchDataFromAPI();

      // Update your state with the new data
      // setState(() {
      //   // Update your data here
      // });

      // Show a success message (optional)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Data refreshed successfully!')),
      );
    } catch (error) {
      // Handle the error and show a message to the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to refresh data: $error')),
      );
    } finally {
      setState(() {
        isLoading = false; // Hide loader after refresh
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print('Received token in HomeScreen: ${widget.token}');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home',
            style: TextStyle(
              color: Color.fromRGBO(209, 77, 90, 1),
            )),
        backgroundColor: const Color.fromRGBO(231, 236, 250, 1),
        toolbarHeight: 60,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            // Drawer Header with User Info
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Color.fromRGBO(231, 236, 250, 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Color.fromRGBO(209, 77, 90, 1),
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Welcome, User',
                    style: TextStyle(
                      color: Color.fromRGBO(209, 77, 90, 1),
                      fontSize: 19,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'user@example.com',
                    style: TextStyle(
                      color: Color.fromRGBO(225, 108, 119, 1),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // Drawer Items
            ListTile(
              leading: const Icon(
                Icons.home,
                color: Color.fromRGBO(209, 77, 90, 1),
              ),
              title: const Text(
                'Home',
                style: TextStyle(
                  color: Color.fromRGBO(56, 56, 56, 1),
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/home');
              },
            ),

            ListTile(
              leading: const Icon(Icons.person,
                  color: Color.fromRGBO(209, 77, 90, 1)),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/profile');
              },
            ),

            const Divider(),

            ListTile(
              leading: const Icon(Icons.logout,
                  color: Color.fromRGBO(209, 77, 90, 1)),
              title: const Text('Logout'),
              onTap: () async {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.remove('token');
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              },
            )
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: SingleChildScrollView(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(children: [
                  const SizedBox(height: 70),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(width: 20),
                      Expanded(
                        child: buildTicketCard(
                          'Phone ticket',
                          phoneTicketCount,
                          const Color.fromRGBO(
                              231, 236, 250, 1), // Couleur de fond de la carte
                          Icons.phone,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PTicketScreen(
                                  token: widget.token,
                                  id: widget.id,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: buildTicketCard(
                          'FieldTicket',
                          fieldTicketCount,
                          const Color.fromRGBO(
                              231, 236, 250, 1), // Couleur de fond de la carte
                          Icons.map,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FieldTicketScreen(
                                  token: widget.token,
                                  id: widget.id,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(width: 20),
                      Expanded(
                        child: buildTicketCard(
                          'Equipement ',
                          0,
                          const Color.fromRGBO(231, 236, 250, 1),
                          Icons.settings,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EquipementScreen(),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(width: 20),
                      Expanded(
                          child: buildTicketCard(
                              'Historique',
                              historiqueCount,
                              const Color.fromRGBO(231, 236, 250,
                                  1), // Couleur de fond de la carte
                              Icons.history, () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HistoriqueScreen(
                              token: widget.token,
                            ),
                          ),
                        );
                      }))
                      // _buildButton(
                      //   context,
                      //   'Historique',
                      //   Icons.history,
                      //   0,
                      //   () {
                      //     Navigator.push(
                      //       context,
                      //       MaterialPageRoute(
                      //         builder: (context) =>
                      //             HistoriqueScreen(token: widget.token),
                      //       ),
                      //     );
                      //   },
                      // ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(width: 20),
                      Expanded(
                        child: buildTicketCard(
                          'Alertes',
                          alertCount,
                          const Color.fromRGBO(
                              231, 236, 250, 1), // Couleur de fond de la carte
                          Icons.warning,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AlerteScreen(
                                  token: widget.token,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      // _buildButton(
                      //   context,
                      //   'Alertes',
                      //   Icons.warning,
                      //   phoneTicketCount,
                      //   () {
                      //     Navigator.push(
                      //       context,
                      //       MaterialPageRoute(
                      //         builder: (context) =>
                      //             AlerteScreen(token: widget.token),
                      //       ),
                      //     );
                      //   },
                      // ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: buildTicketCard(
                          'Profile',
                          0,
                          const Color.fromRGBO(
                              231, 236, 250, 1), // Couleur de fond de la carte
                          Icons.person,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProfileScreen(
                                  token: widget.token,
                                  email: widget.email,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ]),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            IconButton(
              icon: Icon(Icons.notifications),
              color: _selectedIndex == 0
                  ? Color.fromRGBO(209, 77, 90, 1)
                  : Colors.grey,
              onPressed: () {
                _onItemTapped(0);
              },
            ),
            IconButton(
              icon: Icon(Icons.phone),
              color: _selectedIndex == 1
                  ? Color.fromRGBO(209, 77, 90, 1)
                  : Colors.grey,
              onPressed: () {
                _onItemTapped(1);
              },
            ),
            IconButton(
              icon: Icon(Icons.map),
              color: _selectedIndex == 2
                  ? Color.fromRGBO(209, 77, 90, 1)
                  : Colors.grey,
              onPressed: () {
                _onItemTapped(2);
              },
            ),
            IconButton(
              icon: Icon(Icons.person),
              color: _selectedIndex == 3
                  ? Color.fromRGBO(209, 77, 90, 1)
                  : Colors.grey,
              onPressed: () {
                _onItemTapped(3);
              },
            ),
          ],
        ),
        color: Color.fromRGBO(231, 236, 250, 1),
      ),
    );
  }

  Widget buildTicketCard(String title, int count, Color color, IconData icon,
      VoidCallback onPressed) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: Color.fromRGBO(209, 77, 90, 1), // Couleur de la bordure
          width: 1,
        ),
      ),
      elevation: 5, // Élévation de la carte
      color:
          const Color.fromRGBO(231, 236, 250, 1), // Couleur de fond de la carte
      child: SizedBox(
        width: 160, // Largeur désirée
        height: 120, // Hauteur désirée
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      color: Color.fromRGBO(209, 77, 90, 1),
                      size: 40,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color.fromRGBO(209, 77, 90, 1),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (count != 0)
              Positioned(
                top: -12,
                right: 10,
                child: Icon(
                  Icons.bookmark, // Icône "badge" ou "bookmark"
                  color: Colors.orange, // Couleur orange pleine opacité
                  size: 28, // Taille ajustée pour plus de visibilité
                  shadows: [
                    BoxShadow(
                      color: Colors.black
                          .withOpacity(0.2), // Ombre pour donner du relief
                      blurRadius: 5,
                      offset: Offset(1, 1),
                    ),
                  ],
                ),
              ),

            // Positioned(
            //   top: -15,
            //   right: 10,
            //   child: Container(
            //     padding: const EdgeInsets.all(
            //         6), // Ajustement de la taille du badge
            //     decoration: BoxDecoration(
            //       color: Color.fromRGBO(
            //           255, 165, 0, 0.9), // Couleur orange avec plus d'opacité
            //       shape: BoxShape.circle,
            //       boxShadow: [
            //         BoxShadow(
            //           color: Colors.black
            //               .withOpacity(0.2), // Ombre pour donner du relief
            //           blurRadius: 5,
            //           offset: Offset(1, 0),
            //         ),
            //       ],
            //     ),
            //     child: Icon(
            //       Icons.bookmark, // Icône "badge"
            //       color: Colors.white, // Couleur de l'icône contrastante
            //       size: 18, // Taille ajustée pour plus de visibilité
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(BuildContext context, String label, IconData icon,
      int count, VoidCallback onPressed) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: Color.fromRGBO(209, 77, 90, 1),
          width: 1,
        ),
      ),
      elevation: 5,
      color: Color.fromRGBO(231, 236, 250, 1),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          width: 140,
          height: 120,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    color: Color.fromRGBO(209, 77, 90, 1),
                    size: 40,
                  ),
                  const SizedBox(height: 15),
                  Text(
                    label,
                    style: TextStyle(
                      color: Color.fromRGBO(209, 77, 90, 1),
                    ),
                  ),
                ],
              ),
              if (count > 0)
                Positioned(
                  top: -15,
                  right: -15,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$count',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
