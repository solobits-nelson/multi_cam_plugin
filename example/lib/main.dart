import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:multi_cam/multi_cam.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Permission.camera.request();

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('MultiCam example app'),
        ),
        body: Center(
          child: MultiCam(),
        ),
      ),
    );
  }
}
