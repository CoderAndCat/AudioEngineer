//
//  AVAssetDealTestViewController.swift
//  AudioEngineerPractice
//
//  Created by 武文龙 on 2022/5/29.
//

import UIKit
import AVFAudio
import AVFoundation

class AVAssetDealTestViewController: UIViewController {

    
    private var player = AVAudioPlayer.init()
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }


    
    //MARK: - Action
    @IBAction private func playPcm(_ sender: UIButton) {
        
        if let rec1Url = Bundle.main.url(forResource: "record1", withExtension: "pcm") {
            do {
                self.player = try AVAudioPlayer.init(contentsOf: rec1Url)
                self.player.prepareToPlay()
                self.player.play()
            } catch let error {
                debugPrint("player 读取文件失败：\(error.localizedDescription)")
            }
        }else{
            debugPrint("----- pcm文件未找到")
            return
        }
        
        
    }

    @IBAction private func pcmAVAssetDeal(_ sender: UIButton) {
        if let rec1Url = Bundle.main.url(forResource: "record11", withExtension: "caf") {
            debugPrint("资源 URL:\(rec1Url)")
            let aset = AVURLAsset.init(url: rec1Url)
            
            let semaphore = DispatchSemaphore(value: 1)
            if #available(iOS 15.0, *) {
                semaphore.wait()
                aset.loadTracks(withMediaType: .audio) { tracks, error in
                    debugPrint("---- .audioTracks:\(String(describing: tracks)),error:\(String(describing: error?.localizedDescription))")
                    semaphore.signal()
                }
            }
            semaphore.wait()
            semaphore.signal()
            let assTracks = aset.tracks(withMediaType: .audio)
            if let originTrack = assTracks.first {
                debugPrint("------ .audioTrack Not empty")
            }else{
                debugPrint("------ .audioTrack empty")
            }
            debugPrint("--- pcmAsset traksCount:\(aset.tracks.count)")
            
        }else{
            debugPrint("----- pcm文件未找到")
            return
        }
    }
    
    
}
