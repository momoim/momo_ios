//
//  MMLoginService.h
//  momo
//
//  Created by houxh on 11-6-29.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kMMUserLogin        @"UserLogin"
#define kMMUserLogout       @"UserLogout"

@interface MMLoginService : NSObject {
	int activeCount;
}

@property(nonatomic, readonly) int activeCount;
@property(copy)	NSString *avatarImageURL;
+ (MMLoginService*)shareInstance;

-(int)increaseActiveCount;
-(int)decreaseActiveCount;

- (NSDictionary*)doLogin:(NSString *)mobile zonecode:(NSString*)zonecode
            password:(NSString *)password statusCode:(NSInteger*)status;
- (void)doLogout:(BOOL)sendNotification;

- (NSString*)oauthToken;
- (NSString*)oauthTokenSecret;
- (NSString*)queueName;
- (NSInteger)userStatus;
- (BOOL)isProbationer;
- (NSString*)getLoginNumber;
- (NSInteger)getLoginUserId;
- (NSString*)getLoginRealName;
- (NSString*)userName;
- (void)setUserName:(NSString*)name;
- (BOOL)bindToWeibo;
- (void)setBindToWeibo:(BOOL)bind;
- (BOOL)bindToKaixin;
- (void)setBindToKaixin:(BOOL)bind;
- (NSInteger)smsCount;
- (void)setSmsCount:(NSInteger)count;

//未注册用户
- (NSInteger)getRegisterVerifyCode:(NSString*)mobile zonecode:(NSString*)zonecode;
- (NSString*)reGetRegisterVerifyCode:(NSString*)mobile zonecode:(NSString*)zonecode;
- (NSDictionary*)verifyRegister:(NSString*)mobile zonecode:(NSString*)zonecode
                       password:(NSString *)password statusCode:(NSInteger*)status;


- (void)getSMSCountFromServer;

//是否在MQ服务器注册推送
- (BOOL)registerPushNotification:(NSString*)deviceToken;
- (void)unregisterPushNotification;

- (BOOL)pushNotificationRegistered;
- (void)setPushNotificationRegistered:(BOOL)registerd;
- (NSString*)pushDeviceToken;
- (void)setPushDeviceToken:(NSString*)deviceToken;

- (NSString*)errorStringFromResponseError:(NSString*)error statusCode:(NSInteger)statusCode;

@end
