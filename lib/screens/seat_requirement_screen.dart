import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'seat_layout_screen.dart';

class SeatRequirementScreen extends StatefulWidget {
  const SeatRequirementScreen({super.key});

  @override
  State<SeatRequirementScreen> createState() => _SeatRequirementScreenState();
}

class _SeatRequirementScreenState extends State<SeatRequirementScreen> {
  DateTime? _selectedDate;
  String? _selectedTime;
  String? _selectedFloor;
  final List<String> _times = [
    '8:00am - 9:00am',
    '9:00am - 10:00am',
    '10:00am - 11:00am',
    '11:00am - 12:00pm',
    '12:00pm - 1:00pm',
    '1:00pm - 2:00pm',
    '2:00pm - 3:00pm',
    '3:00pm - 4:00pm',
    '4:00pm - 5:00pm',
    '5:00pm - 6:00pm',
  ];

  final List<String> _floors = [
    'Ground Floor',
    'First Floor',
    'Second Floor',
    'Third Floor',
  ];

  // Checkbox selections
  bool _pcAccess = false;
  bool _powerSocket = false;
  bool _nearWindow = false;

  Future<void> _pickDate() async {
    DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _onSubmit() {
    if (_selectedDate == null ||
        _selectedTime == null ||
        _selectedFloor == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select all fields')));
      return;
    }

    // Navigate to seat layout screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SeatLayoutScreen(
          selectedFloor: _selectedFloor!,
          selectedDate: _selectedDate!,
          selectedTime: _selectedTime!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seat Reservation')),
      body: Stack(
        children: [
          // Background image (optional)
          Positioned.fill(
            child: Image.asset('assets/images/Library.jpg', fit: BoxFit.cover),
          ),
          Container(color: Colors.black.withOpacity(0)),

          // Form card
          Center(
            child: SingleChildScrollView(
              child: Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                color: Colors.white.withOpacity(0.7),
                elevation: 10,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Find a Seat',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Date Picker
                      ListTile(
                        title: Text(
                          _selectedDate == null
                              ? 'Select Date'
                              : DateFormat(
                                  'dd MMM yyyy',
                                ).format(_selectedDate!),
                        ),
                        trailing: const Icon(Icons.calendar_month),
                        onTap: _pickDate,
                      ),
                      const SizedBox(height: 12),

                      // Time Dropdown
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Select Time',
                          border: OutlineInputBorder(),
                        ),
                        items: _times
                            .map(
                              (time) => DropdownMenuItem(
                                value: time,
                                child: Text(time),
                              ),
                            )
                            .toList(),
                        value: _selectedTime,
                        onChanged: (value) =>
                            setState(() => _selectedTime = value),
                      ),
                      const SizedBox(height: 12),

                      // Floor Dropdown
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Select Floor Level',
                          border: OutlineInputBorder(),
                        ),
                        items: _floors
                            .map(
                              (floor) => DropdownMenuItem(
                                value: floor,
                                child: Text(floor),
                              ),
                            )
                            .toList(),
                        value: _selectedFloor,
                        onChanged: (value) =>
                            setState(() => _selectedFloor = value),
                      ),
                      const SizedBox(height: 12),

                      // Seat type options
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Seat Type Preference:'),
                          CheckboxListTile(
                            title: const Text('PC Access'),
                            value: _pcAccess,
                            onChanged: (v) => setState(() => _pcAccess = v!),
                          ),
                          CheckboxListTile(
                            title: const Text('Power Socket'),
                            value: _powerSocket,
                            onChanged: (v) => setState(() => _powerSocket = v!),
                          ),
                          CheckboxListTile(
                            title: const Text('Near Window'),
                            value: _nearWindow,
                            onChanged: (v) => setState(() => _nearWindow = v!),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      ElevatedButton(
                        onPressed: _onSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(
                            255,
                            58,
                            160,
                            211,
                          ),
                          minimumSize: const Size(double.infinity, 45),
                        ),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
