//
//  JKSAudioEnginePlayer.swift
//  JamKoo
//
//  Created by 武文龙 on 2022/4/15.
//  Copyright © 2022 XieLulu. All rights reserved.
//

import UIKit
import AVFAudio

class JKSAudioEnginePlayer: AVAudioPlayerNode {
    
    enum PlayStatus {
        case playing
        case pause
        case stop
        case complete
    }
    
    /// 是否需要 再次加载一次 播放计划
    private var needsFileScheduled = false
    /// 当前播放的音频文件
    private var file: AVAudioFile?
    /// 音频文件在内存中的采样率
    private var audioSampleRate: Double = 0
    /// 音频文件时长
    private var audioLengthSeconds: Double = 0
    /// 音频文件 seek 的帧数
    private var seekFrame: AVAudioFramePosition = 0
    /// 当前播放的帧数的位置
    private var currentPosition: AVAudioFramePosition = 0
   /// 音频文件帧数总量
    private var audioLengthSamples: AVAudioFramePosition = 0
    /// 播放状态
    private var playStatus = PlayStatus.stop {
        didSet {
            if playStatus == .complete {
                completeHandle?()
            }
        }
    }
    private var completeHandle: (()->())?
    /// 当前已经播放的帧数（针对当前 计划的片段 不是从音频开头算起）
    private var currentFrame: AVAudioFramePosition {
      guard
        let lastRenderTime = self.lastRenderTime,
        let playerTime = self.playerTime(forNodeTime: lastRenderTime)
      else {
        return 0
      }

      return playerTime.sampleTime
    }
    
//    private var fileBuffer = AVAudioPCMBuffer.init()
    override init() {
        super.init()
    }
    
    
    //MARK: API
    /// 当前播放文件时长
    var duration: Double {
        return self.audioLengthSeconds
    }
    /// 当前播放进度 s
    var currentTime: Double {
        let tmpFrame = currentFrame + seekFrame
        return Double(tmpFrame) / self.audioSampleRate
    }
    /// 加载音频
    func loadAudioFile(file: AVAudioFile, completeHandle: (()->())?) {
        self.file = file
        self.completeHandle = completeHandle
        let format = file.processingFormat
        audioLengthSamples = file.length
        audioSampleRate = format.sampleRate
        audioLengthSeconds = Double(audioLengthSamples) / audioSampleRate
        seekFrame = 0
        
        
        scheduleFile(file, at: nil) {
            [weak self] in
            guard let sself = self else{
//                JKprint("queue sself nil")
                return
            }
            sself.needsFileScheduled = true
            sself.playStatus = .complete
            sself.completeHandle?()
        }
        self.needsFileScheduled = false
    }
    /// 播放音频
    override func play() {

        guard let file = file else {
            return
        }
        if isPlaying {
            stop()
        }
        if needsFileScheduled {
            debugPrint("-- 音频从头播放-----")
            scheduleFile(file, at: nil) {
                [weak self] in
                guard let sself = self else{
                    debugPrint("queue sself nil")
                    return
                }
                sself.needsFileScheduled = true
                sself.playStatus = .complete
            }

            self.needsFileScheduled = false
            super.play()
        }else{
            super.play()
        }
        playStatus = .playing
    }
    override func pause() {
        super.pause()
        playStatus = .pause
    }
    /// 定位到 某个时间s 返回是否成功
    func seekTo(time: Double,completeHandle: (()->())?) ->Bool{
        
        guard let file = file , time < duration else {
            return false
        }
        self.completeHandle = completeHandle
        debugPrint("播放 seekTo ：\(time)s")
        let offset = AVAudioFramePosition(time * audioSampleRate)
        seekFrame = max(offset, 0)
        seekFrame = min(offset, audioLengthSamples)
        
        debugPrint("播放 seekToFrame:\(seekFrame)")
        let wasPlaying = isPlaying
        /// stop 代表 上个播放计划被 丢弃
        stop()
        
        
        let frameCount = AVAudioFrameCount(audioLengthSamples - seekFrame)

        debugPrint("lastframeCount: \(frameCount)------frameAmount:\(audioLengthSamples) ")
        scheduleSegment(file,
                        startingFrame: seekFrame,
                        frameCount: frameCount,
                        at: nil) {
            [weak self] in
            guard let sself = self else{
                debugPrint("queue sself nil")
                return
            }
            sself.needsFileScheduled = true
            sself.playStatus = .complete
            sself.completeHandle?()
        }
        self.needsFileScheduled = false
        if wasPlaying {
            super.play()
        }
        return true
    }
    /// 是否有 供播放的内容
    func hasContentForPlay() ->Bool{
        guard let _ = file else {
            return false
        }
        return true
    }
    /// 移除播放音频
    func removeFile() {
        self.file = nil
        stop()
    }
    /// 音频在内存中的格式
    func getFileProcessFormat() ->AVAudioFormat?{
        guard let file = file else {
            return nil
        }
        return file.processingFormat
    }
    //MARK: private
}
