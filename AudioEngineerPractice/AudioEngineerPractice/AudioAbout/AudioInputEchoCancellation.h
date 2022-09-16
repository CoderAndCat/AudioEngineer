//
//  AudioInputEchoCancellation.h
//  AudioEngineerPractice
//
//  Created by 武文龙 on 2022/9/16.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^audioInputDataGet)(char *_Nullable buffer, int size);


@interface AudioInputEchoCancellation : NSObject

- (void)setOutputDataBlock: (audioInputDataGet)block;

- (void)audioInputStart;

- (void)audioInputStop;

- (instancetype)initWithAsbd: (AudioStreamBasicDescription)asbd;

@end

NS_ASSUME_NONNULL_END
