import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:attendancce1/Services/database_service.dart';

class EventScreen extends StatefulWidget {
  final String eventId;

  EventScreen({required this.eventId});

  @override
  _EventScreenState createState() => _EventScreenState();
}

class _EventScreenState extends State<EventScreen> {
  final DatabaseService _dbService = DatabaseService();
  Map<String, dynamic>? _eventData;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchEventData();
  }

  Future<void> _fetchEventData() async {
    try {
      final eventDoc = await _dbService.getEvent(widget.eventId);
      setState(() {
        _eventData = eventDoc.data() as Map<String, dynamic>?; // Allow for null here
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching event details: $e';
        _isLoading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    } else if (_errorMessage.isNotEmpty) {
      return Center(child: Text(_errorMessage));
    }

    final name = _eventData?['name'] ?? 'Event';
    final date = (_eventData?['date'] as Timestamp?)?.toDate();
    final location = _eventData?['location'] ?? 'Unknown location';
    final description = _eventData?['description'] ?? 'No description available';
    final durationInMinutes = _eventData?['duration'] as int? ?? 0;

    // Calculate hours and remaining minutes from durationInMinutes
    final hours = durationInMinutes ~/ 60;
    final minutes = durationInMinutes % 60;
    final durationText = '$hours hrs $minutes mins';

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        backgroundColor: Colors.deepPurple, // Custom app bar color
        elevation: 0, // Remove app bar shadow
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Image (Replace with actual image)
            Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                image: DecorationImage(
                  image: AssetImage('assets/event_placeholder.png'), // Replace with your asset image
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(height: 20),
            // Event Details in a Card
            Card(
              elevation: 5,
              margin: EdgeInsets.zero, // Remove card margins
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style:
                      TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    Divider(),
                    if (date != null) ...[
                      _buildDetailRow('Date', DateFormat.yMMMd().format(date)),
                      _buildDetailRow('Time', DateFormat.jm().format(date)),
                    ],
                    _buildDetailRow('Duration', durationText), // Display duration
                    _buildDetailRow('Location', location),
                    SizedBox(height: 10),
                    Text(
                      'Description:',
                      style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(description),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper function to build detail rows
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(value),
        ],
      ),
    );
  }
}
