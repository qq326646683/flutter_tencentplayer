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
        this.progressInterval = 200,
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