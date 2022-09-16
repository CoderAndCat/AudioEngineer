//
//  WebMessageHandle.swift
//  AudioEngineerPractice
//
//  Created by 武文龙 on 2022/7/13.
//

import Foundation
import WebKit
protocol JKSWebScriptHandleDelegate: AnyObject {
    /// 乐谱渲染结束回调
    func receiveWebScoreRenderEnd()
    
    func loadScoreError()
}
class JKSWebMessageHandle: NSObject, WKScriptMessageHandler {
    
    /// web 的显示游标接口
    let webApiShowCursorImg = "showCursorImg();"
    /// web 的下一个音符接口
    let webApiScrollTo = "scrollTo();"
    
    /// 获取所有 note 音符的数字
    let webApiQueryNotes = "queryAllNotes();"
    ///获取所有 音符及对应的 五线谱唱名，简谱唱名 [{note:"音符符号",sing:"五线谱唱名",noteFlag:"简谱唱名"}]
    let webApiQueryNotesAndChangMing = "queryAllNotesWithSing();"
    /// 获取所有音符 数据
    let webApiQueryAllNotesModel = "getScoreData();"
    
    /// web 显示五线谱接口
    let webApiShowScore = "showStaffScoreMode();"
    /// web 显示简谱接口
    let webApiShowNumScore = "showNumberScoreMode();"
    /// web 重录
    let webApiReRecord = "reRecord();"
    /// web 自动播放
    let webApiAutoScrollPlay = "sheetMusic();"
    /// web 乐谱暂停播放
    let webApiAutoScrollPause = "pausePlayback();"
    /// web 乐谱继续播放
    let webApiAutoScrollResumePlaying = "resumePlaying();"
    
    let noteKey = "note"
    let wxChangMingKey = "sing"
    let jpChangMingKey = "noteFlag"
    let noteAfterTransposeKey = "transposeNote"
    
    
    
    
    /// 获取速度和拍号 {"bpm":90, "numerator":4, "denominator": 4} numerator:分子 denominator:分母
    let webApiQueryTempoAndTimeSignatures = "queryFirstInstsument();"
    let bpmKey = "bpm"
    let timeSignaltureNumeratorKey = "numerator"
    let timeSignaltureDenominatorKey = "denominator"
    
    /// web渲染完成后 回调
    let nativeApiRenderScoreEnd = "renderScoreEnd"
    /// web 拉取乐谱完成，开始渲染
    let nativeApiRenderScoreStart = "renderScoreStart"
    /// web 资源文件失败
    let nativeApiLoadResourceError = "loadResourceError"
    /// web 加载文件成功，将结果 文本回传
    let nativeApiLoadResourceSuccess = "loadResourceSuccess"
    /// web 传输 log
    let nativeApiPrintLog = "printLog"

    weak var delegate: JKSWebScriptHandleDelegate?
    
    
    
    /// 加载本地或远程musicxml文件 ,参数为 资源地址  scoreType: 乐谱类型 0: 五线谱 1:简谱
    func getWebApiLoadResourcesWithParam(url: String, scoreType: Int) ->String{
        return "loadResource(\"\(url)\", \(scoreType));"
    }
    
    func getWebApiRenderMusicxmlStr(musicxmlStr: String) ->String{
        return "renderQuickStartmusicxml('\n\(musicxmlStr)\n');"
    }
    /// 获取web 倍速设置API
    func getWebApiSetSpeed(speedNum: Double) ->String{
        return "setDoubleSpeed(\(speedNum))"
    }
    /// 获取 web 时间同步音符的 API
    func getWebApiWith(noteId: Int) ->String{
        return "timeProofreading(\(noteId))"
    }
    //MARK: - WKScriptMessageHandler
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == nativeApiRenderScoreEnd {
            debugPrint("----- 乐谱 渲染完成------")
            delegate?.receiveWebScoreRenderEnd()
        }else if message.name == nativeApiLoadResourceError{
            debugPrint("----- 乐谱 webView 加载乐谱 出错------")
            delegate?.loadScoreError()
        }else if message.name == nativeApiRenderScoreStart{
            debugPrint("----- 乐谱 webView 加载乐谱数据结束开始渲染------")
        }else if message.name == nativeApiLoadResourceSuccess{
            guard let scoreStr = message.body as? String else{
                debugPrint("----- 乐谱加载完成，回调数据出错")
                return
            }
            debugPrint("----- 乐谱加载完成，乐谱数据length: \(scoreStr.count)")
        }else if message.name == nativeApiPrintLog {
            guard let logStr = message.body as? String else{
                debugPrint("---- 乐谱回调 打印log，解析log 内容出错")
                return
            }
            debugPrint("---- 乐谱回调 打印log：\(logStr)")
        }else{
            debugPrint("------ 收到 web js 发来的未处理消息 \(message.name)")
        }
    }

    
    /// 线上曲目 乐谱滚动函数 colorType ： 音符演奏评级 （perfect、great、good、pass）
    func getWebApiScrollToInServerBank(colorType: String, dura: Double?) ->String{
        if let dura = dura {
            return "scrollTo(\"\(colorType)\",\(dura));"
        }else{
            return "scrollTo(\"\(colorType)\");"
        }
    }
    
}
