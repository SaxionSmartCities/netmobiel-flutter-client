import 'dart:async';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webview_pro/webview_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher_string.dart';

const String prodBaseUrl = 'https://app.netmobiel.eu/';
const String devBaseUrl = 'http://192.168.0.15:8081/';
const String keycloakUrl = 'https://keycloak.actmedialab.nl/auth/realms/netmobiel/';
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

void devlog(String msg) {
  var now = DateTime.now();
  print('${now.toIso8601String()} $msg');
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Show a debug banner as hint that this app is for research purposes
      debugShowCheckedModeBanner: false,
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
  bool _canUpload = false;
  bool _canHandleExternalUrl = false;
  WebViewController? _controller;
  final String _baseUrl = production ? prodBaseUrl : devBaseUrl;
  String _userAgent = 'Netmobiel';
  PackageInfo _packageInfo = PackageInfo(
    appName: 'Unknown',
    packageName: 'Unknown',
    version: 'Unknown',
    buildNumber: 'Unknown',
    buildSignature: 'Unknown',
  );

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
      _initPackageInfo();
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
    // Hmm, may be still better simply push the message. Not a real issue if missed and better performance.
    dispatchNetmobielPushMessage(message.data['messageRef'], message.notification!.title, message.notification!.body);
    // if (_controller == null) {
    //   print('Controller is still null!');
    // } else {
    //   _controller!.loadUrl('$_baseUrl?msgId=${message.data["messageRef"]}');
    // }
  }

  void handleForegroundMessage(RemoteMessage message) {
    // print('MSG FG Data: ${message.data}');
    // if (message.notification != null) {
    //   print('MSG FG Notification: ${message.notification!.title}: ${message.notification!.body}');
    // }
    dispatchNetmobielPushMessage(message.data['messageRef'], message.notification!.title, message.notification!.body);
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = info;
    });
  }

  void buildUserAgentString() async {
    var appName = _packageInfo.appName;
    var appVersion = _packageInfo.version;
    if (Platform.isAndroid) {
      var androidInfo = await DeviceInfoPlugin().androidInfo;
      var release = androidInfo.version.release;
      var sdkInt = androidInfo.version.sdkInt;
      var manufacturer = androidInfo.manufacturer;
      var model = androidInfo.model;
      setState(() {
        _userAgent =
            'Flutter $appName $appVersion - Android $release (SDK $sdkInt), $manufacturer $model';
        _canUpload = true;
        _canHandleExternalUrl = false;
      });
      // UserAgent Flutter <appName> <appVersion> - Android 10 (SDK 29), HMD Global Nokia 9
    } else if (Platform.isIOS) {
      var iosInfo = await DeviceInfoPlugin().iosInfo;
      var systemName = iosInfo.systemName;
      var version = iosInfo.systemVersion;
      var name = iosInfo.name;
      var model = iosInfo.model;
      setState(() {
        _userAgent = 'Flutter $appName $appVersion - $systemName $version, $name $model';
        _canUpload = true;
        _canHandleExternalUrl = false;
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
    } else if (message == 'capabilities') {
      // Be careful to pass booleans, not strings!
      _controller!.runJavascript('setNetmobielCapabilities($_canUpload, $_canHandleExternalUrl)')
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
  Future<NavigationDecision> getNavigationDelegate(NavigationRequest request) async {
    if (request.url.startsWith(_baseUrl) || request.url.startsWith(keycloakUrl)) {
      devlog('Launch in app (main: ${request.isForMainFrame}): ${request.url}');
      return NavigationDecision.navigate;
    } else {
      devlog('Launch external (main: ${request.isForMainFrame}): ${request.url}');
      if (await canLaunchUrlString(request.url)) {
        if (!await launchUrlString(request.url)) {
          devlog('Could not launch ${request.url}');
        }
      } else {
        devlog('Could not launch ${request.url}');
        throw 'Could not launch ${request.url}';
      }
      return NavigationDecision.prevent;
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
      debuggingEnabled: !production,
      userAgent: _userAgent,
      onWebViewCreated: (WebViewController ctrl) {
        _controller = ctrl;
      },
      navigationDelegate: _canHandleExternalUrl ? getNavigationDelegate : null,
      onPageStarted: (String url) {
        devlog('Page started loading: $url');
      },
      onPageFinished: (String url) {
        devlog('Page finished loading: $url');
      },
    );
    // print('UserAgent = ${view.userAgent}, url = ${view.initialUrl}');
    return Scaffold(
        body: SafeArea(child: Column(children: [Expanded(child: view)])));
  }

}
