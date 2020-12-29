import 'package:flutter/material.dart';

class TencentPlayerValue {
  final Duration duration;
  final Duration position;
  final Duration playable;
  final bool isPlaying;
  final String errorDescription;
  final String playerStatus;
  final Size size;
  final bool isLoading;
  final int netSpeed;
  final double rate;
  final int bitrateIndex;
  final int orientation;
  final int degree;

  bool get initialized => size?.width != null;

  bool get hasError => errorDescription != null;

  double get aspectRatio => size != null ? size.width / size.height > 0.0 ? size.width / size.height : 1.0 : 1.0;

  TencentPlayerValue({
    this.duration = const Duration(),
    this.position = const Duration(),
    this.playable = const Duration(),
    this.isPlaying = false,
    this.errorDescription,
    this.playerStatus,
    this.size,
    this.isLoading = false,
    this.netSpeed,
    this.rate = 1.0,
    this.bitrateIndex = 0, //TODO 默认清晰度
    this.orientation = 0,
    this.degree = 0,
  });

  TencentPlayerValue copyWith({
    Duration duration,
    Duration position,
    Duration playable,
    bool isPlaying,
    String errorDescription,
    String playerStatus,
    Size size,
    bool isLoading,
    int netSpeed,
    double rate,
    int bitrateIndex,
    int orientation,
    int degree,
  }) {
    return TencentPlayerValue(
      duration: duration ?? this.duration,
      position: position ?? this.position,
      playable: playable ?? this.playable,
      isPlaying: isPlaying ?? this.isPlaying,
      errorDescription: errorDescription ?? this.errorDescription,
      playerStatus: playerStatus ?? this.playerStatus,
      size: size ?? this.size,
      isLoading: isLoading ?? this.isLoading,
      netSpeed: netSpeed ?? this.netSpeed,
      rate: rate ?? this.rate,
      bitrateIndex: bitrateIndex ?? this.bitrateIndex,
      orientation: orientation ?? this.orientation,
      degree: degree ?? this.degree,
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
        'playerStatus: $playerStatus),'
        'isLoading: $isLoading),'
        'netSpeed: $netSpeed),'
        'rate: $rate),'
        'bitrateIndex: $bitrateIndex),'
        'orientation: $orientation),'
        'degree: $degree),'
        'size: $size)';
  }
}

enum DataSourceType { asset, network, file }
