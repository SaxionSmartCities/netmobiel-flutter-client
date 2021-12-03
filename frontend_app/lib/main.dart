import 'dart:async';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

const String prodBaseUrl = 'https://app.netmobiel.eu';
const String devBaseUrl = 'http://192.168.0.15:8081/';
const bool production = true;

/// If you want to do something with background messages, enable the following
/// code. As a background service, it is not possible to interact with the
/// application.

// Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   // If you're going to use other Firebase services in the background, such as Firestore,
//   // make sure you call `initializeApp` before using other Firebase services.
//   await Firebase.initializeApp();
//
//   if (message.data != null) {
//     print('Background MSG Data: ${message.data}');
//   }
//   if (message.notification != null) {
//     print('Background MSG Notification: ${message.notification!.title}: ${message.notification!.body}');
//   }
// }

void main() async {
  // FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  /// Update the iOS foreground notification presentation options to allow
  /// heads up notifications.
  // ignore: unused_local_variable
  NotificationSettings settings =
      await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  // print('User granted permission: ${settings.authorizationStatus}');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Show a debug banner as hint that this app is for research purposes
      debugShowCheckedModeBanner: true,
      title: 'Netmobiel',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      routes: {
        '/': (_) => const Home(),
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
  String _fcmToken = '';
  WebViewController? _controller;
  final String _baseUrl = production ? prodBaseUrl : devBaseUrl;
  final telephonePrefix = 'tel:';
  String _userAgent = 'Flutter,';

  Future<void> setupInteractedMessage() async {
    // Get any messages which caused the application to open from
    // a terminated state.
    try {
      RemoteMessage? initialMessage =
          await FirebaseMessaging.instance.getInitialMessage();

      // If the message also contains a data property with a "type" of "chat",
      // navigate to a chat screen
      if (initialMessage != null) {
        handleInitialMessage(initialMessage);
      }

      // Also handle any interaction when the app is in the background via a
      // Stream listener
      FirebaseMessaging.onMessageOpenedApp.listen(handleInitialMessage);
    } catch (e) {
      print(e);
    }
  }

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) {
      // https://pub.dev/packages/webview_flutter
      // Use the Hybrid composition mode, the virtual display has keyboard problems
      // like keyboard is not going away when the focus has gone away.
      WebView.platform = SurfaceAndroidWebView();
    }
    try {
      setupInteractedMessage()
          .catchError((error) {
        print(error.toString());
      });
      FirebaseMessaging.instance
          .getToken()
          .then((token) => saveToken(token))
          .catchError((error) {
            print(error.toString());
          });
      // Any time the token refreshes, store this in the database too.
      FirebaseMessaging.instance.onTokenRefresh.listen(saveToken);
      FirebaseMessaging.onMessage.listen(handleForegroundMessage);
    } catch (e) {
      print(e);
    }
    buildUserAgentString();
  }

  void saveToken(String? token) {
    token ??= '';
    setState(() {
      _fcmToken = token!;
    });
  }

  void handleInitialMessage(RemoteMessage message) {
    // Should do some navigation here
    // print('MSG IN Data: ${message.data}');
    // if (message.notification != null) {
    //   print('MSG IN Notification: ${message.notification!.title}: ${message.notification!.body}');
    // }
    // We do not use the mechanism with Javascript. At the time of initial message the application
    // might not yet completely loaded and up and running. Instead, do a reload of the url.
    // dispatchNetmobielInitialMessage(message.data['messageRef']);
    if (_controller == null) {
      print('Controller is still null!');
    } else {
      _controller!.loadUrl('$_baseUrl?msgId=${message.data["messageRef"]}');
    }
  }

  void handleForegroundMessage(RemoteMessage message) {
    // print('MSG FG Data: ${message.data}');
    // if (message.notification != null) {
    //   print('MSG FG Notification: ${message.notification!.title}: ${message.notification!.body}');
    // }
    dispatchNetmobielPushMessage(message.data['messageRef'], message.notification!.title, message.notification!.body);
  }

  void buildUserAgentString() async {
    if (Platform.isAndroid) {
      var androidInfo = await DeviceInfoPlugin().androidInfo;
      var release = androidInfo.version.release;
      var sdkInt = androidInfo.version.sdkInt;
      var manufacturer = androidInfo.manufacturer;
      var model = androidInfo.model;
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
      setState(() {
        _userAgent = 'Flutter - $systemName $version, $name $model';
      });
    }
  }

  JavascriptChannel _requestChannel(BuildContext context) {
    return JavascriptChannel(
        name: 'NetmobielAppRequest',
        onMessageReceived: (JavascriptMessage message) {
          publishNetmobielResponse(message.message);
        });
  }

  void publishNetmobielResponse(String message) {
    if (_controller == null) {
      print('Controller is still null!');
    } else if (message == 'fcmToken') {
      _controller!.runJavascript('setNetmobielFcmToken("$_fcmToken")')
          .catchError((error) {
        print('Got error: $error');
      });
    } else {
      print('Do not understand request: $message');
    }
  }

  void dispatchNetmobielPushMessage(String msgId, String? title, String? body) {
    if (_controller == null) {
      print('Controller is still null!');
    } else {
      // Encode the strings to prevent issues with javascript syntax and clever injection
      final titleEnc = title == null ? null : Uri.encodeComponent(title);
      final bodyEnc = body == null ? null : Uri.encodeComponent(body);
      String script = 'dispatchNetmobielPushMessage("$msgId", "$titleEnc", "$bodyEnc")';
      // print('Run script: $script');
      _controller!.runJavascript(script)
          .catchError((error) {
        print('Got error: $error');
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    final view = WebView(
      initialUrl: _baseUrl,
      javascriptMode: JavascriptMode.unrestricted,
      javascriptChannels: {
        _requestChannel(context)
      },
      debuggingEnabled: true,
      userAgent: _userAgent,
      onWebViewCreated: (WebViewController ctrl) {
        _controller = ctrl;
      },
    );
    // print('UserAgent = ${view.userAgent}, url = ${view.initialUrl}');
    return Scaffold(
        body: SafeArea(child: Column(children: [Expanded(child: view)])));
  }

}
