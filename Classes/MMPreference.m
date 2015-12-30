//
//  MMPreference.m
//  momo
//
//  Created by houxh on 11-8-12.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import "MMPreference.h"
#import "MMGlobalData.h"

#define kMMIsExcavationFriend  @"MMIsExcavationFriend"
#define kMMShouldPlaySound @"MMShouldPlaySound"
#define kMMSyncToWeibo @"MMSyncToWeiBo"
#define kMMDownThumbUnderGPRS @"MMDownThumbUnderGPRS" //default 1
#define kMMUploadCrashLog @"MMUploadUploadCrashLog"
#define kMMAutoUploadCrashLog @"MMAutoUploadCrashLog"
#define kMMPlaySoundOnNewMessage @"MMPlaySoundOnNewMessage"
#define kMMVibrateOnNewMessage @"MMVibrateOnNewMessage"
#define kMMSkipUpdateVersion @"MMSkipUpdateVersion"
#define kMMAutoPlayNewAudioMessage @"MMAutoPlayNewAudioMessage"
#define kMMCheckAppUpdateDate @"MMCheckAppUpdateDate"
#define KMMDownContactAvatar @"MMDownContactAvatar"
#define kMMDownContactAvatarOnGPRS @"MMDownContactAvatarOnGPRS"
#define kMMShowMessagePhotoType @"MMShowMessagePhotoType"

const NSString *kMMStartView = @"StartView";
const NSString *kMMAddressBookViewController	= @"MMAddressBookViewController";
const NSString *kMMAboutMeViewController        = @"MMAboutMeViewController";
const NSString *kMMMessageViewController		= @"MMMessageViewController";
const NSString *kMMPreferenceViewController		= @"MMPreferenceViewController";
const NSString *kMMIMRootViewController         = @"MMIMRootViewController";   

const NSString *kMMIsFuzzySearch				= @"MMIsFuzzySearch";//1 YES,0 NO  default 1

@implementation MMPreference

+ (MMPreference*)shareInstance {
	static MMPreference* instance = nil;
	if(!instance) {
		@synchronized(self) {
			if(!instance) {
				instance = [[[MMPreference alloc] init] autorelease];
			}
		}
	}
	return instance;
}

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

-(void)reset {
    [MMGlobalData removeAllPreference];
    
//    [self setSyncMode:kSyncModeNone];
//    [self setIsExcavationFriend:YES];
//	[self setShouldPlaySound:YES];
//	[self setVibrateOnNewMessage:NO];
//	[self setAutoPlayNewAudioMessage:YES];
	[self setVibrateOnNewMessage:NO];
	[self setAutoPlayNewAudioMessage:YES];
}


-(NSInteger)syncMode {
    NSString *syncMode = [MMGlobalData getPreferenceforKey:@"sync_mode"];
    if (nil == syncMode) {
        return kSyncModeNone;
    }
    if ([syncMode isEqualToString:@"syncModeNone"]) {
        return kSyncModeNone;
    } else if ([syncMode isEqualToString:@"syncModeRemote"]) {
        return kSyncModeRemote;
    } else if ([syncMode isEqualToString:@"syncModeLocal"]) {
        return kSyncModeLocal;
    } else {
        assert(0);
    }
    return kSyncModeNone;
}

-(void)setSyncMode:(NSInteger)mode {
    if (mode == self.syncMode) {
        return;
    }
    [self willChangeValueForKey:@"syncMode"];
    switch (mode) {
        case kSyncModeNone:
            [MMGlobalData setPreference:@"syncModeNone" forKey:@"sync_mode"];
            [MMGlobalData savePreference];
            break;
        case kSyncModeRemote:
            [MMGlobalData setPreference:@"syncModeRemote" forKey:@"sync_mode"];
            [MMGlobalData savePreference];
            break;
        case kSyncModeLocal:
            [MMGlobalData setPreference:@"syncModeLocal" forKey:@"sync_mode"];
            [MMGlobalData savePreference];
            break;
        default:
            assert(0);
            break;
    }
    [self didChangeValueForKey:@"syncMode"];
    
}

-(BOOL)isExcavationFriend {
    NSString *str = [MMGlobalData getPreferenceforKey:kMMIsExcavationFriend];
    return [str intValue];
}

-(void)setIsExcavationFriend:(BOOL)IsExcavationFriend {
	if (IsExcavationFriend == self.isExcavationFriend ) {
		return ;
	}
	
	[self willChangeValueForKey:@"isExcavationFriend"];
    NSString *str = [NSString stringWithFormat:@"%d", IsExcavationFriend];
    [MMGlobalData setPreference:str forKey:(NSString*)kMMIsExcavationFriend]; 
	[MMGlobalData savePreference];	
	[self didChangeValueForKey:@"isExcavationFriend"];
}

- (BOOL)shouldPlaySound {
	NSString *str = [MMGlobalData getPreferenceforKey:kMMShouldPlaySound];
	if (!str || str.length == 0) {
		return YES;
	}
    return [str boolValue];
}

- (void)setShouldPlaySound:(BOOL)playSound {
	NSString *str = [NSString stringWithFormat:@"%d", playSound];
    [MMGlobalData setPreference:str forKey:(NSString*)kMMShouldPlaySound]; 
	[MMGlobalData savePreference];	
}

- (BOOL)syncToWeibo {
    NSString *str = [MMGlobalData getPreferenceforKey:kMMSyncToWeibo];
	if (!str || str.length == 0) {
		return NO;
	}
    return [str boolValue];
}

- (void)setSyncToWeibo:(BOOL)syncToWeibo {
    NSString *str = [NSString stringWithFormat:@"%d", syncToWeibo];
    [MMGlobalData setPreference:str forKey:(NSString*)kMMSyncToWeibo]; 
	[MMGlobalData savePreference];
}

- (BOOL)downThumbUnderGPRS {
    NSString *str = [MMGlobalData getPreferenceforKey:kMMDownThumbUnderGPRS];
	if (!str || str.length == 0) {
		return YES;
	}
    return [str boolValue];
}

- (void)setDownThumbUnderGPRS:(BOOL)downThumbUnderGPRS {
    NSString *str = [NSString stringWithFormat:@"%d", downThumbUnderGPRS];
    [MMGlobalData setPreference:str forKey:(NSString*)kMMDownThumbUnderGPRS]; 
	[MMGlobalData savePreference];
}

- (NSString*)startView {
    NSString* str = [MMGlobalData getPreferenceforKey:kMMStartView];
    if (!str || str.length == 0) {
        return (NSString*)kMMIMRootViewController;
    }
    return str;
}

- (void)setStartView:(NSString *)startView {
    [MMGlobalData setPreference:startView forKey:kMMStartView];
    [MMGlobalData savePreference];
}

- (BOOL)uploadCrashLog {
    NSString *str = [MMGlobalData getPreferenceforKey:kMMUploadCrashLog];
	if (!str || str.length == 0) {
		return YES;
	}
    return [str boolValue];
}

- (void)setUploadCrashLog:(BOOL)uploadCrashLog {
    NSString *str = [NSString stringWithFormat:@"%d", uploadCrashLog];
    [MMGlobalData setPreference:str forKey:(NSString*)kMMUploadCrashLog]; 
	[MMGlobalData savePreference];
}

- (BOOL)autoUploadCrashLog {
    NSString *str = [MMGlobalData getPreferenceforKey:kMMAutoUploadCrashLog];
	if (!str || str.length == 0) {
		return NO;
	}
    return [str boolValue];
}

- (void)setAutoUploadCrashLog:(BOOL)autoUploadCrashLog {
    NSString *str = [NSString stringWithFormat:@"%d", autoUploadCrashLog];
    [MMGlobalData setPreference:str forKey:(NSString*)kMMAutoUploadCrashLog]; 
	[MMGlobalData savePreference];
}

- (BOOL)playSoundOnNewMessage {
    NSString *str = [MMGlobalData getPreferenceforKey:kMMPlaySoundOnNewMessage];
	if (!str || str.length == 0) {
		return YES;
	}
    return [str boolValue];
}

- (void)setPlaySoundOnNewMessage:(BOOL)playSoundOnNewMessage {
    NSString *str = [NSString stringWithFormat:@"%d", playSoundOnNewMessage];
    [MMGlobalData setPreference:str forKey:(NSString*)kMMPlaySoundOnNewMessage]; 
	[MMGlobalData savePreference];
}

- (BOOL)vibrateOnNewMessage {
    NSString *str = [MMGlobalData getPreferenceforKey:kMMVibrateOnNewMessage];
	if (!str || str.length == 0) {
		return NO;
	}
    return [str boolValue];
}

- (void)setVibrateOnNewMessage:(BOOL)vibrateOnNewMessage {
    NSString *str = [NSString stringWithFormat:@"%d", vibrateOnNewMessage];
    [MMGlobalData setPreference:str forKey:(NSString*)kMMVibrateOnNewMessage]; 
	[MMGlobalData savePreference];
}

- (NSString*)skipUpdateVersion {
    NSString *str = [MMGlobalData getPreferenceforKey:kMMSkipUpdateVersion];
	if (!str || str.length == 0) {
		return nil;
	}
    return str;
}

- (void)setSkipUpdateVersion:(NSString*)skipUpdateVersion {
    [MMGlobalData setPreference:skipUpdateVersion forKey:(NSString*)kMMSkipUpdateVersion]; 
	[MMGlobalData savePreference];
}

- (BOOL)autoPlayNewAudioMessage {
    NSString *str = [MMGlobalData getPreferenceforKey:kMMAutoPlayNewAudioMessage];
	if (!str || str.length == 0) {
		return NO;
	}
    return [str boolValue];
}

- (void)setAutoPlayNewAudioMessage:(BOOL)autoPlayNewAudioMessage {
    NSString *str = [NSString stringWithFormat:@"%d", autoPlayNewAudioMessage];
    [MMGlobalData setPreference:str forKey:(NSString*)kMMAutoPlayNewAudioMessage]; 
	[MMGlobalData savePreference];
}

- (BOOL)isGuideImageShowed:(NSString*)imageName {
    NSString* key = [NSString stringWithFormat:@"show_%@", imageName];
    NSString *str = [MMGlobalData getPreferenceforKey:key];
	if (!str || str.length == 0) {
		return NO;
	}
    return [str boolValue];
}

- (void)setGuideImage:(NSString*)imageName isShowed:(BOOL)showed {
    NSString* key = [NSString stringWithFormat:@"show_%@", imageName];
    NSString *str = [NSString stringWithFormat:@"%d", showed];
    [MMGlobalData setPreference:str forKey:(NSString*)key]; 
	[MMGlobalData savePreference];
}

- (NSDate*)checkAppUpdateDate {
    NSString *str = [MMGlobalData getPreferenceforKey:kMMCheckAppUpdateDate];
	if (!str || str.length == 0) {
		return nil;
	}
    
    
    NSTimeInterval timeStamp = [str longLongValue];
    return [NSDate dateWithTimeIntervalSince1970:timeStamp];
}

- (void)setCheckAppUpdateDate:(NSDate *)checkAppUpdateDate {
    NSString *str = [NSString stringWithFormat:@"%d", (int)[checkAppUpdateDate timeIntervalSince1970]];
    [MMGlobalData setPreference:str forKey:(NSString*)kMMCheckAppUpdateDate]; 
	[MMGlobalData savePreference];
}

- (BOOL)downContactAvatar {
    NSString *str = [MMGlobalData getPreferenceforKey:KMMDownContactAvatar];
	if (!str || str.length == 0) {
		return YES;
	}
    return [str boolValue];
}

- (void)setDownContactAvatar:(BOOL)downContactAvatar {
    NSString *str = [NSString stringWithFormat:@"%d", downContactAvatar];
    [MMGlobalData setPreference:str forKey:(NSString*)KMMDownContactAvatar]; 
	[MMGlobalData savePreference];
}

- (BOOL)downContactAvatarOnGPRS {
    NSString *str = [MMGlobalData getPreferenceforKey:kMMDownContactAvatarOnGPRS];
	if (!str || str.length == 0) {
		return NO;
	}
    return [str boolValue];
}

- (void)setDownContactAvatarOnGPRS:(BOOL)downContactAvatarOnGPRS {
    NSString *str = [NSString stringWithFormat:@"%d", downContactAvatarOnGPRS];
    [MMGlobalData setPreference:str forKey:(NSString*)kMMDownContactAvatarOnGPRS]; 
	[MMGlobalData savePreference];
}

- (MM_SHOW_PHOTO_TYPE)showMessagePhotoType {
    NSString *str = [MMGlobalData getPreferenceforKey:kMMShowMessagePhotoType];
	if (!str || str.length == 0) {
		return kMMShowBigPhoto;
	}
    return [str intValue];
}

- (void)setShowMessagePhotoType:(MM_SHOW_PHOTO_TYPE)showMessagePhotoType {
    NSString *str = [NSString stringWithFormat:@"%d", showMessagePhotoType];
    [MMGlobalData setPreference:str forKey:(NSString*)kMMShowMessagePhotoType]; 
	[MMGlobalData savePreference];
}

@end
