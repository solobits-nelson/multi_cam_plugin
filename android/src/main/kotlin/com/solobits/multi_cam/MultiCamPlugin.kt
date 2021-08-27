package com.solobits.multi_cam

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.FlutterPlugin.FlutterPluginBinding


class MultiCamPlugin : FlutterPlugin {
    override fun onAttachedToEngine(binding: FlutterPluginBinding) {
        binding
                .platformViewRegistry
                .registerViewFactory("multi_cam_plugin", CameraViewFactory())
    }

    override fun onDetachedFromEngine(binding: FlutterPluginBinding) {}
}