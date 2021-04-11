//
//  LJSignalAudioPlayer.h
//  Signaji
//
//  Created by Luca Cipressi on 24/12/2017.
//  Copyright © 2017 Zhouqi Mo. All rights reserved.
//

#import <Foundation/Foundation.h>
@class SignalEvent;

@interface LJSignalData : NSObject

@property (nonatomic) NSData* signalDataBuffer;


-(instancetype)initWithSignal:(SignalEvent*)cellSignal;
-(void)prepareForSignal:(SignalEvent*)cellSignal;
//-(instancetype)initWithFrequency:(float)frequency withVolume:(float)volume andWaveformType:(int)wavetype;
@end
