import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationHelper{
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> initializeNotification() async{
    tz.initializeTimeZones();//confirm local time
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettings = InitializationSettings(android: androidSettings);
    await _notificationsPlugin.initialize(initializationSettings);

    const AndroidNotificationChannel channel = AndroidNotificationChannel
      ('reminder_channel',
      "Reminders",
      description: 'Channel for Reminder Notification',
      importance: Importance.high,
      playSound: true,
    );

    await _notificationsPlugin.
    resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.
    createNotificationChannel(channel);
  }

//set at specific time
  static Future<void> scheduleNotification(int id,String title,String category,DateTime
      sceduledTime) async{
    const androidDetails = AndroidNotificationDetails(
      'reminder_channel',
      "Reminders",
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );
    final notificationDetails = NotificationDetails(android: androidDetails);
    //ensure follow set time
    if (sceduledTime.isBefore(DateTime.now())){
    }else{
      await _notificationsPlugin.zonedSchedule(
          id, title, category, tz.TZDateTime.from(sceduledTime,tz.local),
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime
      );
    }
  }
  //cancel notification
  static Future<void> cancelNotification(int id) async{
    await _notificationsPlugin.cancel(id);
  }
}