//
//  AppleSamplerTestViewController.swift
//  AudioEngineerPractice
//
//  Created by 武文龙 on 2022/5/23.
//

import UIKit
import AVFAudio

class AppleSamplerTestViewController: UIViewController {
    
    private let audioEngineer = AVAudioEngine()
    private let appleSample = AVAudioUnitSampler()
    
    /// 音频播放节点
    private let playerNode = JKSAudioEnginePlayer.init()
    
    private let sampleRate: Float64 = 44100
    private let sampleBit: UInt32 = 32
    private let channlCount: UInt32 = 1
    
    private lazy var outputFormat = {
        return self.audioEngineer.outputNode.inputFormat(forBus: 0)
    }()
    
    /// 音量调节单元
    let booster =  AVAudioUnitEQ()
    
    //MARK:  - override
    override func viewDidLoad() {
        super.viewDidLoad()
        prepareAudioEngineer()
        loadSF2ToSampler()
        // 读取并播放音频文件
        loadAudioFile()
        self.playerNode.play()
        
    }
    
    //MARK: - private
    private func prepareAudioEngineer() {
        
        let avSession = AVAudioSession.sharedInstance()
        do {
            try avSession.setPreferredSampleRate(44100)
            try avSession.setPreferredOutputNumberOfChannels(1)
        } catch let eore {
            debugPrint("----- audioSession 设置出错：\(eore.localizedDescription)")
        }
       
        
        audioEngineer.attach(appleSample)
        audioEngineer.attach(booster)
        audioEngineer.attach(self.playerNode)
        
        audioEngineer.connect(appleSample, to: booster, format: self.outputFormat)
        audioEngineer.connect(booster, to: audioEngineer.mainMixerNode, format: self.outputFormat)
        audioEngineer.connect(self.playerNode, to: audioEngineer.mainMixerNode, format: self.outputFormat)
        
        let format = appleSample.outputFormat(forBus: .min)
        debugPrint("采样器输出格式---:\(format.settings)")
        
        do {
            try audioEngineer.start()
        } catch let eroe {
            debugPrint("----- 音频引擎启动出错---：\(eroe.localizedDescription)")
        }
        
    }
    
    private func loadSF2ToSampler() {
        
        guard let qudiSf2 = Bundle.main.url(forResource: "Library2", withExtension: "sf2") else{
            debugPrint("---- 音色文件读取出错")
            return
        }
        do {
            /// 音色的 program
            let program: UInt8 = 4
            /// 音色的bank
            let bank = 0
            var bMSB: Int
            if bank <= 127 {
                bMSB = 0x79
            } else {
                bMSB = 0x78
            }
            let bLSB: Int = bank % 128
            try self.appleSample.loadSoundBankInstrument(at: qudiSf2, program: program, bankMSB: UInt8(bMSB), bankLSB: UInt8(bLSB))
            appleSample.reset()
        } catch let erore {
            debugPrint("----- 音色文件加载出错--：\(erore.localizedDescription)")
        }
        
    }
    private func loadAudioFile() {
        guard let fouSeason = Bundle.main.url(forResource: "fourSeason", withExtension: "mp3") else{
            debugPrint("---- 四季歌mp3文件未找到")
            return
        }
        
        do {
            let avFile = try AVAudioFile.init(forReading: fouSeason)
            self.playerNode.loadAudioFile(file: avFile, completeHandle: nil)
            
        } catch let rooe {
            debugPrint("--- 四季歌 MP3 文件读取 出错:\(rooe.localizedDescription)")
            return
        }
        
        
       
        
    }
    //MARK: - API
    /// iOS 原生引擎各节点统一输出音频格式
    static func audioEngineNodeOutputFormat() ->AVAudioFormat?
    {
        var setting: [String: Any] = [:]
//        if #available(iOS 13.0, *) {
            setting = [AVSampleRateKey : NSNumber.init(value: 44100), AVLinearPCMIsNonInterleaved: NSNumber(1), AVNumberOfChannelsKey: NSNumber(value: 1), AVLinearPCMIsBigEndianKey: NSNumber(0), AVLinearPCMBitDepthKey: NSNumber(32), AVLinearPCMIsFloatKey: NSNumber(1), AVFormatIDKey: kAudioFormatLinearPCM]
//        } else {
//            setting = [AVSampleRateKey : NSNumber.init(value: 44100), AVLinearPCMIsNonInterleaved: NSNumber(0), AVNumberOfChannelsKey: NSNumber(value: 1), AVLinearPCMIsBigEndianKey: NSNumber(0), AVLinearPCMBitDepthKey: NSNumber(16), AVLinearPCMIsFloatKey: NSNumber(0), AVFormatIDKey: kAudioFormatLinearPCM]
//        }

        
        
        if let avFormat = AVAudioFormat.init(settings: setting) {
            return avFormat
        }else{
            return nil
        }
    }
    //MARK: - Action
    
    @IBAction func note60TouchDown(_ sender: UIButton) {
        self.appleSample.startNote(60, withVelocity: 127, onChannel: 0)
    }
    @IBAction func note60TouchUp(_ sender: UIButton) {
        self.appleSample.stopNote(60, onChannel: 0)
    }
    
    @IBAction func note61TouchDown(_ sender: UIButton) {
        self.appleSample.startNote(61, withVelocity: 127, onChannel: 0)
    }
    @IBAction func note61TouchUp(_ sender: UIButton) {
        self.appleSample.stopNote(61, onChannel: 0)
    }
    
    @IBAction func note62TouchDown(_ sender: UIButton) {
        self.appleSample.startNote(62, withVelocity: 127, onChannel: 0)
    }
    @IBAction func note62TouchUp(_ sender: UIButton) {
        self.appleSample.stopNote(62, onChannel: 0)
    }
    
    
    @IBAction func note63TouchDown(_ sender: UIButton) {
        self.appleSample.startNote(63, withVelocity: 127, onChannel: 0)
    }
    @IBAction func note63TouchUp(_ sender: UIButton) {
        self.appleSample.stopNote(63, onChannel: 0)
    }
    
    @IBAction func note64TouchDown(_ sender: UIButton) {
        self.appleSample.startNote(64, withVelocity: 127, onChannel: 0)
    }
    @IBAction func note64TouchUp(_ sender: UIButton) {
        self.appleSample.stopNote(64, onChannel: 0)
    }
    
    @IBAction func note65TouchDown(_ sender: UIButton) {
        self.appleSample.startNote(65, withVelocity: 127, onChannel: 0)
    }
    @IBAction func note65TouchUp(_ sender: UIButton) {
        self.appleSample.stopNote(65, onChannel: 0)
    }
    
    @IBAction func note66TouchDown(_ sender: UIButton) {
        self.appleSample.startNote(66, withVelocity: 127, onChannel: 0)
    }
    @IBAction func note66TouchUp(_ sender: UIButton) {
        self.appleSample.stopNote(66, onChannel: 0)
    }
    @IBAction func note72TouchDown(_ sender: UIButton) {
        self.appleSample.startNote(72, withVelocity: 127, onChannel: 0)
    }
    @IBAction func note72TouchUp(_ sender: UIButton) {
        self.appleSample.stopNote(72, onChannel: 0)
    }
    
    
    
    
    @IBAction func pitchBend(_ sender: UISlider) {
        self.appleSample.sendPitchBend(UInt16(sender.value), onChannel: 0)
    }
    /// 打开滑音
    @IBAction func cc65(_ sender: UIButton) {
        self.appleSample.sendController(65, withValue: 127, onChannel: 0)
    }
    @IBAction func cc5(_ sender :UISlider)  {
        self.appleSample.sendController(5, withValue: UInt8(sender.value), onChannel: 0)
    }
    /// 主音量 cc 7 （粗调）
    @IBAction func mainVolumeCC7(_ sender: UISlider) {
        self.appleSample.sendController(7, withValue: UInt8(sender.value), onChannel: 0)
    }
    /// 主音量 cc39 （微调）实际无效果
    @IBAction func mainVolumeCC39(_ sender: UISlider) {
        self.appleSample.sendController(39, withValue: UInt8(sender.value), onChannel: 0)
    }
    
    
    
    /// 情绪控制 cc11（粗调） 实际效果 和 cc7 相同
    @IBAction func sentimentCC11(_ sender: UISlider) {
        self.appleSample.sendController(11, withValue: UInt8(sender.value), onChannel: 0)
    }
    
    /// 声像调整 cc 10 （粗调）实际效果 cc7 的反向调节
    @IBAction func cc10(_ sender: UISlider) {
        self.appleSample.sendController(10, withValue: UInt8(sender.value), onChannel: 0)
    }
    
    @IBAction func breathCC2(_ sender: UISlider) {
        self.appleSample.sendController(2, withValue: UInt8(sender.value), onChannel: 0)
    }
    
    /// 颤音深度 cc1 （粗调）无实际效果
    @IBAction func modulationCC1(_ sender: UISlider) {
        self.appleSample.sendController(1, withValue: UInt8(sender.value), onChannel: 0)
    }
    /// 颤音速度 cc33 （微调）无实际效果
    @IBAction func modulationSpeedCC33(_ sender: UISlider) {
        self.appleSample.sendController(33, withValue: UInt8(sender.value), onChannel: 0)
    }
    
    
    
}
