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
- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([@"init" isEqualToString:call.method]) {
        NSLog(@"init");
        [self disposeAllPlayers];
        result(nil);
    }else if([@"create" isEqualToString:call.method]){
        NSLog(@"create");
        
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
        playConfig.connectRetryCount=  3 ;
        playConfig.connectRetryInterval = 3;
        playConfig.timeout = 10 ;//[argsMap[@"progressInterval"] intValue] ;
        
        id cacheFolderPath = argsMap[@"cachePath"];
        if (cacheFolderPath!=nil&&cacheFolderPath!=NULL&&![@"" isEqualToString:cacheFolderPath]&&cacheFolderPath!=[NSNull null]) {
            playConfig.cacheFolderPath = cacheFolderPath;
        }
      
        playConfig.maxCacheItems = 1;
        playConfig.progressInterval = 0.5;
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
    
    NSDictionary* argsMap = call.arguments;
    int64_t textureId = ((NSNumber*)argsMap[@"textureId"]).unsignedIntegerValue;
    FLTVideoPlayer* player = _players[@(textureId)];
    
    
    if([@"play" isEqualToString:call.method]){
        [player resume];
        result(nil);
    }else if([@"pause" isEqualToString:call.method]){
        [player pause];
        result(nil);
    }else if([@"seekTo" isEqualToString:call.method]){
        NSLog(@"跳转到指定位置");
        [player seekTo:[[argsMap objectForKey:@"position"] intValue]];
        result(nil);
    }else if([@"setRate" isEqualToString:call.method]){ //播放速率
        NSLog(@"修改播放速率");
        float rate = [[argsMap objectForKey:@"rate"] floatValue];
        if (rate<0||rate>2) {
            result(nil);
            return;
        }
        [player setRate:rate];
        result(nil);
        
    }else if([@"setBitrateIndex" isEqualToString:call.method]){
        
        NSLog(@"修改播放清晰度");
        int  index = [[argsMap objectForKey:@"index"] intValue];
        [player setBitrateIndex:index];
    }else if([@"dispose" isEqualToString:call.method]){
        [_registry unregisterTexture:textureId];
        [_players removeObjectForKey:@(textureId)];
        [player dispose];
        result(nil);
    }else{
        result(FlutterMethodNotImplemented);
    }
    
}

- (void)onPlayerSetup:(FLTVideoPlayer*)player
         frameUpdater:(FLTFrameUpdater*)frameUpdater
               result:(FlutterResult)result {
    
    int64_t textureId = [_registry registerTexture:player];
    frameUpdater.textureId = textureId;

    FlutterEventChannel* eventChannel = [FlutterEventChannel
                                         eventChannelWithName:[NSString stringWithFormat:@"flutter_tencentplayer/videoEvents%lld",
                                                               textureId]
                                         binaryMessenger:_messenger];
    
    [eventChannel setStreamHandler:player];
  
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
