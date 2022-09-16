//
//  PlayMidiViewController.swift
//  AudioEngineerPractice
//
//  Created by 武文龙 on 2022/7/6.
//

import UIKit
import AVFAudio

class PlayMidiViewController: UIViewController {

    
    @IBOutlet weak var midiPlayBtn: UIButton!
    
    @IBOutlet weak var mp3PlayBtn: UIButton!
    
    @IBOutlet weak var midiRateLab: UILabel!
    @IBOutlet weak var maxMidiRateLab: UILabel!
    @IBOutlet weak var midiRateSlider: UISlider!
    
    
    let auEngine: AVAudioEngine = AVAudioEngine.init()
    
    /// 默认给十个采样器，来对应 midi 的十个轨道
    var trackSampleArray: [AVAudioUnitSampler] = [AVAudioUnitSampler(),AVAudioUnitSampler(),AVAudioUnitSampler(),AVAudioUnitSampler(),AVAudioUnitSampler(),AVAudioUnitSampler(),AVAudioUnitSampler(),AVAudioUnitSampler(),AVAudioUnitSampler(),AVAudioUnitSampler()]
    
    
    let auPlayer = JKSAudioEnginePlayer.init()
    
    var  auQueue: JKSMusicSequencer?
    
    
    var midFileUrl: URL?
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        prepareAudioEngine()
        try! auEngine.start()
        self.auQueue = JKSMusicSequencer.init(auEng: auEngine)
        loadMidFile()
        loadMp3File()
        // Do any additional setup after loading the view.
    }

    override func viewWillDisappear(_ animated: Bool) {
        self.auQueue?.sequencer.stop()
        self.auEngine.stop()
    }
    
    //MARK: - private
    private func prepareAudioEngine() {
        self.auEngine.attach(self.auPlayer)
        self.auEngine.connect(self.auPlayer, to: self.auEngine.mainMixerNode, format: auEngine.outputNode.inputFormat(forBus: 0))
        
        
        
        for trkSample in self.trackSampleArray {
            self.auEngine.attach(trkSample)
            
            self.auEngine.connect(trkSample, to: self.auEngine.mainMixerNode, format: auEngine.outputNode.inputFormat(forBus: 0))
        }
        
        
    }
    private func loadMp3File() {
        if let fileUrl = Bundle.main.url(forResource: "midi小星星3", withExtension: "mp3") {
            do {
                let auFile = try AVAudioFile.init(forReading: fileUrl)
                self.auPlayer.loadAudioFile(file: auFile, completeHandle: nil)
            } catch let eore {
                debugPrint("---- mp3 文件 初始化出错： \(eore.localizedDescription)")
            }
            
        }else{
            debugPrint("----- mp3 文件读取出错")
        }
    }
    private func loadMidFile() {
        guard let auQueue = auQueue else {
            return
        }

        if let midFile = Bundle.main.url(forResource: "3_4", withExtension: "mid") {
            do {
                try auQueue.sequencer.load(from: midFile)
                for track in auQueue.sequencer.tracks.enumerated() {
                    if self.trackSampleArray.count >= track.offset {
                        if track.element.isMuted {
                            debugPrint("---- 静音轨道--:\(track.offset)")
                        }
//                        track.element.isLoopingEnabled = true
//                        track.element.numberOfLoops = 1000
//                        track.element.loopRange = AVBeatRange.init(start: 0, length: 12)
                        
                        track.element.destinationAudioUnit = self.trackSampleArray[track.offset]
                        switch track.offset {
                        case 0:
                            // 小星星 通道0 速度轨道
                            loadGM1SF2ToSampler(0, 0, self.trackSampleArray[track.offset])
                        case 1:
                            // 小星星 通道1 Piano 钢琴
                            loadGM1SF2ToSampler(0, 0, self.trackSampleArray[track.offset])
                        case 2:
                            // 小星星 通道2 bass  贝斯
                            loadGM1SF2ToSampler(33, 0, self.trackSampleArray[track.offset])
                        case 3:
                            // 小星星 通道3 架子鼓
                            loadGM1SF2ToSampler(0, 128, self.trackSampleArray[track.offset])
                        case 4:
                            break
                            // 小星星 通道4 架子鼓
                            loadGM1SF2ToSampler(0, 128, self.trackSampleArray[track.offset])
                        case 5:
                            break
                            // 小星星 通道1 钢琴
                            loadGM1SF2ToSampler(1, 0, self.trackSampleArray[track.offset])
                        case 6:
                            break
                            // 小星星 通道1 钢琴
                            loadGM1SF2ToSampler(1, 0, self.trackSampleArray[track.offset])
                        default:
                            break
                            // 小星星 通道10 架子鼓
                            loadGM1SF2ToSampler(0, 128, self.trackSampleArray[track.offset])
                        }
                    }
                }
                auQueue.addCallback()
            } catch let eore {
                debugPrint("--- 发生错误： \(eore.localizedDescription)")
            }
        }else{
            debugPrint("---- 小星星 mid 文件读取失败--")
        }
        
        
        
    }
    
    private func loadGM1SF2ToSampler(_ programPar: UInt8, _ bankPar: Int, _ samplePar: AVAudioUnitSampler) {
        guard let woodBlockSf2 = Bundle.main.url(forResource: "wood block", withExtension: "sf2") else{
            debugPrint("--- 音色文件 wood block 读取出错----")
            return
        }
        do {
            /// 音色的 program
            let program: UInt8 = 115
            /// 音色的bank
            let bank = 0
            var bMSB: Int
            if bank <= 127 {
                bMSB = 0x79
            } else {
                bMSB = 0x78
            }
            let bLSB: Int = bank % 128
            try samplePar.loadSoundBankInstrument(at: woodBlockSf2, program: program, bankMSB: UInt8(bMSB), bankLSB: UInt8(bLSB))
            samplePar.reset()
        } catch let erore {
            debugPrint("----- 音色文件加载出错--：\(erore.localizedDescription)")
        }
        return
        
        
        guard let qudiSf2 = Bundle.main.url(forResource: "Library1", withExtension: "sf2") else{
            debugPrint("---- 音色文件读取出错")
            return
        }
        do {
            /// 音色的 program
            let program: UInt8 = programPar
            /// 音色的bank
            let bank = bankPar
            var bMSB: Int
            if bank <= 127 {
                bMSB = 0x79
            } else {
                bMSB = 0x78
            }
            let bLSB: Int = bank % 128
            try samplePar.loadSoundBankInstrument(at: qudiSf2, program: program, bankMSB: UInt8(bMSB), bankLSB: UInt8(bLSB))
            samplePar.reset()
        } catch let erore {
            debugPrint("----- 音色文件加载出错--：\(erore.localizedDescription)")
        }
        
    }
    
    func sampleTransform() {
        
    }
    //MARK: - Action
    @available(iOS 13.0, *)
    @IBAction func playMidTap(_ sender: UIButton) {
        guard let auQueue = auQueue else {
            return
        }
        if auQueue.sequencer.isPlaying {
            auQueue.sequencer.stop()
            auQueue.sequencer.currentPositionInBeats = 0
            self.midiPlayBtn.setImage(UIImage.init(systemName: "play.circle"), for: .normal)
            self.midiPlayBtn.setImage(UIImage.init(systemName: "play.circle"), for: .normal)
        }else{
            auQueue.sequencer.prepareToPlay()
            try! auQueue.sequencer.start()
            self.midiPlayBtn.setImage(UIImage.init(systemName: "pause.circle"), for: .normal)
            self.midiPlayBtn.setImage(UIImage.init(systemName: "pause.circle"), for: .normal)
        }
        
    }
    
    
    @available(iOS 13.0, *)
    @IBAction func mp3PlayBtnTap() {
        if self.auPlayer.isPlaying {
            self.auPlayer.stop()
            _ = self.auPlayer.seekTo(time: 0, completeHandle: nil)
            self.mp3PlayBtn.setImage(UIImage.init(systemName: "play.circle"), for: .normal)
            self.mp3PlayBtn.setImage(UIImage.init(systemName: "play.circle"), for: .normal)
        }else{
            self.auPlayer.play()
            self.mp3PlayBtn.setImage(UIImage.init(systemName: "pause.circle"), for: .normal)
            self.mp3PlayBtn.setImage(UIImage.init(systemName: "pause.circle"), for: .normal)
        }
    }
    
    @IBAction func midiRateValueChanged(_ sender: UISlider) {
        guard let auQueue = auQueue else {
            return
        }

        let curVal = sender.value
        let curValStr = String(format: "%.1f", curVal)
        let curValFloat = Float(curValStr)
        if let curValF = curValFloat ,auQueue.sequencer.rate !=  curValF{
            auQueue.sequencer.rate = curValF
            self.midiRateLab.text = curValStr
        }
    }
    
}
