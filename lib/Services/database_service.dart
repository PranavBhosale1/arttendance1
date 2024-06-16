import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get user data by UID
  Future<DocumentSnapshot<Map<String, dynamic>>> getUserData(String uid) async {
    return _firestore.collection('users').doc(uid).get();
  }

  // Get all events
  Stream<QuerySnapshot<Map<String, dynamic>>> getEvents() {
    return _firestore.collection('events').snapshots();
  }

  // Get a specific event by ID
  Future<DocumentSnapshot<Map<String, dynamic>>> getEvent(String eventId) async {
    return _firestore.collection('events').doc(eventId).get();
  }
// Award credit to user
  Future<void> awardCredit(String userId, int credits) async {
    try {
      // Update the user's credits in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({'credits': FieldValue.increment(credits)});
    } catch (e) {
      // Handle any potential errors here
      print('Error awarding credits: $e');
    }
  }

  // Get attendance history for a user
  Future<QuerySnapshot<Map<String, dynamic>>> getAttendanceHistory(
      String eventId) {
    return _firestore
        .collection('attendance')
        .where('eventId', isEqualTo: eventId)
        .get();
  }
// Update existing task
  Future<void> updateTask(
      String eventId, Map<String, dynamic> updatedTaskData) async {
    try {
      await _firestore.collection('events').doc(eventId).update(updatedTaskData);
      print('Task updated successfully!');
    } catch (e) {
      print('Error updating task: $e');
      rethrow;
    }
  }
  // Create new task
  Future<void> createTask(Map<String, dynamic> taskData) async {
    try {
      await _firestore.collection('events').add(taskData);
      print('Task added successfully!');
    } catch (e) {
      print('Error adding task: $e');
      rethrow;
    }
  }
  // Mark attendance for an event
  Future<void> markAttendance(String qrCodeData) async {
    // 1. Check for authenticated user
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      // 2. Query events by QR code
      final eventQuery = await _firestore
          .collection('events')
          .where('qrCode', isEqualTo: qrCodeData)
          .get();

      if (eventQuery.docs.isEmpty) {
        throw Exception('Invalid QR code or event not found');
      }

      final eventDoc = eventQuery.docs.first;
      final eventId = eventDoc.id;
      final eventData = eventDoc.data() as Map<String, dynamic>;

      // 3. Check if event has started and not ended yet
      final eventStartTime = eventData['startTime'] as Timestamp;
      final now = Timestamp.now();
      if (now.toDate().isBefore(eventStartTime.toDate())) {
        throw Exception('Event has not started yet.');
      }
      if (eventData['endTime'] != null) {
        final eventEndTime = eventData['endTime'] as Timestamp;
        if (now.toDate().isAfter(eventEndTime.toDate())) {
          throw Exception('Event has already ended.');
        }
      }

      // 4. Query attendance records for the user and event
      final attendanceQuery = await _firestore
          .collection('attendance')
          .where('userId', isEqualTo: user.uid)
          .where('eventId', isEqualTo: eventId)
          .get();

      if (attendanceQuery.docs.isNotEmpty) {
        // 5. Update existing attendance record if found (mark end time and calculate credits)
        final attendanceDoc = attendanceQuery.docs.first;

        // Check if the attendance is already marked as ended
        if (attendanceDoc.data()['endTime'] != null) {
          throw Exception('Attendance for this event has already been marked as ended.');
        }

        final endTime = Timestamp.now();
        final durationMinutes = (endTime.toDate().difference(eventStartTime.toDate()).inMinutes).toInt();

        final eventDuration = eventData['duration'] as int; // Get event duration in minutes

        final creditsEarned = (durationMinutes / eventDuration).floor();

        // Update attendance document
        await attendanceDoc.reference.update({
          'endTime': endTime,
          'creditsEarned': creditsEarned,
        });

        // Update user's credits
        await _firestore.collection('users').doc(user.uid).update({
          'credits': FieldValue.increment(creditsEarned),
        });
      } else {
        // 6. Create a new attendance record if not found
        await _firestore.collection('attendance').add({
          'userId': user.uid,
          'eventId': eventId,
          'startTime': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error marking attendance: $e');
      // Handle the error (e.g., show a snackbar to the user)
      rethrow;
    }
  }

  // Get a specific attendance record by ID
  Future<DocumentSnapshot<Map<String, dynamic>>> getAttendanceRecord(String attendanceId) {
    return _firestore.collection('attendance').doc(attendanceId).get();
  }

  Stream<QuerySnapshot> getUpcomingEvents() {
    return _firestore
        .collection('events')
        .where('date',
        isGreaterThanOrEqualTo:
        Timestamp.fromDate(DateTime.now())) // Filter by current time
        .snapshots();
  }
}
