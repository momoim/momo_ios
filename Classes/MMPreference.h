//
//  MMPreference.h
//  momo
//
//  Created by houxh on 11-8-12.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DefineEnum.h"

enum {
	kSyncModeNone,
	kSyncModeRemote,
    kSyncModeLocal
};
extern const NSString *kMMAddressBookViewController;
extern const NSString *kMMAboutMeViewController;
extern const NSString *kMMMessageViewController;
extern const NSString *kMMPreferenceViewController;
extern const NSString *kMMIMRootViewController;
extern const NSString *kMMStartView;

extern const NSString *kMMIsFuzzySearch;

@interface MMPreference : NSObject

@property (nonatomic) NSInteger syncMode;
@property (nonatomic) BOOL isExcavationFriend;
@property (nonatomic) BOOL shouldPlaySound;
@property (nonatomic) BOOL downThumbUnderGPRS;
@property (nonatomic, copy) NSString* startView;
@property (nonatomic) BOOL uploadCrashLog;
@property (nonatomic) BOOL autoUploadCrashLog;
@property (nonatomic) BOOL playSoundOnNewMessage; //新消息提示音
@property (nonatomic) BOOL vibrateOnNewMessage; //新消息震动
@property (nonatomic, copy) NSString* skipUpdateVersion;
@property (nonatomic) BOOL autoPlayNewAudioMessage; //自动播放新语音消息
@property (nonatomic, retain) NSDate* checkAppUpdateDate; //最近检测app 更新的时间

@property (nonatomic) BOOL downContactAvatar;
@property (nonatomic) BOOL downContactAvatarOnGPRS;

@property (nonatomic) MM_SHOW_PHOTO_TYPE showMessagePhotoType;

+(MMPreference*)shareInstance;

-(void)reset;

//判断是否需要显示引导图
- (BOOL)isGuideImageShowed:(NSString*)imageName;
- (void)setGuideImage:(NSString*)imageName isShowed:(BOOL)showed;

@end
