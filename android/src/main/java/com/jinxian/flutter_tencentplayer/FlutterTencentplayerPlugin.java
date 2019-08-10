package com.jinxian.flutter_tencentplayer;

import android.content.Context;
import android.content.res.AssetManager;
import android.net.Uri;
import android.os.Bundle;
import android.os.Environment;
import android.util.Base64;
import android.util.LongSparseArray;
import android.view.Surface;
import android.widget.Toast;

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
import com.tencent.rtmp.TXPlayerAuthBuilder;
import com.tencent.rtmp.TXVodPlayConfig;
import com.tencent.rtmp.TXVodPlayer;
import com.tencent.rtmp.downloader.ITXVodDownloadListener;
import com.tencent.rtmp.downloader.TXVodDownloadDataSource;
import com.tencent.rtmp.downloader.TXVodDownloadManager;
import com.tencent.rtmp.downloader.TXVodDownloadMediaInfo;

import java.io.BufferedOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.HashMap;
import java.util.Map;

import static android.widget.Toast.LENGTH_SHORT;
import static com.tencent.rtmp.downloader.TXVodDownloadDataSource.QUALITY_OD;

/**
 * FlutterTencentplayerPlugin
 */
public class FlutterTencentplayerPlugin implements MethodCallHandler {

    ///////////////////// TencentPlayer 开始////////////////////

    private static class TencentPlayer implements ITXVodPlayListener {
        private TXVodPlayer mVodPlayer;
        TXVodPlayConfig mPlayConfig;
        private Surface surface;
        TXPlayerAuthBuilder authBuilder;

        private final TextureRegistry.SurfaceTextureEntry textureEntry;

        private TencentQueuingEventSink eventSink = new TencentQueuingEventSink();

        private final EventChannel eventChannel;

        private final Registrar mRegistrar;



        TencentPlayer(
                Registrar mRegistrar,
                EventChannel eventChannel,
                TextureRegistry.SurfaceTextureEntry textureEntry,
                MethodCall call,
                Result result) {
            this.eventChannel = eventChannel;
            this.textureEntry = textureEntry;
            this.mRegistrar = mRegistrar;


            mVodPlayer = new TXVodPlayer(mRegistrar.context());

            setPlayConfig(call);

            setTencentPlayer(call);

            setFlutterBridge(eventChannel, textureEntry, result);

            setPlaySource(call);
        }


        private void setPlayConfig(MethodCall call) {
            mPlayConfig = new TXVodPlayConfig();
            if (call.argument("cachePath") != null) {
                mPlayConfig.setCacheFolderPath(call.argument("cachePath").toString());//        mPlayConfig.setCacheFolderPath(Environment.getExternalStorageDirectory().getPath() + "/nellcache");
                mPlayConfig.setMaxCacheItems(1);
            } else {
                mPlayConfig.setCacheFolderPath(null);
            }
            if (call.argument("headers") != null) {
                mPlayConfig.setHeaders((Map<String, String>) call.argument("headers"));
            }

            mPlayConfig.setProgressInterval(((Number) call.argument("progressInterval")).intValue());
            mVodPlayer.setConfig(this.mPlayConfig);
        }

        private  void setTencentPlayer(MethodCall call) {
            mVodPlayer.setVodListener(this);
//            mVodPlayer.enableHardwareDecode(true);
            mVodPlayer.setLoop((boolean) call.argument("loop"));
            if (call.argument("startTime") != null) {
                mVodPlayer.setStartTime(((Number)call.argument("startTime")).floatValue());
            }
            mVodPlayer.setAutoPlay((boolean) call.argument("autoPlay"));

        }

        private void setFlutterBridge(EventChannel eventChannel, TextureRegistry.SurfaceTextureEntry textureEntry, Result result) {
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


            Map<String, Object> reply = new HashMap<>();
            reply.put("textureId", textureEntry.id());
            result.success(reply);
        }

        private void setPlaySource(MethodCall call) {
            // network FileId播放
            if (call.argument("auth") != null) {
                authBuilder = new TXPlayerAuthBuilder();
                Map authMap = (Map<String, Object>)call.argument("auth");
                authBuilder.setAppId(((Number)authMap.get("appId")).intValue());
                authBuilder.setFileId(authMap.get("fileId").toString());
                mVodPlayer.startPlay(authBuilder);
            } else {
                // asset播放
                if (call.argument("asset") != null) {
                    String assetLookupKey = mRegistrar.lookupKeyForAsset(call.argument("asset").toString());
                    AssetManager assetManager = mRegistrar.context().getAssets();
                    try {
                        InputStream inputStream = assetManager.open(assetLookupKey);
                        String cacheDir = mRegistrar.context().getCacheDir().getAbsoluteFile().getPath();
                        String fileName = Base64.encodeToString(assetLookupKey.getBytes(), Base64.DEFAULT);
                        File file = new File(cacheDir, fileName + ".mp4");
                        FileOutputStream fileOutputStream = new FileOutputStream(file);
                        if(!file.exists()){
                            file.createNewFile();
                        }
                        int ch = 0;
                        while((ch=inputStream.read()) != -1) {
                            fileOutputStream.write(ch);
                        }
                        inputStream.close();
                        fileOutputStream.close();

                        mVodPlayer.startPlay(file.getPath());
                    } catch (IOException e) {
                        e.printStackTrace();
                    }
                } else {
                    // file、 network播放
                    mVodPlayer.startPlay(call.argument("uri").toString());
                }
            }
        }

        // 播放器监听1
        @Override
        public void onPlayEvent(TXVodPlayer player, int event, Bundle param) {
            switch (event) {
                case TXLiveConstants.PLAY_EVT_VOD_PLAY_PREPARED:
                    Map<String, Object> preparedMap = new HashMap<>();
                    preparedMap.put("event", "initialized");
                    preparedMap.put("duration", (int) player.getDuration());
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

        void setBitrateIndex(int index) {
            mVodPlayer.setBitrateIndex(index);
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
    ///////////////////// TencentPlayer 结束////////////////////

    ////////////////////  TencentDownload 开始/////////////////
    class TencentDownload implements ITXVodDownloadListener {
        private TencentQueuingEventSink eventSink = new TencentQueuingEventSink();

        private final EventChannel eventChannel;

        private final Registrar mRegistrar;


        TencentDownload(
                Registrar mRegistrar,
                EventChannel eventChannel,
                MethodCall call,
                Result result) {
            this.eventChannel = eventChannel;
            this.mRegistrar = mRegistrar;


            TXVodDownloadManager downloader = TXVodDownloadManager.getInstance();
            downloader.setListener(this);
            downloader.setDownloadPath(call.argument("savePath").toString());
            downloader.startDownloadUrl(call.argument("sourceUrl").toString());
//            downloader.startDownloadUrl("http://1253131631.vod2.myqcloud.com/26f327f9vodgzp1253131631/f4bdff799031868222924043041/playlist.m3u8");
//            TXPlayerAuthBuilder auth = new TXPlayerAuthBuilder();
//            auth.setAppId(1252463788);
//            auth.setFileId("4564972819220421305");
//            TXVodDownloadDataSource source = new TXVodDownloadDataSource(auth, QUALITY_OD);
//            downloader.startDownload(source);
            Toast.makeText(mRegistrar.context(), call.argument("savePath").toString() + "===" + call.argument("sourceUrl"), Toast.LENGTH_LONG).show();

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
            result.success(null);
        }

        @Override
        public void onDownloadStart(TXVodDownloadMediaInfo txVodDownloadMediaInfo) {
            Map<String, Object> mediaInfoMap = new HashMap<>();
            mediaInfoMap.put("downloadEvent", "start");
            mediaInfoMap.put("mediaInfo", Util.convertToMap(txVodDownloadMediaInfo));
            eventSink.success(mediaInfoMap);
        }

        @Override
        public void onDownloadProgress(TXVodDownloadMediaInfo txVodDownloadMediaInfo) {
            Map<String, Object> mediaInfoMap = new HashMap<>();
            mediaInfoMap.put("downloadEvent", "progress");
            mediaInfoMap.put("mediaInfo", Util.convertToMap(txVodDownloadMediaInfo));
            eventSink.success(mediaInfoMap);
        }

        @Override
        public void onDownloadStop(TXVodDownloadMediaInfo txVodDownloadMediaInfo) {
            Map<String, Object> mediaInfoMap = new HashMap<>();
            mediaInfoMap.put("downloadEvent", "stop");
            mediaInfoMap.put("mediaInfo", Util.convertToMap(txVodDownloadMediaInfo));
            eventSink.success(mediaInfoMap);
        }

        @Override
        public void onDownloadFinish(TXVodDownloadMediaInfo txVodDownloadMediaInfo) {
            Map<String, Object> mediaInfoMap = new HashMap<>();
            mediaInfoMap.put("downloadEvent", "complete");
            mediaInfoMap.put("mediaInfo", Util.convertToMap(txVodDownloadMediaInfo));
            eventSink.success(mediaInfoMap);
        }

        @Override
        public void onDownloadError(TXVodDownloadMediaInfo txVodDownloadMediaInfo, int i, String s) {
            Map<String, Object> mediaInfoMap = new HashMap<>();
            mediaInfoMap.put("downloadEvent", "error");
            mediaInfoMap.put("mediaInfo", "code:" + i + "  msg:" +  s);
            eventSink.success(mediaInfoMap);
        }

        @Override
        public int hlsKeyVerify(TXVodDownloadMediaInfo txVodDownloadMediaInfo, String s, byte[] bytes) {
            return 0;
        }
    }
    ////////////////////  TencentDownload 结束/////////////////
    private final Registrar registrar;
    private final LongSparseArray<TencentPlayer> videoPlayers;
    private final HashMap<String, TencentDownload> downloadManagerMap;

    private FlutterTencentplayerPlugin(Registrar registrar) {
        this.registrar = registrar;
        this.videoPlayers = new LongSparseArray<>();
        this.downloadManagerMap = new HashMap<>();



    }


    /**
     * Plugin registration.
     */
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


                TencentPlayer player = new TencentPlayer(registrar, eventChannel, handle, call, result);
                videoPlayers.put(handle.id(), player);
                break;
            case "download":
                String sourceUrl = call.argument("sourceUrl").toString();
                EventChannel downloadEventChannel = new EventChannel(registrar.messenger(), "flutter_tencentplayer/downloadEvents" + sourceUrl);
                TencentDownload tencentDownload = new TencentDownload(registrar, downloadEventChannel, call, result);

                downloadManagerMap.put(sourceUrl, tencentDownload);
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
            case "setBitrateIndex":
                int bitrateIndex = ((Number) call.argument("index")).intValue();
                player.setBitrateIndex(bitrateIndex);
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
