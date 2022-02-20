//
//  AudioUnitParcViewController.swift
//  AudioEngineerPractice
//
//  Created by 武文龙 on 2022/2/20.
//

import UIKit
import AVFAudio

// https://juejin.cn/post/6980729874931515399#heading-27
// https://stackoverflow.com/questions/63213753/ios-audio-units-connecting-with-graphs

class AudioUnitParcViewController: UIViewController {
    /// 全局通用的采样率
    var graphSampleRate: Double = 44100.0
    /// 输入输出 延迟 ms
    let ioBufferDuration: Double = 0.005
    
    /// 输入输出的音频单元
    var audioUnit: AVAudioUnit?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpAudioSession()
    }


    func setUpAudioSession() {
        let aseesion = AVAudioSession.sharedInstance()
        do {
            /* 配置 AVAudioSession**/
            try aseesion.setPreferredSampleRate(graphSampleRate)
            try aseesion.setCategory(.playAndRecord)
            try aseesion.setActive(true, options: AVAudioSession.SetActiveOptions.notifyOthersOnDeactivation)
            self.graphSampleRate = aseesion.sampleRate
            
            
            // 通过设置延迟，来控制 buffer 大小
            /**
             * 音频硬件 I/O buffer 时间。在44.1 kHz采样率下，默认持续时间约为23毫秒，相当于1024个采样的片大小。如果I/O延迟在你的应用中非常重要，你可以请求一个更短的持续时间，降低到 0.005毫秒 (相当于256个样本)
             */
            try aseesion.setPreferredIOBufferDuration(self.ioBufferDuration)
            
            
            
            
            
            
            /* 获取音频单元(连接到设备硬件以进行输入、输出或同时输入和输出。) 也可以使用 0 作为通配符，来获取一个音频单元集**/
            
            var ioUnitDescription = AudioComponentDescription.init(componentType: kAudioUnitType_Output, componentSubType: kAudioUnitSubType_RemoteIO, componentManufacturer: kAudioUnitManufacturer_Apple, componentFlags: 0, componentFlagsMask: 0)
            
            
            // 一种不推荐的获取 音频单元的方法
//            var ioUnitInstance: AudioUnit?
//            if let foundIoUnitReference = AudioComponentFindNext(nil, &ioUnitDescription) {
//
//                AudioComponentInstanceNew(foundIoUnitReference, &ioUnitInstance)
//            }else{
//                debugPrint("---- 音频单元获取出错")
//                return
//            }
            
            //推荐获取音频单元的方法
            var components = [AVAudioUnitComponent]()
            components = AVAudioUnitComponentManager.shared().components(matching: ioUnitDescription)
            debugPrint("---- 获取指定类型的音频单元 数组 \(components.count) 个")
            if let firstAudioUnit = components.first {
                ioUnitDescription = firstAudioUnit.audioComponentDescription
                
                AVAudioUnit.instantiate(with: ioUnitDescription) { audioUnitOption, eorr in
                    if let er = eorr {
                        debugPrint("---- 音频单元实例化出错-- \(er.localizedDescription)")
                    }
                    
                    if let audioUnitt = audioUnitOption {
                        debugPrint("------ 拿到了音频单元")
                        self.audioUnit = audioUnitt
                    }
                }
            
            }
            
            
            
        } catch let error {
            debugPrint("配置 AudioSession 出错 \(error.localizedDescription)")
        }
        
        
    }
}
