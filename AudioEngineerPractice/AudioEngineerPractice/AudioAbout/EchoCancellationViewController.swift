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
    
    
    
    let AudioRecorderRenderCallback: AURenderCallback = {(inRefCon: UnsafeMutableRawPointer, ioActionFlags: UnsafeMutablePointer<AudioUnitRenderActionFlags>, inTimeStamp:UnsafePointer<AudioTimeStamp>, inBusNumber: UInt32, inNumberFrames: UInt32, ioData: UnsafeMutablePointer<AudioBufferList>?) -> OSStatus in
        
        guard let ioData_ = ioData else{
            return 123
        }
        
        let context = inRefCon.load(as: AudioRenderContext.self)
        var eore: OSStatus = noErr
        
        
        /*
         typealias AVAudioEngineManualRenderingBlock = (AVAudioFrameCount, UnsafeMutablePointer<AudioBufferList>, UnsafeMutablePointer<OSStatus>?) -> AVAudioEngineManualRenderingStatus
         */
        let renderingBlock: AVAudioEngineManualRenderingBlock = context.renderingBlock.load(as: AVAudioEngineManualRenderingBlock.self)
        
        let renderingStatus = renderingBlock(inNumberFrames, ioData_, &eore)
        
        if (renderingStatus != AVAudioEngineManualRenderingStatus.success) {
            debugPrint("---- renderingBlock fail----")
            return eore
        }
        
        return eore
    }
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupAudioInputLowiOS13()
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
        
        echoObj.setOutputDataBlock { dataPointer, size in
            if let dataPointer_ = dataPointer {
                var dataArray = [Int8]()
                for i in 0..<size {
                    let dataPointerIn = dataPointer_ + Int(i)
                    dataArray.append(Int8(dataPointerIn.pointee))
                }
               
                let audioData = Data.init(bytes: dataArray, count: dataArray.count)
                
                debugPrint("---- 收到音频输入 数据解析大小:\(audioData.count) 大小：\(size)")
            }else{
                debugPrint("---- 收到数据 nil  大小：\(size)")
            }
        }
        
        
    }
    
    func setupAudioEngine() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, options: .defaultToSpeaker)
            if #available(iOS 13.0, *) {
                try micNode.setVoiceProcessingEnabled(true)
            }else{
                
            }
            try AVAudioSession.sharedInstance().setPreferredSampleRate(44100)
            
            self.audioEngine.attach(audioin)
            
            
            let format = micNode.outputFormat(forBus: 0)
            self._audioStreamBasicDescription = format.streamDescription.pointee

            self.audioEngine.connect(endMixNode, to: self.audioEngine.outputNode, format: format)
            debugPrint("---- 音频引擎格式 :\(format.settings)")
        } catch let eore {
            debugPrint("---- 音频引擎设置出错：\(eore.localizedDescription)")
        }
        
        
    }

    @IBAction func startEngine(_ sender: UIButton) {
        if let echoCancelObj_ = echoCancelObj {
            echoCancelObj_.audioInputStart()
        }else{
            debugPrint("---- 回声消除对象 nil")
        }
        
        if self.audioEngine.isRunning {
            return
        }
        do {
            try self.audioEngine.start()
        } catch let erore {
            debugPrint("----- 音频引擎启动出错--- :\(erore.localizedDescription)")
        }
    }
    
    
    
    @IBAction func stopEngine(_ sender: UIButton) {
        
        if let echoCancelObj_ = echoCancelObj {
            echoCancelObj_.audioInputStop()
        }else{
            debugPrint("---- 回声消除对象 nil")
        }
        
//        if !self.audioEngine.isRunning {
//            return
//        }
//        self.audioEngine.stop()
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
