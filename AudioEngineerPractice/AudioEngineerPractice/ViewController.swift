//
//  ViewController.swift
//  AudioEngineerPractice
//
//  Created by 武文龙 on 2022/2/17.
//

import UIKit
import AVFoundation


class ViewController: UIViewController {
    
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
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.rateEffectSlider.setValue(10, animated: false)
        self.pitchEffectSlider.setValue(2400, animated: false)
        self.volumeSlider.setValue(60, animated: false)
        self.wetDryMixSlider.setValue(0, animated: false)
        
        self.rateEffectValueLab.text = "1.0"
        self.playBtn.setTitle(nil, for: .normal)
        self.playBtn.setTitle(nil, for: .highlighted)
        if #available(iOS 13.0, *) {
            self.playBtn.setImage(UIImage(systemName: playImageName), for: .normal)
            self.playBtn.setImage(UIImage(systemName: playImageName), for: .highlighted)
        } else {
            // Fallback on earlier versions
        }
        
        
        
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
                startAudio()
                
            } catch let eorr {
                debugPrint("----- 发生错误  \(eorr.localizedDescription)")
            }
            
        }
    }


    //MARK: - Private
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
        
        playerNode.scheduleFile(auf, at: nil) {
            [weak self] in
            guard let sself = self else{
                debugPrint("queue sself nil")
                return
            }
            debugPrint("--- 音频播放完成")
            if #available(iOS 13.0, *) {
                DispatchQueue.main.async {
                    sself.playBtn.setImage(UIImage.init(systemName: sself.playImageName), for: .normal)
                    sself.playBtn.setImage(UIImage.init(systemName: sself.playImageName), for: .highlighted)
                }
            }
            
            sself.startAudio()
        }
    }
    
    @IBAction func pitchEffectChanged(_ sender: UISlider) {
        let ve = String(format: "%.1f", sender.value - 2400.0)
        self.pitchEffectLab.text = ve
        // 变调到高音 音效的 pitch 属性，取值范围从 -2400 音分到 2400 音分，包含 4 个八度音阶。 默认值为 0 一個八度音程可以分为12个半音。每一个半音的音程相当于相邻钢琴键间的音程，等于100音分
        self.rateEffect.pitch = sender.value - 2400.0
    }
    @IBAction func rateEffectChanged(_ sender: UISlider) {
        let ve = String(format: "%.1f", sender.value / Float(10.0))
        self.rateEffectValueLab.text = ve
        self.rateEffect.rate = sender.value / Float(10)
    }
    
    @IBAction func playBtnTouch(_ sender: UIButton) {
        if self.playerNode.isPlaying {
            playerNode.pause()
            if #available(iOS 13.0, *) {
                self.playBtn.setImage(UIImage.init(systemName: playImageName), for: .normal)
                self.playBtn.setImage(UIImage.init(systemName: playImageName), for: .highlighted)
            }
            
        }else{
            self.playerNode.play()
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
        self.present(aunvc, animated: true, completion: nil)
        
    }
}

