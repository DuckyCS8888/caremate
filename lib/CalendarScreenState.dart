import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart'; // Import intl package for formatting date

class CalendarScreen extends StatefulWidget {
  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String _currentView = 'Month';

  List<String> weekDays = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"];
  List<String> timeSlots = [
    "6am", "7am", "8am", "9am", "10am", "11am", "12pm",
    "1pm", "2pm", "3pm", "4pm", "5pm", "6pm", "7pm",
    "8pm", "9pm", "10pm", "11pm", "12am", "1am", "2am",
    "3am", "4am", "5am"
  ];

  Map<DateTime, List<String>> dayNotes = {}; // Stores notes for each day
  Map<DateTime, List<String>> reminderTimes = {}; // Stores reminder times for each day as Strings

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Icon(Icons.menu, color: Colors.black),
            SizedBox(width: 8),
            Text(
              'Calendar',
              style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Spacer(),
            PopupMenuButton<String>(
              icon: Icon(Icons.calendar_today, color: Colors.black),
              onSelected: (value) {
                setState(() {
                  _currentView = value;
                });
              },
              itemBuilder: (context) => [
                PopupMenuItem(value: 'Month', child: Text('Month View')),
              ],
            ),
            SizedBox(width: 16),
            Icon(Icons.search, color: Colors.black),
          ],
        ),
      ),
      body: Stack(
        children: [
          buildCalendarBody(),
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: () => _showAddNoteDialog(context),
              backgroundColor: Colors.blue,
              child: Icon(Icons.add, size: 30, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildCalendarBody() {
    switch (_currentView) {
      case 'Month':
        return buildMonthView();
      default:
        return Center(child: Text("Invalid view"));
    }
  }

  // Month View
  Widget buildMonthView() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          TableCalendar(
            headerStyle: HeaderStyle(formatButtonVisible: false, titleCentered: true),
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });

              // Fetch data from Firestore for the selected day
              fetchNotesFromFirestore(selectedDay);
            },
            calendarFormat: _calendarFormat,
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            startingDayOfWeek: StartingDayOfWeek.sunday,
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
              selectedDecoration: BoxDecoration(color: Colors.deepOrange, shape: BoxShape.circle),
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (dayNotes.containsKey(date) && reminderTimes.containsKey(date)) {
                  List<String> notes = dayNotes[date]!;
                  List<String> times = reminderTimes[date]!;

                  if (notes.isEmpty || times.isEmpty) {
                    return SizedBox.shrink(); // No marker
                  }

                  return Positioned(
                    bottom: 5,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                }
                return SizedBox.shrink();
              },
            ),
          ),
          // Below calendar, display notes for selected day
          if (_selectedDay != null && dayNotes.containsKey(_selectedDay))
            Expanded(
              child: ListView.builder(
                itemCount: dayNotes[_selectedDay]?.length ?? 0,
                itemBuilder: (context, index) {
                  String note = dayNotes[_selectedDay]?[index] ?? '';
                  String time = reminderTimes[_selectedDay]?[index] ?? ''; // Default is empty string
                  if (time.isEmpty) {
                    time = 'No time set'; // Avoid showing any default or unwanted time like 08:00
                  }

                  // Format the selected day to show only the date without time
                  String formattedDate = _selectedDay != null
                      ? DateFormat('yyyy-MM-dd').format(_selectedDay!)
                      : '';

                  return ListTile(
                    title: Text("$note at $time"), // Display time with note
                    subtitle: Text(formattedDate), // Display the formatted date
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        _deleteNoteAndTime(_selectedDay!, index);
                      },
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showAddNoteDialog(BuildContext context) async {
    TextEditingController _noteController = TextEditingController();
    TimeOfDay? _reminderTime;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Note and Set Reminder'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _noteController,
                decoration: InputDecoration(hintText: 'Write your note here'),
                maxLines: 5,
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  _reminderTime = await _selectTime(context);
                  if (_reminderTime != null) {
                    // Safely format the time to the format user prefers
                    String formattedTime = _reminderTime!.format(context);
                    setState(() {
                      if (!dayNotes.containsKey(_selectedDay)) {
                        dayNotes[_selectedDay!] = [];
                        reminderTimes[_selectedDay!] = [];
                      }
                      dayNotes[_selectedDay!]!.add(_noteController.text);
                      reminderTimes[_selectedDay!]!.add(formattedTime); // Save time as String
                    });

                    // Save data to Firestore
                    saveNoteToFirestore(_selectedDay!, _noteController.text, formattedTime);

                    Navigator.pop(context); // Close the dialog
                  }
                },
                child: Text('Set Reminder'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<TimeOfDay?> _selectTime(BuildContext context) async {
    return showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
  }

  // Function to save note and reminder to Firestore under user ID
  void saveNoteToFirestore(DateTime selectedDay, String note, String reminderTime) async {
    String dateKey = selectedDay.toIso8601String().split('T').first;  // Convert the day into string format
    String userId = FirebaseAuth.instance.currentUser?.uid ?? "";  // Get the logged-in user's UID

    if (userId.isEmpty) {
      print("No user logged in.");
      return;
    }

    DocumentReference docRef = _firestore.collection('users').doc(userId).collection('notes').doc(dateKey);

    await docRef.set({
      'notes': FieldValue.arrayUnion([note]),
      'times': FieldValue.arrayUnion([reminderTime]), // Save formatted time as String
    }, SetOptions(merge: true));  // Merge instead of overwriting existing data

    print('Note and time saved successfully.');
  }

  // Fetch notes from Firestore for the logged-in user
  void fetchNotesFromFirestore(DateTime selectedDay) async {
    String dateKey = selectedDay.toIso8601String().split('T').first;
    String userId = FirebaseAuth.instance.currentUser?.uid ?? "";  // Get the logged-in user's UID

    if (userId.isEmpty) {
      print("No user logged in.");
      return;
    }

    try {
      DocumentSnapshot snapshot = await _firestore.collection('users').doc(userId).collection('notes').doc(dateKey).get();

      if (snapshot.exists) {
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        List<String> notes = List<String>.from(data['notes'] ?? []);
        List<String> times = List<String>.from(data['times'] ?? []);

        setState(() {
          dayNotes[selectedDay] = notes;
          reminderTimes[selectedDay] = times; // Store the time as String
        });
      }
    } catch (e) {
      print('Error fetching notes: $e');
    }
  }

  // Delete note and reminder time from Firestore and UI
  void _deleteNoteAndTime(DateTime selectedDay, int index) async {
    String dateKey = selectedDay.toIso8601String().split('T').first;
    String userId = FirebaseAuth.instance.currentUser?.uid ?? "";

    if (userId.isEmpty) {
      print("No user logged in.");
      return;
    }

    try {
      DocumentReference docRef = _firestore.collection('users').doc(userId).collection('notes').doc(dateKey);

      // Remove the specific note and time from Firestore
      List<String> notes = dayNotes[selectedDay]!;
      List<String> times = reminderTimes[selectedDay]!;

      notes.removeAt(index);
      times.removeAt(index);

      // If no notes remain for this day, delete the document
      if (notes.isEmpty) {
        await docRef.delete(); // Delete the entire document if no notes remain
      } else {
        await docRef.set({
          'notes': notes,
          'times': times, // Remove the time from Firestore
        }, SetOptions(merge: true));
      }

      // Update UI
      setState(() {
        dayNotes[selectedDay] = notes;
        reminderTimes[selectedDay] = times;
      });

      print('Note and time deleted successfully.');
    } catch (e) {
      print('Error deleting note: $e');
    }
  }

  String _monthName(int month) {
    const List<String> months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
}
