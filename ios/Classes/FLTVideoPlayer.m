//
//  FLTVideoPlayer.m
//  flutter_plugin_demo3
//
//  Created by Wei on 2019/5/15.
//

#import "FLTVideoPlayer.h"
#import <libkern/OSAtomic.h>

@implementation FLTVideoPlayer

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
            
            self->_eventSink(@{
                               @"event":@"initialized",
                               @"duration":@([player duration]),
                                @"width":@([player width]),
                               @"height":@([player height])
                               });
        }else if(EvtID==PLAY_EVT_PLAY_PROGRESS){
            int64_t progress = [player currentPlaybackTime];
            int64_t duration = [player duration];
            self->_eventSink(@{
                               @"event":@"progress",
                                @"progress":@([player currentPlaybackTime]),
                               @"duration":@([player duration]),
                               @"playable":@([player playableDuration])
                               });
            
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
            self->_eventSink(@{
                               @"event":@"error",
                               @"errorInfo":@"EVT_MSG",
                               });
        }
        
        
//        if (EvtID==PLAY_EVT_RCV_FIRST_I_FRAME) {//渲染首个视频数据包(IDR)
//            self->_eventSink(@{
//                               @"event":@"PLAY_EVT_RCV_FIRST_I_FRAME",@"rawEvent":@(EvtID),}
//                             );
//        }
//        if (EvtID == PLAY_EVT_VOD_LOADING_END || EvtID == PLAY_EVT_VOD_PLAY_PREPARED) {//loading结束（点播）,视频加载完毕（点播）
//            self->_eventSink(@{@"event":@"PLAY_EVT_VOD_LOADING_END",@"rawEvent":@(EvtID),});
//        }
//        if (EvtID == PLAY_EVT_PLAY_BEGIN) {//视频播放开始
//            int64_t progress = [player currentPlaybackTime];
//            int64_t duration = [player duration];
//            self->_eventSink(@{@"event":@"PLAY_EVT_PLAY_BEGIN",
//                               @"rawEvent":@(EvtID),
//                               @"position":@(progress),
//                               @"duration":@(duration)
//                               });
//        }else if(EvtID == PLAY_EVT_PLAY_PROGRESS){//视频播放进度
//            if ([player isPlaying]) {
//                int64_t progress = [player currentPlaybackTime];
//                int64_t duration = [player duration];
//                self->_eventSink(@{@"event":@"PLAY_EVT_PLAY_PROGRESS",
//                                   @"rawEvent":@(EvtID),
//                                   @"position":@(progress),
//                                   @"duration":@(duration)
//                                   });
//            }
//        }else if (EvtID == PLAY_ERR_NET_DISCONNECT || EvtID == PLAY_EVT_PLAY_END || EvtID == PLAY_ERR_FILE_NOT_FOUND || EvtID == PLAY_ERR_HLS_KEY || EvtID == PLAY_ERR_GET_PLAYINFO_FAIL) {//网络断连,且经多次重连抢救无效,可以放弃治疗,更多重试请自行重启播放;视频播放结束;播放文件不存在;HLS解码key获取失败;获取点播文件信息失败
//            self->_eventSink(@{@"event":@"PLAY_EVT_PLAY_END",@"rawEvent":@(EvtID),});
//        }
//        else if (EvtID == PLAY_EVT_PLAY_LOADING){//视频播放loading
//            self->_eventSink(@{@"event":@"PLAY_EVT_PLAY_LOADING",@"rawEvent":@(EvtID),});
//        }
//        else if (EvtID == PLAY_EVT_CONNECT_SUCC) {//已经连接服务器
//            self->_eventSink(@{@"event":@"PLAY_EVT_CONNECT_SUCC",@"rawEvent":@(EvtID),});
//        }
//
        
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
    return nil;
}

- (FlutterError* _Nullable)onListenWithArguments:(id _Nullable)arguments
                                       eventSink:(nonnull FlutterEventSink)events {
    _eventSink = events;
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

- (void)setMirror:(BOOL)isMirror{
    [_txPlayer setMirror:isMirror];
}

-(void)snapshot:(void (^)(UIImage * _Nonnull))snapshotCompletionBlock{
    
}



@end
