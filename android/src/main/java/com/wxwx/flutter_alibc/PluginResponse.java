package com.wxwx.flutter_alibc;

import java.util.*;

public class PluginResponse {

    private String errorCode;
    private String errorMessage;
    private Object data;

    public PluginResponse(String errorCode, String errorMessage, Object data) {
        this.errorCode = errorCode;
        this.errorMessage = errorMessage;
        this.data = data;
    }

    public static PluginResponse success(Object obj) {
        return new PluginResponse("0", "成功", obj);
    }

    public Map<String, Object> toMap() {
        Map<String, Object> map = new HashMap<>();
        map.put("errorCode", errorCode);
        map.put("errorMessage", errorMessage);
        map.put("data", data);
        return map;
    }
}