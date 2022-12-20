//
//  EchoCancellationViewController.swift
//  AudioEngineerPractice
//
//  Created by 武文龙 on 2022/9/14.
//

import UIKit
import AVFAudio

class EchoCancellationViewController: UIViewController {

    
    private let audioEngine = AVAudioEngine()
    private var micNode: AVAudioInputNode {
        return self.audioEngine.inputNode
    }
    private var endMixNode: AVAudioMixerNode {
        return self.audioEngine.mainMixerNode
    }
    
    
//    private var inputNode = AVAudioInputNode
    
    private var audioComponentDesc = AudioComponentDescription()
    private var audioUnit: AudioUnit?
    
    private var _audioStreamBasicDescription = AudioStreamBasicDescription()
    private var _maximumFramesPerSlice: UInt32 = 0
    
    private var echoCancelObj: AudioInputEchoCancellation?
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        if #available(iOS 13.0, *) {
//
//        }else{
//            setupAudioInputLowiOS13()
//        }

        setupAudioEngine()
        // Do any additional setup after loading the view.
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if self.audioEngine.isRunning {
            self.audioEngine.stop()
        }
    }
    
    func setupAudioInputLowiOS13() {
        let format = micNode.outputFormat(forBus: 0)
        
        let echoObj = AudioInputEchoCancellation.init(asbd: format.streamDescription.pointee)
        self.echoCancelObj = echoObj
       
        echoObj.setOutputDataBlock {[weak self] bufferList in
            guard let sself = self else{
                debugPrint("queue sself nil")
                return
            }
            
            
            if let pcmBufPointer = bufferList.pointee.mBuffers.mData {
                let pcmBuf = pcmBufPointer.load(as: AVAudioPCMBuffer.self)
                
            }else{
                debugPrint("------ setOutputDataBlock， bufferList nil")
            }
        }
    }
    
    func setupAudioEngine() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, options: .defaultToSpeaker)
            try AVAudioSession.sharedInstance().setPreferredSampleRate(44100)
            
            if #available(iOS 13.0, *) {
                try micNode.setVoiceProcessingEnabled(true)
            }else{
                if let micAudioUnit = self.micNode.audioUnit {
                    // 0 开启  1 关闭
                    var enableFlag = UInt32(0)
                    let size = UInt32(MemoryLayout.size(ofValue: enableFlag))
                    let res = AudioUnitSetProperty(micAudioUnit, kAUVoiceIOProperty_BypassVoiceProcessing, kAudioUnitScope_Global, 0, &enableFlag, size)
                    if res == noErr {
                        debugPrint("----- 回声消除 iOS 13 以下 设置成功 ")
                    }else{
                        debugPrint("----- 回声消除 iOS 13 以下 设置失败 fail-----:\(res)")
                    }
                }else{
                    debugPrint("---- micNode  audioUnit ------nil")
                }
            }
            
            
            
            let format = micNode.outputFormat(forBus: 0)

            self.audioEngine.connect(micNode, to: endMixNode, format: format)
            self.audioEngine.connect(endMixNode, to: self.audioEngine.outputNode, format: format)
            
            
            debugPrint("---- 音频引擎格式 :\(format.settings)")
        } catch let eore {
            debugPrint("---- 音频引擎设置出错：\(eore.localizedDescription)")
        }
        
        
    }

    @IBAction func startEngine(_ sender: UIButton) {
//        if let echoCancelObj_ = echoCancelObj {
//            echoCancelObj_.audioInputStart()
//        }else{
//            debugPrint("---- 回声消除对象 nil")
//        }
        
        if self.audioEngine.isRunning {
            return
        }
        do {
            try self.audioEngine.start()
            
        } catch let erore {
            debugPrint("----- 音频引擎启动出错--- :\(erore.localizedDescription)")
            return
        }
        
        
        
        
    }
    
    
    
    @IBAction func stopEngine(_ sender: UIButton) {
        
//        if let echoCancelObj_ = echoCancelObj {
//            echoCancelObj_.audioInputStop()
//        }else{
//            debugPrint("---- 回声消除对象 nil")
//        }
        
        if !self.audioEngine.isRunning {
            return
        }
        self.audioEngine.stop()
    }
    
//    func lowiOS13SetupAudioUnit() {
//        var eore: OSStatus = noErr
//        var des: AudioComponentDescription = AudioComponentDescription(componentType: kAudioUnitType_Output, componentSubType: kAudioUnitSubType_VoiceProcessingIO, componentManufacturer: kAudioUnitManufacturer_Apple, componentFlags: 0, componentFlagsMask: 0)
//
//        let audioCom = AudioComponentFindNext(nil, &des)
//        guard let component = audioCom else{
//            debugPrint("------ AudioComponentFindNext  error")
//            return
//        }
//
//        eore = AudioComponentInstanceNew(component, &self.audioUnit)
//        if (eore != noErr) {
//            debugPrint("------ AudioComponentInstanceNew  error")
//            return
//        }
//        guard let audioUnit = audioUnit else{
//            debugPrint("------ audioUnit Init  error")
//            return
//        }
//
//        var propertySize = UInt32(MemoryLayout.size(ofValue: self._audioStreamBasicDescription))
//
//        //  设置 麦克风输出格式 及是否可输入
//        eore = AudioUnitSetProperty(audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 1, &self._audioStreamBasicDescription, propertySize)
//        if (eore != noErr) {
//            AudioComponentInstanceDispose(audioUnit)
//            debugPrint("----AudioUnitSetProperty BUS1  error")
//            return
//        }
//
//
////        var bus0PreSliceSIze = UInt32(MemoryLayout.size(ofValue: self._audioStreamBasicDescription))
////        // 设置扬声器输入格式
////        eore = AudioUnitSetProperty(audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &self._audioStreamBasicDescription, bus0PreSliceSIze)
////
////        if (eore != noErr) {
////            AudioComponentInstanceDispose(audioUnit)
////            debugPrint("----AudioUnitSetProperty BUS0  error")
////            return
////        }
//
//        var enable: UInt32 = 1
//        // 只使用输入
//        eore = AudioUnitSetProperty(audioUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, 1, &enable, UInt32(MemoryLayout.size(ofValue: enable)))
//        if (eore != noErr) {
//            AudioComponentInstanceDispose(audioUnit)
//            debugPrint("----AudioUnitSetProperty BUS1 enable  error")
//            return
//        }
//
//
//        var callback = AURenderCallbackStruct()
//        callback.inputProc = AudioRecorderRenderCallback
//        callback.inputProcRefCon = UnsafeMutableRawPointer.
//
//
//        eore = AudioUnitSetProperty(audioUnit, kAudioOutputUnitProperty_SetInputCallback, kAudioUnitScope_Global, 1, &callback, UInt32(MemoryLayout.size(ofValue: callback)))
//        if eore != noErr {
//            debugPrint("------ AudioUnitSetProperty-- kAudioOutputUnitProperty_SetInputCallback--- error")
//        }
//
//    }
    
//    func headRawPointerOfSelf() ->UnsafeMutableRawPointer {
//        let pointer = UnsafeMutableRawPointer.allocate(byteCount: MemoryLayout.size(ofValue: self), alignment: MemoryLayout<EchoCancellationViewController>.alignment)
//        pointer.storeBytes(of: <#T##T#>, as: <#T##T.Type#>)
//
//    }
    
    
}













struct AudioRenderContext {
    /// Audio device context received in AudioDevice's `startRendering:context` callback.
//    var deviceContext: TVIAudioDeviceContext
    /// Maximum frames per buffer.
    var maxFramesPerBuffer: size_t
    /// Buffer passed to AVAudioEngine's manualRenderingBlock to receive the mixed audio data.
    var bufferList: AudioBufferList
    /*
         * Points to AVAudioEngine's manualRenderingBlock. This block is called from within the VoiceProcessingIO playout
         * callback in order to receive mixed audio data from AVAudioEngine in real time.
         */
    var renderingBlock: UnsafeMutableRawPointer
    
    
}
