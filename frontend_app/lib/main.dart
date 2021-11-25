import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
// import 'package:flutter_statusbarcolor/flutter_statusbarcolor.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:device_info/device_info.dart';

String url = "https://app.netmobiel.eu";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print("Firebase.initializeApp");
  await Firebase.initializeApp(options: const FirebaseOptions(
      apiKey: "AIzaSyDsvRU4TKWO-dHYkmZYowm3ptD2y7Szojc",      // Auth / General Use
      appId: "1:119510705158:android:7c4a4cbb2b10a9c4688f87", // General Use
      projectId: "netmobiel-push",                            // General Use
      // authDomain: "YOUR_APP.firebaseapp.com",              // Auth with popup/redirect
      databaseURL: "https://netmobiel-push.firebaseio.com",   // Realtime Database
      storageBucket: "netmobiel-push.appspot.com",            // Storage
      messagingSenderId: "",                         // Cloud Messaging
      // measurementId: "G-12345",                               // Analytics
      androidClientId: "119510705158-slk85pna9hhqf19481a4afsipprpr5ua.apps.googleusercontent.com",
      iosClientId: "119510705158-auh7kbc1uot14hsd1q0qek4daa8h4v8n.apps.googleusercontent.com",
      iosBundleId: "eu.netmobiel.frontendApp",
      // appGroupId: "",
    )
  );
  /// Update the iOS foreground notification presentation options to allow
  /// heads up notifications.
  print("FirebaseMessaging.instance.requestPermission");
  NotificationSettings settings = await FirebaseMessaging.instance
      .requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  print('User granted permission: ${settings.authorizationStatus}');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    // FlutterStatusbarcolor.setStatusBarColor(Color.fromRGBO(51, 137, 150, 1.0));
    // FlutterStatusbarcolor.setStatusBarWhiteForeground(true);
    // FlutterStatusbarcolor.setNavigationBarWhiteForeground(true);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      routes: {
        "/": (_) => Home(),
      },
    );
  }
}

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final flutterWebviewPlugin = FlutterWebviewPlugin();
  String _fcmToken = "";
  final String _baseUrl = "https://app.netmobiel.eu";
  late StreamSubscription<WebViewStateChanged> _onStateChanged;
  final telephonePrefix = 'tel:';
  String _userAgent = 'Flutter,';

  Future<void> setupInteractedMessage() async {
    // Get any messages which caused the application to open from
    // a terminated state.
    print("setupInteractedMessage");
    try {
      RemoteMessage? initialMessage =
      await FirebaseMessaging.instance.getInitialMessage();

      // If the message also contains a data property with a "type" of "chat",
      // navigate to a chat screen
      print("Got initial message");
      if (initialMessage != null) {
        handleInitialMessage(initialMessage);
      }

      // Also handle any interaction when the app is in the background via a
      // Stream listener
      FirebaseMessaging.onMessageOpenedApp.listen(handleInitialMessage);
      print("Setup listener initial message");
    } catch (e) {
      print(e);
    }
  }

  @override
  void initState() {
    super.initState();
    try {
      setupInteractedMessage().then((value) =>
          print("Interacted message setup done"));
      FirebaseMessaging.instance.getToken()
          .then((token) => saveToken(token))
          .catchError((error) => print(error.toString()));
      // Any time the token refreshes, store this in the database too.
      FirebaseMessaging.instance.onTokenRefresh.listen(saveToken);
      print("Setup token listener");
      FirebaseMessaging.onMessage.listen(handleForegroundMessage);
      print("Setup foreground listener");
    } catch (e) {
      print(e);
    }
    buildUserAgentString();
  }

  void saveToken(String? token) {
    print("Save token: ${token}");
    token ??= "";
    setState(() {
      _fcmToken = token!;
    });
  }

  void handleInitialMessage(RemoteMessage message) {
    // Should do some navigation here
    if (message.data != null) {
      print('MSG Data: ${message.data}');
    }
    if (message.notification != null) {
      print('MSG Notification: ${message.notification}');
    }
  }

  void handleForegroundMessage(RemoteMessage message) {
    if (message.data != null) {
      print('MSG FG Data: ${message.data}');
    }
    if (message.notification != null) {
      print('MSG FG Notification: ${message.notification}');
    }
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
    } else if (Platform.isIOS) {
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

  @override
  Widget build(BuildContext context) {
    print("Build the widget: Resize webview");
    flutterWebviewPlugin.resize(
      Rect.fromLTWH(
        0.0,
        0.0,
        MediaQuery.of(context).size.width,
        MediaQuery.of(context).size.height,
      ),
    );
    print("Listen to state changes");
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
    print("Return the safe area");
    final String _url = _fcmToken.isEmpty ? _baseUrl : "$_baseUrl?fcm=$_fcmToken";
    return SafeArea(
      minimum: const EdgeInsets.all(0.0),
      child: _url == ""
          ? Container(color: const Color.fromRGBO(51, 137, 150, 1.0))
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
