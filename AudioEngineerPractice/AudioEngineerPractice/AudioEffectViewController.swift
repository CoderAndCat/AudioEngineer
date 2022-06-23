//
//  ViewController.swift
//  AudioEngineerPractice
//
//  Created by 武文龙 on 2022/2/17.
//

import UIKit
import AVFoundation


class AudioEffectViewController: UIViewController {
    
    // 混响类型
    static let smallRoom = "smallRoom"
    static let mediumRoom = "mediumRoom"
    static let largeRoom = "largeRoom"
    static let mediumHall = "mediumHall"
    static let largeHall = "largeHall"
    static let plate = "plate"
    static let mediumChamber = "mediumChamber"
    static let largeChamber = "largeChamber"
    static let cathedral = "cathedral"
    static let largeRoom2 = "largeRoom2"
    static let mediumHall2 = "mediumHall2"
    static let mediumHall3 = "mediumHall3"
    static let largeHall2 = "largeHall2"
    
    

    @IBOutlet weak var playBtn: UIButton!
    
    @IBOutlet weak var rateEffectSlider: UISlider!
    
    @IBOutlet weak var rateEffectValueLab: UILabel!
    
    @IBOutlet weak var pitchEffectSlider: UISlider!
    
    @IBOutlet weak var pitchEffectLab: UILabel!
    
    @IBOutlet weak var reverbType: UISegmentedControl!
    
    @IBOutlet weak var reverbTypeLab: UILabel!
    
    @IBOutlet weak var volumeSlider: UISlider!
    
    @IBOutlet weak var volumeValueLab: UILabel!
    
    @IBOutlet weak var wetDryMixSlider: UISlider!
    
    @IBOutlet weak var wetDryMixLab: UILabel!
    
    @IBOutlet weak var playerDurationLab: UILabel!
    
    @IBOutlet weak var testTransformSwitch: UISwitch!
    
    
    
    var playerTimer: Timer?
    
    let pauseImageName = "pause.circle"
    let playImageName = "play.circle"
    
    let audioEngineer = AVAudioEngine()
    /// 音频播放单元
    let playerNode = AVAudioPlayerNode()
     
    /// 音频变速单元
    let rateEffect = AVAudioUnitTimePitch()
    
    /// 混响单元
    let reverbEffect = AVAudioUnitReverb()
    
    /// 调节音量单元
    let volumeEffect = AVAudioUnitEQ()
    
    var audioFile: AVAudioFile?
    
    var audioPlayerStatus = PlayStatus.stop
    
    enum PlayStatus {
        case playing
        case pause
        case complete
        case stop
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
//        prepareAudioEngine()
        var testArray = ["a", "b", "c", "d", "e", "f", "g", "g", "a", "d", "k", "u"]
        testArray = testArray.enumerated().filter { (idx, value) ->Bool in
            return testArray.firstIndex(where: { val1 in
                return val1 == value
            }) == idx
        }.map({ $0.element })
        debugPrint("---去重数组： \(testArray)")
        
        // 分贝 音量转换
        
        let a1 = 0.5 * pow(10, 48/20)
        debugPrint("---- 分贝转换音量：\(a1)")
        
    }


    //MARK: - Private
    private func setupUI() {
        self.rateEffectSlider.setValue(60, animated: false)
        self.pitchEffectSlider.setValue(2400, animated: false)
        self.volumeSlider.setValue(60, animated: false)
        self.wetDryMixSlider.setValue(0, animated: false)
        
        self.rateEffectValueLab.text = "60"
        self.playBtn.setTitle(nil, for: .normal)
        self.playBtn.setTitle(nil, for: .highlighted)
        if #available(iOS 13.0, *) {
            self.playBtn.setImage(UIImage(systemName: playImageName), for: .normal)
            self.playBtn.setImage(UIImage(systemName: playImageName), for: .highlighted)
        } else {
            // Fallback on earlier versions
        }
       
        // 由于 UISwitch 的大小无法通过约束改变，因此尝试通过 缩放来修改
        self.testTransformSwitch.transform = CGAffineTransform.init(scaleX: 2.5, y: 1.5)
        
    }
    private func prepareAudioEngine() {
        if let fourSeason = Bundle.main.url(forResource: "fourSeason", withExtension: "mp3") {
            do {
                audioFile = try AVAudioFile.init(forReading: fourSeason)
                
                let audioFormat = audioFile!.processingFormat
                audioEngineer.attach(playerNode)
                audioEngineer.attach(rateEffect)
                audioEngineer.attach(reverbEffect)
                audioEngineer.attach(volumeEffect)
                
                
                
                
                audioEngineer.connect(playerNode, to: rateEffect, format: audioFormat)
                audioEngineer.connect(rateEffect, to: reverbEffect, format: audioFormat)
                audioEngineer.connect(reverbEffect, to: volumeEffect, format: audioFormat)
                audioEngineer.connect(volumeEffect, to: audioEngineer.mainMixerNode, format: audioFormat)
                
                // 选择混响效果
                reverbEffect.loadFactoryPreset(AVAudioUnitReverbPreset.largeRoom)
                
                // 启动引擎
                try audioEngineer.start()
                
                prepareAudioFile()
                
            } catch let eorr {
                debugPrint("----- 发生错误  \(eorr.localizedDescription)")
            }
            
        }
    }
    private func prepareAudioFile() {
        
        
        rateEffect.rate = 1.0
        // 变调到高音 音效的 pitch 属性，取值范围从 -2400 音分到 2400 音分，包含 4 个八度音阶。 默认值为 0 一個八度音程可以分为12个半音。每一个半音的音程相当于相邻钢琴键间的音程，等于100音分
        rateEffect.pitch = 0
        // 混响效果 混合以百分比形式指定。 范围是 0%（全干）到 100%（全湿）0 ~ 100。
        reverbEffect.wetDryMix = 0
        // 应用于信号的整体增益调整，以分贝为单位。-96 ~ 24
        volumeEffect.globalGain = -36.0
        
    }
    private func startAudio(){
        guard let auf = audioFile else{
            debugPrint("----")
            return
        }
        self.playerDurationLab.text = "0.0"
        
        playerNode.scheduleFile(auf, at: nil) {
            [weak self] in
            guard let sself = self else{
                debugPrint("queue sself nil")
                return
            }
            debugPrint("--- 音频播放完成")
            sself.audioPlayerStatus = .complete
            if #available(iOS 13.0, *) {
                DispatchQueue.main.async {
                    sself.playBtn.setImage(UIImage.init(systemName: sself.playImageName), for: .normal)
                    sself.playBtn.setImage(UIImage.init(systemName: sself.playImageName), for: .highlighted)
                    sself.playerNode.stop()
                }
            }
        }
        self.playerTimer?.invalidate()
        self.playerTimer = nil
        self.playerTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(playerTimerRepeatTask), userInfo: nil, repeats: true)
        
    }
    
    //MARK: Action
    @objc func playerTimerRepeatTask() {
        if let lastRt = self.playerNode.lastRenderTime, let pTime = self.playerNode.playerTime(forNodeTime: lastRt) {
            let sampleTime = pTime.sampleTime
            let sampleRate = pTime.sampleRate
            let currentTime = Double(sampleTime) / sampleRate
            
            self.playerDurationLab.text = "\(round(currentTime))s"
            debugPrint("------ lastRenderTime--currentTime:\(currentTime)")
            
        }
    }
    @IBAction func pitchEffectChanged(_ sender: UISlider) {
        let ve = String(format: "%.1f", sender.value - 2400.0)
        self.pitchEffectLab.text = ve
        // 变调到高音 音效的 pitch 属性，取值范围从 -2400 音分到 2400 音分，包含 4 个八度音阶。 默认值为 0 一個八度音程可以分为12个半音。每一个半音的音程相当于相邻钢琴键间的音程，等于100音分
        self.rateEffect.pitch = sender.value - 2400.0
    }
    @IBAction func rateEffectChanged(_ sender: UISlider) {
        // 播放速率 基于 60 的变化， 范围 0-120
        
        let ve = String(format: "%f", round(sender.value) / Float(60.0))
        debugPrint("当前播放速率：\(ve)")
        if let avf = self.audioFile {
            let dura = Double(avf.length) / avf.processingFormat.sampleRate
            debugPrint("文件 1.0x 时长:\(dura * 1000)ms，预计本次时长：\(dura / (Double(round(sender.value)/Float(60))) * 1000)ms")
        }
        self.rateEffectValueLab.text = "\(round(sender.value))"
        
        // rate 从标准的 1.0 开始变化
        
        self.rateEffect.rate = round(sender.value) / Float(60.0)
    }
    
    @IBAction func playBtnTouch(_ sender: UIButton) {
        if self.audioPlayerStatus == .playing {
            playerNode.pause()
            self.audioPlayerStatus = .pause
            if #available(iOS 13.0, *) {
                self.playBtn.setImage(UIImage.init(systemName: playImageName), for: .normal)
                self.playBtn.setImage(UIImage.init(systemName: playImageName), for: .highlighted)
            }
            
        }else if audioPlayerStatus == .pause {
            self.playerNode.play()
            self.audioPlayerStatus = .playing
            if #available(iOS 13.0, *) {
                self.playBtn.setImage(UIImage.init(systemName: pauseImageName), for: .normal)
                self.playBtn.setImage(UIImage.init(systemName: pauseImageName), for: .highlighted)
            }
        } else if audioPlayerStatus == .complete || audioPlayerStatus == .stop{
            startAudio()
            self.playerNode.play()
            self.audioPlayerStatus = .playing
            self.playerTimer?.fire()
            if #available(iOS 13.0, *) {
                self.playBtn.setImage(UIImage.init(systemName: pauseImageName), for: .normal)
                self.playBtn.setImage(UIImage.init(systemName: pauseImageName), for: .highlighted)
            }
        }
    }
    
    @IBAction func reverbTypeChange(_ sender: UISegmentedControl) {
        
        let sengmentValue = sender.selectedSegmentIndex
        
        if let reverbTypte = AVAudioUnitReverbPreset.init(rawValue: sengmentValue) {
            // 选择混响效果
            reverbEffect.loadFactoryPreset(reverbTypte)
            switch reverbTypte {
            case .smallRoom:
                self.reverbTypeLab.text = Self.smallRoom
            case .mediumRoom:
                self.reverbTypeLab.text = Self.mediumRoom
            case .largeRoom:
                self.reverbTypeLab.text = Self.largeRoom
            case .mediumHall:
                self.reverbTypeLab.text = Self.mediumHall
            case .largeHall:
                self.reverbTypeLab.text = Self.largeHall
            case .plate:
                self.reverbTypeLab.text = Self.plate
            case .mediumChamber:
                self.reverbTypeLab.text = Self.mediumChamber
            case .largeChamber:
                self.reverbTypeLab.text = Self.largeChamber
            case .cathedral:
                self.reverbTypeLab.text = Self.cathedral
            case .largeRoom2:
                self.reverbTypeLab.text = Self.largeRoom2
            case .mediumHall2:
                self.reverbTypeLab.text = Self.mediumHall2
            case .mediumHall3:
                self.reverbTypeLab.text = Self.mediumHall3
            case .largeHall2:
                self.reverbTypeLab.text = Self.largeHall2
            @unknown default:
                self.reverbTypeLab.text = "Unknow"
            }
        }else{
            debugPrint("混响改变出错")
        }
        
        
        
    }
    
    @IBAction func volumeSliderValueChange(_ sender: UISlider) {
        // -96 ~ 24 -> 0 ~ 120
        
        let vol = sender.value - 96
        if vol >= -96.0 && vol <= 24 {
            volumeEffect.globalGain = vol
            self.volumeValueLab.text = String(format: "%.1f", vol)
        }
        
    }
    
    @IBAction func wetDryMixValueChange(_ sender: UISlider) {
        // 0 ~ 100 干 - 湿
        self.reverbEffect.wetDryMix = sender.value
        self.wetDryMixLab.text = "\(sender.value)"
    }
    
    @IBAction func enterNextPage(_ sender: UIButton) {
        let aunvc = AudioUnitParcViewController(nibName: "AudioUnitParcViewController", bundle: nil)
        self.navigationController?.pushViewController(aunvc, animated: true)
        
    }
    @objc private func rateSpeedDuration() {
//        self.millSecondDura += 1
    }

    

    @IBAction func appleSamplerTest(_ sender: UIButton) {
        let appleSamplerVC = AppleSamplerTestViewController.init(nibName: "AppleSamplerTestViewController", bundle: nil)
        self.navigationController?.pushViewController(appleSamplerVC, animated: true)
    }
    
    @IBAction func AVAssetDealTest(_ sender: UIButton) {
        let asVC = AVAssetDealTestViewController.init(nibName: "AVAssetDealTestViewController", bundle: nil)
        self.navigationController?.pushViewController(asVC, animated: true)
    }
    /// 画廊样式 collectionView
    @IBAction func GellaryCollectionView(_ sender: UIButton) {
        let gellaryVC = HuaLangCollectionViewController.init(nibName: "HuaLangCollectionViewController", bundle: nil)
        self.navigationController?.pushViewController(gellaryVC, animated: true)
    }
    /// 渐变layer 测试
    @IBAction private func gradientTest(_ sender: UIButton) {
        let graVC = GradienetTestViewController.init()
        self.navigationController?.pushViewController(graVC, animated: true)
    }
    /// 音频合并
    @IBAction private func mixAudioTrack(_ sender: UIButton) {
        let mixVC = MultipleAudioTrackMixViewController.init(nibName: "MultipleAudioTrackMixViewController", bundle: nil)
        self.navigationController?.pushViewController(mixVC, animated: true)
    }
    /// 毛玻璃效果 vc
    @IBAction private func visualEffectVC(_ sender: UIButton) {
        let visualEVC = VisualEffectViewController.init(nibName: "VisualEffectViewController", bundle: nil)
        self.navigationController?.pushViewController(visualEVC, animated: true)
    }
}

