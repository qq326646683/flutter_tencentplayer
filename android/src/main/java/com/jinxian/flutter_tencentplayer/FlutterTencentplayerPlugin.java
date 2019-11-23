package com.jinxian.flutter_tencentplayer;

import android.content.res.AssetManager;
import android.os.Bundle;
import android.util.Base64;
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


import com.tencent.rtmp.ITXVodPlayListener;
import com.tencent.rtmp.TXLiveConstants;
import com.tencent.rtmp.TXPlayerAuthBuilder;
import com.tencent.rtmp.TXVodPlayConfig;
import com.tencent.rtmp.TXVodPlayer;
import com.tencent.rtmp.downloader.ITXVodDownloadListener;
import com.tencent.rtmp.downloader.TXVodDownloadDataSource;
import com.tencent.rtmp.downloader.TXVodDownloadManager;
import com.tencent.rtmp.downloader.TXVodDownloadMediaInfo;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.HashMap;
import java.util.Map;


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
                mPlayConfig.setMaxCacheItems(0);
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
                //准备阶段
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

        private String fileId;

        private TXVodDownloadManager downloader;

        private TXVodDownloadMediaInfo txVodDownloadMediaInfo;


        void stopDownload() {
            if (downloader != null && txVodDownloadMediaInfo != null) {
                downloader.stopDownload(txVodDownloadMediaInfo);
            }
        }


        TencentDownload(
                Registrar mRegistrar,
                EventChannel eventChannel,
                MethodCall call,
                Result result) {
            this.eventChannel = eventChannel;
            this.mRegistrar = mRegistrar;


            downloader = TXVodDownloadManager.getInstance();
            downloader.setListener(this);
            downloader.setDownloadPath(call.argument("savePath").toString());
            String urlOrFileId = call.argument("urlOrFileId").toString();

            if (urlOrFileId.startsWith("http")) {
                txVodDownloadMediaInfo = downloader.startDownloadUrl(urlOrFileId);
            } else {
                TXPlayerAuthBuilder auth = new TXPlayerAuthBuilder();
                auth.setAppId(((Number)call.argument("appId")).intValue());
                auth.setFileId(urlOrFileId);
                int quanlity = ((Number)call.argument("quanlity")).intValue();
                String templateName = "HLS-标清-SD";
                if (quanlity == 2) {
                    templateName = "HLS-标清-SD";
                } else if (quanlity == 3) {
                    templateName = "HLS-高清-HD";
                } else if (quanlity == 4) {
                    templateName = "HLS-全高清-FHD";
                }
                TXVodDownloadDataSource source = new TXVodDownloadDataSource(auth, templateName);
                txVodDownloadMediaInfo = downloader.startDownload(source);
            }

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
            dealCallToFlutterData("start", txVodDownloadMediaInfo);

        }

        @Override
        public void onDownloadProgress(TXVodDownloadMediaInfo txVodDownloadMediaInfo) {
            dealCallToFlutterData("progress", txVodDownloadMediaInfo);

        }

        @Override
        public void onDownloadStop(TXVodDownloadMediaInfo txVodDownloadMediaInfo) {
            dealCallToFlutterData("stop", txVodDownloadMediaInfo);
        }

        @Override
        public void onDownloadFinish(TXVodDownloadMediaInfo txVodDownloadMediaInfo) {
            dealCallToFlutterData("complete", txVodDownloadMediaInfo);
        }

        @Override
        public void onDownloadError(TXVodDownloadMediaInfo txVodDownloadMediaInfo, int i, String s) {
            HashMap<String, Object> targetMap = Util.convertToMap(txVodDownloadMediaInfo);
            targetMap.put("downloadStatus", "error");
            targetMap.put("error", "code:" + i + "  msg:" +  s);
            if (txVodDownloadMediaInfo.getDataSource() != null) {
                targetMap.put("quanlity", txVodDownloadMediaInfo.getDataSource().getQuality());
                targetMap.putAll(Util.convertToMap(txVodDownloadMediaInfo.getDataSource().getAuthBuilder()));
            }
            eventSink.success(targetMap);
        }

        @Override
        public int hlsKeyVerify(TXVodDownloadMediaInfo txVodDownloadMediaInfo, String s, byte[] bytes) {
            return 0;
        }

        private void dealCallToFlutterData(String type, TXVodDownloadMediaInfo txVodDownloadMediaInfo) {
            HashMap<String, Object> targetMap = Util.convertToMap(txVodDownloadMediaInfo);
            targetMap.put("downloadStatus", type);
            if (txVodDownloadMediaInfo.getDataSource() != null) {
                targetMap.put("quanlity", txVodDownloadMediaInfo.getDataSource().getQuality());
                targetMap.putAll(Util.convertToMap(txVodDownloadMediaInfo.getDataSource().getAuthBuilder()));
            }
            eventSink.success(targetMap);
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
                String urlOrFileId = call.argument("urlOrFileId").toString();
                EventChannel downloadEventChannel = new EventChannel(registrar.messenger(), "flutter_tencentplayer/downloadEvents" + urlOrFileId);
                TencentDownload tencentDownload = new TencentDownload(registrar, downloadEventChannel, call, result);

                downloadManagerMap.put(urlOrFileId, tencentDownload);
                break;
            case "stopDownload":
                downloadManagerMap.get(call.argument("urlOrFileId").toString()).stopDownload();
                result.success(null);
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
