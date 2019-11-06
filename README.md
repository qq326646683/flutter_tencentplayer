线上项目应用运行效果：
http://file.jinxianyun.com/tencentplayer.MP4
# 1.Setup
```
flutter_tencentplayer: ${last_version}

or

flutter_tencentplayer:
    git:
      url: https://github.com/qq326646683/flutter_tencentplayer.git
```
> For Android

1. project/android/build.gradle 添加依赖的aar：
```gradle
def flutterProjectRoot = rootProject.projectDir.parentFile.toPath()
def plugins = new Properties()
def pluginsFile = new File(flutterProjectRoot.toFile(), '.flutter-plugins')
if (pluginsFile.exists()) {
    pluginsFile.withReader('UTF-8') { reader -> plugins.load(reader) }
}

allprojects {
    repositories {
        google()
        jcenter()
        flatDir {
            dirs "${plugins.get("flutter_tencentplayer")}android/libs"
        }
    }
}
```

2. AndroidManifest.xml 声明权限:
```
<!--网络权限-->

<uses-permission android:name="android.permission.INTERNET" />

<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />

<uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />

<!--点播播放器悬浮窗权限-->

<uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW" />

<!--存储-->

<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />

<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
```

> For Ios  



``` 

//项目的info.plist文件上添加如下权限 
<key>NSAppTransportSecurity</key>
	<dict>
		<key>NSAllowsArbitraryLoads</key>
		<true/>
  </dict>
```

# 2.Usage(TencentPlayer)

> 和video_player api相似,支持直播源,视频跳转,切换视频源,边下边播放,清晰度切换,设置播放速度

### 1.初始化播放器,支持asset、network、filePath、fileId四种方式播放
```dart
TencentPlayerController _controller;

_MyAppState() {
    listener = () {
      if (!mounted) {
        return;
      }
      setState(() {});
    };
}

initState() {
    _controller = TencentPlayerController.network('http://file.jinxianyun.com/testhaha.mp4', playerConfig: PlayerConfig())
    //_controller = TencentPlayerController.asset('static/tencent1.mp4')
    //_controller = TencentPlayerController.file('/storage/emulated/0/test.mp4')
    //_controller = TencentPlayerController.network(null, playerConfig: {auth: {"appId": 1252463788, "fileId": '4564972819220421305'}})
    ..initialize().then((_) {
        setState(() {});
      });
    _controller.addListener(listener);
}
```

### 2.<font color=#0000FF >PlayerConfig</font> (播放器配置参数 )
```dart
_controller = TencentPlayerController.network(url, playerConfig: PlayerConfig())

```

Prop | Type | Default | Note
---|---|---|---
autoPlay | bool | true | 是否自动播放
loop | bool | false | 是否循环播放
headers | Map<String, String> |  | 请求头
cachePath | String |  | 缓存路径(边播放边下载)
progressInterval | int | 200 | 播放进度回调频率(毫秒)
startTime | int | 0 | 哪里开始播放(秒)
auth | Map<String, dynamic> |  | 云点播视频源appId&fileId



### 3.<font color=#0000FF >TencentPlayerValue</font> (播放器回调)
```dart
Text("总时长：" + _controller.value.duration.toString())
```
Prop | Type | Note
---|---|---
initialized | bool | 是否初始化完成从而显示播放器
aspectRatio | double | 用来控制播放器宽高比
duration | Duration | 时长
position | Duration | 播放进度
playable | Duration | 缓冲进度
isPlaying | bool | 是否在播放
size | Size | 视频宽高
isLoading | bool | 是否在加载
netSpeed | int | 视频播放网速
rate | double | 播放速度
bitrateIndex | int | 视频清晰度

### 4.<font color=#0000FF >Event</font> (播放器事件)

a.跳转进度
```dart
_controller.seekTo(Duration(seconds: 5));

```
b.设置播放速度
```dart
_controller.setRate(1.5); // 1.0 ~ 2.0

```
c.切换播放源
```dart
controller?.removeListener(listener);
controller?.pause();
controller = TencentPlayerController.network(url, playerConfig: PlayerConfig(startTime: startTime ?? controller.value.position.inSeconds));
controller?.initialize().then((_) {
  if (mounted) setState(() {});
});
controller?.addListener(listener);
```
d.切换清晰度(实质就是切换播放源)


# 3.Usage(Download)
> 离线下载, 支持断点续传(这里只支持m3u8视频、fileId), 支持多文件同时下载

### 1.初始化下载器

```dart
DownloadController _downloadController;

_MyAppState() {
    downloadListener = () {
      if (!mounted) {
        return;
      }
      setState(() {});
    };
}

initState() {
    _downloadController = DownloadController('/storage/emulated/0/tencentdownload', appId: 1252463788);
    _downloadController.addListener(downloadListener);
}
```
### 2.<font color=#0000FF >Event</font> (下载事件)

a. 下载
```dart
_downloadController.dowload("4564972819220421305", quanlity: 2);
// _downloadController.dowload("http://1253131631.vod2.myqcloud.com/26f327f9vodgzp1253131631/f4bdff799031868222924043041/playlist.m3u8");
```
b. 暂停下载
```dart
_downloadController.pauseDownload("4564972819220421305");
// _downloadController.stopDownload("http://1253131631.vod2.myqcloud.com/26f327f9vodgzp1253131631/f4bdff799031868222924043041/playlist.m3u8");

```
b. 取消下载
```dart
_downloadController.cancelDownload("4564972819220421305");
// _downloadController.cancelDownload("http://1253131631.vod2.myqcloud.com/26f327f9vodgzp1253131631/f4bdff799031868222924043041/playlist.m3u8");

```


### 3.<font color=#0000FF >DownloadValue</font> (下载信息回调)
>因为支持多文件同时下载,回调以Map<String, DownloadValue>返回,key为url/fileId

Prop | Type | Note
---|---|---
downloadStatus | String | "start"、"progress"、"stop"、"complete"、"error"
quanlity | int | 1: "FLU"、2: "SD"、3: "HD"、4: "FHD"、5: "2K"、6: "4K"
duration | int |
size | int | 文件大小
downloadSize | int | 已下载大小
progress | int | 已下载大小
playPath | String | 下载文件的绝对路径
isStop | bool | 是否暂停下载
url | String | 下载的视频链接
fileId | String | 下载的视频FileId
error | String | 下载的错误信息



# 4.[Example](https://github.com/qq326646683/flutter_tencentplayer/blob/master/example/lib/main.dart)







