import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class MultiCam extends StatelessWidget {
  const MultiCam({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String viewType = 'multi_cam_plugin';

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _NativeAndroid(viewType: viewType);
      case TargetPlatform.iOS:
        return _NativeIOS(viewType: viewType);
      default:
        throw UnsupportedError("Unsupported platform view");
    }
  }
}

class _NativeAndroid extends StatelessWidget {
  const _NativeAndroid({Key? key, required this.viewType}) : super(key: key);
  final String viewType;

  @override
  Widget build(BuildContext context) {
    return AndroidView(
      viewType: viewType,
      layoutDirection: TextDirection.ltr,
      creationParamsCodec: const StandardMessageCodec(),
    );
  }
}

class _NativeIOS extends StatelessWidget {
  const _NativeIOS({Key? key, required this.viewType}) : super(key: key);
  final String viewType;

  @override
  Widget build(BuildContext context) {
    return UiKitView(
      viewType: viewType,
      creationParamsCodec: const StandardMessageCodec(),
      gestureRecognizers: Set()
        ..add(Factory<TapGestureRecognizer>(() => TapGestureRecognizer())),
    );
  }
}
