//
//  FLTVideoPlayer.m
//  flutter_plugin_demo3
//
//  Created by Wei on 2019/5/15.
//

#import "FLTVideoPlayer.h"
#import <libkern/OSAtomic.h>



@implementation FLTVideoPlayer{
    CVPixelBufferRef finalPiexelBuffer;
}

- (instancetype)initWithCall:(FlutterMethodCall *)call frameUpdater:(FLTFrameUpdater *)frameUpdater registry:(NSObject<FlutterTextureRegistry> *)registry messenger:(NSObject<FlutterBinaryMessenger>*)messenger{
    self = [super init];
    
    _textureId = [registry registerTexture:self];
    FlutterEventChannel* eventChannel = [FlutterEventChannel
                                         eventChannelWithName:[NSString stringWithFormat:@"flutter_tencentplayer/videoEvents%lld",_textureId]
                                         binaryMessenger:messenger];
    
    [eventChannel setStreamHandler:self];
    
    _eventChannel = eventChannel;
    
    NSDictionary* argsMap = call.arguments;
    TXVodPlayConfig* playConfig = [[TXVodPlayConfig alloc]init];
    playConfig.connectRetryCount=  3 ;
    playConfig.connectRetryInterval = 3;
    playConfig.timeout = 10 ;
    
    //     mVodPlayer.setLoop((boolean) call.argument("loop"));
    
    
    id headers = argsMap[@"headers"];
    if (headers!=nil&&headers!=NULL&&![@"" isEqualToString:headers]&&headers!=[NSNull null]) {
        NSDictionary* headers =  argsMap[@"headers"];
        playConfig.headers = headers;
    }
    
    id cacheFolderPath = argsMap[@"cachePath"];
    if (cacheFolderPath!=nil&&cacheFolderPath!=NULL&&![@"" isEqualToString:cacheFolderPath]&&cacheFolderPath!=[NSNull null]) {
        playConfig.cacheFolderPath = cacheFolderPath;
    }else{
        // 设置缓存路径
        playConfig.cacheFolderPath =[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    }
    
    playConfig.maxCacheItems = 5;
    playConfig.progressInterval =  0.5; //[argsMap[@"progressInterval"] intValue] ;
    BOOL autoPlayArg = [argsMap[@"autoPlay"] boolValue];
    float startPosition=0;
    
    id startTime = argsMap[@"startTime"];
    if(startTime!=nil&&startTime!=NULL&&![@"" isEqualToString:startTime]&&startTime!=[NSNull null]){
        startPosition =[argsMap[@"startTime"] floatValue];
    }
    
    _frameUpdater = frameUpdater;
    
    _txPlayer = [[TXVodPlayer alloc]init];
    [playConfig setPlayerPixelFormatType:kCVPixelFormatType_32BGRA];
    [_txPlayer setConfig:playConfig];
    [_txPlayer setIsAutoPlay:autoPlayArg];
    _txPlayer.enableHWAcceleration = YES;
    [_txPlayer setVodDelegate:self];
    [_txPlayer setVideoProcessDelegate:self];
    [_txPlayer setStartTime:startPosition];
    
    id  pathArg = argsMap[@"uri"];
    if(pathArg!=nil&&pathArg!=NULL&&![@"" isEqualToString:pathArg]&&pathArg!=[NSNull null]){
        NSLog(@"播放器启动方式1  play");
        [_txPlayer startPlay:pathArg];
    }else{
        NSLog(@"播放器启动方式2  fileid");
        id auth = argsMap[@"auth"];
        if(auth!=nil&&auth!=NULL&&![@"" isEqualToString:auth]&&auth!=[NSNull null]){
            NSDictionary* authMap =  argsMap[@"auth"];
            int  appId= [authMap[@"appId"] intValue];
            NSString  *fileId= authMap[@"fileId"];
            TXPlayerAuthParams *p = [TXPlayerAuthParams new];
            p.appId = appId;
            p.fileId = fileId;
            [_txPlayer startPlayWithParams:p];
        }
    }
    NSLog(@"播放器初始化结束");
    
    return  self;
    
}


#pragma FlutterTexture
- (CVPixelBufferRef)copyPixelBuffer {
    if(finalPiexelBuffer!=nil){
        return  finalPiexelBuffer;
    }
    return NULL;
}

#pragma 腾讯播放器代理回调方法

/**
 * 视频渲染对象回调
 *
 */
- (CVPixelBufferRef)copyPixelBufferNow {
    if (_pixelBufferNowRef == NULL) {
        return nil;
    }
    
    CVPixelBufferRef pixelBufferOut = NULL;
    CVReturn ret = kCVReturnError;
    size_t height = CVPixelBufferGetHeight(_pixelBufferNowRef);
    size_t width = CVPixelBufferGetWidth(_pixelBufferNowRef);
    size_t bytersPerRow = CVPixelBufferGetBytesPerRow(_pixelBufferNowRef);
    CFDictionaryRef attrs = NULL;
    const void *keys[] = { kCVPixelBufferPixelFormatTypeKey };
    //      kCVPixelFormatType_420YpCbCr8Planar is YUV420
    //      kCVPixelFormatType_420YpCbCr8BiPlanarFullRange is NV12
    uint32_t v = kCVPixelFormatType_420YpCbCr8BiPlanarFullRange;
    const void *values[] = { CFNumberCreate(NULL, kCFNumberSInt32Type, &v) };
    attrs = CFDictionaryCreate(NULL, keys, values, 1, NULL, NULL);
    
    ret = CVPixelBufferCreate(NULL,
                              width,
                              height,
                              CVPixelBufferGetPixelFormatType(_pixelBufferNowRef),
                              attrs,
                              &pixelBufferOut);
    CVPixelBufferLockBaseAddress(_pixelBufferNowRef, kCVPixelBufferLock_ReadOnly);
    CVPixelBufferLockBaseAddress(pixelBufferOut, kCVPixelBufferLock_ReadOnly);
    CFRelease(attrs);
    if (ret == kCVReturnSuccess) {
        memcpy(CVPixelBufferGetBaseAddress(pixelBufferOut), CVPixelBufferGetBaseAddress(_pixelBufferNowRef), height * bytersPerRow);
    } else {
        printf("why copy pixlbuffer error %d",ret);
    }
    CVPixelBufferUnlockBaseAddress(_pixelBufferNowRef, kCVPixelBufferLock_ReadOnly);
    CVPixelBufferUnlockBaseAddress(pixelBufferOut, kCVPixelBufferLock_ReadOnly);
    [self processPixelBuffer:_pixelBufferNowRef];
    return pixelBufferOut;
}

- (void)processPixelBuffer: (CVImageBufferRef)pixelBuffer
{
    CVPixelBufferLockBaseAddress( pixelBuffer, 0 );

    //int bufferWidth = CVPixelBufferGetWidth(pixelBuffer);
    //int bufferHeight = CVPixelBufferGetHeight(pixelBuffer);
    long bufferWidth = CVPixelBufferGetWidth(pixelBuffer);
    long bufferHeight = CVPixelBufferGetHeight(pixelBuffer);
    unsigned char *pixel = (unsigned char *)CVPixelBufferGetBaseAddress(pixelBuffer);

    for( int row = 0; row < bufferHeight; row++ ) {
        for( int column = 0; column < bufferWidth; column++ ) {
            pixel[0] = 0;
            pixel[1] = 0;
            pixel[2] = 0;
            pixel[3] = 0;
            pixel += 4;
        }
    }
    CVPixelBufferUnlockBaseAddress( pixelBuffer, 0 );
}

- (BOOL)onPlayerPixelBuffer:(CVPixelBufferRef)pixelBuffer{
//    self.newPixelBuffer = pixelBuffer;
    _pixelBufferNowRef =pixelBuffer;
    finalPiexelBuffer =  [self copyPixelBufferNow];
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
        
        if(EvtID==PLAY_EVT_VOD_PLAY_PREPARED){
            if ([player isPlaying]) {
                
                int64_t duration = [player duration];
                NSString *durationStr = [NSString stringWithFormat: @"%ld", (long)duration];
                NSInteger  durationInt = [durationStr intValue];
                
                self->_eventSink(@{
                                   @"event":@"initialized",
                                   @"duration":@(durationInt),
                                   @"width":@([player width]),
                                   @"height":@([player height])
                                   });
            }
            
        }else if(EvtID==PLAY_EVT_PLAY_PROGRESS){
            if ([player isPlaying]) {
                int64_t progress = [player currentPlaybackTime];
                int64_t duration = [player duration];
                int64_t playableDuration  = [player playableDuration];
                
                
                NSString *progressStr = [NSString stringWithFormat: @"%ld", (long)progress];
                NSString *durationStr = [NSString stringWithFormat: @"%ld", (long)duration];
                NSString *playableDurationStr = [NSString stringWithFormat: @"%ld", (long)playableDuration];
                NSInteger  progressInt = [progressStr intValue]*1000;
                NSInteger  durationint = [durationStr intValue]*1000;
                NSInteger  playableDurationInt = [playableDurationStr intValue]*1000;
                //                NSLog(@"单精度浮点数： %d",progressInt);
                //                NSLog(@"单精度浮点数： %d",durationint);
                self->_eventSink(@{
                                   @"event":@"progress",
                                   @"progress":@(progressInt),
                                   @"duration":@(durationint),
                                   @"playable":@(playableDurationInt)
                                   });
                
            }
            
        }else if(EvtID==PLAY_EVT_PLAY_LOADING){
            self->_eventSink(@{
                               @"event":@"loading",
                               });
        }else if(EvtID==PLAY_EVT_VOD_LOADING_END){
            self->_eventSink(@{
                               @"event":@"loadingend",
                               });
        }else if(EvtID==PLAY_EVT_PLAY_END){
            self->_eventSink(@{
                               @"event":@"playend",
                               });
        }else if(EvtID==PLAY_ERR_NET_DISCONNECT){
            if(self->_eventSink!=nil){
                self->_eventSink(@{
                                   @"event":@"error",
                                   @"errorInfo":param[@"EVT_MSG"],
                                   });
                
                self->_eventSink(@{
                                   @"event":@"disconnect",
                                   });
                
            }
            
        }else if(EvtID==ERR_PLAY_LIVE_STREAM_NET_DISCONNECT){
            if(self->_eventSink!=nil){
                self->_eventSink(@{
                                   @"event":@"error",
                                   @"errorInfo":param[@"EVT_MSG"],
                                   });
            }
        }else if(EvtID==WARNING_LIVE_STREAM_SERVER_RECONNECT){
            if(self->_eventSink!=nil){
                self->_eventSink(@{
                                   @"event":@"error",
                                   @"errorInfo":param[@"EVT_MSG"],
                                   });
            }
        }else {
            if(EvtID<0){
                if(self->_eventSink!=nil){
                    self->_eventSink(@{
                                       @"event":@"error",
                                       @"errorInfo":param[@"EVT_MSG"],
                                       });
                }
            }
        }
        
    });
}

- (void)onNetStatus:(TXVodPlayer *)player withParam:(NSDictionary *)param {
    self->_eventSink(@{
                       @"event":@"netStatus",
                       @"netSpeed": param[NET_STATUS_NET_SPEED],
                       @"cacheSize": param[NET_STATUS_V_SUM_CACHE_SIZE],
                       });
    
    
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
    [_eventChannel setStreamHandler:nil];
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

@end
