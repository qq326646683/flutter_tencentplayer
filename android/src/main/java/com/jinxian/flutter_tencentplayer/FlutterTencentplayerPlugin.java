package com.jinxian.flutter_tencentplayer;

import android.content.Context;
import android.net.Uri;
import android.os.Bundle;
import android.os.Environment;
import android.util.LongSparseArray;
import android.view.Surface;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.view.FlutterNativeView;
import io.flutter.view.TextureRegistry;

import com.tencent.liteav.demo.play.SuperPlayerGlobalConfig;
import com.tencent.liteav.demo.play.SuperPlayerModel;
import com.tencent.liteav.demo.play.SuperPlayerView;
import com.tencent.rtmp.ITXVodPlayListener;
import com.tencent.rtmp.TXLiveConstants;
import com.tencent.rtmp.TXVodPlayConfig;
import com.tencent.rtmp.TXVodPlayer;

import java.util.HashMap;
import java.util.Map;

/** FlutterTencentplayerPlugin */
public class FlutterTencentplayerPlugin implements MethodCallHandler {
  private static class TencentPlayer implements ITXVodPlayListener {
    private TXVodPlayer mVodPlayer;
    TXVodPlayConfig mVodPlayConfig;
    private Surface surface;

    private final TextureRegistry.SurfaceTextureEntry textureEntry;

    private TencentQueuingEventSink eventSink = new TencentQueuingEventSink();

    private final EventChannel eventChannel;


    TencentPlayer(
            Context context,
            EventChannel eventChannel,
            TextureRegistry.SurfaceTextureEntry textureEntry,
            String dataSource,
            Result result){
      this.eventChannel = eventChannel;
      this.textureEntry = textureEntry;

      mVodPlayer = new TXVodPlayer(context);
//      SuperPlayerGlobalConfig config = SuperPlayerGlobalConfig.getInstance();
//      mVodPlayConfig = new TXVodPlayConfig();
//      mVodPlayConfig.setCacheFolderPath(Environment.getExternalStorageDirectory().getPath() + "/txcache");
//      mVodPlayConfig.setMaxCacheItems(config.maxCacheItem);
//      mVodPlayer.setConfig(this.mVodPlayConfig);
//      mVodPlayer.setRenderMode(config.renderMode);
//      this.mVodPlayer.setVodListener(this);
//      mVodPlayer.enableHardwareDecode(config.enableHWAcceleration);


      setupTencentPlayer(eventChannel, textureEntry, result);

      mVodPlayer.setAutoPlay(true);

      mVodPlayer.startPlay(dataSource);
    }

    private void setupTencentPlayer(EventChannel eventChannel, TextureRegistry.SurfaceTextureEntry textureEntry, Result result) {
      // 注册android向flutter发事件
      eventChannel.setStreamHandler(
        new EventChannel.StreamHandler() {
          @Override
          public void onListen(Object o, EventChannel.EventSink sink) {
            eventSink.setDelegate(sink);
          }
          @Override
          public void onCancel(Object o) {
            eventSink.setDelegate(null);
          }
        }
      );

      surface = new Surface(textureEntry.surfaceTexture());
      mVodPlayer.setSurface(surface);

      // 注册播放器的监听
      mVodPlayer.setVodListener(this);


      Map<String, Object> reply = new HashMap<>();
      reply.put("textureId", textureEntry.id());
      result.success(reply);
    }

    // 播放器监听1
    @Override
    public void onPlayEvent(TXVodPlayer player, int event, Bundle param) {
      switch (event) {
        case TXLiveConstants.PLAY_EVT_VOD_PLAY_PREPARED:
          Map<String, Object> preparedMap = new HashMap<>();
          preparedMap.put("event", "initialized");
          preparedMap.put("duration", (int)player.getDuration());
          preparedMap.put("width", player.getWidth());
          preparedMap.put("height", player.getHeight());
          eventSink.success(preparedMap);
          break;
        case TXLiveConstants.PLAY_EVT_PLAY_PROGRESS:
          Map<String, Object> progressMap = new HashMap<>();
          progressMap.put("event", "progress");
          progressMap.put("progress", param.getInt(TXLiveConstants.EVT_PLAY_PROGRESS_MS));
          progressMap.put("duration", param.getInt(TXLiveConstants.EVT_PLAY_DURATION_MS));
          progressMap.put("playable", param.getInt(TXLiveConstants.EVT_PLAYABLE_DURATION_MS));
          eventSink.success(progressMap);
          break;
        case TXLiveConstants.PLAY_EVT_PLAY_LOADING:
          Map<String, Object> loadingMap = new HashMap<>();
          loadingMap.put("event", "loading");
          eventSink.success(loadingMap);
          break;
        case TXLiveConstants.PLAY_EVT_VOD_LOADING_END:
          Map<String, Object> loadingendMap = new HashMap<>();
          loadingendMap.put("event", "loadingend");
          eventSink.success(loadingendMap);
          break;
        case TXLiveConstants.PLAY_EVT_PLAY_END:
          Map<String, Object> playendMap = new HashMap<>();
          playendMap.put("event", "playend");
          eventSink.success(playendMap);
          break;
        case TXLiveConstants.PLAY_ERR_NET_DISCONNECT:
          Map<String, Object> disconnectMap = new HashMap<>();
          disconnectMap.put("event", "disconnect");
          if (mVodPlayer != null) {
            mVodPlayer.setVodListener(null);
            mVodPlayer.stopPlay(true);
          }
          eventSink.success(disconnectMap);
          break;
      }
      if (event < 0) {
        Map<String, Object> errorMap = new HashMap<>();
        errorMap.put("event", "error");
        errorMap.put("errorInfo", param.getString(TXLiveConstants.EVT_DESCRIPTION));
        eventSink.success(errorMap);
      }
    }
    // 播放器监听2
    @Override
    public void onNetStatus(TXVodPlayer txVodPlayer, Bundle param) {
      Map<String, Object> netStatusMap = new HashMap<>();
      netStatusMap.put("event", "netStatus");
      netStatusMap.put("netSpeed", param.getInt(TXLiveConstants.NET_STATUS_NET_SPEED));
      netStatusMap.put("cacheSize", param.getInt(TXLiveConstants.NET_STATUS_V_SUM_CACHE_SIZE));
      eventSink.success(netStatusMap);
    }

    void play() {
      if (!mVodPlayer.isPlaying()) {
        mVodPlayer.resume();
      }
    }

    void pause() {
      mVodPlayer.pause();
    }

    void seekTo(int location) {
      mVodPlayer.seek(location);
    }

    void setRate(float rate) {
      mVodPlayer.setRate(rate);
    }

    void dispose() {
      if (mVodPlayer != null) {
        mVodPlayer.setVodListener(null);
        mVodPlayer.stopPlay(true);
      }
      textureEntry.release();
      eventChannel.setStreamHandler(null);
      if (surface != null) {
        surface.release();
      }
    }
  }
  ////////////////////////////////////// end //////////////////////////////

  private final Registrar registrar;
  private final LongSparseArray<TencentPlayer> videoPlayers;

  private FlutterTencentplayerPlugin(Registrar registrar) {
    this.registrar = registrar;
    this.videoPlayers = new LongSparseArray<>();

  }


  /** Plugin registration. */
  public static void registerWith(Registrar registrar) {
    final MethodChannel channel = new MethodChannel(registrar.messenger(), "flutter_tencentplayer");
    final FlutterTencentplayerPlugin plugin = new FlutterTencentplayerPlugin(registrar);

    channel.setMethodCallHandler(plugin);

    registrar.addViewDestroyListener(
            new PluginRegistry.ViewDestroyListener() {
              @Override
              public boolean onViewDestroy(FlutterNativeView flutterNativeView) {
                plugin.onDestroy();
                return false;
              }
            }
    );
  }

  @Override
  public void onMethodCall(MethodCall call, Result result) {
    TextureRegistry textures = registrar.textures();
    if (call.method.equals("getPlatformVersion")) {
      result.success("Android " + android.os.Build.VERSION.RELEASE);
    }

    switch (call.method) {
      case "init":
        disposeAllPlayers();
        break;
      case "create":
        TextureRegistry.SurfaceTextureEntry handle = textures.createSurfaceTexture();

        EventChannel eventChannel = new EventChannel(registrar.messenger(), "flutter_tencentplayer/videoEvents" + handle.id());

        TencentPlayer player = new TencentPlayer(registrar.context(), eventChannel, handle, call.argument("uri").toString(), result);
        videoPlayers.put(handle.id(), player);
        break;
      default:
        long textureId = ((Number) call.argument("textureId")).longValue();
        TencentPlayer tencentPlayer = videoPlayers.get(textureId);
        if (tencentPlayer == null) {
          result.error(
                  "Unknown textureId",
                  "No video player associated with texture id " + textureId,
                  null);
          return;
        }
        onMethodCall(call, result, textureId, tencentPlayer);
        break;

    }
  }

  // flutter 发往android的命令
  private void onMethodCall(MethodCall call, Result result, long textureId, TencentPlayer player) {
    switch (call.method) {
      case "play":
        player.play();
        result.success(null);
        break;
      case "pause":
        player.pause();
        result.success(null);
        break;
      case "seekTo":
        int location = ((Number) call.argument("location")).intValue();
        player.seekTo(location);
        result.success(null);
        break;
      case "setRate":
        float rate = ((Number) call.argument("rate")).floatValue();
        player.setRate(rate);
        result.success(null);
        break;
      case "dispose":
        player.dispose();
        videoPlayers.remove(textureId);
        result.success(null);
        break;
      default:
        result.notImplemented();
        break;
    }

  }


  private void disposeAllPlayers() {
    for (int i = 0; i < videoPlayers.size(); i++) {
      videoPlayers.valueAt(i).dispose();
    }
    videoPlayers.clear();
  }

  private void onDestroy() {
    disposeAllPlayers();
  }
}
