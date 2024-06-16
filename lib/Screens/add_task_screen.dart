import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import 'home/home_admin_screen.dart';


class AddTaskScreen extends StatefulWidget {
  final Function(int) onTabSelected; // Callback to switch tabs after adding task

  const AddTaskScreen({Key? key, required this.onTabSelected}) : super(key: key);

  @override
  _AddTaskScreenState createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController();
  String? _qrCodeData; // Make it nullable for initial loading state

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isLoading = false; // Loading state for adding task

  @override
  void initState() {
    super.initState();
    _generateQRCode();
  }

  void _generateQRCode() {
    setState(() {
      _qrCodeData = const Uuid().v4();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    super.dispose();
  }


  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);

        // Clear the time if a new date is selected
        _selectedTime = null;
        _timeController.text = '';
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a date first.')),
      );
      return;
    }

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
        _timeController.text = picked.format(context);
      });
    }
  }


  Future<void> _addTask() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true; // Show loading indicator
      });
      // Combine date and time if both are selected
      DateTime? selectedDateTime;
      if (_selectedDate != null && _selectedTime != null) {
        selectedDateTime = DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          _selectedTime!.hour,
          _selectedTime!.minute,
        );
      }

      final taskData = {
        'name': _nameController.text,
        'date': selectedDateTime != null ? Timestamp.fromDate(selectedDateTime) : null,
        'location': _locationController.text,
        'description': _descriptionController.text,
        'duration': int.tryParse(_durationController.text) ?? 0,
        'qrCode': _qrCodeData,
        'startTime': selectedDateTime != null ? Timestamp.fromDate(selectedDateTime) : null,
        'endTime': null,
        'attendanceIds': [],
      };

      try {
        await DatabaseService().createTask(taskData);

        // Success: Navigate to TasksScreen and show a snackbar
        widget.onTabSelected(0);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Task added successfully!')),
        );
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding task: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Task'),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.0),
        child: Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Task Name
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                        labelText: 'Task Name', prefixIcon: Icon(Icons.task)),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Please enter a task name.'
                        : null,
                  ),
                  SizedBox(height: 16),
                  // Date Picker
                  TextFormField(
                    controller: _dateController,
                    decoration: const InputDecoration(
                        labelText: 'Date', prefixIcon: Icon(Icons.calendar_today)),
                    readOnly: true,
                    onTap: () => _selectDate(context),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Please select a date.'
                        : null,
                  ),
                  // Time Picker
                  TextFormField(
                    controller: _timeController,
                    decoration: const InputDecoration(
                        labelText: 'Time', prefixIcon: Icon(Icons.access_time)),
                    readOnly: true,
                    onTap: () => _selectTime(context),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Please select a time.'
                        : null,
                  ),
                  // Location
                  TextFormField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                        labelText: 'Location', prefixIcon: Icon(Icons.location_on)),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Please enter a location.'
                        : null,
                  ),
                  // Description
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                        labelText: 'Description', prefixIcon: Icon(Icons.description)),
                    maxLines: 3,
                    validator: (value) => value == null || value.isEmpty
                        ? 'Please enter a description.'
                        : null,
                  ),
                  // Duration
                  TextFormField(
                    controller: _durationController,
                    decoration: const InputDecoration(
                        labelText: 'Duration (in minutes)',
                        prefixIcon: Icon(Icons.timer)),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a duration.';
                      }
                      if (int.tryParse(value) == null ||
                          int.tryParse(value)! <= 0) {
                        return 'Please enter a valid duration.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  // Display QR code only after generation
                  if (_qrCodeData != null) // Check if QR code is generated
                    Center(
                      child: QrImageView(
                        data: _qrCodeData!,
                        version: QrVersions.auto,
                        size: 200.0,
                        backgroundColor: Colors.white,
                        padding: EdgeInsets.all(10),
                      ),
                    )
                  else
                    Center(child: CircularProgressIndicator()),
                  SizedBox(height: 20),

                  // Regenerate QR Code Button
                  ElevatedButton(
                    onPressed: _generateQRCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      foregroundColor: Colors.black,
                    ),
                    child: Text('Regenerate QR Code'),
                  ),
                  SizedBox(height: 10),

                  // Add Task Button
                  ElevatedButton(
                    onPressed: _addTask,
                    child: Text('Add Task', style: TextStyle(fontSize: 18)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),


                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}