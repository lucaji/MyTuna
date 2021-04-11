//
//  LJSignalAudioPlayer.m
//  Signaji
//
//  Created by Luca Cipressi on 24/12/2017.
//  Copyright © 2017 Zhouqi Mo. All rights reserved.
//

#import "LJSignalData.h"
#import "MyTuna-Swift.h"

#define kLJ_SAMPLING_FREQUENCY 44100.0

@interface LJSignalData()

@property (nonatomic) int bufferSize;
@property (nonatomic) NSNumber *signalNumber;

@end

@implementation LJSignalData

+(int)cycleSizeForFrequency:(float)frequency {
    return ceilf(kLJ_SAMPLING_FREQUENCY/frequency)-1;
}

+(int)bufferSizeForCycleSize:(int)cycleSize {
    return cycleSize * 10000;
}

+(float*)sineWaveWithFrequency:(float)frequency andVolume:(float)volume {
    int cycleSize = [LJSignalData cycleSizeForFrequency:frequency];
    int bufferSize = [LJSignalData bufferSizeForCycleSize:cycleSize];

    float*audioBuffer = (float *)malloc(bufferSize * sizeof(float));
    for (int j = 0; j < bufferSize-1; j++) {
        audioBuffer[j] = sinf(M_PI*2*frequency*j/kLJ_SAMPLING_FREQUENCY)*volume;
    }
    return audioBuffer;
}

+(float*)squareWaveWithFrequency:(float)frequency andVolume:(float)volume {
    int cycleSize = [LJSignalData cycleSizeForFrequency:frequency];
    int bufferSize = [LJSignalData bufferSizeForCycleSize:cycleSize];

    float*audioBuffer = (float *)malloc(bufferSize * sizeof(float));
    for (int i = 0; i < bufferSize; i+=cycleSize) {
        for (int j = i; j < i+(cycleSize/2); j++) {
            audioBuffer[j] = volume;
        }
        for (int j = i+(cycleSize/2); j < (i+cycleSize); j++) {
            audioBuffer[j] = 0;
        }
    }
    return audioBuffer;
}

+(float*)sawWaveWithFrequency:(float)frequency andVolume:(float)volume {
    int cycleSize = [LJSignalData cycleSizeForFrequency:frequency];
    int bufferSize = [LJSignalData bufferSizeForCycleSize:cycleSize];

    float*audioBuffer = (float *)malloc(bufferSize * sizeof(float));
    for (int j = 0; j < bufferSize; j+=cycleSize) {
        for (int i = j; i < j+(cycleSize/4); i++) {
            audioBuffer[i] = volume*4*(i-j)*frequency/kLJ_SAMPLING_FREQUENCY;
        }
        for (int i = j+(cycleSize/4); i < j+3*cycleSize/4; i++) {
            audioBuffer[i] = volume - volume*4*((i-j)-cycleSize/4)*frequency/kLJ_SAMPLING_FREQUENCY;
        }
        for (int i = j+3*cycleSize/4; i < j+cycleSize; i++) {
            audioBuffer[i] = -volume*2 + volume*4*((i-j)-2*cycleSize/4)*frequency/kLJ_SAMPLING_FREQUENCY;
        }
    }
    return audioBuffer;
}

-(instancetype)initWithSignal:(SignalEvent*)cellSignal {
    self = [super init]; if (!self) return nil;
    [self prepareForSignal:cellSignal];
    return self;
}

-(void)prepareForSignalWithFrequency:(float)frequency withVolume:(float)volume andWaveformType:(int)wavetype {
    int cycleSize = [LJSignalData cycleSizeForFrequency:frequency];
    self.bufferSize = [LJSignalData bufferSizeForCycleSize:cycleSize];
    
    float* audioBuffer = nil;
    switch (wavetype) {
        case 0:
            audioBuffer = [LJSignalData sineWaveWithFrequency:frequency andVolume:volume];
            break;
        case 1:
            audioBuffer = [LJSignalData squareWaveWithFrequency:frequency andVolume:volume];
            break;
        case 2:
            audioBuffer = [LJSignalData sawWaveWithFrequency:frequency andVolume:volume];
            break;
        default:
            NSLog(@"%s unknown signalType.", __PRETTY_FUNCTION__);
            return;
    }
    self.signalDataBuffer = [LJSignalData dataForAudioBuffer:audioBuffer withBufferSize:self.bufferSize];
}

-(void)prepareForSignal:(SignalEvent*)cellSignal {
    float frequency = [cellSignal.signalFrequency floatValue];
    assert (frequency > 0);
    float volume = [cellSignal.signalVolume floatValue];
    [self prepareForSignalWithFrequency:frequency withVolume:volume andWaveformType:cellSignal.signalType.intValue];
}

+(NSData *)dataForAudioBuffer:(float*)audioBuffer withBufferSize:(int)bufferSize   {
    
    unsigned int payloadSize = bufferSize * sizeof(SInt16);     // byte size of waveform data
    unsigned int wavSize = 44 + payloadSize;                    // total byte size
    
    // Allocate a memory buffer that will hold the WAV header and the
    // waveform bytes.
    SInt8 *wavBuffer = (SInt8 *)malloc(wavSize);
    if (wavBuffer == NULL) {
        NSLog(@"Error allocating %u bytes", wavSize);
        return nil;
    }
    
    memset(wavBuffer, 0x00, wavSize);
    
    // Fake a WAV header.
    SInt8 *header = (SInt8 *)wavBuffer;
    header[0x00] = 'R';
    header[0x01] = 'I';
    header[0x02] = 'F';
    header[0x03] = 'F';
    header[0x08] = 'W';
    header[0x09] = 'A';
    header[0x0A] = 'V';
    header[0x0B] = 'E';
    header[0x0C] = 'f';
    header[0x0D] = 'm';
    header[0x0E] = 't';
    header[0x0F] = ' ';
    header[0x10] = 16;    // size of format chunk (always 16)
    header[0x11] = 0;
    header[0x12] = 0;
    header[0x13] = 0;
    header[0x14] = 1;     // 1 = PCM format
    header[0x15] = 0;
    header[0x16] = 1;     // number of channels
    header[0x17] = 0;
    header[0x18] = 0x44;  // samples per sec (44100)
    header[0x19] = 0xAC;
    header[0x1A] = 0;
    header[0x1B] = 0;
    header[0x1C] = 0x88;  // bytes per sec (88200)
    header[0x1D] = 0x58;
    header[0x1E] = 0x01;
    header[0x1F] = 0;
    header[0x20] = 2;     // block align (bytes per sample)
    header[0x21] = 0;
    header[0x22] = 16;    // bits per sample
    header[0x23] = 0;
    header[0x24] = 'd';
    header[0x25] = 'a';
    header[0x26] = 't';
    header[0x27] = 'a';
    
    *((SInt32 *)(wavBuffer + 0x04)) = payloadSize + 36;   // total chunk size
    *((SInt32 *)(wavBuffer + 0x28)) = payloadSize;        // size of waveform data
    
    // Convert the floating point audio data into signed 16-bit.
    SInt16 *payload = (SInt16 *)(wavBuffer + 44);
    for (int t = 0; t < bufferSize; ++t) {
        payload[t] = audioBuffer[t] * 0x7fff;
    }
    
    // Put everything in an NSData object.
    NSData *data = [[NSData alloc] initWithBytesNoCopy:wavBuffer length:wavSize];
    return data;
}


@end
