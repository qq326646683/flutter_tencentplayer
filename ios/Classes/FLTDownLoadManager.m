//
//  FLTDownLoadManager.m
//  flutter_tencentplayer
//
//  Created by wilson on 2019/8/16.
//

#import "FLTDownLoadManager.h"

@implementation FLTDownLoadManager


- (instancetype)initWithMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result{
    _call = call;
    _result = result;
 
//    [_eventChannel setStreamHandler:self];
    NSDictionary* argsMap = _call.arguments;
    _path = argsMap[@"savePath"];
    _urlOrFileId = argsMap[@"urlOrFileId"];
    if (_tXVodDownloadManager == nil) {
        _tXVodDownloadManager = [TXVodDownloadManager shareInstance];
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,  NSUserDomainMask, YES);
        NSString *docPath = [paths lastObject];
        NSString *downloadPath = [docPath stringByAppendingString:@"/downloader" ];
        NSLog(downloadPath);
        [_tXVodDownloadManager setDownloadPath:downloadPath];
//        [_tXVodDownloadManager setDownloadPath: [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingString:@"/downloader"]];
    }
    _tXVodDownloadManager.delegate = self;
    return  self;
}
//
////初始化
//- (instancetype)initWithMethodCall:(NSString *)path mEventSink:(FlutterEventSink)mEventSink result:(FlutterResult)result {
//    _eventSink =mEventSink;
//
//    //初始化下载对象
//    _tXVodDownloadManager =[TXVodDownloadManager shareInstance];
//    _tXVodDownloadManager.delegate = self;
//    _result = result;
//    _call =call;
//
//    NSDictionary* argsMap = _call.arguments;
//    _path = argsMap[@"savePath"];
//    _urlOrFileId = argsMap[@"urlOrFileId"];
//    return  self;
//}


//开始下载
- (void)downLoad{
    //设置下载对象
    
    NSLog(@"开始下载");
 
    
    if([_urlOrFileId hasPrefix: @"http"]){
        [_tXVodDownloadManager startDownloadUrl:_urlOrFileId];
        
    }else{
        
        NSDictionary* argsMap = _call.arguments;
        int appId = [argsMap[@"appId"] intValue];
        int quanlity = [argsMap[@"quanlity"] intValue];
        _urlOrFileId = argsMap[@"urlOrFileId"];
        TXPlayerAuthParams *auth = [TXPlayerAuthParams new];
        auth.appId =appId;
        auth.fileId = _urlOrFileId;
        TXVodDownloadDataSource *dataSource = [TXVodDownloadDataSource new];
        dataSource.auth = auth;
        dataSource.quality = quanlity;
        [_tXVodDownloadManager startDownload:dataSource];
    }
    
}


//停止下载
- (void)stopDownLoad{
    NSLog(@"停止下载");
    [_tXVodDownloadManager startDownloadUrl:_urlOrFileId];
}

// ---------------通信相关
- (FlutterError * _Nullable)onCancelWithArguments:(id _Nullable)arguments {
    _eventSink = nil;
    
    NSLog(@"FLTDownLoadManager停止通信");
    return nil;
}

- (FlutterError * _Nullable)onListenWithArguments:(id _Nullable)arguments eventSink:(nonnull FlutterEventSink)events {
    _eventSink = events;
      NSLog(@"FLTDownLoadManager设置全局通信");
    return nil;
}



//----------------下载回调相关

- (void)onDownloadStart:(TXVodDownloadMediaInfo *)mediaInfo {
    
    [self dealCallToFlutterData:@"start" mediaInfo:mediaInfo ];
}

- (void)onDownloadProgress:(TXVodDownloadMediaInfo *)mediaInfo {
    
    [self dealCallToFlutterData:@"progress" mediaInfo:mediaInfo ];
}

- (void)onDownloadStop:(TXVodDownloadMediaInfo *)mediaInfo {
    
    [self dealCallToFlutterData:@"stop" mediaInfo:mediaInfo ];
    
}
- (void)onDownloadFinish:(TXVodDownloadMediaInfo *)mediaInfo {
    
    [self dealCallToFlutterData:@"complete" mediaInfo:mediaInfo ];
}

- (void)onDownloadError:(TXVodDownloadMediaInfo *)mediaInfo errorCode:(TXDownloadError)code errorMsg:(NSString *)msg {
    
     NSLog(@"onDownloadError");
     NSLog(msg);
     NSLog(_path);
    self->_eventSink(@{
                       @"downloadStatus":@"error",
                       @"error":@(code),
                       });
}

- (int)hlsKeyVerify:(TXVodDownloadMediaInfo *)mediaInfo url:(NSString *)url data:(NSData *)data {
    NSLog(@"停止下载");
    return 0;
}



- (void)dealCallToFlutterData:(NSString*)type mediaInfo:(TXVodDownloadMediaInfo *)mediaInfo {
    NSLog(@"下载类型");
    NSLog(type);
    NSLog(@"%d", mediaInfo.downloadSize);
    if (mediaInfo.dataSource!=nil) {
        //        [mediaInfo.dataSource auth];
        self->_eventSink(@{
                           @"downloadStatus":type,
                           @"quanlity":@0,
                           });
    }
    
}





@end
