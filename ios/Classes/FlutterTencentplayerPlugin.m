#import "FlutterTencentplayerPlugin.h"

#import "FLTVideoPlayer.h"
#import "FLTFrameUpdater.h"


@interface FlutterTencentplayerPlugin ()

@property(readonly, nonatomic) NSObject<FlutterTextureRegistry>* registry;
@property(readonly, nonatomic) NSObject<FlutterBinaryMessenger>* messenger;
@property(readonly, nonatomic) NSMutableDictionary* players;
@property(readonly, nonatomic) NSObject<FlutterPluginRegistrar>* registrar;

@end

@implementation FlutterTencentplayerPlugin

NSObject<FlutterPluginRegistrar>* mRegistrar;


- (instancetype)initWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    self = [super init];
    NSAssert(self, @"super init cannot be nil");
    _registry = [registrar textures];
    _messenger = [registrar messenger];
    _registrar = registrar;
    _players = [NSMutableDictionary dictionaryWithCapacity:1];
    return self;
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel
                                     methodChannelWithName:@"flutter_tencentplayer"
                                     binaryMessenger:[registrar messenger]];
//    FlutterTencentplayerPlugin* instance = [[FlutterTencentplayerPlugin alloc] init];
   FlutterTencentplayerPlugin* instance = [[FlutterTencentplayerPlugin alloc] initWithRegistrar:registrar];
    
    [registrar addMethodCallDelegate:instance channel:channel];

   
}
    
- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([@"init" isEqualToString:call.method]) {
        NSLog(@"init");
        [self disposeAllPlayers];
        result(nil);
    }else if([@"create" isEqualToString:call.method]){
        NSLog(@"create");
        //        {
        //            auth = "<null>";
        //            autoPlay = 1;
        //            cachePath = "<null>";
        //            headers = "<null>";
        //            loop = 0;
        //            progressInterval = 200;
        //            startTime = "<null>";
        //            uri = "http://1252463788.vod2.myqcloud.com/95576ef5vodtransgzp1252463788/e1ab85305285890781763144364/v.f30.mp4";
        //        }
        NSDictionary* argsMap = call.arguments;
        NSLog(@"%@",argsMap);
        FLTFrameUpdater* frameUpdater = [[FLTFrameUpdater alloc] initWithRegistry:_registry];
    
        NSString* pathArg = argsMap[@"uri"];
//        NSDictionary* playConfigArg = argsMap[@"playerConfig"];
//        int connectRetryCount = [playConfigArg[@"connectRetryCount"] intValue];
//        int connectRetryInterval = [playConfigArg[@"connectRetryInterval"] intValue];
//        int timeout = [playConfigArg[@"timeout"] intValue];
//        id cacheFolderPath = playConfigArg[@"cacheFolderPath"];
//        int maxCacheItems = [playConfigArg[@"maxCacheItems"] intValue];
//        float progressInterval = [playConfigArg[@"progressInterval"] floatValue];
//
        TXVodPlayConfig* playConfig = [[TXVodPlayConfig alloc]init];
        playConfig.connectRetryCount=  1 ;
        playConfig.connectRetryInterval = 3;
        playConfig.timeout = 200 ;//[argsMap[@"progressInterval"] intValue] ;
        
        id cacheFolderPath = argsMap[@"cachePath"];
        if (cacheFolderPath!=nil&&cacheFolderPath!=NULL&&![@"" isEqualToString:cacheFolderPath]&&cacheFolderPath!=[NSNull null]) {
            playConfig.cacheFolderPath = cacheFolderPath;
        }
      
        playConfig.maxCacheItems = 1;
        playConfig.progressInterval = 200;
        BOOL autoPlayArg = [argsMap[@"autoPlay"] boolValue];
    
        int startPosition = 0;//[argsMap[@"startPosition"] intValue];
        FLTVideoPlayer* player;
        if (pathArg) {
            player = [[FLTVideoPlayer alloc] initWithPath:pathArg autoPlay:autoPlayArg startPosition:startPosition playConfig:playConfig frameUpdater:frameUpdater];
            if (player) {
                [self onPlayerSetup:player frameUpdater:frameUpdater result:result];
            }
            result(nil);
        } else {
            result(FlutterMethodNotImplemented);
        }
    }else if([@"download" isEqualToString:call.method]){
         NSLog(@"download");
    }else if([@"stopDownload" isEqualToString:call.method]){
         NSLog(@"stopDownload");
    }else {
       //TODO 获取对应的播放器进行操作
        [self onMethodCall:call result:result];
     
        
    }
}

-(void) onMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result{
    if([@"play" isEqualToString:call.method]){
        
    }else if([@"pause" isEqualToString:call.method]){
        
    }else if([@"seekTo" isEqualToString:call.method]){
        
    }else if([@"setRate" isEqualToString:call.method]){
        
    }else if([@"setBitrateIndex" isEqualToString:call.method]){
        
    }else if([@"dispose" isEqualToString:call.method]){
        
    }else{
        result(FlutterMethodNotImplemented);
    }
    
}

- (void)onPlayerSetup:(FLTVideoPlayer*)player
         frameUpdater:(FLTFrameUpdater*)frameUpdater
               result:(FlutterResult)result {
    
    int64_t textureId = [_registry registerTexture:player];
    frameUpdater.textureId = textureId;
    
    
//    NSString * eventStr=@"flutter_tencentplayer/videoEvents";
//    NSString *  textureIdStr =  [NSString stringWithFormat:@"%lld",textureId];
//
//    NSString *eventName = [NSString stringWithFormat:@"%@%@", eventStr, textureIdStr];

//    FlutterEventChannel* eventChannel = [FlutterEventChannel
//                                         eventChannelWithName:@"flutter_tencentplayer/videoEvents"
//                                         binaryMessenger:_messenger];
    
    FlutterEventChannel* eventChannel = [FlutterEventChannel
                                         eventChannelWithName:[NSString stringWithFormat:@"flutter_tencentplayer/videoEvents%lld",
                                                               textureId]
                                         binaryMessenger:_messenger];
    
    
    [eventChannel setStreamHandler:player];
    NSLog(@"发送  视频数据  ");
    player.eventChannel = eventChannel;
    
    _players[@(textureId)] = player;
    result(@{@"textureId" : @(textureId)});
    
}




-(void) disposeAllPlayers{
      NSLog(@"初始化状态");
    // Allow audio playback when the Ring/Silent switch is set to silent
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    
    for (NSNumber* textureId in _players) {
        [_registry unregisterTexture:[textureId unsignedIntegerValue]];
        [[_players objectForKey:textureId] dispose];
    }
    [_players removeAllObjects];
}
    
@end
