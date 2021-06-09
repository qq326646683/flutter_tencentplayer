import 'package:flutter/material.dart';

class TencentPlayerValue {
  final Duration duration;
  final Duration position;
  final Duration playable;
  final bool isPlaying;
  final String? errorDescription;
  final Size? size;
  final bool isLoading;
  final int? netSpeed;
  final int? fps;
  final double rate;
  final int bitrateIndex;
  final int orientation;
  final int degree;
  final int? eventCode;

  bool get initialized => size?.width != null;

  bool get hasError => errorDescription != null;

  double get aspectRatio => size != null
      ? size!.width / size!.height > 0.0
          ? size!.width / size!.height
          : 1.0
      : 1.0;

  TencentPlayerValue({
    this.duration = const Duration(),
    this.position = const Duration(),
    this.playable = const Duration(),
    this.isPlaying = false,
    this.errorDescription,
    this.size,
    this.isLoading = false,
    this.netSpeed,
    this.fps = 0,
    this.rate = 1.0,
    this.bitrateIndex = 0, //TODO 默认清晰度
    this.orientation = 0,
    this.degree = 0,
    this.eventCode,
  });

  TencentPlayerValue copyWith({
    Duration? duration,
    Duration? position,
    Duration? playable,
    bool? isPlaying,
    String? errorDescription,
    Size? size,
    bool? isLoading,
    int? netSpeed,
    int? fps,
    double? rate,
    int? bitrateIndex,
    int? orientation,
    int? degree,
    int? eventCode,
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
      orientation: orientation ?? this.orientation,
      degree: degree ?? this.degree,
      eventCode: eventCode ?? this.eventCode,
      fps: fps ?? this.fps,
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
        'fps: $fps),'
        'rate: $rate),'
        'bitrateIndex: $bitrateIndex),'
        'orientation: $orientation),'
        'degree: $degree),'
        'size: $size),'
        'eventCode: $eventCode),';
  }
}

enum DataSourceType { asset, network, file }
