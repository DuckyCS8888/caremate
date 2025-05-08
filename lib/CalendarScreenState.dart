import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: CalendarScreen(),
    );
  }
}

class CalendarScreen extends StatefulWidget {
  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String _currentView = 'Month';

  Map<DateTime, String> notes = {}; // Store notes
  Map<DateTime, DateTime> reminderTimes = {}; // Store reminder times

  TextEditingController _noteController = TextEditingController();

  // List of weekdays
  List<String> weekDays = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"];

  // Store selected reminder time for display
  String? _selectedReminderTime;

  @override
  void initState() {
    super.initState();

    // Initialize notification plugin
    var initializationSettingsAndroid = AndroidInitializationSettings('app_icon');
    var initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);
    flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  // Schedule Notification for Reminder
  Future<void> _scheduleReminder(DateTime reminderTime) async {
    var androidDetails = AndroidNotificationDetails(
      'reminder_channel_id',
      'Reminder Channel',
      channelDescription: 'This channel is used for reminders.',
      importance: Importance.high,
      priority: Priority.high,
    );
    var platformDetails = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.schedule(
      0,
      'Reminder',
      'You have a reminder for your note!',
      reminderTime,
      platformDetails,
    );
  }

  // Set note and reminder
  void _setReminder(DateTime selectedDay, TimeOfDay selectedTime) {
    DateTime reminderTime = DateTime(
      selectedDay.year,
      selectedDay.month,
      selectedDay.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    setState(() {
      reminderTimes[selectedDay] = reminderTime;
    });

    _scheduleReminder(reminderTime); // Schedule reminder
    if (_noteController.text.isNotEmpty) {
      setState(() {
        notes[selectedDay] = _noteController.text;
      });
    }
  }

  // Show custom time picker dialog
  Future<void> _selectTime(BuildContext context, DateTime selectedDay) async {
    TimeOfDay? selectedTime = await showDialog<TimeOfDay>(
      context: context,
      builder: (BuildContext context) {
        return CustomTimePickerDialog();
      },
    );

    if (selectedTime != null) {
      // Format the selected time
      String formattedTime = '${selectedTime.format(context)}';

      setState(() {
        _selectedReminderTime = formattedTime;  // Store selected reminder time
      });

      _setReminder(selectedDay, selectedTime);
    }
  }

  // Calendar Body toggle for different views (Month, Week, Day)
  Widget buildCalendarBody() {
    switch (_currentView) {
      case 'Month':
        return buildMonthView();
      case 'Week':
        return buildWeekView();
      case 'Day':
        return buildDayView();
      default:
        return buildMonthView();
    }
  }

  Widget buildMonthView() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          TableCalendar(
            focusedDay: _focusedDay,
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
                _noteController.text = notes[selectedDay] ?? '';
              });
            },
            calendarFormat: _calendarFormat,
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
              selectedDecoration: BoxDecoration(color: Colors.deepOrange, shape: BoxShape.circle),
            ),
          ),
          const SizedBox(height: 16),
          // Notes section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: 'Add a note for the selected day',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ),
          // Time Picker section for reminder
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () => _selectTime(context, _selectedDay!),
              child: Text('Pick Reminder Time'),
            ),
          ),
          // Show selected reminder time
          if (_selectedReminderTime != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Selected Reminder Time: $_selectedReminderTime',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          // Save button
          ElevatedButton(
            onPressed: () {
              if (_selectedDay != null) {
                _setReminder(_selectedDay!, TimeOfDay.now()); // Default time if no time picked
              }
            },
            child: Text('Save Note & Set Reminder'),
          ),
        ],
      ),
    );
  }

  Widget buildWeekView() {
    DateTime startOfWeek = _selectedDay ?? _focusedDay;
    int dayOfWeek = startOfWeek.weekday;
    DateTime firstDayOfWeek = startOfWeek.subtract(Duration(days: dayOfWeek - 1));

    List<DateTime> daysOfWeek = List.generate(7, (index) {
      return firstDayOfWeek.add(Duration(days: index));
    });

    List<String> monthsNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    String headerMonth = monthsNames[firstDayOfWeek.month - 1];
    int headerYear = firstDayOfWeek.year;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Text(
            '$headerMonth $headerYear',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(width: 50, child: Text("")),
              Expanded(
                child: Row(
                  children: daysOfWeek.map((day) {
                    String weekday = weekDays[day.weekday % 7]; // Start from Sunday
                    return Expanded(
                      child: Center(
                        child: Column(
                          children: [
                            Text('${day.day}', style: TextStyle(fontWeight: FontWeight.bold)),
                            SizedBox(height: 4),
                            Text(weekday, style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget buildDayView() {
    DateTime displayDay = _focusedDay;
    String weekday = weekDays[displayDay.weekday % 7]; // Adjust for Sunday start

    List<String> monthsNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    String month = monthsNames[_focusedDay.month - 1];

    return Column(
      children: [
        const SizedBox(height: 16),

        // Month & Navigation
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: Icon(Icons.arrow_left),
              onPressed: () {
                setState(() {
                  _focusedDay = _focusedDay.subtract(Duration(days: 1));
                  _selectedDay = _focusedDay;
                });
              },
            ),
            Column(
              children: [
                Text('$month ${_focusedDay.year}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text(
                  weekday,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${displayDay.day}',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            IconButton(
              icon: Icon(Icons.arrow_right),
              onPressed: () {
                setState(() {
                  _focusedDay = _focusedDay.add(Duration(days: 1));
                  _selectedDay = _focusedDay;
                });
              },
            ),
          ],
        ),

        const Divider(),

        // Notes input field
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _noteController,
            decoration: InputDecoration(
              labelText: 'Add a note for ${displayDay.day}',
              border: OutlineInputBorder(),
            ),
            onChanged: (text) {
              setState(() {
                notes[displayDay] = text;
              });
            },
          ),
        ),

        // Display saved note and reminder
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Note: ${notes[displayDay] ?? "No notes for today"}'),
            ],
          ),
        ),
      ],
    );
  }

  // Function to toggle Calendar View
  Widget buildViewToggle() {
    return Row(
      children: [
        ElevatedButton(
          onPressed: () {
            setState(() {
              _currentView = 'Month';
            });
          },
          child: Text("Month View"),
        ),
        ElevatedButton(
          onPressed: () {
            setState(() {
              _currentView = 'Week';
            });
          },
          child: Text("Week View"),
        ),
        ElevatedButton(
          onPressed: () {
            setState(() {
              _currentView = 'Day';
            });
          },
          child: Text("Day View"),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Calendar with Notes & Reminders'),
      ),
      body: Column(
        children: [
          buildViewToggle(), // Calendar view toggle buttons
          Expanded(child: buildCalendarBody()), // Display calendar body based on view
        ],
      ),
    );
  }
}

class CustomTimePickerDialog extends StatefulWidget {
  @override
  _CustomTimePickerDialogState createState() => _CustomTimePickerDialogState();
}

class _CustomTimePickerDialogState extends State<CustomTimePickerDialog> {
  int? _hour = 1;
  int? _minute = 0;
  String _amPm = "AM";

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Select Reminder Time"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              DropdownButton<int>(
                value: _hour,
                items: List.generate(12, (index) => index + 1)
                    .map((hour) => DropdownMenuItem<int>(
                  value: hour,
                  child: Text("$hour"),
                ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _hour = value;
                  });
                },
              ),
              Text(" : "),
              DropdownButton<int>(
                value: _minute,
                items: List.generate(60, (index) => index)
                    .map((minute) => DropdownMenuItem<int>(
                  value: minute,
                  child: Text(minute.toString().padLeft(2, '0')),
                ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _minute = value;
                  });
                },
              ),
              SizedBox(width: 10),
              DropdownButton<String>(
                value: _amPm,
                items: ["AM", "PM"]
                    .map((amPm) => DropdownMenuItem<String>(
                  value: amPm,
                  child: Text(amPm),
                ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _amPm = value!;
                  });
                },
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context, TimeOfDay(hour: _hour! % 12, minute: _minute!));
          },
          child: Text("OK"),
        ),
      ],
    );
  }
}
