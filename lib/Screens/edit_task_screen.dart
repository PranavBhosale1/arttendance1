import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import 'package:uuid/uuid.dart';

class EditTaskScreen extends StatefulWidget {
  final String eventId;
  final Map<String, dynamic> eventData;

  EditTaskScreen({required this.eventId, required this.eventData});

  @override
  _EditTaskScreenState createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen> {
  final _formKey = GlobalKey<FormState>();

  final DatabaseService _dbService = DatabaseService();
  late TextEditingController _nameController;
  late TextEditingController _dateController;
  late TextEditingController _timeController;
  late TextEditingController _locationController;
  late TextEditingController _descriptionController;
  late TextEditingController _durationController;
  String? _qrCodeData;

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.eventData['name']);
    _dateController = TextEditingController(text: DateFormat('yyyy-MM-dd').format(widget.eventData['date'].toDate()));
    _timeController = TextEditingController(text: DateFormat.jm().format(widget.eventData['date'].toDate()));
    _locationController = TextEditingController(text: widget.eventData['location'] ?? '');
    _descriptionController = TextEditingController(text: widget.eventData['description'] ?? '');
    _durationController = TextEditingController(text: widget.eventData['duration']?.toString() ?? '');
    _qrCodeData = widget.eventData['qrCode'];

    _selectedDate = widget.eventData['date'].toDate();
    _selectedTime = TimeOfDay.fromDateTime(_selectedDate!);
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
      // If no date is selected, show a message or handle it differently
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

  Future<void> _updateTask() async {
    if (_formKey.currentState!.validate()) {
      final selectedDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      final updatedTaskData = {
        'name': _nameController.text,
        'date': Timestamp.fromDate(selectedDateTime),
        'location': _locationController.text,
        'description': _descriptionController.text,
        'duration': int.tryParse(_durationController.text) ?? 0,
        'qrCode': _qrCodeData, // Now updating QR code in Firestore
      };

      try {
        await _dbService.updateTask(widget.eventId, updatedTaskData); // Call updateTask function
        Navigator.pop(context); // Go back to the previous screen
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Task updated successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating task: $e')),
        );
      }
    }
  }

  // Function to regenerate QR code
  void _regenerateQRCode() async {
    final newQrCodeData = const Uuid().v4();

    try {
      // Update QR code in Firestore first
      await _dbService.updateTask(widget.eventId, {'qrCode': newQrCodeData});

      setState(() {
        _qrCodeData = newQrCodeData; // Then update local state
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error regenerating QR code: $e')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit Task')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Task Name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Task Name'),
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter a task name.'
                    : null,
              ),
              // Date Picker
              TextFormField(
                controller: _dateController,
                decoration: InputDecoration(labelText: 'Date'),
                readOnly: true,
                onTap: () => _selectDate(context),
                validator: (value) =>
                value == null || value.isEmpty ? 'Please select a date.' : null,
              ),
              // Time Picker
              TextFormField(
                controller: _timeController,
                decoration: InputDecoration(labelText: 'Time'),
                readOnly: true,
                onTap: () => _selectTime(context),
                validator: (value) =>
                value == null || value.isEmpty ? 'Please select a time.' : null,
              ),
              // Location
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(labelText: 'Location'),
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter a location.'
                    : null,
              ),
              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
                maxLines: 3,
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter a description.'
                    : null,
              ),
              // Duration
              TextFormField(
                controller: _durationController,
                decoration:
                InputDecoration(labelText: 'Duration (in minutes)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a duration.';
                  }
                  if (int.tryParse(value) == null || int.tryParse(value)! <= 0) {
                    return 'Please enter a valid duration.';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),

              //Display QR Code
              QrImageView(
                data: _qrCodeData!,
                version: QrVersions.auto,
                size: 200.0,
              ),

              // Button to Regenerate QR code
              ElevatedButton(
                onPressed: _regenerateQRCode,
                child: Text('Regenerate QR Code'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _updateTask,
                child: Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

