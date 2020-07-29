import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:velocity_ui/helper/notification_helper.dart';
import 'package:velocity_ui/main.dart';
import 'package:path_provider/path_provider.dart';
import './mainscreen.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import './constants.dart';
import 'package:vibration/vibration.dart';

class SettingsPage extends StatefulWidget {
  final Storage storage;

  SettingsPage({
    Key key,
    @required this.storage,
  }) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _value = false;
  bool _speedlock = false;
  String speedlock = '160';
  final messageTextController = TextEditingController();

  bool toBoolean(String str) {
    if (str == 'true') {
      return true;
    } else if (str == 'false')
      return false;
    else
      return null;
  }

  void onPressed(bool value) {
    setState(() {
      _value = value;
      value
          ? {
              showOngoingNotification(notifications,
                  title: 'Speed',
                  body: speedInKph.toStringAsFixed(1) + ' Kph' ?? '0'),
              writeData('true'),
            }
          : {notifications.cancelAll(), writeData('false')};
    });
  }

  void speedLockOnPressed(bool value) {
    setState(() {
      _speedlock = value;
      value ? speedlockvibrate() : null;
    });
  }

  Future<void> speedlockvibrate() async {
    try {
      if (speedInKph >= double.parse(speedlock)) {
        Vibration.vibrate();
      }
    } catch (e) {
      print(e);
    }
  }

  final notifications = FlutterLocalNotificationsPlugin();
  @override
  void initState() {
    super.initState();
    getVehicleSpeed();

    value();
    //storage for speedlock

    //storage for notification
    if (widget.storage.readData() == null) {
      widget.storage.writeData('false');
      widget.storage.readData().then((String value) {
        setState(() {
          _value = toBoolean(value);
        });
      });
    }

    widget.storage.readData().then((String value) {
      setState(() {
        _value = toBoolean(value);
        _value
            ? showNotification(notifications,
                title: 'speed',
                body: speedInKph.toStringAsFixed(1) ?? '0',
                type: silent)
            : notifications.cancelAll();
      });
    });
    //intialising notification

    final initializationSettingsAndroid =
        AndroidInitializationSettings('ic_launcher');
    final initializationSettingsIOS = IOSInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
      onDidReceiveLocalNotification: (id, title, body, payload) =>
          onSelectNotification(payload),
    );
    final initializationSettings = InitializationSettings(
        initializationSettingsAndroid, initializationSettingsIOS);
    notifications.initialize(initializationSettings,
        onSelectNotification: onSelectNotification);
  }

  Future<File> writeData(String bool1) async {
    setState(() {
      _value = toBoolean(bool1);
    });

    return widget.storage.writeData(bool1);
  }

  Future onSelectNotification(String payload) async {
    return null;
  }

  double speedInMps;
  double speedInKph;
  var geolocator = Geolocator();
  var locationOptions =
      LocationOptions(accuracy: LocationAccuracy.high, distanceFilter: 10);

  Future<void> getVehicleSpeed() async {
    try {
      geolocator.getPositionStream((locationOptions)).listen((position) async {
        speedInMps = position.speed;

        setState(() {
          speedInKph = speedInMps * 3.6;
          //1.16279 is correction factor to realcase scenario-- Not Required

          showOngoingNotification(notifications,
              title: 'speedometer', body: speedInKph.toStringAsFixed(1) ?? '0');
        });
      });
    } catch (e) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Loading'),
        ),
      );
    }
  }

  void value() {
    if (speedInKph == null) speedInKph = 0;
  }
  double lock=200;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        darkTheme: ThemeData.dark(),
        home: Scaffold(
            appBar: AppBar(
              title: Text('Settings'),
              leading: IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
            body: Column(children: <Widget>[
              SwitchListTile(
                  title: Text('Show speed in notification'),
                  activeColor: Colors.blue,
                  secondary: Icon(Icons.notifications),
                  value: _value,
                  onChanged: (bool value) {
                    onPressed(value);
                  }),
              SwitchListTile(
                secondary: Icon(Icons.alarm_add),
                title: Text(
                    'Speed lock notifier                ' + '${lock.toString()} Kph'),
                value: _speedlock,
                onChanged: (bool value) {
                  speedLockOnPressed(value);
                },
              ),
              Container(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        controller: messageTextController,
                        onChanged: (value) {
                          speedlock = value;
                        },
                        decoration: kTextFieldDecoration,
                      ),
                    ),
                    FlatButton(
                      onPressed: () {
                        messageTextController.clear();
                         lock=double.parse(speedlock);
                         if(lock<0)lock=-lock;
                         else if(lock>200||lock<-200)lock=0;
                        setState(() {});
                      },
                      child: Text(
                        'Confirm',
                      ),
                    ),
                  ],
                ),
              ),
            ])));
  }
}

class Storage {
  Future<String> get localPath async {
    final dir = await getApplicationDocumentsDirectory();
    return dir.path;
  }

  Future<File> get localFile async {
    final path = await localPath;
    return File('$path/db.txt');
  }

  Future<String> readData() async {
    try {
      final file = await localFile;
      String body = await file.readAsString();

      return body;
    } catch (e) {
      return e.toString();
    }
  }

  Future<File> writeData(String data) async {
    final file = await localFile;

    return file.writeAsString("$data");
  }
}
