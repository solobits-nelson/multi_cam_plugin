import Flutter
import UIKit

@available(iOS 13.0, *)
public class SwiftMultiCamPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let factory = CameraNativeViewFactory(messenger: registrar.messenger())
        
        registrar.register(factory, withId: "multi_cam_plugin")
    }
}
