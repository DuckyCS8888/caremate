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

  Map<DateTime, List<String>> dayNotes = {}; // Stores notes for each day
  Map<DateTime, List<TimeOfDay>> reminderTimes = {}; // Stores reminder times for each day
  String? _reminderMessage = ''; // Reminder message for month view
  String? _selectedReminderTime;

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
                  if (_currentView != 'Month') {
                    _reminderMessage = '';
                  }
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
          if (_reminderMessage != null && _reminderMessage!.isNotEmpty && _currentView == 'Month')
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Container(
                alignment: Alignment.center,
                padding: EdgeInsets.all(8),
                // Improved design: Clean message display
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                ),
                child: Text(
                  _reminderMessage!,
                  style: TextStyle(color: Colors.black, fontSize: 14), // Clean text styling
                  textAlign: TextAlign.center,
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

          if (dayNotes.containsKey(selectedDay) && reminderTimes.containsKey(selectedDay)) {
            final List<String> notes = dayNotes[selectedDay]!;
            final List<TimeOfDay> times = reminderTimes[selectedDay]!;

            final Set<String> entries = {};
            for (int i = 0; i < notes.length; i++) {
              String formattedDate = "${selectedDay.day} ${_monthName(selectedDay.month)}";
              String entry = "$formattedDate: ${notes[i]} at ${times[i].format(context)}";
              entries.add(entry);
            }

            setState(() {
              _reminderMessage = entries.join('\n');
            });
          } else {
            setState(() {
              _reminderMessage = '';
            });
          }
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
          Text('Week View', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: daysOfWeek.map((day) {
              List<String> notes = dayNotes[day] ?? [];
              List<TimeOfDay> times = reminderTimes[day] ?? [];

              Set<String> uniqueEntries = {};
              for (int i = 0; i < notes.length; i++) {
                String formattedDate = "${day.day} ${_monthName(day.month)}";
                String entry = "$formattedDate: ${notes[i]} at ${times[i].format(context)}";
                uniqueEntries.add(entry);
              }

              return Expanded(
                child: Column(
                  children: [
                    Text('${day.day}', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    ...uniqueEntries.map((entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Text(entry, style: TextStyle(fontSize: 12, color: Colors.blue)),
                    )),
                    IconButton(
                      icon: Icon(Icons.add, size: 20, color: Colors.blue),
                      onPressed: () {
                        setState(() {
                          _selectedDay = day;
                        });
                        _showAddNoteDialog(context);
                      },
                    ),
                  ],
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
    String month = _monthName(_focusedDay.month);

    List<String> notes = dayNotes[displayDay] ?? [];
    List<TimeOfDay> times = reminderTimes[displayDay] ?? [];

    // Sorting notes and times based on the reminder time (earliest to latest)
    List<MapEntry<TimeOfDay, String>> sortedNotes = [];
    for (int i = 0; i < notes.length; i++) {
      sortedNotes.add(MapEntry(times[i], notes[i]));
    }

    sortedNotes.sort((a, b) => a.key.compareTo(b.key));

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
            itemCount: sortedNotes.length,
            itemBuilder: (context, index) {
              String timeText = sortedNotes[index].key.format(context);
              String noteAtThisTime = sortedNotes[index].value;

              return Container(
                padding: EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey.shade300, width: 1.0)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("[$timeText]   [$noteAtThisTime]", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            dayNotes[displayDay]?.removeAt(index);
                            reminderTimes[displayDay]?.removeAt(index);
                          });
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
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
                    setState(() {
                      _selectedReminderTime = _reminderTime!.format(context);
                      if (!dayNotes.containsKey(_selectedDay)) {
                        dayNotes[_selectedDay!] = [];
                        reminderTimes[_selectedDay!] = [];
                      }
                      dayNotes[_selectedDay!]!.add(_noteController.text);
                      reminderTimes[_selectedDay!]!.add(_reminderTime!);
                    });
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

  String _monthName(int month) {
    const List<String> months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
}