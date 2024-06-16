import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:attendancce1/services/database_service.dart';
import 'package:attendancce1/Screens/Login/login_screen.dart';
import 'package:attendancce1/Screens/add_task_screen.dart';
import 'package:attendancce1/Screens/edit_task_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  @override
  _AdminHomeScreenState createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _selectedIndex = 0;
  late PageController _pageController;
  late List<Widget Function(BuildContext)> _screenBuilders; // Use functions for delayed initialization

  // Functions to create widgets
  Widget _buildTasksScreen(BuildContext context) => TasksScreen();
  Widget _buildAddTaskScreen(BuildContext context) =>
      AddTaskScreen(onTabSelected: _onItemTapped);
  Widget _buildAttendanceListScreen(BuildContext context) =>
      AttendanceListScreen();

  // Callback function to handle tab selection
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: Duration(milliseconds: 300),
      curve: Curves.ease,
    );
  }

  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
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
      // Handle logout errors here
      print('Logout error: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    // Initialize _screenBuilders here (after _pageController is created)
    _screenBuilders = [
      _buildTasksScreen,
      _buildAddTaskScreen,
      _buildAttendanceListScreen,
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Panel'),
        backgroundColor: Colors.deepPurple, // Custom app bar color
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white), // White logout icon
            onPressed: _signOut,
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        children: _screenBuilders
            .map((builder) => builder(context))
            .toList(), // Build widgets dynamically
        onPageChanged: _onItemTapped,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.view_list),
            label: 'View Tasks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_task),
            label: 'Generate Task',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Attendance',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        onTap: _onItemTapped,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }
}
// TasksScreen (to display and edit tasks)
class TasksScreen extends StatelessWidget {
  final DatabaseService _dbService = DatabaseService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _dbService.getEvents(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }
        final events = snapshot.data!.docs;

        return ListView.builder(
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index].data() as Map<String, dynamic>;
            final eventId = events[index].id;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          EditTaskScreen(eventId: eventId, eventData: event),
                    ),
                  );
                },
                child: Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        title: Text(event['name'],
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          '${DateFormat.yMMMd().format(event['date'].toDate())} - ${event['location'] ?? 'N/A'}',
                        ),
                        trailing: SizedBox(
                          width: 60,
                          height: 60,
                          child: QrImageView(
                            data: event['qrCode'],
                            version: QrVersions.auto,
                            size: 50,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text(
                          event['description'] ?? 'No description',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}


class AttendanceListScreen extends StatelessWidget {
  final DatabaseService _dbService = DatabaseService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _dbService.getEvents(),
      builder: (context, eventSnapshot) {
        if (eventSnapshot.hasError) {
          return Center(child: Text('Something went wrong'));
        }
        if (eventSnapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final events = eventSnapshot.data!.docs;

        return ListView.builder(
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index].data() as Map<String, dynamic>;
            final eventId = events[index].id;

            return ExpansionTile(
              title: Text(event['name']),
              subtitle: Text(
                '${DateFormat.yMMMd().format(event['date'].toDate())} - ${event['location']}',
              ),
              children: [
                FutureBuilder<QuerySnapshot>(
                  future: _dbService.getAttendanceHistory(eventId),
                  builder: (context, attendanceSnapshot) {
                    if (attendanceSnapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }

                    if (attendanceSnapshot.hasError || !attendanceSnapshot.hasData || attendanceSnapshot.data!.docs.isEmpty) {
                      return Center(child: Text('No attendance data available.'));
                    }

                    final attendanceDocs = attendanceSnapshot.data!.docs;

                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columnSpacing: 10.0,
                        columns: [
                          DataColumn(label: Text('PRN')),
                          DataColumn(label: Text('Name')),
                          DataColumn(label: Text('Attendance Hours')),
                        ],
                        rows: attendanceDocs.map((attendance) {
                          final attendanceData = attendance.data() as Map<String, dynamic>;
                          final userId = attendanceData['userId'];
                          final attendanceId = attendance.id;
                          return DataRow(cells: [
                            DataCell(FutureBuilder<DocumentSnapshot>(
                              future: _dbService.getUserData(userId),
                              builder: (context, userSnapshot) {
                                if (userSnapshot.connectionState == ConnectionState.done) {
                                  if (userSnapshot.hasData && userSnapshot.data!.exists) {
                                    return Text(userSnapshot.data!.get('prn'));
                                  } else {
                                    return Text('User Not Found');
                                  }
                                } else {
                                  return Text('Loading...');
                                }
                              },
                            )),
                            DataCell(FutureBuilder<DocumentSnapshot>(
                              future: _dbService.getUserData(userId),
                              builder: (context, userSnapshot) {
                                if (userSnapshot.connectionState == ConnectionState.done) {
                                  if (userSnapshot.hasData && userSnapshot.data!.exists) {
                                    return Text(userSnapshot.data!.get('name'));
                                  } else {
                                    return Text('User Not Found');
                                  }
                                } else {
                                  return Text('Loading...');
                                }
                              },
                            )),
                            DataCell(FutureBuilder<int>(
                              future: _calculateAttendanceHours(attendanceId),
                              builder: (context, durationSnapshot) {
                                if (durationSnapshot.connectionState == ConnectionState.done) {
                                  return Text(durationSnapshot.data?.toString() ?? '');
                                } else {
                                  return Text('Loading...');
                                }
                              },
                            )),
                          ]);
                        }).toList(),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<int> _calculateAttendanceHours(String attendanceId) async {
    // ... your existing logic to calculate attendance hours
    final attendanceDoc = await _dbService.getAttendanceRecord(attendanceId);
    final startTime = attendanceDoc.data()!['startTime'].toDate();
    final endTime = attendanceDoc.data()!['endTime']?.toDate();
    if (endTime == null) {
      // Handle if the event is still ongoing
      return DateTime.now().difference(startTime).inMinutes;
    }
    final duration = endTime.difference(startTime);
    return duration.inMinutes; // Return duration in minutes
  }

}
