//
//  JKSMusicSequencer.swift
//  AudioEngineerPractice
//
//  Created by 武文龙 on 2022/7/13.
//

import Foundation
import AVFoundation

public class JKSMusicSequencer: NSObject {

    let callBack: (UnsafeMutableRawPointer?, MusicSequence, MusicTrack, MusicTimeStamp, UnsafePointer<MusicEventUserData>, MusicTimeStamp, MusicTimeStamp) -> Void = {
    (obj, seq, mt, timestamp, userData, timestamp2, timestamp3) in
    // 你不能使用 self 因为它是一个 C 类型的函数
      let mySelf: JKSMusicSequencer = unsafeBitCast(obj, to: JKSMusicSequencer.self)
   
  }
    
    var sequencer: AVAudioSequencer
    
    var musicSequencerFromAuEngine: MusicSequence?
    
    
    
    
    init(auEng: AVAudioEngine) {
        self.sequencer = AVAudioSequencer.init(audioEngine: auEng)
        super.init()
        self.musicSequencerFromAuEngine = auEng.musicSequence
        
    }
    
    func addCallback() {
        guard let musicSequencerFromAuEngine = musicSequencerFromAuEngine else {
            debugPrint("---- auEngine.musicSequence ----- nil")
            return
        }
        
        // 在歌曲的结尾放一个回调
        let error = MusicSequenceSetUserCallback(musicSequencerFromAuEngine, {
            (obj, seq, mt, timestamp, userData, timestamp2, timestamp3) in
            // 你不能使用 self 因为它是一个 C 类型的函数
            
            let client = unsafeBitCast(obj, to: JKSMusicSequencer.self)
            client.musicSequenceCallback(sequence: seq, track: mt, eventTime: timestamp, data: userData, startSliceBeat: timestamp2, endSliceBeat: timestamp3)
            debugPrint("---- 音序器回调----")
            
        }, unsafeBitCast(self, to: UnsafeMutableRawPointer.self))
        if error != 0 {
            debugPrint("----- JKSSequencer 设置回调出错：\(error)")
        }
//        var musicTrack: MusicTrack? = nil
//        MusicSequenceGetIndTrack(musicSequence, 0, &musicTrack)
//        let userData: UnsafeMutablePointer<MusicEventUserData> = UnsafeMutablePointer.alloc(1)
//        MusicTrackNewUserEvent(musicTrack, ceil(musicLengthInBeats), userData)
    }
    
    func musicSequenceCallback(sequence: MusicSequence, track: MusicTrack, eventTime: MusicTimeStamp, data: UnsafePointer<MusicEventUserData>, startSliceBeat: MusicTimeStamp, endSliceBeat: MusicTimeStamp) {
        debugPrint("-----此次出 调用 音序器，获取拍号等。")
    }
    
}

