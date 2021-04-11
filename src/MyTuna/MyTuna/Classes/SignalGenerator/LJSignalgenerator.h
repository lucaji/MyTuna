//
//  LJSignalgenerator.h
//  Signaji
//
//  Created by Luca Cipressi on 24/12/2017.
//  Copyright © 2017 Zhouqi Mo. All rights reserved.
//

#import <Foundation/Foundation.h>
@class SignalEvent;

@interface LJSignalgenerator : NSObject

+(instancetype)singleton;

//-(void)prepareForSignalWithFrequency:(float)frequency withVolume:(float)volume andWaveformType:(int)wavetype;
-(void)prepareForSignal:(SignalEvent*)cellSignal;
-(void)playAudioPlayer;
-(void)stopAudioPlayer;

@end
