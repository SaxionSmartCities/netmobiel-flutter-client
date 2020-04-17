import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:flutter_statusbarcolor/flutter_statusbarcolor.dart';
import 'package:url_launcher/url_launcher.dart';
String url = "https://app.netmobiel.eu";

void main() {
  runApp(new MyApp());
}


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    FlutterStatusbarcolor.setStatusBarColor(Color.fromRGBO(51,137,150, 1.0));
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
  final flutterWebviewPlugin = new FlutterWebviewPlugin();
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  String url = "";
  StreamSubscription<WebViewStateChanged> _onStateChanged;
  final telephonePrefix = 'tel:';


  @override
  void initState() {
    super.initState();
    firebaseCloudMessaging_Listeners();
  }
  void firebaseCloudMessaging_Listeners() {
    if (Platform.isIOS) iOS_Permission();

    _firebaseMessaging.getToken().then((token){
      print(token);
      setState(() {
        url = "https://app.netmobiel.eu?fcm=$token";
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
        IosNotificationSettings(sound: true, badge: true, alert: true)
    );
    _firebaseMessaging.onIosSettingsRegistered
        .listen((IosNotificationSettings settings)
    {
      print("Settings registered: $settings");
    });
  }

  @override
  Widget build(BuildContext context) {
    flutterWebviewPlugin.resize(
      new Rect.fromLTWH(
        0.0,
        0.0,
        MediaQuery
            .of(context)
            .size
            .width,
        MediaQuery
            .of(context)
            .size
            .height,
      ),
    );
    _onStateChanged = flutterWebviewPlugin.onStateChanged.listen((WebViewStateChanged state) async {
      if (mounted) {
        if (state.url.startsWith(telephonePrefix) && state.type == WebViewState.abortLoad) {
          if (await canLaunch(state.url)) {
            await launch(state.url);
          }
        }
      }
    });

    return
      SafeArea(
        minimum: const EdgeInsets.all(0.0),
        child:
            url == "" ?
            Container(color: Color.fromRGBO(51,137,150, 1.0))
                :
            WebviewScaffold(
              userAgent: 'Flutter',
              url: url,
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