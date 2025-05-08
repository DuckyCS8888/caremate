import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

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

  Map<DateTime, String> dayNotes = {}; // Store notes for each day
  Map<DateTime, TimeOfDay> reminderTimes = {}; // Store reminder times for each day
  String _reminderMessage = ''; // To store and display the reminder message

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
                PopupMenuItem(value: 'Week', child: Text('Week View')),
                PopupMenuItem(value: 'Day', child: Text('Day View')),
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
          // Show the reminder message below the content
          if (_reminderMessage.isNotEmpty)
            Positioned(
              bottom: 100, // Adjust the position of the message
              left: 0,
              right: 0,
              child: Container(
                alignment: Alignment.center,
                padding: EdgeInsets.all(8),
                color: Colors.blueAccent,
                child: Text(
                  _reminderMessage,
                  style: TextStyle(color: Colors.white),
                ),
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
      case 'Week':
        return buildWeekView();
      case 'Day':
        return buildDayView();
      default:
        return Center(child: Text("Invalid view"));
    }
  }

  Widget buildMonthView() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TableCalendar(
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
                  // Pick reminder time
                  _reminderTime = await _selectTime(context);
                  if (_reminderTime != null) {
                    // Save reminder time
                    setState(() {
                      reminderTimes[_selectedDay!] = _reminderTime!;
                    });
                  }
                },
                child: Text('Set Reminder'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Save note and reminder message
                setState(() {
                  dayNotes[_selectedDay!] = _noteController.text; // Save note for the selected day
                  _reminderMessage = "Reminder set for '${_noteController.text}' at ${_reminderTime?.format(context)}"; // Set reminder message
                });

                // Show the reminder message for 3 seconds
                Future.delayed(Duration(seconds: 3), () {
                  setState(() {
                    _reminderMessage = ''; // Clear the reminder message after 3 seconds
                  });
                });

                // Dismiss the dialog after saving
                Navigator.pop(context);
              },
              child: Text('Save'),
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

  Widget buildWeekView() {
    DateTime startOfWeek = _selectedDay ?? _focusedDay;
    int dayOfWeek = startOfWeek.weekday;
    DateTime firstDayOfWeek = startOfWeek.subtract(Duration(days: dayOfWeek - 1));

    List<DateTime> daysOfWeek = List.generate(7, (index) {
      return firstDayOfWeek.add(Duration(days: index));
    });

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Text(
            'Week View',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: daysOfWeek.map((day) {
              return Expanded(
                child: Center(
                  child: Column(
                    children: [
                      Text('${day.day}', style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      IconButton(
                        icon: Icon(Icons.add, size: 20, color: Colors.blue),
                        onPressed: () => _showAddNoteDialog(context),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget buildDayView() {
    DateTime displayDay = _focusedDay;
    String weekday = weekDays[displayDay.weekday % 7];
    List<String> monthsNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    String month = monthsNames[_focusedDay.month - 1];

    return Column(
      children: [
        const SizedBox(height: 16),
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
                Text(weekday, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                Text('${displayDay.day}', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
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
        Expanded(
          child: ListView.builder(
            itemCount: timeSlots.length,
            itemBuilder: (context, index) {
              return Container(
                height: 60,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade300, width: 1.0),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      timeSlots[index],
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
