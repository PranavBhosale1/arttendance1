import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/database_service.dart';
import 'Login/login_screen.dart';
import '../widgets/attendance_card.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final DatabaseService _dbService = DatabaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;
  Map<String, dynamic>? _userData;
  List<Map<String, dynamic>> _attendanceHistory = [];
  bool _isLoading = true;
  String _errorMessage = '';
  int _totalAttendanceMinutes = 0;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      _user = _auth.currentUser;
      if (_user != null) {
        final userData = await _dbService.getUserData(_user!.uid);
        final attendanceSnapshot = await _dbService.getAttendanceHistory(_user!.uid);
        _calculateTotalAttendance(attendanceSnapshot.docs);

        setState(() {
          _userData = userData.data() as Map<String, dynamic>?;
          _attendanceHistory = attendanceSnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching user data: $e';
        _isLoading = false;
      });
    }
  }

  // Function to calculate total attendance in minutes
  void _calculateTotalAttendance(List<QueryDocumentSnapshot> attendanceDocs) {
    _totalAttendanceMinutes = 0;
    for (var doc in attendanceDocs) {
      final attendanceData = doc.data() as Map<String, dynamic>;
      final startTime = attendanceData['startTime'].toDate();
      final endTime = attendanceData['endTime']?.toDate();
      if (endTime != null) {
        final totalHours = (_totalAttendanceMinutes / 60).toInt().toStringAsFixed(2);

      } else {
        _totalAttendanceMinutes += DateTime.now().difference(startTime).inMinutes;
      }
    }

    // Award credit if total attendance is 3 hours or more
    if (_totalAttendanceMinutes >= 180 && (_userData?['credits'] ?? 0) == 0) {
      //_dbService.awardCredit(_user!.uid, 1);
      setState(() {
        _userData!['credits'] = (_userData!['credits'] ?? 0) + 1;
      });
    }
  }
  // Logout Function
  Future<void> _signOut() async {
    try {
      await _auth.signOut();
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => LoginScreen()),
              (route) => false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout successful!'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Logout error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (_errorMessage.isNotEmpty) {
      return Center(child: Text(_errorMessage));
    }

    final totalHours = (_totalAttendanceMinutes / 60).toStringAsFixed(2);

    return Scaffold(
      appBar: AppBar(title: const Text('Student Profile')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Information
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Name: ${_userData?['name'] ?? 'Loading...'}',
                        style: TextStyle(fontSize: 18),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Email: ${_user?.email ?? 'Loading...'}',
                        style: TextStyle(fontSize: 18),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Total Credits: ${_userData?['credits'] ?? 0}',
                        style: TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
                ),
              ),

              // Attendance History
              SizedBox(height: 20),
              Text(
                'Attendance History:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              _attendanceHistory.isEmpty
                  ? Center(child: Text('No attendance history yet.'))
                  : ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(), // Disable scrolling in the nested list
                itemCount: _attendanceHistory.length,
                itemBuilder: (context, index) {
                  final attendance = _attendanceHistory[index];

                  return AttendanceCard(
                    eventName: attendance['eventName'],
                    date: attendance['date'].toDate(),
                    isPresent: true,
                    creditsEarned: attendance['creditsEarned'] ?? 0,
                  );
                },
              ),

              // Progress Bar
              SizedBox(height: 20),
              Text(
                'Attendance Progress:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              LinearProgressIndicator(
                value: _totalAttendanceMinutes <= 120
                    ? _totalAttendanceMinutes / 120
                    : 1.0,
                minHeight: 20,
                backgroundColor: Colors.grey[200],
                color: Colors.blue,  // Change 'primary' to 'color'
              ),
              SizedBox(height: 8),
              Text('$totalHours / 2 hours'),

              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _signOut,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                ),
                child: Text('Logout'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
