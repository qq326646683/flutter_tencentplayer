#import "FlutterTencentplayerPlugin.h"
#import <AVFoundation/AVFoundation.h>
#import <TXLiteAVSDK_Player/TXVodPlayer.h>

//// FLTFrameUpdater ////
@interface FLTFrameUpdater : NSObject
@property(nonatomic) int64_t textureId;
@property(nonatomic, readonly) NSObject<FlutterTextureRegistry>* registry;
- (void)onDisplayLink:(CADisplayLink*)link;
@end

@implementation FLTFrameUpdater
- (FLTFrameUpdater*)initWithRegistry:(NSObject<FlutterTextureRegistry>*)registry {
    NSAssert(self, @"super init cannot be nil");
    if (self == nil) return nil;
    _registry = registry;
    return self;
}

- (void)onDisplayLink:(CADisplayLink*)link {
    [_registry textureFrameAvailable:_textureId];
}
@end
//// TencentPlayer ////
@interface TencentPlayer : NSObject <FlutterTexture, FlutterStreamHandler>
@property(readonly, nonatomic) TXVodPlayer* player;
@property(readonly, nonatomic) AVPlayerItemVideoOutput* videoOutput;
@property(readonly, nonatomic) CADisplayLink* displayLink;
@property(nonatomic) FlutterEventChannel* eventChannel;
@property(nonatomic) FlutterEventSink eventSink;
@property(nonatomic, readonly) bool disposed;
@property(nonatomic, readonly) bool isPlaying;
@property(nonatomic, readonly) bool isInitialized;

- (instancetype)initWithURL:(NSURL*)url frameUpdater:(FLTFrameUpdater*)frameUpdater;
- (void)play;
- (void)pause;
@end
@implementation TencentPlayer

- (instancetype)initWithURL:(NSString*)url frameUpdater:(FLTFrameUpdater*)frameUpdater {
    self = [super init];
    NSAssert(self, @"super init cannot be nil");
    _isInitialized = false;
    _isPlaying = false;
    _disposed = false;
    
    _player = [[TXVodPlayer alloc] init];
    [_player startPlay: url];
    
    [self createVideoOutputAndDisplayLink:frameUpdater];
    return self;
}

- (void)createVideoOutputAndDisplayLink:(FLTFrameUpdater*)frameUpdater {
    NSDictionary* pixBuffAttributes = @{
                                        (id)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA),
                                        (id)kCVPixelBufferIOSurfacePropertiesKey : @{}
                                        };
    // todo change
    _videoOutput = [[AVPlayerItemVideoOutput alloc] initWithPixelBufferAttributes:pixBuffAttributes];
    
    _displayLink = [CADisplayLink displayLinkWithTarget:frameUpdater
                                               selector:@selector(onDisplayLink:)];
    [_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    _displayLink.paused = YES;
}

- (CVPixelBufferRef)copyPixelBuffer {
    CVPixelBufferRef newBuffer = [_player framePixelbuffer];

}

@end
//// FlutterTencentplayerPlugin ////
@interface FlutterTencentplayerPlugin ()
@property(readonly, nonatomic) NSObject<FlutterTextureRegistry>* registry;
@property(readonly, nonatomic) NSObject<FlutterBinaryMessenger>* messenger;
@property(readonly, nonatomic) NSMutableDictionary* players;
@property(readonly, nonatomic) NSObject<FlutterPluginRegistrar>* registrar;

@end

@implementation FlutterTencentplayerPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel methodChannelWithName:@"flutter_tencentplayer"
                                                              binaryMessenger:[registrar messenger]];
    
    
    
    FlutterTencentplayerPlugin* instance = [[FlutterTencentplayerPlugin alloc] initWithRegistrar: registrar];
    [registrar addMethodCallDelegate:instance channel:channel];
}

- (instancetype) initWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    self = [super init];
    NSAssert(self, @"super init cannot be nil");
    _registry = [registrar textures];
    _messenger = [registrar messenger];
    _registrar = registrar;
    _players = [NSMutableDictionary dictionaryWithCapacity:1];
    return self;
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  if ([@"init" isEqualToString:call.method]) {
      [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
      
      for (NSNumber* textureId in _players) {
          [_registry unregisterTexture:[textureId unsignedIntegerValue]];
//          [_players[textureId] dispose];
      }
      [_players removeAllObjects];
      
      result(nil);
  }
  else if ([@"create" isEqualToString:call.method]) {
      NSDictionary* argsMap = call.arguments;
      FLTFrameUpdater* frameUpdater = [[FLTFrameUpdater alloc] initWithRegistry: _registry];
      NSString* assetArg = argsMap[@"asset"];
      NSString* uriArg = argsMap[@"uri"];
      TencentPlayer* player;
      if (assetArg) {
          
      } else if (uriArg) {
          
      } else {
          result(FlutterMethodNotImplemented);
      }
      
  }
  else {
    result(FlutterMethodNotImplemented);
  }
}

@end
