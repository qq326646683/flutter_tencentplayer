package com.jinxian.flutter_tencentplayer;

import android.media.MediaMetadataRetriever;

import java.lang.reflect.Field;
import java.util.HashMap;

public class Util {
    public static HashMap<String, Object> convertToMap(Object obj) {

        HashMap<String, Object> map = new HashMap<String, Object>();
        Field[] fields = obj.getClass().getDeclaredFields();
        for (int i = 0, len = fields.length; i < len; i++) {
            String varName = fields[i].getName();
            boolean accessFlag = fields[i].isAccessible();
            fields[i].setAccessible(true);

            Object o = null;
            try {
                o = fields[i].get(obj);
            } catch (IllegalAccessException e) {
                e.printStackTrace();
            }
            if (o != null)
                map.put(varName, o.toString());

            fields[i].setAccessible(accessFlag);
        }

        return map;
    }

    public static int getNetworkVideoRotate(String mUri) {
        int rotation = 0;
        MediaMetadataRetriever mmr = new MediaMetadataRetriever();
        try {
            if (mUri != null) {
                HashMap headers = null;
                if (headers == null) {
                    headers = new HashMap();
                    headers.put("User-Agent", "Mozilla/5.0 (Linux; U; Android 4.4.2; zh-CN; MW-KW-001 Build/JRO03C) AppleWebKit/533.1 (KHTML, like Gecko) Version/4.0 UCBrowser/1.0.0.001 U4/0.8.0 Mobile Safari/533.1");
                }
                if (mUri.startsWith("http")) {
                    mmr.setDataSource(mUri, headers);
                } else {
                    mmr.setDataSource(mUri);
                }
            }

            String rotationStr = mmr.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_ROTATION); // 视频旋转方向
            if (rotationStr!=null && !rotationStr.isEmpty()) {
                rotation = Integer.parseInt(rotationStr);
            }
        } catch (Exception ex) {
            ex.printStackTrace();
        } finally {
            mmr.release();
        }
        return rotation;
    }

}
