import 'package:flutter/material.dart';
import 'package:velocity_ui/mainscreen.dart';
import 'package:flutter/services.dart';
import 'package:velocity_ui/notification_settings.dart';

void main() {WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
    .then((_) {
      runApp(new MyApp());
    });}

class MyApp extends StatelessWidget {
  const MyApp({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      home: Speedometer(storage: Storage1(),)); 
  }
}