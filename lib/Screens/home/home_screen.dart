import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:intl/intl.dart';
import 'package:attendancce1/services/database_service.dart';
import 'package:attendancce1/screens/event_screen.dart';
import 'package:attendancce1/screens/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final DatabaseService _dbService = DatabaseService();
  MobileScannerController? cameraController = MobileScannerController();

  late List<Widget Function(BuildContext)> _widgetOptions;

  @override
  void initState() {
    super.initState();
    _widgetOptions = [
      _buildEventList,
      _buildQRScanner,
      _buildProfile,
    ];
  }

  Widget _buildEventList(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _dbService.getUpcomingEvents(), // Fetch upcoming events
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorWidget("Something went wrong");
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingWidget();
        }

        final events = snapshot.data!.docs;

        if (events.isEmpty) {
          return _buildEmptyStateWidget();
        } else {
          return ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index].data() as Map<String, dynamic>;
              final eventDate = (event['date'] as Timestamp).toDate();
              final formattedDate = DateFormat('EEEE, d MMM yyyy').format(eventDate);
              final formattedTime = DateFormat.jm().format(eventDate);

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EventScreen(eventId: events[index].id),
                      ),
                    );
                  },
                  child: Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: ListTile(
                      title: Text(
                        event['name'],
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Date: $formattedDate'),
                          Text('Time: $formattedTime'),
                          Text('Location: ${event['location'] ?? 'N/A'}'),
                        ],
                      ),
                      trailing: Icon(Icons.arrow_forward_ios),
                    ),
                  ),
                ),
              );
            },
          );
        }
      },
    );
  }

  // Function to build the loading widget
  Widget _buildLoadingWidget() {
    return Center(child: CircularProgressIndicator());
  }

  // Function to build the "no attendance" widget
  Widget _buildEmptyStateWidget() {
    return Center(child: Text('No upcoming events.'));
  }

  // Function to build the error widget
  Widget _buildErrorWidget(String errorMessage) {
    return Center(child: Text(errorMessage));
  }


  Widget _buildQRScanner(BuildContext context) {
    return MobileScanner(
      controller: cameraController,
      onDetect: (capture) async {
        final List<Barcode> barcodes = capture.barcodes;
        final String? code = barcodes.isNotEmpty ? barcodes[0].rawValue : null;
        if (code != null) {
          try {
            await _dbService.markAttendance(code);
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Attendance marked successfully!')),
            );
          } catch (error) {
            // Handle error fetching event data
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: $error')),
            );
          }
        }
      },
    );
  }

  Widget _buildProfile(BuildContext context) {
    return ProfileScreen(); // Assuming you have ProfileScreen implemented
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('EDC App'),
        backgroundColor: Colors.deepPurple, // Custom app bar color
      ),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex)(context),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.event),
            label: 'Events',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner),
            label: 'Scan QR',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.deepPurple, // Matching app bar color
        onTap: _onItemTapped,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 8, // Add slight elevation to the bottom navigation bar
      ),
    );
  }


}
