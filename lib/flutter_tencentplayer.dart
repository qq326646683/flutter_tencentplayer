import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

final MethodChannel _channel = const MethodChannel('flutter_tencentplayer')
  ..invokeMethod<void>('init');

class TencentPlayerValue {
  final Duration duration;
  final Duration position;
  final Duration playable;
  final bool isPlaying;
  final String errorDescription;
  final Size size;
  final bool isLoading;
  final int netSpeed;
  final double rate;
  final int bitrateIndex;

  bool get initialized => duration != null;

  bool get hasError => errorDescription != null;

  double get aspectRatio => size != null ? size.width / size.height : 1.0;

  TencentPlayerValue({
    this.duration = const Duration(),
    this.position = const Duration(),
    this.playable = const Duration(),
    this.isPlaying = false,
    this.errorDescription,
    this.size,
    this.isLoading = false,
    this.netSpeed,
    this.rate = 1.0,
    this.bitrateIndex = 0, //TODO 默认清晰度
  });

  TencentPlayerValue copyWith({
    Duration duration,
    Duration position,
    Duration playable,
    bool isPlaying,
    String errorDescription,
    Size size,
    bool isLoading,
    int netSpeed,
    double rate,
    int bitrateIndex,
  }) {
    return TencentPlayerValue(
      duration: duration ?? this.duration,
      position: position ?? this.position,
      playable: playable ?? this.playable,
      isPlaying: isPlaying ?? this.isPlaying,
      errorDescription: errorDescription ?? this.errorDescription,
      size: size ?? this.size,
      isLoading: isLoading ?? this.isLoading,
      netSpeed: netSpeed ?? this.netSpeed,
      rate: rate ?? this.rate,
        bitrateIndex: bitrateIndex ?? this.bitrateIndex,
    );
  }

  @override
  String toString() {
    return '$runtimeType('
        'duration: $duration, '
        'position: $position, '
        'playable: $playable, '
        'isPlaying: $isPlaying, '
        'errorDescription: $errorDescription),'
        'isLoading: $isLoading),'
        'netSpeed: $netSpeed),'
        'rate: $rate),'
        'bitrateIndex: $bitrateIndex),'
        'size: $size)';
  }
}

enum DataSourceType { asset, network, file }

class PlayerConfig {
  final bool autoPlay;
  final bool loop;
  final Map<String, String> headers;
  final String cachePath;
  final int progressInterval;
  // 单位:秒
  final int startTime;
  final Map<String, dynamic> auth;


  const PlayerConfig(
      {this.autoPlay = true,
      this.loop = false,
      this.headers,
      this.cachePath,
      this.progressInterval = 300,
      this.startTime,
      this.auth,
      });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'autoPlay': this.autoPlay,
        'loop': this.loop,
        'headers': this.headers,
        'cachePath': this.cachePath,
        'progressInterval': this.progressInterval,
        'startTime': this.startTime,
        'auth': this.auth,
      };
}

class TencentPlayerController extends ValueNotifier<TencentPlayerValue> {
  int _textureId;
  final String dataSource;
  final DataSourceType dataSourceType;
  final PlayerConfig playerConfig;

  TencentPlayerController.asset(this.dataSource,
      {this.playerConfig = const PlayerConfig()})
      : dataSourceType = DataSourceType.asset,
        super(TencentPlayerValue());

  TencentPlayerController.network(this.dataSource,
      {this.playerConfig = const PlayerConfig()})
      : dataSourceType = DataSourceType.network,
        super(TencentPlayerValue());

  TencentPlayerController.file(String filePath,
      {this.playerConfig = const PlayerConfig()})
      : dataSource = filePath,
        dataSourceType = DataSourceType.file,
        super(TencentPlayerValue());

  bool _isDisposed = false;
  Completer<void> _creatingCompleter;
  StreamSubscription<dynamic> _eventSubscription;
  _VideoAppLifeCycleObserver _lifeCycleObserver;

  @visibleForTesting
  int get textureId => _textureId;

  Future<void> initialize() async {
    _lifeCycleObserver = _VideoAppLifeCycleObserver(this);
    _lifeCycleObserver.initialize();
    _creatingCompleter = Completer<void>();
    Map<dynamic, dynamic> dataSourceDescription;
    switch (dataSourceType) {
      case DataSourceType.asset:
        dataSourceDescription = <String, dynamic>{'asset': dataSource};
        break;
      case DataSourceType.network:
      case DataSourceType.file:
        dataSourceDescription = <String, dynamic>{'uri': dataSource};
        break;
    }
    value = value.copyWith(isPlaying: playerConfig.autoPlay);
    dataSourceDescription.addAll(playerConfig.toJson());
    final Map<String, dynamic> response =
        await _channel.invokeMapMethod<String, dynamic>(
      'create',
      dataSourceDescription,
    );
    _textureId = response['textureId'];
    _creatingCompleter.complete(null);
    final Completer<void> initializingCompleter = Completer<void>();

    void eventListener(dynamic event) {
      if (_isDisposed) {
        return;
      }
      final Map<dynamic, dynamic> map = event;
      switch (map['event']) {
        case 'initialized':
          value = value.copyWith(
            duration: Duration(milliseconds: map['duration']),
            size: Size(map['width']?.toDouble() ?? 0.0,
                map['height']?.toDouble() ?? 0.0),
          );
          initializingCompleter.complete(null);
          break;
        case 'progress':
          value = value.copyWith(
            position: Duration(milliseconds: map['progress']),
            duration: Duration(milliseconds: map['duration']),
            playable: Duration(milliseconds: map['playable']),
          );
          break;
        case 'loading':
          value = value.copyWith(isLoading: true);
          break;
        case 'loadingend':
          value = value.copyWith(isLoading: false);
          break;
        case 'playend':
          value = value.copyWith(isPlaying: false, position: value.duration);
          break;
        case 'netStatus':
          value = value.copyWith(netSpeed: map['netSpeed']);
          break;
        case 'error':
          value = value.copyWith(errorDescription: map['errorInfo']);
          break;
      }
    }

    _eventSubscription = _eventChannelFor(_textureId)
        .receiveBroadcastStream()
        .listen(eventListener);
    return initializingCompleter.future;
  }

  EventChannel _eventChannelFor(int textureId) {
    return EventChannel('flutter_tencentplayer/videoEvents$textureId');
  }

  @override
  Future dispose() async {
    if (_creatingCompleter != null) {
      await _creatingCompleter.future;
      if (!_isDisposed) {
        _isDisposed = true;
        await _eventSubscription?.cancel();
        await _channel.invokeListMethod(
            'dispose', <String, dynamic>{'textureId': _textureId});
        _lifeCycleObserver.dispose();
      }
    }
    _isDisposed = true;
    super.dispose();
  }

  Future<void> play() async {
    value = value.copyWith(isPlaying: true);
    await _applyPlayPause();
  }

  Future<void> pause() async {
    value = value.copyWith(isPlaying: false);
    await _applyPlayPause();
  }

  Future<void> _applyPlayPause() async {
    if (!value.initialized || _isDisposed) {
      return;
    }
    if (value.isPlaying) {
      await _channel
          .invokeMethod('play', <String, dynamic>{'textureId': _textureId});
    } else {
      await _channel
          .invokeMethod('pause', <String, dynamic>{'textureId': _textureId});
    }
  }

  Future<void> seekTo(Duration moment) async {
    if (_isDisposed) {
      return;
    }
    if (moment > value.duration) {
      moment = value.duration;
    } else if (moment < const Duration()) {
      moment = const Duration();
    }
    await _channel.invokeMethod('seekTo', <String, dynamic>{
      'textureId': _textureId,
      'location': moment.inSeconds,
    });
    value = value.copyWith(position: moment);
  }

  //点播为m3u8子流，会自动无缝seek
  Future<void> setBitrateIndex(int index) async {
    if (_isDisposed) {
      return;
    }
    await _channel.invokeMethod('setBitrateIndex', <String, dynamic>{
      'textureId': _textureId,
      'index': index,
    });
    print('hahaha');
    value = value.copyWith(bitrateIndex: index);
  }

  Future<void> setRate(double rate) async {
    if (_isDisposed) {
      return;
    }
    if (rate > 2.0) {
      rate = 2.0;
    } else if (rate < 1.0) {
      rate = 1.0;
    }
    await _channel.invokeMethod('setRate', <String, dynamic>{
      'textureId': _textureId,
      'rate': rate,
    });
    value = value.copyWith(rate: rate);
  }
}

class _VideoAppLifeCycleObserver with WidgetsBindingObserver {
  bool _wasPlayingBeforePause = false;
  final TencentPlayerController _controller;

  _VideoAppLifeCycleObserver(this._controller);

  void initialize() {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        _wasPlayingBeforePause = _controller.value.isPlaying;
        _controller.pause();
        break;
      case AppLifecycleState.resumed:
        if (_wasPlayingBeforePause) {
          _controller.play();
        }
        break;
      default:
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }
}

class TencentPlayer extends StatefulWidget {
  final TencentPlayerController controller;

  TencentPlayer(this.controller);

  @override
  _TencentPlayerState createState() => new _TencentPlayerState();
}

class _TencentPlayerState extends State<TencentPlayer> {
  VoidCallback _listener;
  int _textureId;

  _TencentPlayerState() {
    _listener = () {
      final int newTextureId = widget.controller.textureId;
      if (newTextureId != _textureId) {
        setState(() {
          _textureId = newTextureId;
        });
      }
    };
  }

  @override
  void initState() {
    super.initState();
    _textureId = widget.controller.textureId;
    widget.controller.addListener(_listener);
  }

  @override
  void didUpdateWidget(TencentPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller.dataSource != widget.controller.dataSource) {
      oldWidget.controller.dispose();
    }
    oldWidget.controller.removeListener(_listener);
    _textureId = widget.controller._textureId;
    widget.controller.addListener(_listener);
  }

  @override
  void deactivate() {
    super.deactivate();
    widget.controller.removeListener(_listener);
  }

  @override
  Widget build(BuildContext context) {
    return _textureId == null ? Container() : Texture(textureId: _textureId);
  }
}


//////////////////////////// 离线下载相关///////////////////////////////////////
enum DownloadStatus{
  start,
  progress,
  stop,
  complete,
  error
}

enum Quanlity {
  QUALITY_OD,
  QUALITY_FLU,
  QUALITY_SD,
  QUALITY_HD,
  QUALITY_FHD,
  QUALITY_2K,
  QUALITY_4K
}

const Map<Quanlity, int> qunanlityMap= {
  Quanlity.QUALITY_OD: 0,
  Quanlity.QUALITY_FLU: 1,
  Quanlity.QUALITY_SD: 2,
  Quanlity.QUALITY_HD: 3,
  Quanlity.QUALITY_FHD: 4,
  Quanlity.QUALITY_2K: 5,
  Quanlity.QUALITY_4K: 6,
};

class DownloadValue {
  final DownloadStatus downloadStatus;
  final Quanlity quanlity;
  final int duration;
  final int size;
  final int downloadSize;
  final double progress;
  final String playPath;
  final bool isStop;
  final String url;
  final String error;

  DownloadValue({
    this.downloadStatus,
    this.quanlity,
    this.duration,
    this.size,
    this.downloadSize,
    this.progress,
    this.playPath,
    this.isStop,
    this.url,
    this.error,
  });

  DownloadValue copyWith({
    DownloadStatus downloadStatus,
    Quanlity quanlity,
    int duration,
    int size,
    int downloadSize,
    double progress,
    String playPath,
    bool isStop,
    String url,
    String error,
  }) {
    return DownloadValue(
      downloadStatus: downloadStatus ?? this.downloadStatus,
      quanlity: quanlity ?? this.quanlity,
      duration: duration ?? this.duration,
      size: size ?? this.size,
      downloadSize: downloadSize ?? this.downloadSize,
      progress: progress ?? this.progress,
      playPath: playPath ?? this.playPath,
      isStop: isStop ?? this.isStop,
      url: url ?? this.url,
      error: error ?? this.error,
    );
  }

  @override
  String toString() {
    return 'downloadStatus: $downloadStatus ,size: $size, downloaded: $downloadSize';
  }

  String showDetailLog() {
    return 'DownloadValue{downloadStatus: $downloadStatus, quanlity: $quanlity,\n duration: $duration, size: $size, downloadSize: $downloadSize,\n progress: $progress,\n playPath: $playPath,\n isStop: $isStop,\n url: $url,\n error: $error}';
  }

  static DownloadValue fromJson(Map<dynamic, dynamic> json) {
    return DownloadValue(
      downloadStatus: json['downloadStatus'],
      duration: int.parse(json['duration']),
      size: int.parse(json['size']),
      downloadSize: int.parse(json['downloadSize']),
      progress: double.parse(json['downloadSize']),
      playPath: json['playPath'] as String,
      isStop: json['isStop'] == "true",
      url: json['url'] as String,
    );

  }

}

class DownloadController extends ValueNotifier<Map<String, DownloadValue>> {
  final String savePath;
  StreamSubscription<dynamic> _eventSubscription;


  DownloadController(this.savePath)
      : super(Map<String, DownloadValue>());

  void dowload(String sourceUrl) async {
    Map<dynamic, dynamic> downloadInfoMap = {
      "savePath": savePath,
      "sourceUrl": sourceUrl,
    };

    await _channel.invokeMethod(
      'download',
      downloadInfoMap,
    );

    void eventListener(dynamic event) {
      final Map<dynamic, dynamic> map = event;

      switch (map['downloadEvent']) {
        case 'start':
          print('download66:start');
          print(map['mediaInfo']);
          map['mediaInfo']["downloadStatus"] = DownloadStatus.start;
          DownloadValue downloadValue = DownloadValue.fromJson(map['mediaInfo']);
          value[downloadValue.url] = downloadValue;
          break;
        case 'progress':
          print('download66:progress');
          print(map['mediaInfo']);
          map['mediaInfo']["downloadStatus"] = DownloadStatus.progress;
          DownloadValue downloadValue = DownloadValue.fromJson(map['mediaInfo']);
          value[downloadValue.url] = downloadValue;
          break;
        case 'stop':
          print('download66:stop');
          print(map['mediaInfo']);
          map['mediaInfo']["downloadStatus"] = DownloadStatus.stop;
          DownloadValue downloadValue = DownloadValue.fromJson(map['mediaInfo']);
          value[downloadValue.url] = downloadValue;
          break;
        case 'complete':
          print('download66:complete');
          print(map['mediaInfo']);
          map['mediaInfo']["downloadStatus"] = DownloadStatus.complete;
          DownloadValue downloadValue = DownloadValue.fromJson(map['mediaInfo']);
          value[downloadValue.url] = downloadValue;
          break;
        case 'error':
          print('download66:error');
          print(map['mediaInfo']);
          DownloadValue downloadValue = DownloadValue.fromJson(map['mediaInfo']);
          value[downloadValue.url] = downloadValue;
          break;
      }
    }

    _eventSubscription = _eventChannelFor(sourceUrl)
        .receiveBroadcastStream()
        .listen(eventListener);
  }

  EventChannel _eventChannelFor(String sourceUrl) {
    return EventChannel('flutter_tencentplayer/downloadEvents$sourceUrl');
  }



}
