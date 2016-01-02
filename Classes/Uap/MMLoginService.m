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

- (NSString*)avatarImageURL {
	return [MMGlobalData getPreferenceforKey:@"avatar"];
}

- (void)setAvatarImageURL:(NSString *)newAvatarURL {
	[self willChangeValueForKey:@"avatarImageURL"];
    [MMGlobalData setPreference:newAvatarURL forKey:@"avatar"];
	[MMGlobalData savePreference];
	[self didChangeValueForKey:@"avatarImageURL"];
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

	self.avatarImageURL = nil;
}

- (NSDictionary*)refreshAccessToken:(NSString*)refreshToken statusCode:(NSInteger*)status {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setObject:refreshToken forKey:@"refresh_token"];
    
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithPath:@"auth/refresh_token.json" withObject:dict usingSSL:NO];
    [request startSynchronous];
    
    NSInteger statusCode = [request responseStatusCode];
    NSDictionary *resp = [request responseObject];
    if (status) {
        *status = statusCode;
    }
    
    return resp;
}


#pragma mark 注册
- (NSInteger)getRegisterVerifyCode:(NSString*)mobile zonecode:(NSString*)zonecode {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [dictionary setObject:mobile forKey:@"mobile"];
    [dictionary setObject:[self filterZoneCode:zonecode] forKey:@"zone_code"];

    ASIHTTPRequest *request = [ASIHTTPRequest requestWithPath:@"auth/verify_code.json" withObject:dictionary usingSSL:NO];
    [request startSynchronous];
    NSInteger statusCode = [request responseStatusCode];

    NSDictionary *response = [request responseObject];
    
    NSLog(@"verify code:%@", response);
    return  statusCode;
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

#pragma mark 好友相关
- (BOOL)addFriend:(int64_t)friendID {
    NSNumber *n = [NSNumber numberWithLongLong:friendID];
    NSDictionary *dict = [NSDictionary dictionaryWithObject:n forKey:@"user_id"];
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithPath:@"friend/add.json" withObject:dict];
    [request startSynchronous];
    NSInteger statusCode = [request responseStatusCode];
    return statusCode == 200;
}

- (NSArray*)getFreinds:(NSInteger*)status {
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithPath:@"friend/index.json?page=1&pagesize=200"];
    [request startSynchronous];
    NSInteger statusCode = [request responseStatusCode];
    NSDictionary *resp = [request responseObject];
    
    if (status != NULL) {
        *status = statusCode;
    }
    if (statusCode == 200) {
        return [resp objectForKey:@"data"];
    } else {
        return nil;
    }
}

- (NSArray*)getPotentialFriends:(NSArray*)mobiles statusCode:(NSInteger*)status {
    NSDictionary *dict = [NSMutableDictionary dictionary];
    [dict setValue:mobiles forKey:@"mobiles"];
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithPath:@"user/search.json" withObject:dict];
    [request startSynchronous];
    NSInteger statusCode = [request responseStatusCode];
    NSArray *resp = [request responseObject];
    
    if (status != NULL) {
        *status = statusCode;
    }
    return resp;
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


