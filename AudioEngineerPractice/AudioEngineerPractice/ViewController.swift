//
//  ViewController.swift
//  AudioEngineerPractice
//
//  Created by 武文龙 on 2022/2/17.
//

import UIKit
import AVFoundation


class ViewController: UIViewController {

    @IBOutlet weak var playBtn: UIButton!
    
    @IBOutlet weak var rateEffectSlider: UISlider!
    
    @IBOutlet weak var rateEffectValueLab: UILabel!
    
    @IBOutlet weak var pitchEffectSlider: UISlider!
    
    @IBOutlet weak var pitchEffectLab: UILabel!
    
    let pauseImageName = "pause.circle"
    let playImageName = "play.circle"
    
    let audioEngineer = AVAudioEngine()
    let playerNode = AVAudioPlayerNode()
     
    
    let rateEffect = AVAudioUnitTimePitch()
    
//    let mainMixer = AVAudioMixerNode.init()
    var audioFile: AVAudioFile?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.rateEffectSlider.setValue(10, animated: false)
        self.pitchEffectSlider.setValue(10, animated: false)
        
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
                audioEngineer.connect(playerNode, to: rateEffect, format: audioFormat)
                audioEngineer.connect(rateEffect, to: audioEngineer.mainMixerNode, format: audioFormat)
                
                rateEffect.rate = 1.0
                rateEffect.pitch = 1.0
                prepareAudioFile()
                try audioEngineer.start()
                
            } catch let eorr {
                debugPrint("----- 发生错误  \(eorr.localizedDescription)")
            }
            
        }
    }


    //MARK: - Private
    private func prepareAudioFile() {
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
            
            sself.prepareAudioFile()
        }
    }
    
    @IBAction func pitchEffectChanged(_ sender: UISlider) {
        let ve = String(format: "%.1f", sender.value / Float(10.0))
        self.pitchEffectLab.text = ve
        self.rateEffect.pitch = sender.value / Float(10)
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
}

