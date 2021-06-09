import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tencentplayer/flutter_tencentplayer.dart';

class TencentPlayerController extends ValueNotifier<TencentPlayerValue> {
  int? _textureId;
  final String? dataSource;
  final DataSourceType dataSourceType;
  final PlayerConfig playerConfig;
  MethodChannel channel = TencentPlayer.channel;

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
  Completer<void>? _creatingCompleter;
  StreamSubscription<dynamic>? _eventSubscription;
  _VideoAppLifeCycleObserver? _lifeCycleObserver;

  int? get textureId => _textureId;

  Future<void> initialize() async {
    if (this.playerConfig.supportBackground == false) {
      _lifeCycleObserver = _VideoAppLifeCycleObserver(this);
      _lifeCycleObserver!.initialize();
    }
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
    final Map<String, dynamic>? response =
        await channel.invokeMapMethod<String, dynamic>(
      'create',
      dataSourceDescription,
    );
    _textureId = response!['textureId'];
    _creatingCompleter!.complete(null);
    final Completer<void> initializingCompleter = Completer<void>();

    void eventListener(dynamic event) {
      if (_isDisposed) {
        return;
      }
      final Map<dynamic, dynamic> map = event;
      int curCode = map['eventCode'];

      switch (map['event']) {
        case 'initialized':
          value = value.copyWith(
            duration: Duration(milliseconds: map['duration']),
            size: Size(map['width']?.toDouble() ?? 0.0,
                map['height']?.toDouble() ?? 0.0),
            degree: map['degree'] ?? 0,
            eventCode: curCode,
          );
          initializingCompleter.complete(null);
          break;
        case 'progress':
          if (!value.isPlaying) return;
          Duration newProgress = Duration(milliseconds: map['progress']);
          Duration newPlayable = Duration(milliseconds: map['playable']);
          if (value.position == newProgress && value.playable == newPlayable)
            return;

          value = value.copyWith(
            position: newProgress,
            duration: Duration(milliseconds: map['duration']),
            playable: newPlayable,
            eventCode: curCode,
          );
          break;
        case 'loading':
          value = value.copyWith(
            isLoading: true,
            eventCode: curCode,
          );
          break;
        case 'loadingend':
          value = value.copyWith(
            isLoading: false,
            eventCode: curCode,
          );
          break;
        case 'playend':
          value = value.copyWith(
            isPlaying: false,
            position: value.duration,
            eventCode: curCode,
          );
          break;
        case 'netStatus':
          int fps = map['fps'].toInt();
          // 忽略小于3的帧率浮动
          if (value.netSpeed == map['netSpeed'] && (value.fps! - fps).abs() < 3) return;
          value = value.copyWith(
            netSpeed: map['netSpeed'],
            fps: fps,
            eventCode: curCode,
          );
          break;
        case 'error':
          value = value.copyWith(
            errorDescription: map['errorInfo'],
            eventCode: curCode,
          );
          break;
        case 'orientation':
          value = value.copyWith(
            orientation: map['orientation'],
            eventCode: curCode,
          );
          break;
        default:
          value = value.copyWith(
            eventCode: curCode,
          );
          break;
      }
    }

    _eventSubscription = _eventChannelFor(_textureId!)
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
      await _creatingCompleter!.future;
      if (!_isDisposed) {
        _isDisposed = true;
        await _eventSubscription?.cancel();
        await channel.invokeListMethod(
            'dispose', <String, dynamic>{'textureId': _textureId});
        _lifeCycleObserver?.dispose();
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
      await channel
          .invokeMethod('play', <String, dynamic>{'textureId': _textureId});
    } else {
      await channel
          .invokeMethod('pause', <String, dynamic>{'textureId': _textureId});
    }
  }

  Future<void> seekTo(Duration moment) async {
    if (_isDisposed) {
      return;
    }
    if (moment == null) {
      return;
    }
    if (moment > value.duration) {
      moment = value.duration;
    } else if (moment < const Duration()) {
      moment = const Duration();
    }
    await channel.invokeMethod('seekTo', <String, dynamic>{
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
    await channel.invokeMethod('setBitrateIndex', <String, dynamic>{
      'textureId': _textureId,
      'index': index,
    });
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
    await channel.invokeMethod('setRate', <String, dynamic>{
      'textureId': _textureId,
      'rate': rate,
    });
    value = value.copyWith(rate: rate);
  }
}

///视频组件生命周期监听
class _VideoAppLifeCycleObserver with WidgetsBindingObserver {
  bool _wasPlayingBeforePause = false;
  final TencentPlayerController _controller;

  _VideoAppLifeCycleObserver(this._controller);

  void initialize() {
    WidgetsBinding.instance!.addObserver(this);
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
    WidgetsBinding.instance!.removeObserver(this);
  }
}
