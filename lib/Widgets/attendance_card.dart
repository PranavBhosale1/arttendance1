import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AttendanceCard extends StatelessWidget {
  final String eventName;
  final Timestamp? date; // Allow null for date
  final bool isPresent;
  final int creditsEarned;

  AttendanceCard({
    required this.eventName,
    required this.date,
    required this.isPresent,
    required this.creditsEarned,
  });

  @override
  Widget build(BuildContext context) {
    final formattedDate = date != null ? DateFormat.yMMMd().add_jm().format(date!.toDate()) : 'Date Unavailable';

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              eventName,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 5),
            Text(
              formattedDate, // Use formatted date
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  isPresent ? Icons.check_circle : Icons.cancel,
                  color: isPresent ? Colors.green : Colors.red,
                ),
                SizedBox(width: 10),
                Text(
                  isPresent ? 'Present' : 'Absent',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isPresent ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            if (isPresent) ...[
              SizedBox(height: 5),
              Text(
                'Credits Earned: $creditsEarned',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
