import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:todo/screens/config/config_service.dart';

class AlerteScreen extends StatefulWidget {
  final String token;

  AlerteScreen({required this.token});

  @override
  _AlerteScreenState createState() => _AlerteScreenState();
}

class _AlerteScreenState extends State<AlerteScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool isLoadingAlerts = false;
  bool isLoadingNotifications = false;
  List<dynamic> alerts = [];
  List<dynamic> notifications = [];
  bool isLoading = false;
  bool isLoadingNotification = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchAlertes();
    fetchNotification();
  }

  var address = ConfigService().adresse;
  var port = ConfigService().port;

  Future<void> fetchAlertes() async {
    setState(() {
      isLoading = true;
    });
    try {
      final response = await http.get(
        Uri.parse('$address:$port/api/alert/'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
        },
      );
      print('Alertes Response Status: ${response.statusCode}');
      print('Alertes Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);
        print('Alertes Response Data: $responseData');

        setState(() {
          alerts = responseData;
          isLoading = false;
        });
      } else {
        print('Failed to load alerts');
        throw Exception('Failed to load alerts: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching alerts: $error');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchNotification() async {
    setState(() {
      isLoadingNotifications = true;
    });
    try {
      final response = await http.get(
        Uri.parse('$address:$port/api/notification/getMOb'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
        },
      );
      print('Notifications Response Status: ${response.statusCode}');
      print('Notifications Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);
        print('Notifications Response Data: $responseData');

        setState(() {
          notifications = responseData;
          isLoadingNotifications = false;
        });
      } else {
        print('Failed to load notifications');
        throw Exception('Failed to load notifications: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching notifications: $error');
      setState(() {
        isLoadingNotifications = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Alertes',
          style: TextStyle(color: Colors.white, fontSize: 24),
        ),
        backgroundColor: Color.fromRGBO(209, 77, 90, 1),
        toolbarHeight: 60,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Alertes'),
            Tab(text: 'Notifications'),
          ],
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildHistoriqueList(alerts, isLoadingAlerts),
          _buildHistoriqueList(notifications, isLoadingNotifications),
        ],
      ),
    );
  }

  Widget _buildHistoriqueList(List<dynamic> historique, bool isLoading) {
    return Padding(
      padding: const EdgeInsets.only(top: 5.0),
      child: isLoading
          ? Center(child: CircularProgressIndicator())
          : historique.isEmpty
              ? Center(child: Text('No alerts found'))
              : ListView.builder(
                  itemCount: historique.length,
                  itemBuilder: (context, index) {
                    final item = historique[index];
                    final message = item['message'] ?? 'No message';
                    final createdAt = item['createdAt'] != null
                        ? DateTime.parse(item['createdAt']).toLocal()
                        : DateTime.now();
                    final formattedDate =
                        '${createdAt.day}/${createdAt.month}/${createdAt.year} ${createdAt.hour}:${createdAt.minute}';

                    return Card(
                      child: ListTile(
                        title: Text('Message: $message'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Created At: $formattedDate'),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
