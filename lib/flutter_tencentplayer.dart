import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

final MethodChannel _channel =
const MethodChannel('flutter_tencentplayer')
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
  }){
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
      'size: $size)';
  }


}

enum DataSourceType { asset, network, file }


class TencentPlayerController extends ValueNotifier<TencentPlayerValue> {
  int _textureId;
  final String dataSource;
  final DataSourceType dataSourceType;

  TencentPlayerController.network(this.dataSource)
    : dataSourceType = DataSourceType.network,
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
      case DataSourceType.network:
        dataSourceDescription = <String, dynamic>{'uri': dataSource};
        break;
      case DataSourceType.asset:
        break;
      case DataSourceType.file:
        break;
    }
    final Map<String, dynamic> response =
       await _channel.invokeMapMethod<String, dynamic>(
        'create',
         dataSourceDescription,
       );
    _textureId = response['textureId'];
    _creatingCompleter.complete(null);
    final Completer<void> initializingCompleter = Completer<void>();

    void eventListener(dynamic event) {
      if(_isDisposed) {
        return;
      }
      final Map<dynamic, dynamic> map = event;
      switch(map['event']) {
        case 'initialized':
          value = value.copyWith(
            duration: Duration(milliseconds: map['duration']),
            size: Size(map['width']?.toDouble() ?? 0.0, map['height']?.toDouble() ?? 0.0),
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
          await _channel.invokeListMethod('dispose', <String, dynamic>{'textureId': _textureId});
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
      await _channel.invokeMethod('play', <String, dynamic>{'textureId': _textureId});
    } else {
      await _channel.invokeMethod('pause', <String, dynamic>{'textureId': _textureId});
    }
  }

  Future<void> seekTo(Duration moment) async {
    if (_isDisposed) {
      return;
    }
    if (moment > value.duration) {
      moment = value.duration;
    } else if(moment < const Duration()) {
      moment = const Duration();
    }
    await _channel.invokeMethod('seekTo', <String, dynamic> {
      'textureId': _textureId,
      'location': moment.inSeconds,
    });
    value = value.copyWith(position: moment);
  }


  Future<void> setRate(double rate) async {
    if (_isDisposed) {
      return;
    }
    if (rate > 2.0) {
      rate = 2.0;
    } else if(rate < 1.0) {
      rate = 1.0;
    }
    await _channel.invokeMethod('setRate', <String, dynamic> {
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
    } ;
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
