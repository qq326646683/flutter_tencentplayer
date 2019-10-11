//
//  FLTDownLoadManager.h
//  flutter_tencentplayer
//
//  Created by wilson on 2019/8/16.
//

#import <Foundation/Foundation.h>
#import <Flutter/Flutter.h>
#import "TXLiteAVSDK.h"
NS_ASSUME_NONNULL_BEGIN

@interface FLTDownLoadManager : NSObject<FlutterStreamHandler,TXVodDownloadDelegate>


@property(nonatomic) FlutterEventSink eventSink;
@property(nonatomic) FlutterEventChannel* eventChannel;
@property(nonatomic) FlutterResult result;
@property(nonatomic) FlutterMethodCall* call;
@property(nonatomic) NSString* path;
@property(nonatomic) NSString* urlOrFileId;
@property(nonatomic) TXVodDownloadManager* tXVodDownloadManager;
@property(nonatomic) TXVodDownloadMediaInfo* tempMedia;

- (instancetype)initWithMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result;

//下载的方法
- (void)downLoad;
//停止下载的方法
- (void)stopDownLoad;

@end

NS_ASSUME_NONNULL_END
