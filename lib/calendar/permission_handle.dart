import 'package:permission_handler/permission_handler.dart';

//allow access
Future<void> requestNotificationPermission()async{
  if(await Permission.notification.isDenied){
    await Permission.notification.request();
  }
}