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
    let ioBufferDuration: Double = 0.000005
    /// 在 0.005 的延迟下 样本数量
    let ioBufferSampleCount: UInt32 = 256
    /// 输入输出的音频单元
    var audioUnit: AVAudioUnit?
    /// 输入音频 buffer数组
    var bufferList: AudioBufferList?
    /// 通道数
    let perFrameChannelCount: UInt32 = 1
    /// 采样深度 16 位 即 两个字节
    let sampleDeepBytes: UInt32 = 2
    /// 持有buffer 数量
    let packetBufferCount: UInt32 = 1
    /// AudioInputFormat
    var inputAudioFormat: AudioStreamBasicDescription?
    
   
    var auRenderCallBack: AURenderCallback?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpAudioUnit()
    }


    func setUpAudioUnit() {
        let aseesion = AVAudioSession.sharedInstance()
        do {
            /* 配置 AVAudioSession**/
            try aseesion.setPreferredSampleRate(graphSampleRate)
            let samrate = aseesion.preferredSampleRate
            debugPrint("---- 采样率设置 --- \(samrate)")
            
            try aseesion.setCategory(.playAndRecord)
            try aseesion.setActive(true, options: AVAudioSession.SetActiveOptions.notifyOthersOnDeactivation)
            self.graphSampleRate = aseesion.sampleRate
            
            
            // 1.通过设置延迟，来控制 buffer 大小
            /**
             * 音频硬件 I/O buffer 时间。在44.1 kHz采样率下，默认持续时间约为23毫秒，相当于1024个采样的片大小。如果I/O延迟在你的应用中非常重要，你可以请求一个更短的持续时间，降低到 0.005毫秒 (相当于256个样本)
             */
            try aseesion.setPreferredIOBufferDuration(self.ioBufferDuration)
            debugPrint("----- 音频 IO buffer 延迟设置--：\(aseesion.preferredIOBufferDuration)秒")
            
            
            //2. 配置一个音频单元说明符
            var ioUnitDescription = AudioComponentDescription.init(componentType:
                                                                    kAudioUnitType_Output,
                                                                   componentSubType: kAudioUnitSubType_RemoteIO,
                                                                   componentManufacturer: kAudioUnitManufacturer_Apple,
                                                                   componentFlags: 0,
                                                                   componentFlagsMask: 0)
            
            
            
            
            
            // 一种不推荐的获取 音频单元的方法
//            var ioUnitInstance: AudioUnit?
//            if let foundIoUnitReference = AudioComponentFindNext(nil, &ioUnitDescription) {
//
//                AudioComponentInstanceNew(foundIoUnitReference, &ioUnitInstance)
//            }else{
//                debugPrint("---- 音频单元获取出错")
//                return
//            }
            
            //3.获取音频单元 推荐获取音频单元的方法
            var components = [AVAudioUnitComponent]()
            components = AVAudioUnitComponentManager.shared().components(matching: ioUnitDescription)
            debugPrint("---- 获取指定类型的音频单元 数组 \(components.count) 个")
            if let firstAudioUnit = components.first {
                ioUnitDescription = firstAudioUnit.audioComponentDescription
                
                
                
                // 实例化 AVAudioUnit
                AVAudioUnit.instantiate(with: ioUnitDescription) { audioUnitOption, eorr in

                    if let er = eorr {
                        debugPrint("---- 音频单元实例化出错-- \(er.localizedDescription)")
                    }
                    
                    guard let audioUnitt = audioUnitOption else{
                        debugPrint("------ 拿到了音频单元")
                        return
                    }
                    self.audioUnit = audioUnitt
                        
                    
                    self.initAudioFormat()
                 
                    self.initCaptureAudioBufferWithAudioUnit(adun: audioUnitt.audioUnit, dataBytes: self.ioBufferSampleCount * self.sampleDeepBytes)
                    
                    
                    let audioUnitName = audioUnitt.name
                    let audioUnitManufactureName = audioUnitt.manufacturerName
                    let audioUnitVersion = audioUnitt.version
                    debugPrint("音频单元audioUnit -- name:\(audioUnitName)-manufactureName:\(audioUnitManufactureName)-version:\(audioUnitVersion)")
                    
                    // 3.1配置音频单元属性
                    self.setAudioUnit(audioUt: audioUnitt.audioUnit)
                    
                    // 3.2 配置音频单元回调
                    
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
                        
//                        debugPrint("---- 音频输入回调 inNumberFrames:\(inNumberFrames)---ioData:\(ioData?.pointee.mNumberBuffers)")
                        
                        let contBridge: AudioUnitParcViewController = Unmanaged<AudioUnitParcViewController>.fromOpaque(inRefCon).takeUnretainedValue()
                        
                        guard let audioUnit = contBridge.audioUnit, var iobflist = contBridge.bufferList else {
                            debugPrint("-- 音频单元为空或音频buffer空 回调直接返回")
                            return OSStatus.init(2.0)
                        }
                        
                        AudioUnitRender(audioUnit.audioUnit, ioActionFlags, inTimeStamp, inBusNumber, inNumberFrames, &iobflist)
                        
//                        let bufferData = iobflist->mBuffers[0].mData
//                        let bufferSize = iobflist->mBuffers[0].mDataByteSize
                        
//
                        return noErr
                    }
                            
                    let enableInputBus: AudioUnitElement = 1
                    
                    let selfPointer = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
                    
                    var auRenderCallbackStruct = AURenderCallbackStruct.init(inputProc: self.auRenderCallBack, inputProcRefCon: selfPointer)

                    
                    
                    let setAuRenderCallbackStruce = AudioUnitSetProperty(audioUnitt.audioUnit, kAudioOutputUnitProperty_SetInputCallback, kAudioUnitScope_Global, enableInputBus, &auRenderCallbackStruct, UInt32(MemoryLayout.size(ofValue: auRenderCallbackStruct)))
                    if setAuRenderCallbackStruce != noErr {
                        debugPrint("---- 设置AudioUnit CallBackStruct 失败")
                    }
                    
                    
                    // 3.3 实例化 AudioUnit
                    let audioUnitOSStatus = AudioUnitInitialize(audioUnitt.audioUnit)
                    if audioUnitOSStatus != noErr {
                        debugPrint("---- audioUnit 实例化出错")
                    }
                    
                    
                    // 音频输入输出单元启动
                    let aUnitStartOSStatus = AudioOutputUnitStart(audioUnitt.audioUnit)
                    if aUnitStartOSStatus != noErr {
                        debugPrint("---- 音频输入输出单元启动失败---- ")
                    }
                }
            }
            
            
            
        } catch let error {
            debugPrint("配置 AudioUnit 出错 \(error.localizedDescription)")
        }
        
        
    }
    
    
    /// 初始化音频格式
    func initAudioFormat() {

        // 样本数据为 Integer 和 设置样本位是否占据了通道的全部可用位，清除它们在通道内是高对齐还是低对齐。
        let afFlag: AudioFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked
        
        let perPacketBytes: UInt32 = self.perFrameChannelCount * self.sampleDeepBytes * 1
        let perFrameBytes: UInt32 = 1 * self.sampleDeepBytes * self.perFrameChannelCount
        
        var asbd: AudioStreamBasicDescription = AudioStreamBasicDescription()
        
        // mReserved参数: 填充结构以强制均匀的8字节对齐。必须设置为0。
        asbd.mSampleRate = Float64(self.graphSampleRate)
        asbd.mFormatID = kAudioFormatLinearPCM
        asbd.mFormatFlags = afFlag
        asbd.mBytesPerPacket = perPacketBytes
        asbd.mFramesPerPacket = UInt32(1)
        asbd.mBytesPerFrame = perFrameBytes
        asbd.mChannelsPerFrame = self.perFrameChannelCount
        asbd.mBitsPerChannel = self.sampleDeepBytes * UInt32(8)
        asbd.mReserved = 0
//        asbd = AudioStreamBasicDescription.init(mSampleRate: Float64(self.graphSampleRate),
//                                                    mFormatID: kAudioFormatLinearPCM,
//                                                    mFormatFlags: afFlag,
//                                                    mBytesPerPacket: perPacketBytes,
//                                                    mFramesPerPacket: 1,
//                                                    mBytesPerFrame: perFrameBytes,
//                                                    mChannelsPerFrame: self.perFrameChannelCount,
//                                                    mBitsPerChannel: self.sampleDeepBytes * UInt32(8),
//                                                    mReserved: 0)
        
        self.inputAudioFormat = asbd
    }
    /// 通过 audioUnit 捕捉buffer
    func initCaptureAudioBufferWithAudioUnit(adun: AudioUnit, dataBytes: UInt32) {
        
        var flag: UInt32 = 0
        let inputBus: AudioUnitElement = 1
        let status = AudioUnitSetProperty(adun, kAudioUnitProperty_ShouldAllocateBuffer, kAudioUnitScope_Output, inputBus, &flag, UInt32(MemoryLayout.size(ofValue: flag)))
        if status != noErr {
            debugPrint("---- 音频单元 setProperty，出错")
            return
        }
        
        let memory = malloc(Int(dataBytes))
        var aoBuffer = AudioBuffer.init(mNumberChannels: self.perFrameChannelCount, mDataByteSize: dataBytes, mData: memory)
        aoBuffer.mNumberChannels = self.perFrameChannelCount
        
        self.bufferList = AudioBufferList.init(mNumberBuffers: self.packetBufferCount, mBuffers: aoBuffer)
    }
    /// 配置音频单元
    func setAudioUnit(audioUt: AudioUnit) {
        guard var auForma = inputAudioFormat else{
            debugPrint("-- audioFormat 为 空-----❌")
            return
        }
      
        let inputBus: AudioUnitElement = 1
        
        let outPutFormatStatus = AudioUnitSetProperty(audioUt, kAudioUnitProperty_StreamFormat,
                                                      kAudioUnitScope_Output,
                                                      inputBus,
                                                      &auForma,
                                                      UInt32(MemoryLayout.size(ofValue: auForma)))
        if outPutFormatStatus != noErr {
            debugPrint("--- audioUnit Output Stream Format Error!")
        }
        
        var enableInput: UInt32 = 1
        var disableOutput: UInt32 = 0
        var enableOutput: UInt32 = 1
        let outputBus: AudioUnitElement = 0
        // 音频单元默认 启用了输出，禁用了输入 在此处开启输入
        
        let openInputStatus = AudioUnitSetProperty(audioUt,
                                                   kAudioOutputUnitProperty_EnableIO,
                                                   kAudioUnitScope_Input,
                                                   inputBus,
                                                   &enableInput,
                                                   UInt32(MemoryLayout.size(ofValue: enableInput)))
        if openInputStatus != noErr {
            debugPrint("---audioUnit OpenInput Error!")
        }
        
        // 可以在 扬声器情况下 禁用输出
        let closeOutputStatus = AudioUnitSetProperty(audioUt,
                                                     kAudioOutputUnitProperty_EnableIO,
                                                     kAudioUnitScope_Output,
                                                     outputBus,
                                                     &enableOutput,
                                                     UInt32(MemoryLayout.size(ofValue: enableOutput)))
        if closeOutputStatus != noErr {
            debugPrint("--- AudioUnit close Output Error!")
        }
    }
    
    
}
