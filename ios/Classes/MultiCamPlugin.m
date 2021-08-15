#import "MultiCamPlugin.h"
#if __has_include(<multi_cam/multi_cam-Swift.h>)
#import <multi_cam/multi_cam-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "multi_cam-Swift.h"
#endif

@implementation MultiCamPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftMultiCamPlugin registerWithRegistrar:registrar];
}
@end
