# MultiCam

A plugin to access both front and back cameras simultaneously.

The plugin presents a native iOS view that shows both front and back cameras using flutter's Platform View.


<p align='center'>
    <img src="https://github.com/solobits-nelson/multi_cam_plugin/blob/main/multi_cam_example.gif" />
</p>

## Usage

Add `multi_cam` as dependency in your pubspec.yaml

```
dependencies:
  multi_cam: 0.0.1
```

Example:

```
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
```

## Upcoming Features
- Support For android
- Audio and Video recording