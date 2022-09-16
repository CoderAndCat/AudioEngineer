//
//  WebViewTestViewController.swift
//  AudioEngineerPractice
//
//  Created by 武文龙 on 2022/7/13.
//

import UIKit
import WebKit
import AVFAudio

class WebViewTestViewController: UIViewController {
    static let robkooTaoBaoMainPage = "tbopen://shop.m.taobao.com/shop/shop_index.htm?shop_id=410102616 "
    
    private var mainWebview: WKWebView?
    
    private let webMessageHandle: JKSWebMessageHandle = JKSWebMessageHandle()

    private var xmlUrl: String?
    
    private var audioPlayer: AVAudioPlayer?
    
    private let playerBtn = UIButton.init(type: .custom)
    
    /// 重新加载乐谱按钮
    lazy private var reloadScoreBtn: UIButton = {
        let tmpbtn = UIButton.init(frame: .zero)
        let titl = NSLocalizedString("network_reload", comment: "Reload")
        tmpbtn.setTitle(titl, for: .normal)
        tmpbtn.setTitle(titl, for: .highlighted)
        tmpbtn.setTitleColor(UIColor(red: 51/255.0, green: 51/255.0, blue: 51/255.0, alpha: 1), for: .normal)
        tmpbtn.setTitleColor(UIColor(red: 51/255.0, green: 51/255.0, blue: 51/255.0, alpha: 1), for: .highlighted)
        tmpbtn.layer.masksToBounds = true
        tmpbtn.layer.cornerRadius = 5
        tmpbtn.contentEdgeInsets = UIEdgeInsets.init(top: 5, left: 10, bottom: 5, right: 10)
        tmpbtn.layer.borderColor = UIColor(red: 51/255.0, green: 51/255.0, blue: 51/255.0, alpha: 1).cgColor
        tmpbtn.layer.borderWidth = 1
        tmpbtn.backgroundColor = UIColor.clear
        tmpbtn.addTarget(self, action: #selector(reloadScoreWeb), for: .touchUpInside)
        return tmpbtn
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        makeData()
        setupUI()
//        addJsForWeb()
//        loadHtml()
        loadHtmlContainSchemeToTaoBao()
        // Do any additional setup after loading the view.
    }
    
    //MARK: - Private
    private func makeData() {
        if let audioFileUrl = Bundle.main.url(forResource: "JiuEr", withExtension: "mp3") {
            self.audioPlayer = try! AVAudioPlayer.init(contentsOf: audioFileUrl)
        }else{
            debugPrint("---- 音频 或 xml 读取失败----")
        }
        
        /// 读取本地 xml 文件
        let homePath = NSHomeDirectory()
        let homeUrl = URL(fileURLWithPath: homePath, isDirectory: true)
        let xmlFileUrl = homeUrl.appendingPathComponent("Documents").appendingPathComponent("Download").appendingPathComponent("SerBankResource").appendingPathComponent("resource").appendingPathComponent("WJ").appendingPathExtension("xml")
        debugPrint("----xml文件 URL 地址：\(xmlFileUrl),\n-- absoluStr:\(xmlFileUrl.absoluteString),\n path: \(xmlFileUrl.path), \n relativePath:\(xmlFileUrl.relativePath)")
        self.xmlUrl = xmlFileUrl.relativePath
        
        
        
    }
    
    
    private func setupUI() {
        let config = WKWebViewConfiguration()
        let userContent = WKUserContentController()
        
        config.userContentController = userContent
        self.mainWebview = WKWebView(frame: self.view.bounds, configuration: config)
        self.mainWebview!.uiDelegate = self
        self.mainWebview!.navigationDelegate = self
        self.view.addSubview(self.mainWebview!)
        
        self.playerBtn.setTitle("", for: .normal)
        self.playerBtn.setTitle("", for: .highlighted)
        self.playerBtn.setTitle("", for: .selected)
        self.playerBtn.setImage(UIImage(named: "audioPlayer_player"), for: .normal)
        self.playerBtn.setImage(UIImage(named: "audioPlayer_player"), for: .highlighted)
        self.playerBtn.setImage(UIImage(named: "audioPlayer_pause"), for: .selected)
        self.view.addSubview(self.playerBtn)
        
        setConstants()
    }
    private func addJsForWeb() {
        guard let mainWebview = mainWebview else {
            return
        }
        
        let userContent = mainWebview.configuration.userContentController
        /// 获取本地JS文件 注入到WebView 中
        let homePath = NSHomeDirectory()
        if var homeUrl = URL(string: homePath) {
            homeUrl.appendPathComponent("Documents")
            homeUrl.appendPathComponent("Download")
            homeUrl.appendPathComponent("SerBankResource")
            let jsFileUrl = homeUrl.appendingPathComponent("js")
            
            
//            let fm = FileManager.default
//            if let jsDirEnum = fm.enumerator(atPath: jsFileUrl.path) {
//                for subPath in jsDirEnum.allObjects {
//                    if let subPathStr = subPath as? String {
//                        let subUrl = jsFileUrl.appendingPathComponent(subPathStr)
//                        if fm.fileExists(atPath: subUrl.path) {
//                            let fileData = try! Data(contentsOf: URL(fileURLWithPath: subUrl.path))
//                            debugPrint("----- js文件夹 子文件 :\(subUrl.path)")
//                            
//                        }
//                    }
//                }
//            }
            
            
            
            
            
            let httpJsUrl = jsFileUrl.appendingPathComponent("http").appendingPathExtension("js")
//            debugPrint("--------- httpjsUrl:\(httpJsUrl), path:\(httpJsUrl.path)")
            if FileManager.default.fileExists(atPath: httpJsUrl.path)  {
                do {
                    let httpJsUrlFPUrl = URL(fileURLWithPath: httpJsUrl.path)
                    
                    let htJsData = try Data.init(contentsOf: httpJsUrlFPUrl, options: .mappedIfSafe)
                    if let htJsStr = String(data: htJsData, encoding: .utf8) {
                        // 脚本注入时机，及是否注入主框架
                        let htJsUserScript = WKUserScript(source: htJsStr, injectionTime: .atDocumentStart, forMainFrameOnly: true)
                        userContent.addUserScript(htJsUserScript)
                        debugPrint("----js文件已注入URL：\(httpJsUrlFPUrl), path:\(httpJsUrlFPUrl.path)")
                    }else{
                        debugPrint("----- js文件 转换出错：\(httpJsUrl.path)")
                    }
                } catch let eroe {
                    debugPrint("---- 读取 js 文件出错:\(eroe.localizedDescription)")
                }
                
            }else{
                debugPrint("---- someError, 糟糕透顶不是URL:\(httpJsUrl.path)")
            }
            let renderNumScoresJsUrl = jsFileUrl.appendingPathComponent("renderNumberScore").appendingPathExtension("js")
            if FileManager.default.fileExists(atPath: renderNumScoresJsUrl.path)  {
                let renderNumScoresJsUrlFPUrl = URL(fileURLWithPath: renderNumScoresJsUrl.path)
                let renderNumScoresJsdata = try! Data.init(contentsOf: renderNumScoresJsUrlFPUrl)
                if let renderNumScoresJsStr = String(data: renderNumScoresJsdata, encoding: .utf8) {
                    // 脚本注入时机，及是否注入主框架
                    let renderNumScoresJsUserScript = WKUserScript(source: renderNumScoresJsStr, injectionTime: .atDocumentStart, forMainFrameOnly: true)
                    userContent.addUserScript(renderNumScoresJsUserScript)
                    debugPrint("----js文件已注入：\(renderNumScoresJsUrl)")
                }else{
                    debugPrint("----- js文件 转换出错：\(renderNumScoresJsUrl)")
                }
            }
            let hammer_miniJsUrl = jsFileUrl.appendingPathComponent("hammer.mini").appendingPathExtension("js")
            if FileManager.default.fileExists(atPath: hammer_miniJsUrl.path){
                let hammer_miniJsUrlFPUrl = URL(fileURLWithPath: renderNumScoresJsUrl.path)
                let hammer_miniJsdata = try! Data.init(contentsOf: hammer_miniJsUrlFPUrl)
                if let hammer_miniJsStr = String(data: hammer_miniJsdata, encoding: .utf8) {
                    // 脚本注入时机，及是否注入主框架
                    let hammer_miniJsUserScript = WKUserScript(source: hammer_miniJsStr, injectionTime: .atDocumentStart, forMainFrameOnly: true)
                    userContent.addUserScript(hammer_miniJsUserScript)
                    debugPrint("----js文件已注入：\(hammer_miniJsUrl)")
                }else{
                    debugPrint("----- js文件 转换出错：\(hammer_miniJsUrl)")
                }
            }
            let OsmdAudioPlayer_minJsUrl = jsFileUrl.appendingPathComponent("OsmdAudioPlayer.min").appendingPathExtension("js")
            if FileManager.default.fileExists(atPath: OsmdAudioPlayer_minJsUrl.path){
                let OsmdAudioPlayer_minJsUrlFPUrl = URL(fileURLWithPath: OsmdAudioPlayer_minJsUrl.path)
                let OsmdAudioPlayer_minJsdata = try! Data.init(contentsOf: OsmdAudioPlayer_minJsUrlFPUrl)
                if let OsmdAudioPlayer_minJsStr = String(data: OsmdAudioPlayer_minJsdata, encoding: .utf8) {
                    // 脚本注入时机，及是否注入主框架
                    let OsmdAudioPlayer_minJsUserScript = WKUserScript(source: OsmdAudioPlayer_minJsStr, injectionTime: .atDocumentStart, forMainFrameOnly: true)
                    userContent.addUserScript(OsmdAudioPlayer_minJsUserScript)
                    debugPrint("----js文件已注入：\(OsmdAudioPlayer_minJsUrl)")
                }else{
                    debugPrint("----- js文件 转换出错：\(OsmdAudioPlayer_minJsUrl)")
                }
            }
            let opensheetmusicdisplay_minJsUrl = jsFileUrl.appendingPathComponent("opensheetmusicdisplay.min").appendingPathExtension("js")
            if FileManager.default.fileExists(atPath: opensheetmusicdisplay_minJsUrl.path){
                let opensheetmusicdisplay_minJsUrlFPUrl = URL(fileURLWithPath: opensheetmusicdisplay_minJsUrl.path)
                let opensheetmusicdisplay_minJsdata = try! Data.init(contentsOf: opensheetmusicdisplay_minJsUrlFPUrl)
                if let opensheetmusicdisplay_minJsStr = String(data: opensheetmusicdisplay_minJsdata, encoding: .utf8) {
                    // 脚本注入时机，及是否注入主框架
                    let opensheetmusicdisplay_minJsUserScript = WKUserScript(source: opensheetmusicdisplay_minJsStr, injectionTime: .atDocumentStart, forMainFrameOnly: true)
                    userContent.addUserScript(opensheetmusicdisplay_minJsUserScript)
                    debugPrint("----js文件已注入：\(opensheetmusicdisplay_minJsUrl)")
                }else{
                    debugPrint("----- js文件 转换出错：\(opensheetmusicdisplay_minJsUrl)")
                }
            }
            let renderScoreJsUrl = jsFileUrl.appendingPathComponent("renderScore").appendingPathExtension("js")
            if FileManager.default.fileExists(atPath: renderScoreJsUrl.path){
                let renderScoreJsUrlFPUrl = URL(fileURLWithPath: renderScoreJsUrl.path)
                let renderScoreJsdata = try! Data.init(contentsOf: renderScoreJsUrlFPUrl)
                if let renderScoreJsStr = String(data: renderScoreJsdata, encoding: .utf8) {
                    // 脚本注入时机，及是否注入主框架
                    let renderScoreJsUserScript = WKUserScript(source: renderScoreJsStr, injectionTime: .atDocumentStart, forMainFrameOnly: true)
                    userContent.addUserScript(renderScoreJsUserScript)
                    debugPrint("----js文件已注入：\(renderScoreJsUrl)")
                }else{
                    debugPrint("----- js文件 转换出错：\(renderScoreJsUrl)")
                }
            }
            let jquery_360_minJsUrl = jsFileUrl.appendingPathComponent("jquery-3.6.0.min").appendingPathExtension("js")
            if FileManager.default.fileExists(atPath: jquery_360_minJsUrl.path){
                let jquery_360_minJsUrlFPUrl = URL(fileURLWithPath: jquery_360_minJsUrl.path)
                let jquery_360_minJsdata = try! Data.init(contentsOf: jquery_360_minJsUrlFPUrl)
                if let jquery_360_minJsStr = String(data: jquery_360_minJsdata, encoding: .utf8) {
                    // 脚本注入时机，及是否注入主框架
                    let jquery_360_minJsUserScript = WKUserScript(source: jquery_360_minJsStr, injectionTime: .atDocumentStart, forMainFrameOnly: true)
                    userContent.addUserScript(jquery_360_minJsUserScript)
                    debugPrint("----js文件已注入：\(jquery_360_minJsUrl)")
                }else{
                    debugPrint("----- js文件 转换出错：\(jquery_360_minJsUrl)")
                }
            }
            
        }
        
    }
    private func setConstants() {
        guard let mainWebview = mainWebview else {
            return
        }

        mainWebview.translatesAutoresizingMaskIntoConstraints = false
        mainWebview.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 60).isActive = true
        mainWebview.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        mainWebview.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        mainWebview.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        
//        self.playerBtn.translatesAutoresizingMaskIntoConstraints = false
//        self.playerBtn.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
//        self.playerBtn.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
//        self.playerBtn.widthAnchor.constraint(equalTo: 60).isActive = true
//        self.playerBtn.
        
    }
    private func loadHtml() {
        
        let homeDir = NSHomeDirectory()
        debugPrint("---- homeDir: \(homeDir)")
        if var homeDirUrl = URL.init(string: homeDir) {
            homeDirUrl.appendPathComponent("Documents")
            homeDirUrl.appendPathComponent("Download")
            homeDirUrl.appendPathComponent("SerBankResource")
            homeDirUrl.appendPathComponent("html")
            homeDirUrl.appendPathComponent("renderMultiSwitchScore")
            homeDirUrl.appendPathExtension("html")
            if FileManager.default.fileExists(atPath: homeDirUrl.path) {
                debugPrint("--- 已读取到手动拖入 Document 路径的文件：\(homeDirUrl.path)")
            }else{
                debugPrint("--- 未读取到手动拖入 Document 路径的文件：\(homeDirUrl.path)")
            }
            let urlReq = URLRequest.init(url: URL(fileURLWithPath: homeDirUrl.path))
            guard let mainWebview = mainWebview else {
                return
            }
            mainWebview.load(urlReq)
        }
        
        
        
    }
    /// 测试跳转淘宝 app 连接
    func loadHtmlContainSchemeToTaoBao() {
        let urlReq = URLRequest.init(url: URL(string: "https://mp.weixin.qq.com/s?__biz=MzAxODM5OTkwNg==&tempkey=MTE3OV9SYkZCc3hGNXVJUzdUTkgxNXF3WUtaM2Q4Ym5KMnB1QUVibnRjRmZ5N2pZSHVfMXdBZE1xNmVZX2JXWmJhRGdpdTV5M3hGN084U3pMSnVWVlpsN21lOGlGWjVnT1JYMEgzQWNoVHctN1FjeGhxbnZHUzVFNGJnSHhqNFdUTVZYN1hrX3lFZTNPVXR5ZXliX2VEdV9VVFdLSEo4X0t3Q3ZnSVk4bW1Rfn4%3D&chksm=1bd7829c2ca00b8a2db354545e3d5c6efbb53cc393d3b39cf6c3c592f577cb38f797b3bc6ddb&mpshare=1&scene=1&srcid=0822LbZwLo3wJKi84va6kadn&sharer_sharetime=1661156743829&sharer_shareid=de7f411d40261ae26587957a01d6b657&version=4.0.12.99158&platform=mac#rd")!)

        mainWebview!.load(urlReq)
        return
        if let taoBaohtmlPath = Bundle.main.path(forResource: "testSchemeInApp", ofType: "html") {
            mainWebview!.loadFileURL(URL.init(fileURLWithPath: taoBaohtmlPath), allowingReadAccessTo: URL.init(fileURLWithPath: taoBaohtmlPath))
        }
    }
    
    //MARK: - Action
    @objc private func reloadScoreWeb() {
        self.mainWebview?.reload()
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}


extension WebViewTestViewController: WKUIDelegate, WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        debugPrint("EWI QuickStart Score loadFail--\(error.localizedDescription)")
    }
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        debugPrint(error.localizedDescription)
    }
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        debugPrint("----- webHtml 加载完成，继续加载的 musicxml 地址：../resource/WJ.xml，type: \(1)")
        if self.reloadScoreBtn.superview != nil {
            self.reloadScoreBtn.removeFromSuperview()
        }
        
//        self.mainWebview?.evaluateJavaScript(self.webMessageHandle.getWebApiLoadResourcesWithParam(url: "../resource/WJ.xml", scoreType: 1), completionHandler: {some, erro in
//            if let haser = erro {
//                debugPrint("--- wkwebView evaluate JS error:\(haser)")
//            }
//        })
        
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let tgUrl = navigationAction.request.url {
            var resUrl = tgUrl
            var tgUrlStr = tgUrl.absoluteString
            let taoBaoSchemes = "tbopen://"
            let tmallSchemes = "tmall://"
            
            debugPrint("===== webView 要打开的 URL:\(tgUrl.absoluteString)")
            if let tabBaoSubRange = tgUrlStr.range(of: "taobao://"){
                // 淘宝的跳转链接 找到其中的商品id
                tgUrlStr.replaceSubrange(tabBaoSubRange, with: taoBaoSchemes)
                guard let resUrl1 = URL(string: tgUrlStr) else{
                    debugPrint("----- 跳转淘宝连接出错----")
                    return
                }
                resUrl = resUrl1
            }
            
            if resUrl.scheme == "tbopen" || resUrl.scheme == "tmall" {
                debugPrint("------- resUrlAbsPath = \(resUrl.absoluteString)")
                UIApplication.shared.open(tgUrl)
            }else if tgUrl.absoluteString.contains("m.tb.cn") {
                // 含有淘宝的 http 和https 链接 直接跳浏览器
                if let staticResUrl = URL.init(string: Self.robkooTaoBaoMainPage) {
                    UIApplication.shared.open(staticResUrl)
                    debugPrint("---- 直接跳 设备浏览器 地址：\(Self.robkooTaoBaoMainPage)")
                }
            }else{
                debugPrint("----- Schemes 打开失败：\(String(describing: resUrl.scheme))")
            }
        }
        decisionHandler(WKNavigationActionPolicy.allow)
            
    }
    
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        debugPrint("---- webview 弹窗: \(message)")
        completionHandler()
    }
    
    func receiveWebScoreRenderEnd() {
        if self.reloadScoreBtn.superview != nil {
            self.reloadScoreBtn.removeFromSuperview()
        }
    }
    
    
    func loadScoreError() {
        self.mainWebview?.addSubview(self.reloadScoreBtn)
        self.reloadScoreBtn.snp.remakeConstraints { make in
            make.center.equalToSuperview()
        }
    }
    
    
}
