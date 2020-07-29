import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:ui';
import './speed.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'notification_settings.dart';
import 'package:firebase_admob/firebase_admob.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

class Speedometer extends StatefulWidget {
  final Storage1 storage;
  Speedometer({Key key, @required this.storage}) : super(key: key);

  @override
  _SpeedometerState createState() => _SpeedometerState();
}

class _SpeedometerState extends State<Speedometer>
    with TickerProviderStateMixin {
  AnimationController controller;
  AnimationController c2;
  Animation animation;
  Animation animation1;
  Animation animation2;
  Animation animation3;

  bool introanimation = true;
  double maxspeed = 0;
  double heading = 0;

  double odo = 0;
  speedView() {
    return CustomPaint(
      foregroundPainter: SpeedPainter(
          defaultCircleColor: Colors.grey[200],
          percentageCompletedCircleColor: AnimationControl(),
          completedPercentage: introanimation
              ? animation1.value * 70
              : linearInterpolate * 7 / 16,
          circleWidth: 100),
    );
  }

  double linearInterpolate;
  double linearInterpolateCompass;
  BannerAd myBanner;
  MobileAdTargetingInfo targetingInfo;
  InterstitialAd myInterstitial;
  void _onData(double x) => setState(() {
        heading = x;
      });
  void initState() {
    super.initState();
    getVehicleSpeed();
    startstopwatch();
    FlutterCompass.events.listen(_onData);
    controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1200),
    );
    c2 = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
    animation1 = CurvedAnimation(parent: controller, curve: Curves.easeInOut);
    animation = ColorTween(
      begin: Colors.green,
      end: Colors.white,
    ).animate(c2);

    animation2 = CurvedAnimation(parent: c2, curve: Curves.easeInOut);
    controller.forward();
    c2.forward();
    animation1.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        controller.reverse(from: 1.0);
      } else if (status == AnimationStatus.dismissed) {
        introanimation = false;
        linearInterpolate = 0;
      }
    });
    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        c2.reverse(from: 1.0);
      } else if (status == AnimationStatus.dismissed) c2.forward();
    });

    controller.addListener(() {
      setState(() {
        linearInterpolate = 0;
        linearInterpolateCompass = 0;
      });
    });
    c2.addListener(() {
      setState(() {
        linearInterpolate = lerpDouble(linearInterpolate, speedInKph, 0.01);
      });
      setState(() {
        linearInterpolateCompass =
            lerpDouble(linearInterpolateCompass, heading, 0.05);
      });
    });
    odome();
    value();
    //Admob testing
    FirebaseAdMob.instance
        .initialize(appId: 'ca-app-pub-6305741283302796~3566438550');
    targetingInfo = MobileAdTargetingInfo(

        // or MobileAdGender.female, MobileAdGender.unknown
        // Android emulators are considered test devices
        );

    myBanner = BannerAd(
      // Replace the testAdUnitId with an ad unit id from the AdMob dash.
      // https://developers.google.com/admob/android/test-ads
      // https://developers.google.com/admob/ios/test-ads
      adUnitId: "ca-app-pub-6305741283302796/9109321537",
      size: AdSize.smartBanner,
      targetingInfo: targetingInfo,
      listener: (MobileAdEvent event) {
        print("BannerAd event is $event");
      },
    );
    myInterstitial = InterstitialAd(
      // Replace the testAdUnitId with an ad unit id from the AdMob dash.
      // https://developers.google.com/admob/android/test-ads
      // https://developers.google.com/admob/ios/test-ads
      adUnitId: "ca-app-pub-6305741283302796/1603486166",
      targetingInfo: targetingInfo,
      listener: (MobileAdEvent event) {
        print("InterstitialAd event is $event");
      },
    );
    show_adbanner();

    //odometer
    totalDistance = '0';

    if (widget.storage.readData() == null) {
      widget.storage.writeData('0');
    } else
      widget.storage.readData().then((String value) {
        setState(() {
          totalDistance = value;
        });
      });
  }

  //ad
  void show_adbanner() {
    myBanner
      // typically this happens well before the ad is shown
      ..load()
      ..show(
        // Positions the banner ad 60 pixels from the bottom of the screen
        anchorOffset: 00.0,
        // Positions the banner ad 10 pixels from the center of the screen to the right
        horizontalCenterOffset: 0.0,
        // Banner Position
        anchorType: AnchorType.bottom,
      );
  }

  void show_bigAdbanner() {
    myInterstitial
      ..load()
      ..show(
        anchorType: AnchorType.bottom,
        anchorOffset: 0.0,
        horizontalCenterOffset: 0.0,
      );
  }

  Color AnimationControl() {
    if (animation1.value * 4.2 + 0.11 < 1.74)
      return Colors.green;
    else if (animation1.value * 4.2 + 0.11 > 1.74 &&
        animation1.value * 4.2 + 0.11 < 2.61)
      return Colors.orange;
    else if (animation1.value * 4.2 + 0.11 > 2.61 &&
        animation1.value * 4.2 + 0.11 < 4.71) return Colors.red;
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
          // if (speedInKph <= 5) speedInKph = 0.0;
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

  void odome() {
    const oneSec = const Duration(milliseconds: 300);

    new Timer.periodic(oneSec, (Timer t) {
      setState(() {
        odo += linearInterpolate * (0.3 / 3600);
        int x = int.parse(totalDistance);

        if (linearInterpolate > maxspeed) maxspeed = linearInterpolate;
        writeData('10');
        widget.storage.readData().then((String value) {
          totalDistance = value;
          print(value);
        });
      });
    });
  }

  String displayhour = "0";
  String minutes = "0";
  int seconds = 0;
  var swatch = Stopwatch();
  final dur = const Duration(seconds: 1);
  void starttimer() {
    Timer(dur, keeprunning);
  }

  void keeprunning() {
    if (swatch.isRunning) {
      starttimer();
    }
    setState(() {
      displayhour = swatch.elapsed.inHours.toString().padLeft(1);
      minutes = (swatch.elapsed.inMinutes % 60).toString().padLeft(2, '0');
      seconds = swatch.elapsed.inSeconds;
    });
  }

  void startstopwatch() {
    swatch.start();
    starttimer();
  }

  Container rotate() {
    return Container(
      child: Transform.rotate(
        angle: introanimation
            ? animation1.value * 4.2 + 0.11
            : linearInterpolate * (0.59 / 20),
        origin: Offset(-6, -10),
        child: Container(
          child: Stack(
            children: <Widget>[
              new Positioned(
                left: 10,
                bottom: 30,
                child: RotatedBox(
                    quarterTurns: 6,
                    child: Image.asset(
                      'assets/needle.png',
                      scale: 2.1,
                    )),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Container rotateCompass() {
    return Container(
      child: Transform.rotate(
        angle: -linearInterpolateCompass * 6.28 / 360,
        origin: Offset(0, 0),
        child: Container(
          child: Stack(
            children: <Widget>[
              new Positioned(
                left: 0,
                bottom: 20,
                right:5,
                child: RotatedBox(
                    quarterTurns: 0,
                    child: Image.asset('assets/compass5.png',)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  //writestorage
  Future<File> writeData(String bool1) async {
    setState(() {
      totalDistance = bool1;
    });

    return widget.storage.writeData(bool1);
  }

//odometer
  String totalDistance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: <Widget>[
          Stack(
            alignment: AlignmentDirectional.bottomCenter,
            overflow: Overflow.clip,
            children: <Widget>[
              SizedBox(
                height: 400,
                width: 600,
                child: Container(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Colors.white, animation.value])),
                ),
              ),
              Positioned(
                height: 350,
                width: 350,
                top: 125,
                child: Container(
                    height: 400,
                    width: 350,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey[400],
                          blurRadius: 8.0,
                        ),
                      ],
                      color: Colors.grey[200],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(175),
                      child: speedView(),
                    )),
              ),
              Positioned(
                height: 350,
                width: 320,
                top: 150,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: Stack(
                    children: <Widget>[
                      rotateCompass(),
                      Container(
                        decoration: BoxDecoration(
                            gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [Colors.black38, Colors.transparent])),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(175),
                        ),
                      ),
                      rotate()
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: 100,
                width: 150,
                child: Container(
                  padding: EdgeInsets.only(
                    top: 50,
                  ),
                  color: Colors.transparent,
                  child: Center(
                    child: Row(
                      children: <Widget>[
                        SizedBox(width: 43),
                        Text(
                          linearInterpolate.toStringAsFixed(1),
                          style: TextStyle(fontSize: 30, color: Colors.black87),
                        ),
                        Text(
                          ' km/h',
                          style: TextStyle(fontSize: 15, color: Colors.black26),
                        )
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                  top: 30,
                  left: 12,
                  child: Container(
                    child: IconButton(
                        icon: Icon(
                          Icons.settings,
                          color: Colors.grey[600],
                        ),
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => SettingsPage(
                                        storage: Storage(),
                                      )));
                          show_bigAdbanner();
                        }),
                  )),
            ],
          ),
          SizedBox(
            height: 20,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  Text(
                    'Trip Distance',
                    style: TextStyle(fontSize: 12, color: Colors.black38),
                  ),
                  Text(
                    odo.toStringAsFixed(1) + " km",
                    style: TextStyle(fontSize: 21, color: Colors.black87),
                  ),
                ],
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  Text(
                    'Odometer',
                    style: TextStyle(fontSize: 12, color: Colors.black38),
                  ),
                  Text(
                    totalDistance + " km",
                    style: TextStyle(fontSize: 21, color: Colors.black87),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  Text(
                    'Time Elapsed',
                    style: TextStyle(fontSize: 14, color: Colors.black38),
                  ),
                  RichText(
                    text: TextSpan(
                        text: displayhour,
                        style: TextStyle(fontSize: 25, color: Colors.black87),
                        children: <TextSpan>[
                          TextSpan(
                              text: ' h',
                              style: TextStyle(
                                  fontSize: 10, color: Colors.black26)),
                          TextSpan(
                            text: minutes,
                            style: TextStyle(
                              fontSize: 25,
                              color: Colors.black87,
                            ),
                          ),
                          TextSpan(
                              text: ' m',
                              style: TextStyle(
                                  fontSize: 10, color: Colors.black26))
                        ]),
                  ),
                ],
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  Text(
                    'Average Speed',
                    style: TextStyle(fontSize: 14, color: Colors.black38),
                  ),
                  RichText(
                    text: TextSpan(
                        text: '${(odo / seconds * 3600).toStringAsFixed(1)}',
                        style: TextStyle(fontSize: 25, color: Colors.black87),
                        children: <TextSpan>[
                          TextSpan(
                              text: ' km/hr',
                              style: TextStyle(
                                  fontSize: 14, color: Colors.black26))
                        ]),
                  ),
                ],
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  Text(
                    'MaxSpeed',
                    style: TextStyle(fontSize: 14, color: Colors.black38),
                  ),
                  RichText(
                    text: TextSpan(
                        text: '${(maxspeed).toStringAsFixed(1)} ',
                        style: TextStyle(fontSize: 25, color: Colors.black87),
                        children: <TextSpan>[
                          TextSpan(
                              text: ' km/hr',
                              style: TextStyle(
                                  fontSize: 14, color: Colors.black26))
                        ]),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 20),
          Center(
              child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              Text(
                'Heading',
                style: TextStyle(fontSize: 14, color: Colors.black38),
              ),
              Text('${heading.toStringAsFixed(0)} °',
                  style: TextStyle(fontSize: 25, color: Colors.black87)),
            ],
          )),
        ],
      ),
    );
  }
}

class Storage1 {
  Future<String> get localPath async {
    final dir = await getApplicationDocumentsDirectory();
    return dir.path;
  }

  Future<File> get localFile async {
    final path = await localPath;
    return File('$path/odo.txt');
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
