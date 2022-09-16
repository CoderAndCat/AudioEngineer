//
//  MultipleAudioTrackMixViewController.swift
//  AudioEngineerPractice
//
//  Created by 武文龙 on 2022/6/1.
//

import UIKit
import AVFAudio
import AVFoundation

class MultipleAudioTrackMixViewController: UIViewController {

    
    //MARK: - private property
    private var resultFile: AVAudioFile?
    
    @IBOutlet weak var playerBtn: UIButton!
    private var audioPlayer = AVAudioPlayer()
    //MARK: - override
    override func viewDidLoad() {
        super.viewDidLoad()

        
    }


    //MARK: - private
    private func startAudioFileMix() {
        guard let ori1FileUrl = Bundle.main.url(forResource: "record11", withExtension: "caf") else{
            debugPrint("---- 读取 pcm 文件出错")
            return
        }
        guard let ori2FileUrl = Bundle.main.url(forResource: "record2", withExtension: "caf") else{
            debugPrint("---- 读取 pcm 文件出错")
            return
        }
        
        pingJieAudio(originAudio: ori1FileUrl, backgroundAudio: ori2FileUrl) {[weak self] result in
            guard let sself = self, result else{
                return
            }
            if let resultFile = sself.resultFile {
                debugPrint("----- 音频合成最终文件:\(resultFile.url)")
                
                sself.audioPlayer = try! AVAudioPlayer.init(contentsOf: resultFile.url)
            }
        }
        
    }
    /// 将 backgroundAudio 拼接到 originAudio 后面
    private func pingJieAudio(originAudio: URL, backgroundAudio: URL, originVolume: Float = 1.0, backgroundVolume: Float = 1.0, completionHandle: @escaping (_ result: Bool) -> Void) {
        //1.获取素材
        let originAsset = AVURLAsset(url: originAudio)
        let backAsset = AVURLAsset(url: backgroundAudio)
        let semaphore = DispatchSemaphore(value: 1)
        if #available(iOS 15.0, *) {
            semaphore.wait()
            originAsset.loadTracks(withMediaType: .audio) { tracks, error in
                semaphore.signal()
            }
            semaphore.wait()
            backAsset.loadTracks(withMediaType: .audio) { tracks, error in
                semaphore.signal()
            }
        }
        semaphore.wait()
        semaphore.signal()
        //2.获取音频素材轨道
        let compostion = AVMutableComposition()
        
        let originTracks = originAsset.tracks(withMediaType: .audio)
        guard let originTrack = originTracks.first  else{
            completionHandle(false)
            return
        }
        let backTracks = backAsset.tracks(withMediaType: .audio)
        guard let backTrack = backTracks.first else{
            completionHandle(false)
            return
        }
        //3.创建轨道
        guard let resultAudioTrack = compostion.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) else{
            completionHandle(false)
            return
        }
        
        var beginTime = CMTime.zero
        
        //4.合并
        do {
            /// 定义originTrack 需要合并进入的 起始点和时长
            let originTrackTimeRange = CMTimeRange.init(start: CMTime.zero, duration: CMTime.init(seconds: 5, preferredTimescale: originAsset.duration.timescale))
            try resultAudioTrack.insertTimeRange(originTrackTimeRange, of: originTrack, at: beginTime)
            beginTime = CMTimeAdd(beginTime, originTrackTimeRange.duration)
            try resultAudioTrack.insertTimeRange(CMTimeRange(start: .zero, duration: backAsset.duration), of: backTrack, at: beginTime)
            
            
        } catch let error {
            debugPrint("---- 录音混音出错--- \(error.localizedDescription)")
            completionHandle(false)
        }
        
        //5.音量
        let originalAudioParameters = AVMutableAudioMixInputParameters.init(track: originTrack)
        originalAudioParameters.setVolume(originVolume, at: .zero)
        
        let audioMix = AVMutableAudioMix()
        audioMix.inputParameters = [originalAudioParameters]
        //6.导出
        guard let session = AVAssetExportSession.init(asset: compostion, presetName: AVAssetExportPresetAppleM4A) else {
            completionHandle(false)
            
            return
        }
        let filename = UUID().uuidString + ".m4a"
        //此处一定要用fileURLWithPath
        let mixPutUrl = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(filename)
        session.audioMix = audioMix
        session.outputURL = mixPutUrl
        session.outputFileType = .m4a
        session.shouldOptimizeForNetworkUse = true
        session.exportAsynchronously {
            DispatchQueue.main.async { [self] in
                
                switch session.status {
                case .failed:
                    debugPrint(" 混音导出-------- fail \(session.error.debugDescription)")
                    completionHandle(false)
                case .cancelled:
                    debugPrint(" 混音导出 ----- 取消")
                    completionHandle(false)
                case .completed:
                    debugPrint(" 混音导出 ----- 成功")
                    self.resultFile = try? AVAudioFile(forReading: mixPutUrl)
                    completionHandle(true)
                default:
                    debugPrint("混音导出 ---- 未知问题")
                    completionHandle(false)
                }
            }
        }
    }
    
    //MARK: - Action
    @IBAction private func playerOrStopResultFile(_ sender: UIButton) {
        if self.audioPlayer.isPlaying {
            self.audioPlayer.stop()
        }else{
            self.audioPlayer.play()
        }
    }
    @IBAction private func startToMixAudio(_ sender: UIButton) {
        self.startAudioFileMix()
    }
}
