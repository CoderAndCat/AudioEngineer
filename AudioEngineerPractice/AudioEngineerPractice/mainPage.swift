//
//  ViewController.swift
//  AudioEngineerPractice
//
//  Created by 武文龙 on 2022/2/17.
//

import UIKit
import AVFoundation
import MediaPlayer


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
    /// 是否正在手动调节音量
    var changingMainVolumeInApp = false
    
    @IBOutlet weak var sysVolumeSlider: UISlider!
    @IBOutlet weak var sysVolumeValueLab: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        if #available(iOS 15.0, *) {
            AVAudioSession.sharedInstance().addObserver(self, forKeyPath: "outputVolume", options: NSKeyValueObservingOptions.new, context: nil)
        } else {
            NotificationCenter.default.addObserver(self, selector: #selector(volumeChanged(notifica:)), name: Notification.Name.init("AVSystemController_SystemVolumeDidChangeNotification"), object: nil)
        }
    }


    //MARK: - Private
 
    private func setupUI() {
       
    }

    //MARK: Action
    @objc func volumeChanged(notifica: Notification) {
        if changingMainVolumeInApp {return}
        if let volum:Float = notifica.userInfo?["AVSystemController_AudioVolumeNotificationParameter"] as! Float?{
            self.sysVolumeSlider.setValue(volum, animated: true)
            self.sysVolumeValueLab.text = String(format: "%.2f", volum)
       }
    }
    @IBAction func enterNextPage(_ sender: UIButton) {
        let aunvc = AudioUnitParcViewController(nibName: "AudioUnitParcViewController", bundle: nil)
        self.navigationController?.pushViewController(aunvc, animated: true)
        
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
    /// midi 伴奏播放
    @IBAction private func playMidFile() {
        let playMidVC = PlayMidiViewController.init(nibName: "PlayMidiViewController", bundle: nil)
        self.navigationController?.pushViewController(playMidVC, animated: true)
    }
    /// 跳转到 本地xml 乐谱渲染界面
    @IBAction private func goToSerBankVC() {
        let serBkvc = WebViewTestViewController()
        self.navigationController?.pushViewController(serBkvc, animated: true)
    }
    /// 跳转 Schemes
    @IBAction private func turnToScheme() {
        
        if let schemeStr = ("tbopen://shop.m.taobao.com/shop/shop_index.htm?shop_id=410102616").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
//        if let schemeUrl = URL(string: "taobao://shop.m.taobao.com/shop/shop_index.htm?shop_id=410102616") {
            UIApplication.shared.open(URL(string: schemeStr)!)
            debugPrint("---- 跳转schemes：\(schemeStr)")
        }else{
            debugPrint("---- 构造 Schemes URL 出错")
        }
    }
    
    @IBAction private func micorEchoCancellation(_ sender: UIButton) {
//        let echoCanVC = EchoCancellationViewController.init(nibName: "EchoCancellationViewController", bundle: nil)
//        self.navigationController?.pushViewController(echoCanVC, animated: true)
        
        let configTest = ButtonConAndCellConViewController.init(nibName: "ButtonConAndCellConViewController", bundle: nil)
        self.navigationController?.pushViewController(configTest, animated: true)
    }
    
    @IBAction private func audioIODeviceDisplay() {
        let auIOVC = AudioIODeviceDisViewController.init(nibName: "AudioIODeviceDisViewController", bundle: nil)
        self.navigationController?.pushViewController(auIOVC, animated: true)
        
    }
    
    @IBAction func mainVolumeChange(sender: UISlider) {
        MPVolumeView.setVolume(sender.value)
        self.sysVolumeValueLab.text = String(format: "%.2f", sender.value)
    }
    @IBAction func volumeSliderTouchdown(_ sender: UISlider) {
        self.changingMainVolumeInApp = true
    }
    @IBAction func volumeSliderTouchUp(_ sender: UISlider) {
        self.changingMainVolumeInApp = false
    }
    
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let chDic = change, keyPath == "outputVolume" {
            if self.changingMainVolumeInApp {return}
            if let volumeVal = chDic[NSKeyValueChangeKey.newKey] as? Float {
                DispatchQueue.main.async {
                    self.sysVolumeSlider.setValue(volumeVal, animated: true)
                    self.sysVolumeValueLab.text = String(format: "%.2f", volumeVal)
                }
            }
        }
    }
}

