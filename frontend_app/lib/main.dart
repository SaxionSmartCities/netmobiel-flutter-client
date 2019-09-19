import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:flutter_statusbarcolor/flutter_statusbarcolor.dart';

String url = "https://app.netmobiel.eu";

void main() {
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown])
      .then((_) => runApp(new MyApp()));
}


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    FlutterStatusbarcolor.setStatusBarColor(Color.fromRGBO(51,137,150, 1.0));
    FlutterStatusbarcolor.setStatusBarWhiteForeground(true);
    FlutterStatusbarcolor.setNavigationBarWhiteForeground(true);
    return new MaterialApp(
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
    return
      SafeArea(
        minimum: const EdgeInsets.all(0.0),
        child:
          WebviewScaffold(
            userAgent: 'Flutter',
            url: url,
            withJavascript: true,
            withLocalStorage: true,
            withZoom: false,
            scrollBar: false,
          ),
      );
  }
}