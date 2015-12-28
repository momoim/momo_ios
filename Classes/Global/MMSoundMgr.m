//
//  MMSoundMgr.m
//  
//
//  Created by jackie on 11-8-16.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MMSoundMgr.h"
#import <AudioToolbox/AudioToolbox.h>
#import "MMLogger.h"


static void completionCallback (SystemSoundID  mySSID, void* myself) {
	AudioServicesRemoveSystemSoundCompletion(mySSID);
	 
	[MMSoundMgr shareInstance].isPlaying = NO;
}

@implementation MMSoundMgr
@synthesize isPlaying = isPlaying_;

+ (MMSoundMgr*)shareInstance {
	static id _instance = nil;
    @synchronized(self) {
        if(_instance == nil) 
            _instance = [[[self class] alloc] init];
    }
    return _instance;
}

- (id)init {
	if (self = [super init]) {
		soundNameAndIds = [[NSMutableDictionary alloc] init];
	}
	return self;
}


- (void)playSound:(NSString*)fileName {
	assert([NSThread isMainThread]);
	
	NSNumber* soundIdObject = [soundNameAndIds objectForKey:fileName];
	if (!soundIdObject) {
		NSString* path = @"Sound";
		NSString* soundPath = [[NSBundle mainBundle] pathForResource:fileName ofType:nil inDirectory:path];
		
		NSFileManager* fileManager = [NSFileManager defaultManager];
		if (![fileManager fileExistsAtPath:soundPath]) {
			MLOG(@"sound file not exist: %@", soundPath);
			return;
		}
		
		CFURLRef soundURL = (CFURLRef)[NSURL fileURLWithPath:soundPath];
		SystemSoundID soundId;
		AudioServicesCreateSystemSoundID(soundURL, &soundId);
		
		soundIdObject = [NSNumber numberWithUnsignedInt:soundId];
		[soundNameAndIds setObject:soundIdObject forKey:fileName];
	}

    //防止大量播放
    if (isPlaying_) {
        return;
    }
    isPlaying_ = YES;
    
    AudioServicesAddSystemSoundCompletion([soundIdObject unsignedIntValue], NULL, NULL, completionCallback, NULL);
	AudioServicesPlaySystemSound([soundIdObject unsignedIntValue]);
}

- (void)playNewMessageSound {
    static CFTimeInterval lastPlayTime = 0;
    
    CFTimeInterval currentTime = CACurrentMediaTime();
    if (currentTime - lastPlayTime > 2) {
        lastPlayTime = currentTime;
        
        [self playSound:@"breeding.wav"];
    }
}

- (void)playVibrate {
    static CFTimeInterval lastPlayTime = 0;
    
    CFTimeInterval currentTime = CACurrentMediaTime();
    if (currentTime - lastPlayTime > 2) {
        lastPlayTime = currentTime;
        
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    }
}

@end
