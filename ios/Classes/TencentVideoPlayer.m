

#import "TencentVideoPlayer.h"
#import <libkern/OSAtomic.h>



@implementation TencentVideoPlayer{
//    CVPixelBufferRef finalPiexelBuffer;
//    CVPixelBufferRef pixelBufferNowRef;
    CVPixelBufferRef volatile _latestPixelBuffer;
    CVPixelBufferRef _lastBuffer;
    //视频自带角度
    NSNumber* _degree;
}

- (instancetype)initWithCall:(FlutterMethodCall *)call frameUpdater:(TencentFrameUpdater *)frameUpdater registry:(NSObject<FlutterTextureRegistry> *)registry messenger:(NSObject<FlutterBinaryMessenger>*)messenger{
    self = [super init];
    _latestPixelBuffer = nil;
     _lastBuffer = nil;
    // NSLog(@"FLTVideo  初始化播放器");
    _textureId = [registry registerTexture:self];
    // NSLog(@"FLTVideo  _textureId %lld",_textureId);
    
    FlutterEventChannel* eventChannel = [FlutterEventChannel
                                         eventChannelWithName:[NSString stringWithFormat:@"flutter_tencentplayer/videoEvents%lld",_textureId]
                                         binaryMessenger:messenger];
    
   
    
    _eventChannel = eventChannel;
    [_eventChannel setStreamHandler:self];
    NSDictionary* argsMap = call.arguments;
    TXVodPlayConfig* playConfig = [[TXVodPlayConfig alloc]init];
    playConfig.connectRetryCount=  3 ;
    playConfig.connectRetryInterval = 3;
    playConfig.timeout = 10 ;
    
    
    
    id headers = argsMap[@"headers"];
    if (headers!=nil&&headers!=NULL&&![@"" isEqualToString:headers]&&headers!=[NSNull null]) {
        NSDictionary* headers =  argsMap[@"headers"];
        playConfig.headers = headers;
    }
    
    id cacheFolderPath = argsMap[@"cachePath"];
    if (cacheFolderPath!=nil&&cacheFolderPath!=NULL&&![@"" isEqualToString:cacheFolderPath]&&cacheFolderPath!=[NSNull null]) {
        playConfig.cacheFolderPath = cacheFolderPath;
        playConfig.maxCacheItems = 2;
    }else{
        // 设置缓存路径
        //playConfig.cacheFolderPath =[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        playConfig.maxCacheItems = 0;
    }
    playConfig.maxBufferSize=4;
    
    playConfig.progressInterval =  1;
    id pi = argsMap[@"progressInterval"];
    if (pi!=nil) {
        playConfig.progressInterval = [pi intValue];
    }
    
    BOOL autoPlayArg = [argsMap[@"autoPlay"] boolValue];
    float startPosition=0;
    
    id startTime = argsMap[@"startTime"];
    if(startTime!=nil&&startTime!=NULL&&![@"" isEqualToString:startTime]&&startTime!=[NSNull null]){
        startPosition =[argsMap[@"startTime"] floatValue];
    }
    
    frameUpdater.textureId = _textureId;
    _frameUpdater = frameUpdater;
    
    _txPlayer = [[TXVodPlayer alloc]init];
    [playConfig setPlayerPixelFormatType:kCVPixelFormatType_32BGRA];
    [_txPlayer setConfig:playConfig];
    [_txPlayer setIsAutoPlay:autoPlayArg];
    _txPlayer.enableHWAcceleration = YES;
    [_txPlayer setVodDelegate:self];
    [_txPlayer setVideoProcessDelegate:self];
    [_txPlayer setStartTime:startPosition];
    
    BOOL loop =  [argsMap[@"loop"] boolValue];
    [_txPlayer setLoop: loop];
  
    id  pathArg = argsMap[@"uri"];
    if(pathArg!=nil&&pathArg!=NULL&&![@"" isEqualToString:pathArg]&&pathArg!=[NSNull null]){
        NSLog(@"播放器启动方式1  play");
        _degree = [NSNumber numberWithInteger:[self degressFromVideoFileWithURL: pathArg]];
        [_txPlayer startPlay:pathArg];
    }else{
        NSLog(@"播放器启动方式2  fileid");
        id auth = argsMap[@"auth"];
        if(auth!=nil&&auth!=NULL&&![@"" isEqualToString:auth]&&auth!=[NSNull null]){
            NSDictionary* authMap =  argsMap[@"auth"];
            int  appId= [authMap[@"appId"] intValue];
            NSString  *fileId= authMap[@"fileId"];
            NSString  *sign= authMap[@"sign"];
            TXPlayerAuthParams *p = [TXPlayerAuthParams new];
            p.appId = appId;
            p.fileId = fileId;
            if (sign != nil) {
                p.sign = sign;
            }
            [_txPlayer startPlayWithParams:p];
        }
    }
    NSLog(@"播放器初始化结束");
    
 
    return  self;
    
}


#pragma FlutterTexture
- (CVPixelBufferRef)copyPixelBuffer {
    CVPixelBufferRef pixelBuffer = _latestPixelBuffer;
       while (!OSAtomicCompareAndSwapPtrBarrier(pixelBuffer, nil,
                                                (void **)&_latestPixelBuffer)) {
           pixelBuffer = _latestPixelBuffer;
       }
       return pixelBuffer;
}

#pragma 腾讯播放器代理回调方法
- (BOOL)onPlayerPixelBuffer:(CVPixelBufferRef)pixelBuffer{
    
    if (_lastBuffer == nil) {
        _lastBuffer = CVPixelBufferRetain(pixelBuffer);
        CFRetain(pixelBuffer);
    } else if (_lastBuffer != pixelBuffer) {
        CVPixelBufferRelease(_lastBuffer);
        _lastBuffer = CVPixelBufferRetain(pixelBuffer);
        CFRetain(pixelBuffer);
    }

    CVPixelBufferRef newBuffer = pixelBuffer;

    CVPixelBufferRef old = _latestPixelBuffer;
    while (!OSAtomicCompareAndSwapPtrBarrier(old, newBuffer,
                                             (void **)&_latestPixelBuffer)) {
        old = _latestPixelBuffer;
    }

    if (old && old != pixelBuffer) {
        CFRelease(old);
    }
    [self.frameUpdater refreshDisplay];
    return NO;
}

/**
 * 点播事件通知
 *
 * @param player 点播对象
 * @param EvtID 参见TXLiveSDKEventDef.h
 * @param param 参见TXLiveSDKTypeDef.h
 * @see TXVodPlayer
 */
-(void)onPlayEvent:(TXVodPlayer *)player event:(int)EvtID withParam:(NSDictionary *)param{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSMutableDictionary* playEventDic = [NSMutableDictionary dictionary];
        [playEventDic setValue:@(EvtID) forKey:@"eventCode"];
        
        switch (EvtID) {
            case PLAY_EVT_VOD_PLAY_PREPARED: {
                int64_t duration = [player duration];
                NSString *durationStr = [NSString stringWithFormat: @"%ld", (long)duration];
                NSInteger  durationInt = [durationStr intValue];
                
                BOOL isRotateAttri = [self ->_degree intValue] == 90 || [self ->_degree intValue] == 270;
                
                int width = isRotateAttri ? [player height] : [player width];
                int height = isRotateAttri ? [player width] : [player height];
                

                [playEventDic setValue:@"initialized" forKey:@"event"];
                [playEventDic setValue:@(durationInt) forKey:@"duration"];
                [playEventDic setValue:@(width) forKey:@"width"];
                [playEventDic setValue:@(height) forKey:@"height"];

                if (self->_degree != nil) {
                    [playEventDic setValue:@([self->_degree integerValue]) forKey:@"degree"];
                }
                break;
            }
                
            case PLAY_EVT_PLAY_PROGRESS: {
                int64_t progress = [player currentPlaybackTime];
                int64_t duration = [player duration];
                int64_t playableDuration  = [player playableDuration];
                
                
                NSString *progressStr = [NSString stringWithFormat: @"%ld", (long)progress];
                NSString *durationStr = [NSString stringWithFormat: @"%ld", (long)duration];
                NSString *playableDurationStr = [NSString stringWithFormat: @"%ld", (long)playableDuration];
                NSInteger  progressInt = [progressStr intValue]*1000;
                NSInteger  durationInt = [durationStr intValue]*1000;
                NSInteger  playableDurationInt = [playableDurationStr intValue]*1000;
            
                [playEventDic setValue:@"progress" forKey:@"event"];
                [playEventDic setValue:@(progressInt) forKey:@"progress"];
                [playEventDic setValue:@(durationInt) forKey:@"duration"];
                [playEventDic setValue:@(playableDurationInt) forKey:@"playable"];
                break;
            }
            case PLAY_EVT_PLAY_LOADING:
                [playEventDic setValue:@"loading" forKey:@"event"];
                break;
            case PLAY_EVT_VOD_LOADING_END:
                [playEventDic setValue:@"loadingend" forKey:@"event"];
                break;
            case PLAY_EVT_PLAY_END:
                [playEventDic setValue:@"playend" forKey:@"event"];
                break;

            default:
                break;
        }
        
        if (EvtID < 0) {
            [playEventDic setValue:@"error" forKey:@"event"];
            [playEventDic setValue:param[@"EVT_MSG"] forKey:@"errorInfo"];
        }
        
        if (self->_eventSink != nil) {
            self->_eventSink(playEventDic);
        }
        
    });
}

- (void)onNetStatus:(TXVodPlayer *)player withParam:(NSDictionary *)param {
    if(self->_eventSink!=nil){
        self->_eventSink(@{
            @"event":@"netStatus",
            @"netSpeed": param[NET_STATUS_NET_SPEED],
            @"fps": param[NET_STATUS_VIDEO_FPS],
        });
    }
}

#pragma FlutterStreamHandler
- (FlutterError* _Nullable)onCancelWithArguments:(id _Nullable)arguments {
    _eventSink = nil;
    NSLog(@"FLTVideo停止通信");
    return nil;
}

- (FlutterError* _Nullable)onListenWithArguments:(id _Nullable)arguments
                                       eventSink:(nonnull FlutterEventSink)events {
    _eventSink = events;
    
    NSLog(@"FLTVideo开启通信");
    //[self sendInitialized];
    return nil;
}

- (void)dispose {
    _disposed = true;
    [self stopPlay];
    _txPlayer = nil;
    _frameUpdater = nil;
     NSLog(@"FLTVideo  dispose");
    CVPixelBufferRef old = _latestPixelBuffer;
       while (!OSAtomicCompareAndSwapPtrBarrier(old, nil,
                                                (void **)&_latestPixelBuffer)) {
           old = _latestPixelBuffer;
       }
       if (old) {
           CFRelease(old);
       }

       if (_lastBuffer) {
           CVPixelBufferRelease(_lastBuffer);
           _lastBuffer = nil;
       }
    
//    if(_eventChannel){
//        [_eventChannel setStreamHandler:nil];
//        _eventChannel =nil;
//    }
    
}

-(void)setLoop:(BOOL)loop{
    [_txPlayer setLoop:loop];
    _loop = loop;
}

- (void)resume{
    [_txPlayer resume];
}
-(void)pause{
    [_txPlayer pause];
}
- (int64_t)position{
    return [_txPlayer currentPlaybackTime];
}

- (int64_t)duration{
    return [_txPlayer duration];
}

- (void)seekTo:(int)position{
    [_txPlayer seek:position];
}

- (void)setStartTime:(CGFloat)startTime{
    [_txPlayer setStartTime:startTime];
}

- (int)stopPlay{
    return [_txPlayer stopPlay];
}

- (float)playableDuration{
    return [_txPlayer playableDuration];
}

- (int)width{
    return [_txPlayer width];
}

- (int)height{
    return [_txPlayer height];
}

- (void)setRenderMode:(TX_Enum_Type_RenderMode)renderMode{
    [_txPlayer setRenderMode:renderMode];
}

- (void)setRenderRotation:(TX_Enum_Type_HomeOrientation)rotation{
    
    [_txPlayer setRenderRotation:rotation];
}

- (void)setMute:(BOOL)bEnable{
    [_txPlayer setMute:bEnable];
}




- (void)setRate:(float)rate{
    [_txPlayer setRate:rate];
}

- (void)setBitrateIndex:(int)index{
    [_txPlayer setBitrateIndex:index];
}

- (void)setMirror:(BOOL)isMirror{
    [_txPlayer setMirror:isMirror];
}

-(void)snapshot:(void (^)(UIImage * _Nonnull))snapshotCompletionBlock{
    
}

- (NSUInteger)degressFromVideoFileWithURL:(NSString *)path
{
    NSUInteger degress = 0;
    
    NSArray *tracks;
    if ([path hasPrefix: @"http"]) {
        AVAsset *asset = [AVAsset assetWithURL:[NSURL URLWithString: path]];
        tracks = [asset tracksWithMediaType:AVMediaTypeVideo];
    } else {
        AVURLAsset* videoAsset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath: path] options:nil];
        tracks = [videoAsset tracksWithMediaType:AVMediaTypeVideo];
    }
    if([tracks count] > 0) {
        AVAssetTrack *videoTrack = [tracks objectAtIndex:0];
        CGAffineTransform t = videoTrack.preferredTransform;
       
        if(t.a == 0 && t.b == 1.0 && t.c == -1.0 && t.d == 0){
            // Portrait
            degress = 90;
        }else if(t.a == 0 && t.b == -1.0 && t.c == 1.0 && t.d == 0){
            // PortraitUpsideDown
            degress = 270;
        }else if(t.a == 1.0 && t.b == 0 && t.c == 0 && t.d == 1.0){
            // LandscapeRight
            degress = 0;
        }else if(t.a == -1.0 && t.b == 0 && t.c == 0 && t.d == -1.0){
            // LandscapeLeft
            degress = 180;
        }
    }
   
    return degress;
}
@end
