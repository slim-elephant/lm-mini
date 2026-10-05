#import "FlutterCallkitIncomingPlugin.h"
#import <Flutter/Flutter.h>

// China App Store / MIIT: compile this ObjC no-op instead of the plugin's
// Swift (which imports CallKit and auto-links CallKit.framework).
// Restore: remove disable_callkit_pod from ios/Podfile — see agent.md.

@implementation FlutterCallkitIncomingPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
  FlutterMethodChannel *channel = [FlutterMethodChannel
      methodChannelWithName:@"flutter_callkit_incoming"
            binaryMessenger:[registrar messenger]];
  FlutterCallkitIncomingPlugin *instance =
      [[FlutterCallkitIncomingPlugin alloc] init];
  [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall *)call
                  result:(FlutterResult)result {
  result(nil);
}
@end
