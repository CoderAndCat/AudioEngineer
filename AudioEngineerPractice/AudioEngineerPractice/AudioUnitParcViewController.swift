//
//  AudioUnitParcViewController.swift
//  AudioEngineerPractice
//
//  Created by 武文龙 on 2022/2/20.
//

import UIKit
import AVFAudio

// https://juejin.cn/post/6980729874931515399#heading-27
// https://stackoverflow.com/questions/63213753/ios-audio-units-connecting-with-graphs

class AudioUnitParcViewController: UIViewController {
    /// 全局通用的采样率
    var graphSampleRate: Double = 44100.0
    /// 输入输出 延迟 s
    let ioBufferDuration: Double = 0.005
    /// 在 0.005 的延迟下 样本数量
    let ioBufferSampleCount: UInt32 = 256
    /// 输入输出的音频单元
    var audioUnit: AudioUnit?
    /// 输入音频 buffer数组
    var bufferList: AudioBufferList?
    /// 通道数
    let channelCount: UInt32 = 1
    /// 采样深度 16 位 即 两个字节
    let sampleDeepBytes: UInt32 = 2
    /// 每个packet 的 frame 个数
    let perPacketFrameCount: UInt32 = 1
    /// audioUnit InputElement
    let auInputElement: AudioUnitElement = 1
    /// audioUnit OutputElement
    let auOutputElement: AudioUnitElement = 0
    ///从 AURemoteIO 取回属性值。 我们将使用这个值来相应地分配缓冲区
    var maximumFramePerSlice: UInt32 = 0
    
    /// AudioInputFormat
    var asbd: AudioStreamBasicDescription?
    
   
    var auRenderCallBack: AURenderCallback?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setAuduiSession()
        initASBD()
        setupAudioUnit()
    }

    func setAuduiSession() {
        let aseesion = AVAudioSession.sharedInstance()
        do {
            try aseesion.setPreferredSampleRate(graphSampleRate)
            let samrate = aseesion.sampleRate
            try aseesion.overrideOutputAudioPort(.none)
            try aseesion.setCategory(.playAndRecord, options: [.allowBluetooth, .allowBluetoothA2DP])
            // 1.通过设置延迟，来控制 buffer 大小
            /**
             * 音频硬件 I/O buffer 时间。在44.1 kHz采样率下，默认持续时间约为23毫秒，相当于1024个采样的片大小。如果I/O延迟在你的应用中非常重要，你可以请求一个更短的持续时间，降低到 0.005毫秒 (相当于256个样本)
             */
            try aseesion.setPreferredIOBufferDuration(self.ioBufferDuration)
            debugPrint("----- 音频 IO buffer 延迟设置--：\(aseesion.preferredIOBufferDuration)秒 采样率：\(samrate)")
            
            try aseesion.setActive(true, options: .notifyOthersOnDeactivation)
            self.graphSampleRate = aseesion.sampleRate
        }catch let erroro {
            debugPrint("--- AudioSession 设置出错\(erroro.localizedDescription)")
        }
    }
    /// 初始化一个 asbd
    func initASBD() {
        // 样本数据为 Integer 和 设置样本位是否占据了通道的全部可用位，清除它们在通道内是高对齐还是低对齐。
        let afFlag: AudioFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked
        
        let perPacketBytes: UInt32 = self.channelCount * self.sampleDeepBytes * 1 * self.perPacketFrameCount
        let perFrameBytes: UInt32 = 1 * self.sampleDeepBytes * self.channelCount
        
        let asbdd: AudioStreamBasicDescription = AudioStreamBasicDescription.init(mSampleRate: Float64(self.graphSampleRate),
                                                                                 mFormatID: kAudioFormatLinearPCM,
                                                                                 mFormatFlags: afFlag,
                                                                                 mBytesPerPacket: perPacketBytes,
                                                                                 mFramesPerPacket: self.perPacketFrameCount,
                                                                                 mBytesPerFrame: perFrameBytes,
                                                                                 mChannelsPerFrame: self.channelCount,
                                                                                 mBitsPerChannel: self.channelCount * 16,
                                                                                 mReserved: 0)// mReserved参数: 填充结构以强制均匀的8字节对齐。必须设置为0。
        self.asbd = asbdd
        
    }
    /// 设置并初始化音频单元
    func setupAudioUnit() {
            
        //1. 配置一个音频单元说明符
        var ioUnitDescription = AudioComponentDescription.init(componentType:kAudioUnitType_Output,
                                                               componentSubType: kAudioUnitSubType_RemoteIO,
                                                               componentManufacturer: kAudioUnitManufacturer_Apple,
                                                               componentFlags: 0,
                                                               componentFlagsMask: 0)
        
        
        
        
    

        
        //2.获取音频单元指针
        
        guard let auComponent = AudioComponentFindNext(nil, &ioUnitDescription) else{
            debugPrint("----- AudioComponentFindNext(nil, &ioUnitDescription)")
            return
        }
        let auComponentStatus = AudioComponentInstanceNew(auComponent, &self.audioUnit)
        
        if auComponentStatus != noErr {
            debugPrint("---- AudioComponentInstanceNew(auComponent, &aunit) OSStatus Error")
        }
        guard let audioUnit = self.audioUnit else {
            debugPrint("---- audioUnit 初始化失败")
            return
        }
        
        // 3. 设置音频单元的相关属性
        self.setAudioUnitProperty(audioUt: audioUnit)
        
        // 4. 配置音频单元回调
        /// 音频单元回调
        /// - Parameters:
        ///   - inRefCon: 音频单元注册 回调时的自定义数据
        ///   - ioActionFlags: 用于描述有关此调用上下文的更多信息的标志（例如通知案例中的pre或post）。
        ///   - inTimeStamp: 与此音频单元渲染调用相关的时间戳。
        ///   - inBusNumber: 与此音频单元渲染调用关联的总线编号。
        ///   - inNumberFrames: 提供的ioData参数中音频数据中将表示的示例帧数。
        ///   - ioData: 用于包含渲染或提供的音频数据的AudioBufferList。
        /// - Returns: 结果代码
        self.auRenderCallBack = {(inRefCon, ioActionFlags, inTimeStamp, inBusNumber, inNumberFrames, ioData) ->OSStatus in
            // C 函数的 闭包里 不能 直接从外部引用self，需要通过下边这种方式 否则报错：A C function pointer cannot be formed from a closure that captures context
            
            let contBridge: AudioUnitParcViewController = Unmanaged<AudioUnitParcViewController>.fromOpaque(inRefCon).takeUnretainedValue()
            
            guard let audioUnit = contBridge.audioUnit else {
                debugPrint("-- 音频单元为空或音频buffer空 回调直接返回")
                return OSStatus.init(2.0)
            }
            guard  let ioDataRes = ioData else{
                debugPrint("--- 音频回调数据  nil ")
                return OSStatus.init(3.0)
            }
            
            if AudioUnitRender(audioUnit, ioActionFlags, inTimeStamp, 1, inNumberFrames, ioDataRes) != noErr {
                debugPrint("AudioUnitRender Error")
            }
            
            let auBuffer = ioDataRes.pointee.mBuffers
            
            let bufferSize = auBuffer.mDataByteSize
            if let bufferData = auBuffer.mData {
                debugPrint("--- bufferData字节，---size:\(bufferSize)")
            }else{
                debugPrint("--- bufferData 无数据")
            }
            
            
            return noErr
        }
        
        
        let selfPointer = UnsafeMutableRawPointer(mutating: UnsafeRawPointer(Unmanaged.passUnretained(self).toOpaque()))
        
        var auRenderCallbackStruct = AURenderCallbackStruct.init(inputProc: self.auRenderCallBack, inputProcRefCon: selfPointer)

        let setAuRenderCallbackStruce = AudioUnitSetProperty(audioUnit,
                                                             kAudioUnitProperty_SetRenderCallback,
                                                             kAudioUnitScope_Input,
                                                             self.auOutputElement,
                                                             &auRenderCallbackStruct,
                                                             UInt32(MemoryLayout.size(ofValue: auRenderCallbackStruct)))
        if setAuRenderCallbackStruce != noErr {
            debugPrint("---- 设置AudioUnit CallBackStruct 失败")
        }
            
        // 实例化音频单元
        if AudioUnitInitialize(audioUnit) != noErr {
            debugPrint("--- 音频单元 Initialize 失败")
            return
        }
            
        
    }
    func startAudioUnit() {
        guard let auit = self.audioUnit else{
            debugPrint("--- 开始音频单元失败-- 音频单元 nil")
            return
        }
        // .音频输入输出单元启动
        let aUnitStartOSStatus = AudioOutputUnitStart(auit)
        if aUnitStartOSStatus != noErr {
            debugPrint("---- 音频输入输出单元启动失败---- ")
        }
    }
    func stopAudioUnit() {
        guard let auit = self.audioUnit else{
            debugPrint("--- 开始音频单元失败-- 音频单元 nil")
            return
        }
        if AudioOutputUnitStop(auit) != noErr {
            debugPrint("---- 音频单元停止失败")
        }
    }
    
    /// 配置音频单元
    func setAudioUnitProperty(audioUt: AudioUnit) {
        guard var auForma = asbd else{
            debugPrint("-- audioFormat 为 空-----❌")
            return
        }
        
        
        var enableInput: UInt32 = 1
        var disableOutput: UInt32 = 0
        var enableOutput: UInt32 = 1
        //开启音频输入 音频单元默认 启用了输出，禁用了输入 在此处开启输入
        let openInputStatus = AudioUnitSetProperty(audioUt,
                                                   kAudioOutputUnitProperty_EnableIO,
                                                   kAudioUnitScope_Input,
                                                   self.auInputElement,
                                                   &enableInput,
                                                   UInt32(MemoryLayout.size(ofValue: enableInput)))
        if openInputStatus != noErr {
            debugPrint("---audioUnit OpenInput Error!")
        }
        
        var outputSwitch = false
        if outputSwitch {
            //打开输出
            if AudioUnitSetProperty(audioUt,
                                    kAudioOutputUnitProperty_EnableIO,
                                    kAudioUnitScope_Output,
                                    self.auOutputElement,
                                    &disableOutput,
                                    UInt32(MemoryLayout.size(ofValue: disableOutput))) != noErr
            {
                debugPrint("---- AudioUnitSetPro 打开输出错误")
            }
        }else {
            // 关闭输出（可以在 扬声器情况下 禁用输出）
            let closeOutputStatus = AudioUnitSetProperty(audioUt,
                                                         kAudioOutputUnitProperty_EnableIO,
                                                         kAudioUnitScope_Output,
                                                         self.auOutputElement,
                                                         &disableOutput,
                                                         UInt32(MemoryLayout.size(ofValue: disableOutput)))
            if closeOutputStatus != noErr {
                debugPrint("--- AudioUnit close Output Error!")
            }
        }
        
        // 设置连接两个 unit 的管道大小 与setPreferredIOBufferDuration 的大小有关 默认使用 4096
        var maxSlice: UInt32 = 4096
        
        /// 指定音频单元在一次调用其 AudioUnitRender(_:_:_:_:_:_:) 函数时准备提供的最大样本帧数。
        if AudioUnitSetProperty(audioUt,
                                kAudioUnitProperty_MaximumFramesPerSlice,
                                kAudioUnitScope_Global,
                                self.auOutputElement,
                                &maxSlice,
                                UInt32(MemoryLayout<UInt32>.stride)) != noErr
        {
            debugPrint("----- AudioUnit设置 最大切片出错")
        }
        
        
        // 从 AURemoteIO 取回属性值。 我们将使用这个值来相应地分配缓冲区
        if AudioUnitGetProperty(audioUt,
                                    kAudioUnitProperty_MaximumFramesPerSlice,
                                    kAudioUnitScope_Global,
                                    self.auOutputElement,
                                    &maxSlice,
                                    &maximumFramePerSlice) != noErr
        {
            debugPrint("--- 取回 maximumFramesPerSlice 出错")
        }
        
        
        // 设置输出格式
        let outPutFormatStatus = AudioUnitSetProperty(audioUt, kAudioUnitProperty_StreamFormat,
                                                      kAudioUnitScope_Output,
                                                      self.auInputElement,
                                                      &auForma,
                                                      UInt32(MemoryLayout.size(ofValue: auForma)))
        if outPutFormatStatus != noErr {
            debugPrint("--- audioUnit Output Stream Format Error!")
        }
        
       // 设置输入格式
        if AudioUnitSetProperty(audioUt, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, self.auOutputElement, &auForma, UInt32(MemoryLayout.size(ofValue: auForma))) != noErr {
            debugPrint("---- 设置音频输入格式错误")
        }
    }
    
    
    // MARK: - Action
    
    @IBAction func startTouch(_ sender: UIButton) {
        startAudioUnit()
    }
    
    @IBAction func stopTouch(_ sender: UIButton) {
        stopAudioUnit()
    }
}
