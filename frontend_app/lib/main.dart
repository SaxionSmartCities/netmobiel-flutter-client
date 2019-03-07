import 'package:flutter/material.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';

import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';

String url = "https://htbm.smartenschede.nl/";

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Flutter Demo',
      theme: new ThemeData(
        primarySwatch: Colors.blue,
      ),
      routes: {
        "/": (_) => Home(title: 'Netmobiel PoC'),
        "/webview": (_) => WebviewScaffold(
          url: url,
          appBar: AppBar(
            title: Text("WebView"),
          ),
          withJavascript: true,
          withLocalStorage: true,
          withZoom: true,
        )
      },
    );
  }
}

class Home extends StatefulWidget {
  Home({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _HomeState createState() => new _HomeState();
}

class _HomeState extends State<Home> {
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging();

  final webView = FlutterWebviewPlugin();
  TextEditingController controller = TextEditingController(text: url);

  @override
  void initState() {
    super.initState();

    webView.close();
    controller.addListener(() {
      url = controller.text;
    });

    // Set the GCM listener
    firebaseCloudMessaging_Listeners();
  }

  void firebaseCloudMessaging_Listeners() {
    print('firebase');
    if (Platform.isIOS) iOS_Permission();

    _firebaseMessaging.getToken().then((token){
      print(token);
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
  void dispose() {
    webView.dispose();
    controller.dispose();
    super.dispose();
  }

  void _sendNotification() {
    print("TODO: Send notification");
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text(widget.title),
      ),
      body: new Center(
        child: new Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              padding: EdgeInsets.all(10.0),
              child: TextField(
                controller: controller,
              ),
            ),
            RaisedButton(
              child: Text("Open Webview"),
              onPressed: () {
                Navigator.of(context).pushNamed("/webview");
              },
            )
          ],
        ),
      ),
      floatingActionButton: new FloatingActionButton(
        onPressed: _sendNotification,
        tooltip: 'Increment',
        child: new Icon(Icons.notifications),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
