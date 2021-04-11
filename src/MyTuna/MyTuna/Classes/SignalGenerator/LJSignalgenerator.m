//
//  LJSignalgenerator.m
//  Signaji
//
//  Created by Luca Cipressi on 24/12/2017.
//  Copyright © 2017 Zhouqi Mo. All rights reserved.
//

#import "LJSignalgenerator.h"
#import "LJSignalData.h"

#import "MyTuna-Swift.h"
#import <AVFoundation/AVFoundation.h>

#define MP3HEADER   44

@interface LJSignalgenerator() <AVAudioPlayerDelegate>

@property (nonatomic) SignalEvent *cellSignal;
@property (nonatomic) LJSignalData* signalData;

@property (nonatomic) AVAudioPlayer *audioPlayer;

@end

@implementation LJSignalgenerator

+(instancetype)singleton {
    static LJSignalgenerator*_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[[self class] alloc] init];
    });
    return _sharedInstance;
}

-(instancetype)init {
    self = [super init]; if (!self) return nil;
    self.cellSignal = nil;
    self.signalData = nil;
    self.audioPlayer = nil;
    return self;
}

//-(instancetype)initWithFrequency:(float)frequency withVolume:(float)volume andWaveformType:(int)wavetype {
//    self = [super init]; if (!self) return nil;
//    self.cellSignal = nil;
//    self.signalData = [[LJSignalData alloc] initWithFrequency:frequency withVolume:volume andWaveformType:wavetype];
//    self.audioPlayer = nil;
//    return self;
//}

-(void)prepareForSignal:(SignalEvent*)cellSignal {
    self.cellSignal = cellSignal;
    self.signalData = [[LJSignalData alloc] initWithSignal:cellSignal];

    __autoreleasing NSError *error = nil;
    self.audioPlayer = [[AVAudioPlayer alloc] initWithData:self.signalData.signalDataBuffer error:&error];
    [self.audioPlayer prepareToPlay];
}

-(void)playAudioPlayer  {
    if (self.audioPlayer) {
        [self.audioPlayer setNumberOfLoops:-1];
        [self.audioPlayer play];
    }
}

-(void)stopAudioPlayer  {
    if (self.audioPlayer) {
        [self.audioPlayer stop];
    }
}




@end
