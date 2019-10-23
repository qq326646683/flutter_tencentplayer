//
//  FLTVideoPlayer.h
//  flutter_plugin_demo3
//
//  Created by Wei on 2019/5/15.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <GLKit/GLKit.h>
#import "FLTFrameUpdater.h"
#import "TXLiteAVSDK.h"
#import <Flutter/Flutter.h>
NS_ASSUME_NONNULL_BEGIN

@interface FLTVideoPlayer : NSObject<FlutterTexture, FlutterStreamHandler,TXVideoCustomProcessDelegate,TXVodPlayListener>
@property(readonly,nonatomic) TXVodPlayer* txPlayer;
@property(nonatomic) FlutterEventChannel* eventChannel;

//ios主动和flutter通信
@property(nonatomic) FlutterEventSink eventSink;
@property(nonatomic, readonly) bool disposed;
@property(nonatomic, readonly) int64_t textureId;

/**
 * 是否循环播放
 */
@property (nonatomic, assign) BOOL loop;
@property(nonatomic)FLTFrameUpdater* frameUpdater;

- (instancetype)initWithCall:(FlutterMethodCall*)call
                frameUpdater:(FLTFrameUpdater*)frameUpdater
                    registry:(NSObject<FlutterTextureRegistry>*)registry
                   messenger:(NSObject<FlutterBinaryMessenger>*)messenger;
- (void)dispose;
-(void)resume;
-(void)pause;
-(int64_t)position;
-(int64_t)duration;
-(void)seekTo:(int)position;
/**
 * 设置播放开始时间
 * 在startPlay前设置，修改开始播放的起始位置
 */
- (void)setStartTime:(CGFloat)startTime;

/**
 * 停止播放音视频流
 * @return 0 = OK
 */
- (int)stopPlay;
/**
 * 可播放时长
 */
- (float)playableDuration;
/**
 * 视频宽度
 */
- (int)width;

/**
 * 视频高度
 */
- (int)height;
/**
 * 设置画面的方向
 * @param rotation 方向
 * @see TX_Enum_Type_HomeOrientation
 */
- (void)setRenderRotation:(TX_Enum_Type_HomeOrientation)rotation;
/**
 * 设置画面的裁剪模式
 * @param renderMode 裁剪
 * @see TX_Enum_Type_RenderMode
 */
- (void)setRenderMode:(TX_Enum_Type_RenderMode)renderMode;
/**
 * 设置静音
 */
- (void)setMute:(BOOL)bEnable;

/*
 * 截屏
 * @param snapshotCompletionBlock 通过回调返回当前图像
 */
- (void)snapshot:(void (^)(UIImage *))snapshotCompletionBlock;
/**
 * 设置播放速率
 * @param rate 正常速度为1.0；小于为慢速；大于为快速。最大建议不超过2.0
 */
- (void)setRate:(float)rate;
// 设置播放清晰度
- (void)setBitrateIndex:(int)index;
/**
 * 设置画面镜像
 */
- (void)setMirror:(BOOL)isMirror;

@end

NS_ASSUME_NONNULL_END
