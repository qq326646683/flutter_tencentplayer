//
//  FLTVideoPlayer.m
//  flutter_plugin_demo3
//
//  Created by Wei on 2019/5/15.
//

#import "FLTVideoPlayer.h"
#import <libkern/OSAtomic.h>

@implementation FLTVideoPlayer



// 初始化播放器方式2
- (instancetype)initWithCall:(FlutterMethodCall *)call frameUpdater:(FLTFrameUpdater *)frameUpdater{
    self = [super init];
    NSLog(@"create---------------");
    NSDictionary* argsMap = call.arguments;
    NSLog(@"%@",argsMap);
   
    TXVodPlayConfig* playConfig = [[TXVodPlayConfig alloc]init];
    playConfig.connectRetryCount=  3 ;
    playConfig.connectRetryInterval = 3;
    playConfig.timeout = 10 ;
    
//     mVodPlayer.setLoop((boolean) call.argument("loop"));
    

    id headers = argsMap[@"headers"];
    if (headers!=nil&&headers!=NULL&&![@"" isEqualToString:headers]&&headers!=[NSNull null]) {
        playConfig.headers = headers;
    }
   
    id cacheFolderPath = argsMap[@"cachePath"];
    if (cacheFolderPath!=nil&&cacheFolderPath!=NULL&&![@"" isEqualToString:cacheFolderPath]&&cacheFolderPath!=[NSNull null]) {
        playConfig.cacheFolderPath = cacheFolderPath;
    }
    
    playConfig.maxCacheItems = 1;
    playConfig.progressInterval =[argsMap[@"progressInterval"] intValue] ;
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
        NSLog(@"播放器启动  play");
        [_txPlayer startPlay:pathArg];
    }else{
        NSLog(@"播放器启动  fileid");
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
    return self;
}

//初始化播放器方式1
- (instancetype)initWithPath:(NSString*)path autoPlay:(bool)autoPlay startPosition:(int)position playConfig:(TXVodPlayConfig*)playConfig frameUpdater:(FLTFrameUpdater*)frameUpdater {
    self = [super init];
    NSLog(@"初始化播放器");
    _frameUpdater = frameUpdater;
    _txPlayer = [[TXVodPlayer alloc]init];
    [playConfig setPlayerPixelFormatType:kCVPixelFormatType_32BGRA];
    [_txPlayer setConfig:playConfig];
    [_txPlayer setIsAutoPlay:autoPlay];
    _txPlayer.enableHWAcceleration = YES;
    [_txPlayer setVodDelegate:self];
    [_txPlayer setVideoProcessDelegate:self];
    [_txPlayer setStartTime:position];
    int result = [_txPlayer startPlay:path];
    if (result!=0) {
        NSLog(@"播放器启动失败");
        return nil;
    }
    NSLog(@"播放器初始化结束");
    return self;
}



#pragma FlutterTexture
- (CVPixelBufferRef)copyPixelBuffer {
    if(self.newPixelBuffer!=nil){
        //出现过的异常：Signal 11 was raised, 原因：使用被释放掉的对象,注意内存问题
        //ijk解决问题如下：弄不清楚原理
        CVPixelBufferRetain(self.newPixelBuffer);
        CVPixelBufferRef pixelBuffer = self.lastestPixelBuffer;
        while (!OSAtomicCompareAndSwapPtrBarrier(pixelBuffer, self.newPixelBuffer, (void **) &_lastestPixelBuffer)) {
            NSLog(@"OSAtomicCompareAndSwapPtrBarrier");
            pixelBuffer = self.lastestPixelBuffer;
        }
        return pixelBuffer;
    }
    return NULL;
}

#pragma 腾讯播放器代理回调方法

/**
 视频渲染对象回调
 @param pixelBuffer 渲染图像，此为C引用，注意内存管理问题
 @return 返回YES则SDK不再显示；返回NO则SDK渲染模块继续渲染
 说明：渲染图像的数据类型为config中设置的renderPixelFormatType
 出现过的异常：Signal 11 was raised, 原因：使用被释放掉的对象
 */
- (BOOL)onPlayerPixelBuffer:(CVPixelBufferRef)pixelBuffer{
    self.newPixelBuffer = pixelBuffer;
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
                NSInteger  progressInt = [progressStr intValue];
                NSInteger  durationint = [durationStr intValue];
                NSInteger  playableDurationInt = [playableDurationStr intValue];
                //                NSLog(@"单精度浮点数： %d",progressInt);
                //                NSLog(@"单精度浮点数： %d",durationint);
                self->_eventSink(@{
                                   @"event":@"progress",
                                   @"progress":@(progressInt),
                                   @"duration":@(durationint),
                                   @"playable":@(playableDurationInt)
                                   });
                
                //                self->_eventSink(@{
                //                                   @"event":@"progress",
                //                                   @"progress":@0,
                //                                   @"duration":@0,
                //                                   @"playable":@0,
                //                                   });
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
            //TODO 停止播放操作
            
            self->_eventSink(@{
                               @"event":@"disconnect",
                               });
            
            
        }else {
            
            if(self->_eventSink!=nil){
                self->_eventSink(@{
                                   @"event":@"error",
                                   @"errorInfo":@"EVT_MSG",
                                   });
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

-(void)setLoop:(bool)loop{
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
