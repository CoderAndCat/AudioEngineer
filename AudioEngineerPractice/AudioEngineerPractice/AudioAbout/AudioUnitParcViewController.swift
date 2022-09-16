//
//  AudioUnitParcViewController.swift
//  AudioEngineerPractice
//
//  Created by 武文龙 on 2022/2/20.
//

import UIKit
import AVFAudio


class AudioUnitParcViewController: UIViewController {
    /// 全局通用的采样率
    var graphSampleRate: Double = 44100.0
    /// 输入输出 延迟 s
    let ioBufferDuration: Double = 0.005
    /// 在 0.005 的延迟下 样本数量
    let ioBufferSampleCount: UInt32 = 256
    
    let audioEngineer = AVAudioEngine.init()
    
    
    /// 混响效果器
    let reverb = AVAudioUnitReverb.init()
    
    let player = JKSAudioEnginePlayer.init()
    /// 播放器的下个节点
    let playerMix = AVAudioMixerNode.init()
    /// 音频输入的混音节点
    let inputEndMix = AVAudioMixerNode()
    /// 音频格式转换
    let audioConver = AVAudioConverter.init()
    /// 音频 pcm 录制文件
    var audioRecordFile: AVAudioFile?
    /// 音频 pcm 录制文件的 句柄
//    var audioRecordFileHandle: FileHandle?
    /// 是否正在录制
    var recording = false
    /// 录制时长 ms
    var recordDuration: Int = 0
    /// 伴奏播放计时器
    var accomTimer: Timer?
    
    private lazy var outputFormat = {
        return self.audioEngineer.outputNode.inputFormat(forBus: 0)
    }()
    
    
    @IBOutlet weak var accomProgressSlider: UISlider!
    
    
    
    override func viewDidLoad() {

        super.viewDidLoad()
        setAuduiSession()
        configAudioNode()
        
       
    }

    func setAuduiSession() {
        let aseesion = AVAudioSession.sharedInstance()
        do {
            try aseesion.setPreferredSampleRate(graphSampleRate)
            let samrate = aseesion.preferredSampleRate
            try aseesion.overrideOutputAudioPort(.none)
            try aseesion.setCategory(.playAndRecord, options: [.allowBluetooth, .allowBluetoothA2DP])
            // 1.通过设置延迟，来控制 buffer 大小
            /**
             * 音频硬件 I/O buffer 时间。在44.1 kHz采样率下，默认持续时间约为23毫秒，相当于1024个采样的片大小。如果I/O延迟在你的应用中非常重要，你可以请求一个更短的持续时间，降低到 0.005毫秒 (相当于256个样本)
             */
            try aseesion.setPreferredIOBufferDuration(self.ioBufferDuration)
            debugPrint("----- 音频 IO buffer 延迟设置--：\(aseesion.preferredIOBufferDuration)秒 采样率：\(samrate)")
            
            try aseesion.setPreferredOutputNumberOfChannels(1)
            debugPrint("----- 音频通道 输出设置结果：\(aseesion.preferredOutputNumberOfChannels)")
            
//            try aseesion.setPreferredInputNumberOfChannels(1)
//            debugPrint("----- 音频通道 输入设置结果：\(aseesion.preferredInputNumberOfChannels)")
            
            try aseesion.setActive(true, options: .notifyOthersOnDeactivation)
            self.graphSampleRate = aseesion.sampleRate
        }catch let erroro {
            debugPrint("--- AudioSession 设置出错\(erroro.localizedDescription)")
        }
    }
    
    func configAudioNode() {
//        self.reverb.loadFactoryPreset(.largeRoom2)
        // 0->100
//        self.reverb.wetDryMix = 100
        
//        let format = audioEngineer.inputNode.outputFormat(forBus: 0)
//        debugPrint("------ inputNode formatSetting:\(format)")
        
//        let wantFormat = AppleSamplerTestViewController.audioEngineNodeOutputFormat()!
        
        
        //把混响附着到音频引擎
//        self.audioEngineer.attach(self.reverb)
        self.audioEngineer.attach(self.player)
        self.audioEngineer.attach(self.playerMix)
//        self.audioEngineer.attach(self.inputEndMix)
        // 一次链接 输入-> 混响 -> 输出
//        self.audioEngineer.connect(self.audioEngineer.inputNode, to: reverb, format: format)
//        self.audioEngineer.connect(reverb, to: inputEndMix, format: format)
//        self.audioEngineer.connect(inputEndMix, to: audioEngineer.mainMixerNode, format: format)
        self.audioEngineer.connect(self.player, to: self.playerMix, format: self.outputFormat)
        self.audioEngineer.connect(self.playerMix, to: self.audioEngineer.mainMixerNode, format: self.outputFormat)
        self.audioEngineer.connect(self.audioEngineer.mainMixerNode, to: self.audioEngineer.outputNode, format: self.outputFormat)
//        self.audioEngineer.mainMixerNode.volume = 0
        
        
        
        
//        self.inputEndMix.installTap(onBus: AVAudioNodeBus(0), bufferSize: .max, format: wantFormat) {[weak self] pcmbuffer, time in
//            guard let sself = self, sself.recording else{
////                JKprint("queue sself nil")
//                return
//            }
////            debugPrint("----- 麦克风最终混音节点输出流format：\(pcmbuffer.format.settings), ")
//            do{
//                try sself.audioRecordFile?.write(from: pcmbuffer)
//            }catch let eore{
//                debugPrint("----- 音频写入出错：\(eore.localizedDescription)")
//            }
//        }
        
        self.playerMix.installTap(onBus: 0, bufferSize: .max, format: self.outputFormat) {[weak self] pcmBuffer, time in
            debugPrint("----- 播放节点流数据format：\(pcmBuffer.format.settings), 可用帧数:\(pcmBuffer.frameLength)")
            guard let sself = self else{
//                JKprint("queue sself nil")
                return
            }
            
            if let audioRecordFile = sself.audioRecordFile {
//                if #available(iOS 13.0, *) {
                    try! audioRecordFile.write(from: pcmBuffer)
//                } else {
//                    if let coverPcm = AVAudioPCMBuffer.init(pcmFormat: audioRecordFile.fileFormat, frameCapacity: pcmBuffer.frameLength) {
//
//                        // 转换 pcm 格式
//                        try! sself.audioConver.convert(to: coverPcm, from: pcmBuffer)
//                        try! audioRecordFile.write(from: pcmBuffer)
//                    }else{
//                        debugPrint("音频转换 替代buffer 创建出错----")
//                    }
//                }

               
            }else{
                debugPrint("---- 音频录制文件 nil ，未录制 伴奏")
            }

        }
    }
    
    
    func startAudioEngine() {
        do {
            try self.audioEngineer.start()
        } catch let eorre {
            debugPrint("音频引擎启动出错------\(eorre.localizedDescription)")
        }
        
    }

    /// 新增整个伴奏播放计划, 和录制文件
    func prepareAccomAndRecordFile() {
        if let fourSeason = Bundle.main.url(forResource: "fourSeason", withExtension: "mp3") {
            do {
                let accFile = try AVAudioFile.init(forReading: fourSeason)
                self.player.loadAudioFile(file: accFile) {
                    [weak self] in
                    guard let sself = self else{
//                        JKprint("queue sself nil")
                        return
                    }
                    sself.recording = false
                    sself.accomTimer?.invalidate()
                    sself.accomTimer = nil
                    DispatchQueue.main.async {
                        sself.player.stop()
                    }
                }
                self.accomProgressSlider.minimumValue = 0
                self.accomProgressSlider.maximumValue = Float(self.player.duration * 1000)
                self.accomProgressSlider.setValue(0, animated: false)
                let tmpTime = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(accPlayerRepeatTask), userInfo: nil, repeats: true)
                self.accomTimer = tmpTime
                RunLoop.current.add(self.accomTimer!, forMode: .common)
                
                
                if audioRecordFile == nil {
                    let fm = FileManager.default
                    let fileUrl = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("pcm")
                    fm.createFile(atPath: fileUrl.path, contents: nil)
                    audioRecordFile = try AVAudioFile.init(forWriting: fileUrl, settings: self.outputFormat.settings)
                }
                
             
            } catch let eorr {
                debugPrint("----- 发生错误  \(eorr.localizedDescription)")
            }
            
        }
    }
    
    
    // MARK: - Action
    
    @IBAction func startTouch(_ sender: UIButton) {
        if self.recording {
            return
        }
        self.audioRecordFile = nil
        startAudioEngine()
        prepareAccomAndRecordFile()
        self.recording = true
        self.player.play()
        self.accomTimer?.fire()
    }
    
    @IBAction func stopTouch(_ sender: UIButton) {
        self.audioEngineer.stop()
        self.recording = false
        self.player.stop()
        self.accomTimer?.invalidate()
        self.accomTimer = nil
        guard let audioRecordFile = audioRecordFile else {
            return
        }
        debugPrint("------ 音频录制文件地址：\(audioRecordFile.url)")
    }
    
    @IBAction func accomProgressChanged(_ sender: UISlider) {
        
    }
    @IBAction func accomProgressChangedEnd(_ sender: UISlider) {
        /// 计算剔除录制文件 内容大小，并剔除已录制的内容
//        let format = self.audioEngineer.inputNode.inputFormat(forBus: 0)
        
        /// 开始录制
        if self.player.seekTo(time: Double(sender.value)/1000, completeHandle: nil) {
            self.recording = true
        }
        debugPrint("------- 录制进度调整结束，调整至:\(sender.value)s")
    }
    @IBAction func accomProgressChangedStart(_ sender: UISlider) {
        self.recording = false
        debugPrint("---- 录制进度调整开始，当前进度：\(sender.value)s")
    }
    
    @objc func accPlayerRepeatTask() {
        if !self.recording {
            return
        }
        let currentT = self.player.currentTime
        DispatchQueue.main.async {
            self.accomProgressSlider.setValue(Float(currentT) * 1000, animated: true)
        }
    }
}
