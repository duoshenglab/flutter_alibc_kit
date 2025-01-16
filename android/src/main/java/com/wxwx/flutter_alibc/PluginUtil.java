package com.wxwx.flutter_alibc;

import com.alibaba.baichuan.android.trade.model.OpenType;
import com.alibaba.baichuan.trade.biz.applink.adapter.AlibcFailModeType;
import com.alibaba.baichuan.trade.biz.core.taoke.AlibcTaokeParams;
import com.wxwx.flutter_alibc.PluginConstants.*;
import com.wxwx.flutter_alibc.PluginConstants;
import java.util.Map;

public class PluginUtil {

    public static OpenType getOpenType(String open) {
        if (PluginConstants.Auto_OpenType.equals(open)) {
            return OpenType.Auto;
        } else {
            return OpenType.Native;
        }
    }

    public static String getClientType(String client) {
        if (client.equals(PluginConstants.Tmall_ClientType)) {
            return "tmall";
        } else {
            return "taobao";
        }
    }

    public static AlibcFailModeType getFailModeType(String mode) {
        if (PluginConstants.JumpH5_FailMode.equals(mode)) {
            return AlibcFailModeType.AlibcNativeFailModeJumpH5;
        } else if (PluginConstants.JumpDownloadPage_FailMode.equals(mode)) {
            return AlibcFailModeType.AlibcNativeFailModeJumpDOWNLOAD;
        } else {
            return AlibcFailModeType.AlibcNativeFailModeNONE;
        }
    }

    public static AlibcTaokeParams getTaokeParams(Map<String, Object> taokePar) {
        String pid = (String) taokePar.get("pid");
        AlibcTaokeParams taokeParams = new AlibcTaokeParams("", "", "");
        if (pid!= null) {
            taokeParams.setPid(pid);
        }
        Object extParams = taokePar.get("extParams");
        //TODO 其他参数待添加
        return taokeParams;
    }

}