import 'dart:io';

class DownloadValue {
  final String downloadStatus;
  final int quanlity;
  final int duration;
  final int size;
  final int downloadSize;
  final double progress;
  final String playPath;
  final bool isStop;
  final String url;
  final String fileId;
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
    this.fileId,
    this.error,
  });

  DownloadValue copyWith({
    String downloadStatus,
    int quanlity,
    int duration,
    int size,
    int downloadSize,
    double progress,
    String playPath,
    bool isStop,
    String url,
    String fileId,
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
      fileId: fileId ?? this.fileId,
      error: error ?? this.error,
    );
  }


  @override
  String toString() {
    return toJson().toString();
  }

  Map<String, dynamic> toJson() =>
      <String, dynamic>{
        'downloadStatus': this.downloadStatus,
        'quanlity': this.quanlity,
        'duration': this.duration,
        'size': this.size,
        'downloadSize': this.downloadSize,
        'progress': this.progress,
        'playPath': this.playPath,
        'isStop': this.isStop,
        'url': this.url,
        'fileId': this.fileId,
        'error': this.error,
      };

  factory DownloadValue.fromJson(Map<dynamic, dynamic> json) {

    return DownloadValue(
      downloadStatus: json['downloadStatus'] as String,
      quanlity: int.parse(json['quanlity'].toString()),
      duration: int.parse(json['duration']),
      size: int.parse(json['size']),
      downloadSize: int.parse(json['downloadSize']),
      progress: double.parse(json['progress']),
      playPath: json['playPath'] as String,
      isStop: json['isStop'] == "true",
      url: json['url'] as String,
      fileId: json['fileId'] as String,
      error: json['error'] as String,
    );

  }

}