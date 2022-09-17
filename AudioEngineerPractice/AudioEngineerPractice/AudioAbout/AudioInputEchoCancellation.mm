//
//  AudioInputEchoCancellation.m
//  AudioEngineerPractice
//
//  Created by 武文龙 on 2022/9/16.
//

#import "AudioInputEchoCancellation.h"
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>

@interface AudioInputEchoCancellation()

@property (nonatomic, assign) AudioUnit audioUnit;

@property (copy) audioInputDataGet outDataBlock;

@property (nonatomic, assign) UInt32 maximumFramesPerSlice;

@property (nonatomic, assign) AudioBufferList* pInputAudioBufferList;

@property (nonatomic, assign) AudioStreamBasicDescription asbd;



@end



@implementation AudioInputEchoCancellation



- (instancetype)initWithAsbd: (AudioStreamBasicDescription)asbd
{
    self = [super init];
    if (!self) return nil;
    
    _asbd = asbd;
    AudioComponentDescription des;
    des.componentFlags = 0;
    des.componentFlagsMask = 0;
    des.componentManufacturer = kAudioUnitManufacturer_Apple;
    des.componentType = kAudioUnitType_Output;
    des.componentSubType = kAudioUnitSubType_VoiceProcessingIO;
    
    AudioComponent audioComponent;
    audioComponent = AudioComponentFindNext(NULL, &des);
    OSStatus ret = AudioComponentInstanceNew(audioComponent, &_audioUnit);
    if (ret != noErr) {
        return nil;
    }
    
    
    UInt32 flags = 1;
    /// 打开输入口
    ret = AudioUnitSetProperty(self.audioUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, 1, &flags, sizeof(flags));
    if (ret != noErr) return nil;
    /// 输入总线的输出格式
    ret = AudioUnitSetProperty(self.audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 1, &asbd, sizeof(asbd));
    if (ret != noErr) return nil;
    
    /// 输出总线的输入格式
    ret = AudioUnitSetProperty(self.audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &asbd, sizeof(asbd));
    if (ret != noErr) return nil;
    
    
    /// 麦克风 每次运送最大帧数
    UInt32 framePerSliceSize = sizeof(_maximumFramesPerSlice);
    ret = AudioUnitGetProperty(self.audioUnit, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, 0, &_maximumFramesPerSlice, &framePerSliceSize);
    if (ret != noErr) return nil;
    
    
//    AURenderCallbackStruct renderCallback;
//    renderCallback.inputProc = AudioRenderCallback;
//    renderCallback.inputProcRefCon = (__bridge void* _Nullable)(self);
//    ret = AudioUnitSetProperty(self.audioUnit, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Output, 0, &renderCallback, sizeof(renderCallback));
//    if (ret != noErr) return nil;
    
    
    AURenderCallbackStruct inputCallback;
    inputCallback.inputProc = audioInputCallback;
    inputCallback.inputProcRefCon = (__bridge void* _Nullable)(self);
    
    ret = AudioUnitSetProperty(_audioUnit, kAudioOutputUnitProperty_SetInputCallback, kAudioUnitScope_Input, 1, &inputCallback, sizeof(inputCallback));
    
    if (ret != noErr) return nil;

    ret = AudioUnitInitialize(self.audioUnit);
    if (ret != noErr) return nil;
    
    return self;
}
/// 设置数据输出block
- (void)setOutputDataBlock:(audioInputDataGet)block {
    self.outDataBlock = block;
}



static OSStatus audioInputCallback(void *inRefCon, AudioUnitRenderActionFlags *ioActionFlags, const AudioTimeStamp *inTimeStamp, UInt32 inBusNumber, UInt32 inNumberFrame, AudioBufferList *__nullable ioData)
{
    AudioInputEchoCancellation *r = (__bridge AudioInputEchoCancellation *)(inRefCon);
    // 这里被坑惨了AudioBufferList如果自己初始化并且分配mData内存 在AVAudioSessionCategoryPlayAndRecord模式并且使用扬声器播放时 AudioUnitRender时会返回-50 kAudioOutputUnitProperty_SetInputCallback有说明 Note that the inputProc will always receive a NULL AudioBufferList in ioData猜测应该是系统要自己控制AudioBufferList.mData的内存分配与释放 将AudioBufferList每次回调才初始化并且mData传NULL解决此问题
    AudioBufferList list;
    list.mNumberBuffers = 1;
    list.mBuffers[0].mData = NULL;
    list.mBuffers[0].mDataByteSize = 0;
    list.mBuffers[0].mNumberChannels = 1;
    
    
    OSStatus error = AudioUnitRender(r.audioUnit, ioActionFlags, inTimeStamp, inBusNumber, inNumberFrame, &list);
    
    if (error != noErr)
        NSLog(@"record_callback error : %d", error);
    
    
    if (r.outDataBlock) {
        r.outDataBlock(&list);
    }
//    int size = list->mBuffers[0].mDataByteSize;
//    char *src = (char*)list->mBuffers[0].mData;
//    if (size > 0 && src)
//    {
//        char *dst = (char*)calloc(1, size);
//        memcpy(dst, src, size);
//        if (r.outDataBlock) {
//            r.outDataBlock(dst, size);
//        }else{
//            NSLog(@"record_callback error outDataBlock Nil");
//        }
//    }else{
//        NSLog(@"record_callback error  size < 0");
//    }
    return noErr;
}

- (void)audioInputStart {
    AudioOutputUnitStart(self.audioUnit);
}
- (void)audioInputStop {
    AudioOutputUnitStop(self.audioUnit);
}

- (void)dealloc {
    self.outDataBlock = NULL;
}

@end
