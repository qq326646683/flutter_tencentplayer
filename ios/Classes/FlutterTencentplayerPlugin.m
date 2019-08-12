#import "FlutterTencentplayerPlugin.h"

@implementation FlutterTencentplayerPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel
                                     methodChannelWithName:@"flutter_tencentplayer"
                                     binaryMessenger:[registrar messenger]];
    FlutterTencentplayerPlugin* instance = [[FlutterTencentplayerPlugin alloc] init];
    [registrar addMethodCallDelegate:instance channel:channel];
}
    
- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([@"init" isEqualToString:call.method]) {
        NSLog(@"init");
    }else if([@"create" isEqualToString:call.method]){
        NSLog(@"create");
    }else if([@"download" isEqualToString:call.method]){
         NSLog(@"download");
    }else if([@"stopDownload" isEqualToString:call.method]){
         NSLog(@"stopDownload");
    }else {
        result(FlutterMethodNotImplemented);
    }
    
    
    
}
    
@end
