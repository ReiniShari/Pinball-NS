/* mini SDK (see ../../README.md): the RemoteIO output unit of AudioToolbox */
#ifndef PNS_AUDIOTOOLBOX_H
#define PNS_AUDIOTOOLBOX_H

#include <stdint.h>

typedef uint32_t UInt32;
typedef int32_t SInt32;
typedef double Float64;
typedef UInt32 OSType;
typedef SInt32 OSStatus;

typedef struct OpaqueAudioComponent *AudioComponent;
typedef struct ComponentInstanceRecord *AudioComponentInstance;
typedef AudioComponentInstance AudioUnit;

typedef struct AudioComponentDescription {
    OSType componentType, componentSubType, componentManufacturer;
    UInt32 componentFlags, componentFlagsMask;
} AudioComponentDescription;

typedef struct AudioStreamBasicDescription {
    Float64 mSampleRate;
    UInt32 mFormatID, mFormatFlags, mBytesPerPacket, mFramesPerPacket, mBytesPerFrame;
    UInt32 mChannelsPerFrame, mBitsPerChannel, mReserved;
} AudioStreamBasicDescription;

typedef struct AudioBuffer { UInt32 mNumberChannels; UInt32 mDataByteSize; void *mData; } AudioBuffer;
typedef struct AudioBufferList { UInt32 mNumberBuffers; AudioBuffer mBuffers[1]; } AudioBufferList;
typedef struct AudioTimeStamp AudioTimeStamp;          /* only passed by address here */
typedef UInt32 AudioUnitRenderActionFlags;
typedef UInt32 AudioUnitPropertyID;
typedef UInt32 AudioUnitScope;
typedef UInt32 AudioUnitElement;

typedef OSStatus (*AURenderCallback)(void *inRefCon, AudioUnitRenderActionFlags *ioActionFlags,
                                     const AudioTimeStamp *inTimeStamp, UInt32 inBusNumber,
                                     UInt32 inNumberFrames, AudioBufferList *ioData);
typedef struct AURenderCallbackStruct { AURenderCallback inputProc; void *inputProcRefCon; } AURenderCallbackStruct;

enum {
    kAudioUnitType_Output = 0x61756F75,             /* 'auou' */
    kAudioUnitSubType_RemoteIO = 0x72696F63,        /* 'rioc' */
    kAudioUnitSubType_DefaultOutput = 0x64656620,   /* 'def ' (macOS) */
    kAudioUnitManufacturer_Apple = 0x6170706C,      /* 'appl' */
    kAudioFormatLinearPCM = 0x6C70636D              /* 'lpcm' */
};
enum {
    kAudioFormatFlagIsFloat = 1u << 0, kAudioFormatFlagIsBigEndian = 1u << 1,
    kAudioFormatFlagIsSignedInteger = 1u << 2, kAudioFormatFlagIsPacked = 1u << 3,
    kAudioFormatFlagIsNonInterleaved = 1u << 5
};
enum { kAudioUnitProperty_StreamFormat = 8, kAudioUnitProperty_MaximumFramesPerSlice = 14, kAudioUnitProperty_SetRenderCallback = 23 };
enum { kAudioUnitScope_Global = 0, kAudioUnitScope_Input = 1, kAudioUnitScope_Output = 2 };

AudioComponent AudioComponentFindNext(AudioComponent inComponent, const AudioComponentDescription *inDesc);
OSStatus AudioComponentInstanceNew(AudioComponent inComponent, AudioComponentInstance *outInstance);
OSStatus AudioComponentInstanceDispose(AudioComponentInstance inInstance);
OSStatus AudioUnitSetProperty(AudioUnit inUnit, AudioUnitPropertyID inID, AudioUnitScope inScope,
                              AudioUnitElement inElement, const void *inData, UInt32 inDataSize);
OSStatus AudioUnitInitialize(AudioUnit inUnit);
OSStatus AudioUnitUninitialize(AudioUnit inUnit);
OSStatus AudioOutputUnitStart(AudioUnit ci);
OSStatus AudioOutputUnitStop(AudioUnit ci);

#endif
