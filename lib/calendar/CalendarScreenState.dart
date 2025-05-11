import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:projects/calendar/notification_helper.dart';
import 'package:permission_handler/permission_handler.dart';

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

  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    requestNotificationPermission();
    NotificationHelper.initializeNotification();
    _loadReminders();
  }

  Future<void> requestNotificationPermission() async {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
  }

  void _loadReminders() async {
    String userId = FirebaseAuth.instance.currentUser?.uid ?? "";
    if (userId.isEmpty) {
      print("No user logged in.");
      return;
    }

    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notes')
          .get();

      snapshot.docs.forEach((doc) {
        print("Reminder: ${doc.data()}");
      });
    } catch (e) {
      print("Error loading reminders: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Text(
              'Calendar',
              style: GoogleFonts.comicNeue(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Colors.deepOrange,
              ),
            ),
            Spacer(),

            SizedBox(width: 16),
            Container(
              width: 180,
              height: 40,
              padding: EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search notes...',
                  border: InputBorder.none,
                  isDense: true,
                  suffixIcon: IconButton(
                    icon: Icon(Icons.search, size: 20),
                    onPressed: () => _searchNoteAndJump(_searchController.text),
                  ),
                ),
                onSubmitted: _searchNoteAndJump,
              ),
            ),
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
                if (dayNotes.containsKey(date)) {
                  return Positioned(
                    bottom: 5,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    ),
                  );
                }
                return SizedBox.shrink();
              },
            ),
          ),
          if (_selectedDay != null && dayNotes.containsKey(_selectedDay))
            Expanded(
              child: ListView.builder(
                itemCount: dayNotes[_selectedDay]?.length ?? 0,
                itemBuilder: (context, index) {
                  String note = dayNotes[_selectedDay]?[index] ?? '';
                  String time = reminderTimes[_selectedDay]?[index] ?? 'No time set';
                  String formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDay!);

                  return ListTile(
                    title: Text("$note at $time"),
                    subtitle: Text(formattedDate),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, color: Colors.blue), // Edit icon
                          onPressed: () {
                            // Handle the edit functionality here
                            _editNoteAndTime(index);
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red), // Delete icon
                          onPressed: () {
                            _deleteNoteAndTime(_selectedDay!, index);
                          },
                        ),
                      ],
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
                    String formattedTime = _reminderTime!.format(context);
                    setState(() {
                      if (!dayNotes.containsKey(_selectedDay)) {
                        dayNotes[_selectedDay!] = [];
                        reminderTimes[_selectedDay!] = [];
                      }
                      dayNotes[_selectedDay!]!.add(_noteController.text);
                      reminderTimes[_selectedDay!]!.add(formattedTime);
                    });

                    saveNoteToFirestore(_selectedDay!, _noteController.text, formattedTime);

                    DateTime reminderDateTime = DateFormat('yyyy-MM-dd HH:mm:ss').parse(
                        '${DateFormat('yyyy-MM-dd').format(_selectedDay!)} ${formattedTime}' );

                    NotificationHelper.scheduleNotification(
                      0,
                      'Reminder',
                      _noteController.text,
                      reminderDateTime,
                    );
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
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
                setState(() {
                  _currentView = 'Month'; // Switch back to the month view
                });
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<TimeOfDay?> _selectTime(BuildContext context) async {
    return showTimePicker(context: context, initialTime: TimeOfDay.now());
  }

  void saveNoteToFirestore(DateTime selectedDay, String note, String reminderTime) async {
    String dateKey = selectedDay.toIso8601String().split('T').first;
    String userId = FirebaseAuth.instance.currentUser?.uid ?? "";

    if (userId.isEmpty) return;

    DocumentReference docRef = _firestore.collection('users').doc(userId).collection('notes').doc(dateKey);

    await docRef.set({
      'notes': FieldValue.arrayUnion([note]),
      'times': FieldValue.arrayUnion([reminderTime]),
    }, SetOptions(merge: true));
  }

  void fetchNotesFromFirestore(DateTime selectedDay) async {
    String dateKey = selectedDay.toIso8601String().split('T').first;
    String userId = FirebaseAuth.instance.currentUser?.uid ?? "";

    if (userId.isEmpty) return;

    try {
      DocumentSnapshot snapshot = await _firestore.collection('users').doc(userId).collection('notes').doc(dateKey).get();

      if (snapshot.exists) {
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        List<String> notes = List<String>.from(data['notes'] ?? []);
        List<String> times = List<String>.from(data['times'] ?? []);

        setState(() {
          dayNotes[selectedDay] = notes;
          reminderTimes[selectedDay] = times;
        });
      }
    } catch (e) {
      print('Error fetching notes: $e');
    }
  }

  void _deleteNoteAndTime(DateTime selectedDay, int index) async {
    String dateKey = selectedDay.toIso8601String().split('T').first;
    String userId = FirebaseAuth.instance.currentUser?.uid ?? "";

    if (userId.isEmpty) return;

    try {
      DocumentReference docRef = _firestore.collection('users').doc(userId).collection('notes').doc(dateKey);

      List<String> notes = dayNotes[selectedDay]!;
      List<String> times = reminderTimes[selectedDay]!;

      notes.removeAt(index);
      times.removeAt(index);

      if (notes.isEmpty) {
        await docRef.delete();
      } else {
        await docRef.set({'notes': notes, 'times': times}, SetOptions(merge: true));
      }

      setState(() {
        dayNotes[selectedDay] = notes;
        reminderTimes[selectedDay] = times;
      });
    } catch (e) {
      print('Error deleting note: $e');
    }
  }

  void _searchNoteAndJump(String query) async {
    String userId = FirebaseAuth.instance.currentUser?.uid ?? "";
    if (userId.isEmpty) return;

    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notes')
          .get();

      for (var doc in snapshot.docs) {
        DateTime date = DateTime.parse(doc.id);
        List<String> notes = List<String>.from(doc['notes'] ?? []);

        for (var note in notes) {
          if (note.toLowerCase().contains(query.toLowerCase())) {
            setState(() {
              _selectedDay = date;
              _focusedDay = date;
            });
            fetchNotesFromFirestore(date);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Found note on ${DateFormat('yyyy-MM-dd').format(date)}")),
            );
            _searchController.clear();
            return;
          }
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No matching note found.")),
      );
    } catch (e) {
      print("Error searching notes: $e");
    }
  }

  void _editNoteAndTime(int index) {
    TextEditingController _editNoteController = TextEditingController(text: dayNotes[_selectedDay]?[index]);
    TimeOfDay? _reminderTime = TimeOfDay.now(); // Set default time if needed

    // Show dialog to edit note
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Note'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // TextField for editing the note
              TextField(
                controller: _editNoteController,
                decoration: InputDecoration(hintText: 'Edit your note here'),
                maxLines: 5,
              ),
              SizedBox(height: 10),
              // Time picker for editing the time
              ElevatedButton(
                onPressed: () async {
                  _reminderTime = await _selectTime(context); // Select time
                },
                child: Text('Set Reminder Time'),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  String updatedNote = _editNoteController.text;

                  // Get the formatted time from TimeOfDay
                  String formattedTime = _reminderTime!.format(context);

                  // Update the local state
                  setState(() {
                    dayNotes[_selectedDay]?[index] = updatedNote;
                    reminderTimes[_selectedDay]?[index] = formattedTime;
                  });

                  // Update Firestore
                  saveUpdatedNoteToFirestore(_selectedDay!, updatedNote, formattedTime, index);

                  Navigator.pop(context); // Close the dialog
                },
                child: Text('Save Changes'),
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
  void saveUpdatedNoteToFirestore(DateTime selectedDay, String updatedNote, String updatedTime, int index) async {
    String dateKey = selectedDay.toIso8601String().split('T').first;
    String userId = FirebaseAuth.instance.currentUser?.uid ?? "";

    if (userId.isEmpty) return;

    DocumentReference docRef = _firestore.collection('users').doc(userId).collection('notes').doc(dateKey);

    // Get the current list of notes and times
    List<String> notes = dayNotes[selectedDay] ?? [];
    List<String> times = reminderTimes[selectedDay] ?? [];

    // Replace the old note and time with the updated ones
    notes[index] = updatedNote;  // Replace the old note at the given index
    times[index] = updatedTime;  // Replace the old time at the given index

    // Update Firestore with the new note and time
    await docRef.set({
      'notes': notes,
      'times': times,
    }, SetOptions(merge: true));
  }


}
