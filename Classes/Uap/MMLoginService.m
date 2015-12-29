//
//  MMLoginService.m
//  momo
//
//  Created by houxh on 11-6-29.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MMLoginService.h"
#import "MMUapRequest.h"
#import "json.h"
#import "MMGlobalData.h"
#import "MMCommonAPI.h"
#import "ASIHTTPRequest.h"
#import "oauth.h"
#import "ASIFormDataRequest.h"
#import "MMLogger.h"
#import "MMAvatarMgr.h"
#import "MMGlobalCategory.h"
#import "MMPreference.h"

#define CLIENT_PLATFORM 2	

@implementation MMLoginService
@synthesize activeCount;
@synthesize avatarImageURL;

+ (MMLoginService*)shareInstance {
	static MMLoginService* instance = nil;
	if(!instance) {
		@synchronized(self) {
			if(!instance) {
				instance = [[[MMLoginService alloc] init] autorelease];
			}
		}
	}
	return instance;
}

-(int)increaseActiveCount {
	@synchronized(self) {
		return ++activeCount;
	}
}

-(int)decreaseActiveCount {
	@synchronized(self) {
		assert(activeCount > 0);
		return --activeCount;
	}
}

- (NSInteger)getLoginUserId {
	NSString *str = [MMGlobalData getPreferenceforKey:@"token_uid"];
    return [str intValue];
}

- (NSString*)getLoginRealName {
	NSString *name = [MMGlobalData getPreferenceforKey:@"user_name"];
	if(!name) return @"我";
    if ([name isEqualToString:@"#体验者#"]) {
        return @"体验者";
    }
	return name;
}

- (NSString*)userName {
    return [MMGlobalData getPreferenceforKey:@"user_name"];
}

- (NSString*)getLoginNumber {
	return [MMGlobalData getPreferenceforKey:@"user_mobile"];
}

-(NSInteger)userStatus {
    return [[MMGlobalData getPreferenceforKey:@"user_status"] intValue];
}

- (NSString*)avatarImageURL {
	return [MMGlobalData getPreferenceforKey:@"avatar"];
}

- (void)setAvatarImageURL:(NSString *)newAvatarURL {
	[self willChangeValueForKey:@"avatarImageURL"];
    [MMGlobalData setPreference:newAvatarURL forKey:@"avatar"];
	[MMGlobalData savePreference];
	[self didChangeValueForKey:@"avatarImageURL"];
}

- (BOOL)isProbationer {
    return [self userStatus] == 0;
}

- (void)setUserName:(NSString*)name {
    [MMGlobalData setPreference:name forKey:@"user_name"];
	[MMGlobalData savePreference];
}

- (BOOL)bindToWeibo {
    NSNumber* bindValue = [MMGlobalData getPreferenceforKey:@"bind_weibo"];
    if (!bindValue) {
        return NO;
    }
    return [bindValue boolValue];
}

- (void)setBindToWeibo:(BOOL)bind {
    [MMGlobalData setPreference:[NSNumber numberWithBool:bind] forKey:@"bind_weibo"];
    [MMGlobalData savePreference];
}


- (BOOL)bindToKaixin {
    NSNumber* bindValue = [MMGlobalData getPreferenceforKey:@"bind_kaixin"];
    if (!bindValue) {
        return NO;
    }
    return [bindValue boolValue];
}

- (void)setBindToKaixin:(BOOL)bind {
    [MMGlobalData setPreference:[NSNumber numberWithBool:bind] forKey:@"bind_kaixin"];
    [MMGlobalData savePreference];
}

- (NSInteger)smsCount {
    NSNumber* bindValue = [MMGlobalData getPreferenceforKey:@"sms_count"];
    if (!bindValue) {
        return 0;
    }
    return [bindValue intValue];
}

- (void)setSmsCount:(NSInteger)count {
    [MMGlobalData setPreference:[NSNumber numberWithInt:count] forKey:@"sms_count"];
    [MMGlobalData savePreference];
}

- (void)getSMSCountFromServer {
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    
    NSString* strSource = [NSString stringWithFormat:@"user/sms_count.json"];
	NSDictionary *dicRet = [MMUapRequest getSync:strSource compress:YES];
	NSInteger retCode = [[dicRet valueForKey:@"status"] intValue];
    if (retCode == 200 && [dicRet isKindOfClass:[NSDictionary class]]) {
        NSInteger count = [[dicRet objectForKey:@"count"] intValue];
        if (count > 0) {
            self.smsCount = count;
        }
    }
    
    [pool release];
}

- (NSString*)filterZoneCode:(NSString*)zonecode {
    if ([zonecode hasPrefix:@"+"]) {
        [zonecode substringFromIndex:1];
    }
    return zonecode;
}

- (NSString*)errorStringFromResponseError:(NSString*)error statusCode:(NSInteger)statusCode {
    if (statusCode == 0) {
        return @"网络连接失败";
    }
    
    NSArray* errorArray = [error componentsSeparatedByString:@":"];
    if (errorArray.count < 2) {
        return nil;
    }
    
    return [errorArray objectAtIndex:1];
}

- (NSInteger)errorCodeFromErrorString:(NSString*)error {
    if (!error) {
        return -1;
    }
    
    NSArray* errorArray = [error componentsSeparatedByString:@":"];
    if (errorArray.count < 2) {
        return -1;
    }
    
    return [[errorArray objectAtIndex:0] intValue];
}

- (NSDictionary*)doLogin:(NSString *)mobile zonecode:(NSString*)zonecode password:(NSString *)password statusCode:(NSInteger*)status {
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    [dic setObject:mobile forKey:@"mobile"];
    [dic setObject:password forKey:@"password"];
    [dic setObject:[self filterZoneCode:zonecode] forKey:@"zone_code"];
    
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithPath:@"user/login" withObject:dic usingSSL:NO];
    request.validatesSecureCertificate = NO;
    [request startSynchronous];
    NSInteger statusCode = [request responseStatusCode];

    
    NSDictionary *response = [request responseObject];
    *status = statusCode;
    return response;
}

- (void)doLogout:(BOOL)sendNotification {
    //删除推送队列
    do {
        NSString* deviceToken = [self pushDeviceToken];
        if (deviceToken.length == 0) {
            self.pushNotificationRegistered = NO;
            break;
        }
        
        NSDictionary *dic = [NSDictionary dictionaryWithObject:deviceToken forKey:@"device_id"];
        ASIHTTPRequest *request = [ASIHTTPRequest requestWithPath:@"push/delete.json" withObject:dic];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [request startSynchronous];
            if ([request responseStatusCode] != 200) {
                MLOG(@"post device code fail, %@", [[request responseString] stringByReplacingPercentEscapesUsingEncoding:NSUnicodeStringEncoding]);
            }
            self.pushNotificationRegistered = NO;
        });
    } while (0);

    
    [[MMAvatarMgr shareInstance] reset];
    

    
    self.smsCount = 0;
	self.avatarImageURL = nil;
}



#pragma mark 注册
- (NSInteger)getRegisterVerifyCode:(NSString*)mobile zonecode:(NSString*)zonecode {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [dictionary setObject:mobile forKey:@"mobile"];
    [dictionary setObject:[self filterZoneCode:zonecode] forKey:@"zone_code"];

    NSString *path = [NSString stringWithFormat:@"auth/verify_code?zone_code=%@&mobile=%@", zonecode, mobile];
    
    NSDictionary *response = [MMUapRequest getSync:path compress:NO];
    
    NSLog(@"verify code:%@", response);
    NSInteger statusCode = [[response objectForKey:STATUS] integerValue];
    
    if (statusCode != 200 ) {
        NSString *error = [response objectForKey:@"error"];
        if (statusCode == 0) {
            return 0;
        }
        return [self errorCodeFromErrorString:error];
    }
    return 200;
}

- (NSString*)reGetRegisterVerifyCode:(NSString*)mobile zonecode:(NSString*)zonecode {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [dictionary setObject:mobile forKey:@"mobile"];
    [dictionary setObject:[self filterZoneCode:zonecode] forKey:@"zone_code"];
	NSDictionary *response = nil;
	NSInteger statusCode = [MMUapRequest postSync:@"register/create.json" withObject:dictionary jsonValue:&response];
	if (statusCode != 200) {
		NSString *error = [response objectForKey:@"error"];
        NSString* retString = [self errorStringFromResponseError:error statusCode:statusCode];
        if (!retString) {
            retString = @"获取验证码失败";
        }
        return retString;
	}
    
    return nil;
}

- (NSDictionary*)verifyRegister:(NSString*)mobile zonecode:(NSString*)zonecode password:(NSString *)password statusCode:(NSInteger*)status {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [dictionary setObject:mobile forKey:@"mobile"];
    [dictionary setObject:zonecode forKey:@"zone_code"];
    [dictionary setObject:password forKey:@"code"];
    
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithPath:@"auth/token" withObject:dictionary usingSSL:NO];
    [request startSynchronous];
    NSInteger statusCode = [request responseStatusCode];
	NSDictionary *response = [request responseObject];
    
    *status = statusCode;
    return response;
}

#pragma mark 推送相关
- (BOOL)registerPushNotification:(NSString*)deviceToken {
    NSDictionary *dic = [NSDictionary dictionaryWithObject:deviceToken forKey:@"device_id"];
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithPath:@"push/create.json" withObject:dic];
    [request startSynchronous];
    if ([request responseStatusCode] != 200) {
        MLOG(@"post device code fail, %@", [request responseString]);
        [self setPushNotificationRegistered:NO];
        return NO;
    }
    
    [self setPushDeviceToken:deviceToken];
    [self setPushNotificationRegistered:YES];
    return YES;
}

- (void)unregisterPushNotification {
    NSString* deviceToken = [self pushDeviceToken];
    if (deviceToken.length == 0) {
        self.pushNotificationRegistered = NO;
        return;
    }
    
    NSDictionary *dic = [NSDictionary dictionaryWithObject:deviceToken forKey:@"device_id"];
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithPath:@"push/delete.json" withObject:dic];
    [request startSynchronous];
    if ([request responseStatusCode] != 200) {
        MLOG(@"post device code fail, %@", [request responseString]);
        return;
    }
    self.pushNotificationRegistered = NO;
    self.pushDeviceToken = @"";
}

- (BOOL)pushNotificationRegistered {
    NSNumber* registerValue = [MMGlobalData getPreferenceforKey:@"push_register"];
    if (!registerValue) {
        return NO;
    }
    return [registerValue boolValue];
}

- (void)setPushNotificationRegistered:(BOOL)registerd {
    [MMGlobalData setPreference:[NSNumber numberWithInt:registerd] forKey:@"push_register"];
    [MMGlobalData savePreference];
}

- (NSString*)pushDeviceToken {
    return [MMGlobalData getPreferenceforKey:@"push_device_token"];
}

- (void)setPushDeviceToken:(NSString*)deviceToken {
    [MMGlobalData setPreference:deviceToken forKey:@"push_device_token"];
    [MMGlobalData savePreference];
}


@end



#ifdef MOMO_UNITTEST
#import "GHTestCase.h"
#import "MMGlobalData.h"

//@interface MMLoginServiceUnitTest : GHTestCase {
//	
//}
//@end
//
//@implementation MMLoginServiceUnitTest
//
//
//-(void)testRegister {
//	int result = 0;
//	id rr = nil;
//	result = [MMUapRequest postSync:@"register/destroy.json" 
//						 withObject:[NSDictionary dictionaryWithObject:@"13225911432" forKey:@"mobile"] jsonValue:&rr];
//	GHAssertEquals(result, 0, @"反注册失败");
//
//	result = [[MMLoginService shareInstance] getProbationerVerifyCode:@"13225911432" zonecode:@"86"];
//	GHAssertEquals(result, 0, @"获取验证码失败");
//}
//
//@end
#endif


