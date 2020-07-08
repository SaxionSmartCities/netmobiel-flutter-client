import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:flutter_statusbarcolor/flutter_statusbarcolor.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:device_info/device_info.dart';

String url = "https://app.netmobiel.eu";

void main() {
  runApp(new MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    FlutterStatusbarcolor.setStatusBarColor(Color.fromRGBO(51, 137, 150, 1.0));
    FlutterStatusbarcolor.setStatusBarWhiteForeground(true);
    FlutterStatusbarcolor.setNavigationBarWhiteForeground(true);
    return new MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: new ThemeData(
        primarySwatch: Colors.blue,
      ),
      routes: {
        "/": (_) => Home(),
      },
    );
  }
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => new _HomeState();
}

class _HomeState extends State<Home> {
  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  final flutterWebviewPlugin = new FlutterWebviewPlugin();
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  String _fcmToken = "";
  String _baseUrl = "https://app.netmobiel.eu";
  String _url = "";
  StreamSubscription<WebViewStateChanged> _onStateChanged;
  final telephonePrefix = 'tel:';
  bool _useAcceptance = false;
  String _userAgent = 'Flutter,';

  @override
  void initState() {
    super.initState();
    firebaseCloudMessaging_Listeners();
    buildUserAgentString();
  }

  void buildUserAgentString() async {
    if (Platform.isAndroid) {
      var androidInfo = await DeviceInfoPlugin().androidInfo;
      var release = androidInfo.version.release;
      var sdkInt = androidInfo.version.sdkInt;
      var manufacturer = androidInfo.manufacturer;
      var model = androidInfo.model;
      print('Android $release (SDK $sdkInt), $manufacturer $model');
      setState(() {
        _userAgent =
            'Flutter - Android $release (SDK $sdkInt), $manufacturer $model';
      });
      // Android 9 (SDK 28), Xiaomi Redmi Note 7
    }
    if (Platform.isIOS) {
      var iosInfo = await DeviceInfoPlugin().iosInfo;
      var systemName = iosInfo.systemName;
      var version = iosInfo.systemVersion;
      var name = iosInfo.name;
      var model = iosInfo.model;
      print('$systemName $version, $name $model');
      // iOS 13.1, iPhone 11 Pro Max iPhone
      setState(() {
        _userAgent = 'Flutter - $systemName $version, $name $model';
      });
    }
  }

  void firebaseCloudMessaging_Listeners() {
    if (Platform.isIOS) iOS_Permission();

    _firebaseMessaging.getToken().then((token) {
      print(token);
      setState(() {
        _url = "$_baseUrl?fcm=$token";
        _fcmToken = token;
      });
    });

    _firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> message) async {
        print('on message $message');
      },
      onResume: (Map<String, dynamic> message) async {
        print('on resume $message');
      },
      onLaunch: (Map<String, dynamic> message) async {
        print('on launch $message');
      },
    );
  }

  void iOS_Permission() {
    _firebaseMessaging.requestNotificationPermissions(
        IosNotificationSettings(sound: true, badge: true, alert: true));
    _firebaseMessaging.onIosSettingsRegistered
        .listen((IosNotificationSettings settings) {
      print("Settings registered: $settings");
    });
  }

  @override
  Widget build(BuildContext context) {
    flutterWebviewPlugin.resize(
      new Rect.fromLTWH(
        0.0,
        0.0,
        MediaQuery.of(context).size.width,
        MediaQuery.of(context).size.height,
      ),
    );
    _onStateChanged = flutterWebviewPlugin.onStateChanged
        .listen((WebViewStateChanged state) async {
      if (mounted) {
        if (state.url.startsWith(telephonePrefix) &&
            state.type == WebViewState.abortLoad) {
          if (await canLaunch(state.url)) {
            await launch(state.url);
          }
        }
      }
    });
    _prefs.then((SharedPreferences prefs) {
      var tmp = prefs.getBool('enabled_acceptance') ?? false;
      print('ACC: $tmp');
      if (tmp != _useAcceptance) {
        setState(() {
          _useAcceptance = tmp;
          _baseUrl = _useAcceptance
              ? "https://app.acc.netmobiel.eu"
              : "https://app.netmobiel.eu";
          _url = _fcmToken.isNotEmpty ? "$_baseUrl?fcm=$_fcmToken" : _baseUrl;
        });
      }
    });
    if (_useAcceptance) {
      FlutterStatusbarcolor.setStatusBarColor(Color.fromRGBO(255, 133, 0, 1.0));
    } else {
      FlutterStatusbarcolor.setStatusBarColor(
          Color.fromRGBO(51, 137, 150, 1.0));
    }
    return SafeArea(
      minimum: const EdgeInsets.all(0.0),
      child: _url == ""
          ? Container(color: Color.fromRGBO(51, 137, 150, 1.0))
          : WebviewScaffold(
              userAgent: _userAgent,
              url: _url,
              debuggingEnabled: true,
              invalidUrlRegex: '^$telephonePrefix',
              withJavascript: true,
              withLocalStorage: true,
              withZoom: false,
              scrollBar: false,
              withOverviewMode: false,
            ),
    );
  }
}
