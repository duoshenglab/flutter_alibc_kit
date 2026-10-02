//
//  FlutterAlibcHandle.swift
//  flutter_alibc
//
//  Created by xing.wu on 2021/5/15.
//

import Foundation

class FlutterAlibcHandle: NSObject, AlibcWkWebViewDelegate {
    func noticeToken(result: String) {
        if result == "" {
            channel?.invokeMethod(FlutterAlibcConstKey.CallBackString.AlibcTaokeLogin.rawValue, arguments: [
                FlutterAlibcConstKey.ErrorCode : "-1",
                FlutterAlibcConstKey.ErrorMessage:"取消授权",
            ])
        }else{
            let array : Array = result.components(separatedBy: "=")
            let token:String = array[1]
            channel?.invokeMethod(FlutterAlibcConstKey.CallBackString.AlibcTaokeLogin.rawValue, arguments: [
                FlutterAlibcConstKey.ErrorCode : "0",
                FlutterAlibcConstKey.ErrorMessage:"success",
                FlutterAlibcConstKey.Data :[
                    "accessToken":token]
            ])
        }
        
    }
    
    func noticeCode(result: String) {
        if result == "" {
            channel?.invokeMethod(FlutterAlibcConstKey.CallBackString.AlibcTaokeLoginForCode.rawValue, arguments: [
                FlutterAlibcConstKey.ErrorCode : "-1",
                FlutterAlibcConstKey.ErrorMessage:"取消授权",
            ])
        }else{
            let array : Array = result.components(separatedBy: "=")
            let code : String = array[1]
            channel?.invokeMethod(FlutterAlibcConstKey.CallBackString.AlibcTaokeLoginForCode.rawValue, arguments: [
                FlutterAlibcConstKey.ErrorCode : "0",
                FlutterAlibcConstKey.ErrorMessage:"success",
                FlutterAlibcConstKey.Data :[
                    "code":code]
            ])
        }
    }
    
    var channel : FlutterMethodChannel? = nil;
    private var qdWebView: AlibcQdWebView?
    private var qdStarting = false
    private var qdStartWork: DispatchWorkItem?
    private let viewControllerProvider: () -> UIViewController?

    public func qdByHide(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard qdWebView == nil && !qdStarting else {
            result(FlutterError(code: "BUSY", message: "已有渠道授权正在进行", details: nil))
            return
        }
        do { _ = try QdOAuthRequest(getStringFromCall(key: "url", call: call)) }
        catch {
            result(FlutterError(code: "INVALID_URL", message: "渠道授权 URL 参数无效", details: nil))
            return
        }
        qdStarting = true
        result(nil)
        startQdWhenReady(call: call, deadline: Date().addingTimeInterval(5))
    }

    private func qdParent() -> UIViewController? {
        let flutterController = viewControllerProvider()
        var window = flutterController?.viewIfLoaded?.window
        if window == nil {
            let windows: [UIWindow]
            if #available(iOS 13.0, *) {
                windows = UIApplication.shared.connectedScenes
                    .compactMap { $0 as? UIWindowScene }
                    .filter { $0.activationState == .foregroundActive || $0.activationState == .foregroundInactive }
                    .sorted { $0.activationState == .foregroundActive && $1.activationState != .foregroundActive }
                    .flatMap { $0.windows }
            } else { windows = UIApplication.shared.windows }
            window = windows.first { $0.isKeyWindow && !$0.isHidden && $0.rootViewController != nil }
                ?? windows.first { !$0.isHidden && $0.windowLevel == .normal && $0.rootViewController != nil }
        }
        guard let targetWindow = window, !targetWindow.isHidden else { return nil }
        if #available(iOS 13.0, *), let scene = targetWindow.windowScene {
            guard scene.activationState == .foregroundActive else { return nil }
        }
        guard UIApplication.shared.applicationState == .active,
              var parent = targetWindow.rootViewController else { return nil }
        while let presented = parent.presentedViewController { parent = presented }
        guard !parent.isBeingDismissed, !parent.isBeingPresented,
              parent.transitionCoordinator == nil else { return nil }
        return parent
    }

    private func startQdWhenReady(call: FlutterMethodCall, deadline: Date) {
        guard qdStarting else { return }
        guard let parent = qdParent() else {
            if Date() >= deadline {
                finishQd(code: "NO_WINDOW", message: "等待应用恢复前台后仍找不到授权窗口", data: nil)
                return
            }
            let work = DispatchWorkItem { [weak self] in self?.startQdWhenReady(call: call, deadline: deadline) }
            qdStartWork = work
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: work)
            return
        }
        qdStartWork = nil
        do {
            let controller = try AlibcQdWebView(url: getStringFromCall(key: "url", call: call)) { [weak self] code, message, data in
                self?.finishQd(code: code, message: message, data: data)
            }
            qdWebView = controller
            qdStarting = false
            controller.start(parent: parent, backURL: getStringFromCall(key: "backUrl", call: call))
        } catch { finishQd(code: "INVALID_URL", message: "渠道授权 URL 参数无效", data: nil) }
    }

    private func finishQd(code: String, message: String, data: [String: String]?) {
        guard qdStarting || qdWebView != nil else { return }
        qdStartWork?.cancel()
        qdStartWork = nil
        qdStarting = false
        qdWebView = nil
        channel?.invokeMethod(FlutterAlibcConstKey.CallBackString.AlibcQdByHide.rawValue,
            arguments: ["errorCode": code, "errorMessage": message, "data": data as Any? ?? NSNull()])
    }

    init(channel: FlutterMethodChannel, viewControllerProvider: @escaping () -> UIViewController? = { nil }) {
        self.viewControllerProvider = viewControllerProvider
        super.init()
        self.channel = channel
    }

    //    MARK: - 对flutter暴露的方法
    
    //    MARK:  初始化阿里百川
    public func initAlibc(call : FlutterMethodCall , result : @escaping FlutterResult){
        //        线上环境
        AlibcTradeSDK.sharedInstance()?.setEnv(AlibcEnvironment.release)
        let version : String = getStringFromCall(key: "version", call: call);
        let appName : String = getStringFromCall(key: "appName", call: call);
        //        判断是否存在
        if version != ""{
            AlibcTradeSDK.sharedInstance()?.setIsvVersion(version)//设置三方App版本,可用于标识App版本
        }
        if appName != ""{
            AlibcTradeSDK.sharedInstance()?.setIsvAppName(appName)//设置三方App名称,可用于标识App
        }
        //        开发阶段打开日志开关
        AlibcTradeSDK.sharedInstance()?.setDebugLogOpen(true)
        
        //        初始化
        AlibcTradeSDK.sharedInstance()?.asyncInit(success: {
            let dic = [FlutterAlibcConstKey.ErrorCode :"0",FlutterAlibcConstKey.ErrorMessage:"success"]
            result(dic);
        }, failure: { (error) in
            let dic = [FlutterAlibcConstKey.ErrorCode :String((error! as NSError).code) ,FlutterAlibcConstKey.ErrorMessage:error?.localizedDescription] as! Dictionary<String,String>
            result(dic);
        })
    }
    
    //    MARK:  淘宝登录
    public func loginTaoBao(call : FlutterMethodCall , result : @escaping FlutterResult){
        //        判断是否登录
        if(!ALBBCompatibleSession.sharedInstance().isLogin()){
            // 登陆
            let rootViewController : UIViewController = UIApplication.shared.windows.last!.rootViewController!
            ALBBSDK.sharedInstance().auth(rootViewController) {
                let userInfo : ALBBUser = ALBBCompatibleSession.sharedInstance().getUser()
                self.channel?.invokeMethod(FlutterAlibcConstKey.CallBackString.AlibcTaobaoLogin.rawValue, arguments: [
                    FlutterAlibcConstKey.ErrorCode : "0",
                    FlutterAlibcConstKey.ErrorMessage:"success",
                    FlutterAlibcConstKey.Data :[
                        //                        昵称
                        "nick":userInfo.nick,
                        //                        头像地址
                        "avatarUrl":userInfo.avatarUrl,
                        "openId":userInfo.openId,
                        "openSid":userInfo.openSid,
                        "topAccessToken":userInfo.topAccessToken,
                        "topAuthCode":userInfo.topAuthCode,]
                ])
            } failureCallback: { error in
                let dic = [FlutterAlibcConstKey.ErrorCode :String((error! as NSError).code) ,FlutterAlibcConstKey.ErrorMessage: String(error!.localizedDescription)]
                result(dic);
                self.channel?.invokeMethod(FlutterAlibcConstKey.CallBackString.AlibcTaobaoLogin.rawValue, arguments: [dic])
            }
        }else{
            // 返回数据
            let userInfo : ALBBUser = ALBBCompatibleSession.sharedInstance().getUser()
            
            channel?.invokeMethod(FlutterAlibcConstKey.CallBackString.AlibcTaobaoLogin.rawValue, arguments: [
                FlutterAlibcConstKey.ErrorCode : "0",
                FlutterAlibcConstKey.ErrorMessage:"success",
                FlutterAlibcConstKey.Data :[
                    //                        昵称
                    "nick":userInfo.nick,
                    //                        头像地址
                    "avatarUrl":userInfo.avatarUrl,
                    "openId":userInfo.openId,
                    "openSid":userInfo.openSid,
                    "topAccessToken":userInfo.topAccessToken,
                    "topAuthCode":userInfo.topAuthCode,]
            ])
        }
    }
    
    //    MARK:  退出登陆
    public func loginOut(call : FlutterMethodCall , result : @escaping FlutterResult){
        if qdStarting { finishQd(code: "CANCELLED", message: "渠道授权已取消", data: nil) }
        qdWebView?.cancel()
        ALBBSDK.sharedInstance()?.logout()
    }
    
    //        MARK:  淘客授权，拿token
    
    public func openByAsyncWebView(call: FlutterMethodCall, result : @escaping FlutterResult, callBackString: String){
        let rootViewController : UIViewController = UIApplication.shared.windows.last!.rootViewController!
        //            获取url
        let url : String = getStringFromCall(key: "url", call: call);
        
        //            设置showParams
        let showParams = AlibcTradeShowParams.init()
        showParams.backUrl =  getStringFromCall(key: "backUrl", call: call)
        showParams.isNeedPush = true
        showParams.isNeedCustomNativeFailMode = getBoolFromCall(key: "isNeedCustomNativeFailMode", call: call)
        //            设置openType
        let tmpType : Int = (getNumberFromCall(key: "openType", call: call)).intValue;
        showParams.openType = self.openType(mode: tmpType)
        //            降级处理措施
        let failMode : Int = (getNumberFromCall(key: "nativeFailMode", call: call)).intValue;
        showParams.nativeFailMode =  NativeFailMode(mode: failMode)
        
        //            设置打开app
        let tmpSchemeType : Int = (getNumberFromCall(key: "schemeType", call: call)).intValue;
        showParams.linkKey = schemeType(mode: tmpSchemeType)
        //            设置taokeParams
        let taokeParam = getTaokeParams(call: call) ?? nil
        
        
        //            新建一个controller去承载
        let wkvc = AlibcWkWebView()
        //        wkvc.modalPresentationStyle = UIModalPresentationStyle.fullScreen
        wkvc.delegate = self
        if callBackString == FlutterAlibcConstKey.CallBackString.AlibcTaokeLogin.rawValue {
            wkvc.fuctionType = "token"
        }else{
            wkvc.fuctionType = "code"
        }
        
        let res : NSInteger = AlibcTradeSDK.sharedInstance().tradeService().open(byUrl: url, identity: "trade", webView: wkvc.webview, parentController: rootViewController, showParams: showParams, taoKeParams: taokeParam, trackParam: nil) { result in
            
        } tradeProcessFailedCallback: { error in
            
        }
        //        判断
        if res == 1 {
            let nav = UINavigationController.init(rootViewController: wkvc)
            
//            let doneBtn = UIButton(type: UIButton.ButtonType.system)
//            doneBtn.setTitle("完成", for: UIControl.State.normal)
//            doneBtn.addTarget(self, action: #selector(doneBtnAction), for: UIControl.Event.touchUpInside)
            //            self.navigationItem.rightBarButtonItem =  UIBarButtonItem(customView: doneBtn)
            
//            nav.navigationItem.leftBarButtonItem = UIBarButtonItem.init(customView:doneBtn);
            //            let item = UIBarButtonItem(title: "done", style: UIBarButtonItemStyle.Done, target: self, action: "done:");
            //            self.navigationItem.leftBarButtonItem = item;
            nav.modalPresentationStyle = UIModalPresentationStyle.fullScreen
            rootViewController.present(nav, animated: false) {
                
            };
        }
        
    }
    
    //    MARK: 通过url打开，包括h5唤起手机淘宝等
    public func openByUrl(call : FlutterMethodCall , result : @escaping FlutterResult, callBackString: String){
        let rootViewController : UIViewController = UIApplication.shared.windows.last!.rootViewController!
        //            获取url
        let url : String = getStringFromCall(key: "url", call: call);
        let showParams = AlibcTradeShowParams.init()
        showParams.backUrl =  getStringFromCall(key: "backUrl", call: call)
        showParams.isNeedPush = true
        showParams.isNeedCustomNativeFailMode = getBoolFromCall(key: "isNeedCustomNativeFailMode", call: call)
        //            设置openType
        let tmpType : Int = (getNumberFromCall(key: "openType", call: call)).intValue;
        showParams.openType = self.openType(mode: tmpType)
        //            降级处理措施
        let failMode : Int = (getNumberFromCall(key: "nativeFailMode", call: call)).intValue;
        showParams.nativeFailMode =  NativeFailMode(mode: failMode)
        
        //            设置打开app
        let tmpSchemeType : Int = (getNumberFromCall(key: "schemeType", call: call)).intValue;
        showParams.linkKey = schemeType(mode: tmpSchemeType)
        //            设置taokeParams
        let taokeParam = getTaokeParams(call: call) ?? nil
        
        let trackParam : Dictionary<String,Any>? = getDicFromCall(key: "trackParam", call: call) ?? nil
        //        let backUrl : String = getStringFromCall(key: "backUrl", call: call)
        
        AlibcTradeSDK.sharedInstance().tradeService()?.open(byUrl: url, identity: "trade", webView: nil, parentController: rootViewController, showParams: showParams, taoKeParams: taokeParam, trackParam: trackParam, tradeProcessSuccessCallback: { alibcTradeResult in
            //             交易成功，判断是付款成功还是加入购物车
            if alibcTradeResult?.result == AlibcTradeResultType.paySuccess {
                //                付款成功
                self.channel?.invokeMethod(callBackString, arguments: [
                    FlutterAlibcConstKey.ErrorCode:"0",
                    FlutterAlibcConstKey.ErrorMessage:"付款成功",
                    FlutterAlibcConstKey.Data:[
                        "type":0,
                        "paySuccessOrders":alibcTradeResult?.payResult?.paySuccessOrders as Any,
                        "payFailedOrders":alibcTradeResult?.payResult?.payFailedOrders as Any,
                    ]
                ])
            }else if alibcTradeResult?.result == AlibcTradeResultType.addCard {
                //                加入购物车
                self.channel?.invokeMethod(callBackString, arguments: [
                    FlutterAlibcConstKey.ErrorCode:"0",
                    FlutterAlibcConstKey.ErrorMessage:"加入购物车成功",
                    FlutterAlibcConstKey.Data:[
                        "type":1,
                    ]
                ]);
            }
        }, tradeProcessFailedCallback: { error in
            let dic = [FlutterAlibcConstKey.ErrorCode :String((error! as NSError).code) ,FlutterAlibcConstKey.ErrorMessage:error?.localizedDescription] as! Dictionary<String,String>
            self.channel?.invokeMethod(callBackString, arguments: [dic]);
        })
    }
    
    public func openItemDetail(call : FlutterMethodCall , result : @escaping FlutterResult, callBackString: String){
        let itemID : String = getStringFromCall(key: "itemID", call: call);
        let page = AlibcTradePageFactory.itemDetailPage(itemID)
        self.openPageByNewWay(page: page, bizcode: "detail", call: call, result: result, callBackString: callBackString)
    }
    
    public func openShop(call : FlutterMethodCall , result : @escaping FlutterResult, callBackString: String){
        let shopId : String = getStringFromCall(key: "shopId", call: call);
        let page = AlibcTradePageFactory.shopPage(shopId)
        self.openPageByNewWay(page: page, bizcode: "shop", call: call, result: result, callBackString: callBackString)
    }
    
    public func openCart(call : FlutterMethodCall , result : @escaping FlutterResult, callBackString: String){
        let page = AlibcTradePageFactory.myCartsPage()
        self.openPageByNewWay(page: page, bizcode: "cart", call: call, result: result, callBackString: callBackString)
    }
    
    public func syncForTaoke(call : FlutterMethodCall , result : @escaping FlutterResult){
        let isSync = getBoolFromCall(key: "isSync", call: call)
        AlibcTradeSDK.sharedInstance().setIsSyncForTaoke(isSync)
    }
    // 注意，新版本已经移除zfb，谨慎使用
    public func useAlipayNative(call : FlutterMethodCall , result : @escaping FlutterResult){
        let isNeed = getBoolFromCall(key: "isNeed", call: call)
        AlibcTradeSDK.sharedInstance().setShouldUseAlizfNative(isNeed)
    }
    
    //    MARK: - 私有方法
    //    MARK: - 转换
    //    MARK: 唤起类型
    private func openType(mode: Int) -> AlibcOpenType{
        var openType : AlibcOpenType = AlibcOpenType.auto
        switch mode {
        case 0:
            openType = AlibcOpenType.auto
            break
        case 1 :
            openType = AlibcOpenType.native
        default:
            break
        }
        return openType
    }
    //    MARK: 唤起端失败的策略转换
    private func NativeFailMode(mode: Int) -> AlibcNativeFailMode{
        var failType = AlibcNativeFailMode.jumpH5
        switch mode {
        case 0:
            failType = AlibcNativeFailMode.jumpH5
            break
        case 1 :
            failType = AlibcNativeFailMode.jumpDownloadPage
            break
        case 2 :
            failType = AlibcNativeFailMode.none
            break
        default:
            break
        }
        return failType
    }
    private func schemeType(mode: Int) -> String{
        var linkKey = "tmall"
        switch mode {
        case 0:
            linkKey = "tmall"
            break
        case 1 :
            linkKey = "taobao"
            break
        default:
            break
        }
        return linkKey
    }
    //    MARK: - 获取参数
    private func getStringFromCall(key:String,call : FlutterMethodCall) -> String{
        guard let result = (call.arguments as? Dictionary<String, Any>)?[key] as? String else {
            //            result(FlutterError(code: "参数异常", message: "参数url不能为空", details: nil))
            return ""
        }
        
        return result
    }
    private func getNumberFromCall(key:String,call : FlutterMethodCall) -> NSNumber{
        guard let result = (call.arguments as? Dictionary<String, Any>)?[key] as? NSNumber else {
            //            随便定个数字，如果没有，就是这个数字
            return FlutterAlibcConstKey.EmptyNum
        }
        return result
    }
    private func getBoolFromCall(key:String,call : FlutterMethodCall) -> Bool{
        guard let result = (call.arguments as? Dictionary<String, Any>)?[key] as? Bool else {
            return false
        }
        return result
    }
    
    private func getDicFromCall(key:String,call : FlutterMethodCall) -> Dictionary<String, Any>?{
        guard let result = (call.arguments as? Dictionary<String, Any>)?[key] as? Dictionary<String, Any> else {
            return nil
        }
        return result
    }
    
    //    MARK: - 设置淘客参数
    private func getTaokeParams(call : FlutterMethodCall) -> AlibcTradeTaokeParams?{
        let taoke : AlibcTradeTaokeParams = AlibcTradeTaokeParams.init()
        if getDicFromCall(key: "taoKeParams", call: call) == nil {
            return nil
        }
        let taokeParams = getDicFromCall(key: "taoKeParams", call: call)
        //        taoke.adzoneId =
        taoke.adzoneId = (taokeParams!["adzoneId"] is NSNull) ? nil : taokeParams!["adzoneId"] as? String
        taoke.pid = (taokeParams!["pid"] is NSNull) ? nil : taokeParams!["pid"] as? String
        taoke.unionId = (taokeParams!["unionId"] is NSNull) ? nil : taokeParams!["unionId"] as? String
        taoke.subPid = (taokeParams!["subPid"] is NSNull) ? nil : taokeParams!["subPid"] as? String
        taoke.extParams = (taokeParams!["extParams"] is NSNull) ? nil : taokeParams!["extParams"] as? [AnyHashable : Any]
        
        //    判断这玩意是什么格式，dic就直接赋值，jsoÏn需要转dic
        //    if ([extParams isKindOfClass:[NSDictionary class]]) {
        //        taoke.extParams = extParams;
        //    }else{
        //        解析字符串
        //        taoke.extParams = [FlutterAlibcTools dictionaryWithJsonString:extParams];
        //    }
        
        return taoke
        
    }
    private func isNil(){
        
    }
    
    //     MARK: - 不对flutter暴露
    //     MARK: 打开page
    private func openPageByNewWay(page:AlibcTradePage, bizcode:String, call : FlutterMethodCall , result : @escaping FlutterResult, callBackString: String){
        let rootViewController : UIViewController = UIApplication.shared.windows.last!.rootViewController!
        
        let showParams = AlibcTradeShowParams.init()
        showParams.backUrl =  getStringFromCall(key: "backUrl", call: call)
        showParams.isNeedPush = true
        showParams.isNeedCustomNativeFailMode = getBoolFromCall(key: "isNeedCustomNativeFailMode", call: call)
        //            设置openType
        let tmpType : Int = (getNumberFromCall(key: "openType", call: call)).intValue;
        showParams.openType = self.openType(mode: tmpType)
        //            降级处理措施
        let failMode : Int = (getNumberFromCall(key: "nativeFailMode", call: call)).intValue;
        showParams.nativeFailMode =  NativeFailMode(mode: failMode)
        
        //            设置打开app
        let tmpSchemeType : Int = (getNumberFromCall(key: "schemeType", call: call)).intValue;
        showParams.linkKey = schemeType(mode: tmpSchemeType)
        //            设置taokeParams
        let taokeParam = getTaokeParams(call: call) ?? nil
        
        let trackParam : Dictionary<String,Any>? = getDicFromCall(key: "trackParam", call: call) ?? nil
        
        AlibcTradeSDK.sharedInstance().tradeService().open(byBizCode: bizcode, page: page, webView: nil, parentController: rootViewController, showParams: showParams, taoKeParams: taokeParam, trackParam: trackParam) { alibcTradeResult in
            //             交易成功，判断是付款成功还是加入购物车
            if alibcTradeResult?.result == AlibcTradeResultType.paySuccess {
                //                付款成功
                self.channel?.invokeMethod(callBackString, arguments: [
                    FlutterAlibcConstKey.ErrorCode:"0",
                    FlutterAlibcConstKey.ErrorMessage:"付款成功",
                    FlutterAlibcConstKey.Data:[
                        "type":0,
                        "paySuccessOrders":alibcTradeResult?.payResult?.paySuccessOrders as Any,
                        "payFailedOrders":alibcTradeResult?.payResult?.payFailedOrders as Any,
                    ]
                ]);
            }else if alibcTradeResult?.result == AlibcTradeResultType.addCard {
                //                加入购物车
                self.channel?.invokeMethod(callBackString, arguments: [
                    FlutterAlibcConstKey.ErrorCode:"0",
                    FlutterAlibcConstKey.ErrorMessage:"加入购物车成功",
                    FlutterAlibcConstKey.Data:[
                        "type":1,
                    ]
                ]);
            }
        } tradeProcessFailedCallback: { error in
            //            退出交易流程
            //            Android没有orderIdList，所以去掉
            let dic = [FlutterAlibcConstKey.ErrorCode :String((error! as NSError).code) ,FlutterAlibcConstKey.ErrorMessage:error?.localizedDescription] as! Dictionary<String,String>
            self.channel?.invokeMethod(callBackString, arguments: [dic]);
        }
        
        
    }

}


/**
 可设置的参数
 1.是否同步淘客打点
 2.是否使用Native支付宝
 3.是否使用淘客参数（是，需要设置如下参数）
 adzoneId
 pid
 //有adzoneId则pid失效
 unionId
 subPid
 extParams{
 sellerId
 taokeAppkey
 }
 4.页面打开方式
 是否唤端 Auto/Native
 唤起目标应用 淘宝/天猫
 是否以push的方式打开页面
 是否绑定webview
 是否自定义唤端失败策略（若是：H5，DownLoad，None）
 5.跟踪参数 customParams自定义
 */
