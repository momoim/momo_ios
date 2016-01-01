//
//  MMMessageSyncer.m
//  momo
//
//  Created by wangsc on 11-1-11.
//  Copyright 2011 ND. All rights reserved.
//

#import "MMMessageSyncer.h"
#import "MMGlobalData.h"
#import "RegexKitLite.h"
#import "MMUapRequest.h"
#import "MMUIComment.h"
#import "MMUIMessage.h"
#import "GTMBase64.h"
#import "MMMomoUserMgr.h"
#import "SBJSON.h"
#import "MMCommonAPI.h"
#import "MMLoginService.h"

@implementation NSString (UnsignedLongLongValue)
- (unsigned long long)unsignedLongLongValue { 
	return strtoull([self UTF8String], NULL, 0); 
}

@end

//only used in this file
#define VERIFY_JSON_SINGLE_VALUE(Dict, key) {NSObject* value = [Dict objectForKey:key];\
if (!value || [value isKindOfClass:[NSNull class]]) { return NO;}}
#define VERIFY_JSON_POSSIBLE_NULL_VALUE(Dict, key) {NSObject* value = [Dict objectForKey:key];\
if (value && [value isKindOfClass:[NSNull class]]) { return NO;}}
#define VERIFY_JSON_SPECIFY_TYPE(Dict, key, type) {NSObject* value = [Dict objectForKey:key];\
if (!value || ![value isKindOfClass:[type class]]) { return NO;}}
#define VERIFY_JSON_ARRAY_VALUE(Dict, key) VERIFY_JSON_SPECIFY_TYPE(Dict, key, NSArray)
#define VERIFY_JSON_DICTIONARY_VALUE(Dict, key) VERIFY_JSON_SPECIFY_TYPE(Dict, key, NSDictionary)

static MMMessageSyncer* s_instance = nil;
@implementation MMMessageSyncer
@synthesize lastError;

+ (id)shareInstance {
	if (!s_instance) {
		s_instance = [[MMMessageSyncer alloc] init];
	}
	return s_instance;
}

-(NSString *)stringWithUnescapeHTML:(NSString*)string
{
	string = [string stringByReplacingOccurrencesOfString:@"&quot;" withString:@"\""];
	string = [string stringByReplacingOccurrencesOfString:@"&apos;" withString:@"'"];
	string = [string stringByReplacingOccurrencesOfString:@"&amp;" withString:@"&"];
	string = [string stringByReplacingOccurrencesOfString:@"&lt;" withString:@"<"];
	string = [string stringByReplacingOccurrencesOfString:@"&gt;" withString:@">"];
	string = [string stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
	return string;
}

- (NSString *)errorStringWithResponseDict:(NSDictionary*)dict statusCode:(NSInteger)statusCode {
    if (statusCode == 0) {
        if ([MMCommonAPI isNetworkReachable]) {
            return @"网络超时";
        } else {
            return @"网络连接失败";
        }
    }
    
    if (!dict || ![dict isKindOfClass:[NSDictionary class]]) {
        return @"未知错误";
    }
    
    if ([dict objectForKey:@"error"]) {
        return [dict objectForKey:@"error"];
    }
    
    return @"未知错误";
}

- (NSString *)errorStringWithResponseJSON:(NSString*)json statusCode:(NSInteger)statusCode {
    SBJSON* sbjson = [[[SBJSON alloc] init] autorelease];
    NSDictionary* dicRet = [sbjson objectWithString:json];
    return [self errorStringWithResponseDict:dicRet statusCode:lastError];
}

- (MMCommentInfo*)commentFromDict:(NSDictionary*)commentDict {
	MMCommentInfo* commentInfo = [[[MMCommentInfo alloc] init] autorelease];
	commentInfo.commentId =	 [commentDict objectForKey:@"id"];
	commentInfo.createDate = [[commentDict objectForKey:@"created_at"] unsignedLongLongValue];
	commentInfo.sourceName = [commentDict objectForKey:@"source_name"];
	
	NSDictionary* userDict = [commentDict objectForKey:@"user"];
	commentInfo.uid = [[userDict objectForKey:@"id"] integerValue];
	commentInfo.avatarImageUrl = [userDict objectForKey:@"avatar"];
	commentInfo.realName = [userDict objectForKey:@"name"];
	commentInfo.ownerId = [[MMLoginService shareInstance] getLoginUserId];
	
    //parset content
	commentInfo.text = [commentDict objectForKey:@"text"];
    commentInfo.text = [commentInfo.text stringByReplacingOccurrencesOfString:@"<" withString:@"&lt;"];
    commentInfo.text = [commentInfo.text stringByReplacingOccurrencesOfString:@">" withString:@"&gt;"];
	commentInfo.text = [commentInfo.text stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
	
	NSArray* atList = [commentDict objectForKey:@"at"];
	for (NSUInteger i = 0; i < [atList count]; i++) {
		NSDictionary* atDict = [atList objectAtIndex:i];
		
		NSUInteger uid = [[atDict objectForKey:@"id"] intValue];
		NSString*  userName = [atDict objectForKey:@"name"];
		NSString* atLink = [NSString stringWithFormat:@"<A href=\"momo://user=%d\">@%@</A>", uid, userName]; 
		NSString* target = [NSString stringWithFormat:@"[@%d]", i];
		commentInfo.text = [commentInfo.text stringByReplacingOccurrencesOfString:target withString:atLink];
        
        [[MMMomoUserMgr shareInstance] setUserId:uid realName:userName avatarImageUrl:nil];
	}
    
    //URL加上a标签
    commentInfo.text = [MMCommonAPI addHTMLLinkTag:commentInfo.text];
	
	[[MMMomoUserMgr shareInstance] setUserId:commentInfo.uid 
									realName:commentInfo.realName 
							  avatarImageUrl:commentInfo.avatarImageUrl];
    
	return commentInfo;
}

- (MMMessageInfo*)messageFromDict:(NSDictionary*)messageDict {
	MMMessageInfo* messageInfo = [[[MMMessageInfo alloc] init] autorelease];
	messageInfo.statusId = [messageDict objectForKey:@"id"];
	messageInfo.ownerId = [[MMLoginService shareInstance] getLoginUserId];
	messageInfo.typeId = [messageInfo messageTypeFromString:[messageDict objectForKey:@"type"]];
	messageInfo.allowRetweet = [[messageDict objectForKey:@"allow_rt"] boolValue];
	messageInfo.allowComment = [[messageDict objectForKey:@"allow_comment"] boolValue];
	messageInfo.allowPraise = [[messageDict objectForKey:@"allow_praise"] boolValue];
	messageInfo.allowDel = [[messageDict objectForKey:@"allow_del"] boolValue];
	messageInfo.allowHide = [[messageDict objectForKey:@"allow_hide"] boolValue];
	messageInfo.retweetStatusId = [messageDict objectForKey:@"rt_status_id"];
	
	//user
	NSDictionary* userDict = [messageDict objectForKey:@"user"];
	messageInfo.uid = [[userDict objectForKey:@"id"] intValue];
	messageInfo.avatarImageUrl = [userDict objectForKey:@"avatar"];
	messageInfo.realName = [userDict objectForKey:@"name"];
	
	messageInfo.text = [messageDict objectForKey:@"text"];
    messageInfo.text = [messageInfo.text stringByReplacingOccurrencesOfString:@"<" withString:@"&lt;"];
    messageInfo.text = [messageInfo.text stringByReplacingOccurrencesOfString:@">" withString:@"&gt;"];
	messageInfo.text = [messageInfo.text stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
	
	//at information
	NSArray* atList = [messageDict objectForKey:@"at"];
	for (NSUInteger i = 0; i < [atList count]; i++) {
		NSDictionary* atDict = [atList objectAtIndex:i];
		
		NSUInteger uid = [[atDict objectForKey:@"id"] intValue];
		NSString*  userName = [atDict objectForKey:@"name"];
		NSString* atLink = [NSString stringWithFormat:@"<A href=\"momo://user=%d\">@%@</A>", uid, userName]; 
		NSString* target = [NSString stringWithFormat:@"[@%d]", i];
		messageInfo.text = [messageInfo.text stringByReplacingOccurrencesOfString:target withString:atLink];
        
        [[MMMomoUserMgr shareInstance] setUserId:uid realName:userName avatarImageUrl:nil];
	}
    
    //URL添加A标签
    messageInfo.text = [MMCommonAPI addHTMLLinkTag:messageInfo.text];
    if (!messageInfo.text) {
        messageInfo.text = @"  ";
    }
	
	messageInfo.createDate = [[messageDict objectForKey:@"created_at"] intValue];
	messageInfo.modifiedDate = [[messageDict objectForKey:@"modified_at"] unsignedLongLongValue];
	messageInfo.storaged = [[messageDict objectForKey:@"storaged"] boolValue];
    
    //长文本内容
    messageInfo.isLongText = [[messageDict objectForKey:@"is_long_text"] boolValue];
    messageInfo.longTextUrl = [messageDict objectForKey:@"long_text_url"];
    if (messageInfo.isLongText) {
        //先判断长文本有没有下载过了
        MMMessageInfo* localMessageInfo = [[MMUIMessage instance] getMessage:messageInfo.statusId];
        if (localMessageInfo && localMessageInfo.isLongText && localMessageInfo.longText.length > 0) {
            messageInfo.longText = localMessageInfo.longText;
        } else {
            //下载长文本
            NSString* errorString = nil;
            NSString* longText = [self getLongText:messageInfo.statusId withErrorString:&errorString];
            if (longText.length > 0) {
                longText = [MMCommonAPI addHTMLLinkTag:longText];
            }
            messageInfo.longText = longText;
        }
    }
	
	//group
	NSDictionary* groupDict = [messageDict objectForKey:@"group"];
	if (groupDict && [groupDict isKindOfClass:[NSDictionary class]]) {
		messageInfo.groupType = [[groupDict objectForKey:@"app_id"] intValue];
		messageInfo.groupId = [[groupDict objectForKey:@"id"] intValue];
		messageInfo.groupName = [groupDict objectForKey:@"name"];
	}
	
	messageInfo.sourceName = [messageDict objectForKey:@"source_name"];
	messageInfo.liked = [[messageDict objectForKey:@"liked"] boolValue];
	messageInfo.likeCount = [[messageDict objectForKey:@"like_count"] intValue];
    
    NSDictionary* locationDict = [messageDict objectForKey:@"location"];
    if (locationDict && [locationDict isKindOfClass:[NSDictionary class]]) {
        if (locationDict.allKeys.count > 0) {
            messageInfo.longitude = [[locationDict objectForKey:@"longitude"] doubleValue];
            messageInfo.latitude  = [[locationDict objectForKey:@"latitude"] doubleValue];
            messageInfo.address   = [locationDict objectForKey:@"address"];
            messageInfo.isCorrect = [[locationDict objectForKey:@"isCorrect"] boolValue];
        }
    }
	
	//like list
	messageInfo.liked = [[messageDict objectForKey:@"liked"] boolValue];
	NSObject* likeList = [messageDict objectForKey:@"like_list"];
	if ([likeList isKindOfClass:[NSString class]]) {
		messageInfo.likeList = (NSString*)likeList;
	} else {
		if ([likeList isKindOfClass:[NSArray class]] && messageInfo.likeCount > 0) {
			NSArray* likeArray = (NSArray*)likeList;
			if (likeArray.count == 1) {
				NSString* name = [[likeArray objectAtIndex:0] objectForKey:@"name"];
				messageInfo.likeList = [NSString stringWithFormat:@"%@觉得这挺赞的", name];
			} else {
				NSString* name1 = [[likeArray objectAtIndex:0] objectForKey:@"name"];
				NSString* name2 = [[likeArray objectAtIndex:1] objectForKey:@"name"];
				
				if (likeArray.count == 2) {
					messageInfo.likeList = [NSString stringWithFormat:@"%@和%@觉得这挺赞的", name1, name2];
				} else {
					messageInfo.likeList = [NSString stringWithFormat:@"%@、%@等%d人觉得这挺赞的", name1, name2, messageInfo.likeCount];
				}
			}
		}
	}
	
	//comment
	messageInfo.commentCount = [[messageDict objectForKey:@"comment_count"] intValue];
    if (messageInfo.commentCount > 0) {
        id comment = [messageDict objectForKey:@"comment_list"];
        
        if ([comment isKindOfClass:[NSArray class]]) {
            NSArray *commentArray = comment;
            if (commentArray.count > 0) {
                NSDictionary *commentDict = [commentArray objectAtIndex:0];
                NSString* commentId = [commentDict objectForKey:@"id"];
                if (![[MMUIComment instance] isCommentExist:commentId ownerId:[[MMLoginService shareInstance] getLoginUserId]]) {
                    MMCommentInfo* commentInfo = [self commentFromDict:commentDict];
                    commentInfo.statusId = messageInfo.statusId;
                    commentInfo.ignoreTimeLine = YES;
                    [[MMUIComment instance] insertComment:commentInfo];
                    
                    messageInfo.recentComment = commentInfo;
                }
                
                messageInfo.recentCommentId = commentId;
            }
        } else if ([comment isKindOfClass:[NSDictionary class]]) {
            NSDictionary *commentDict = comment;
            NSString* commentId = [commentDict objectForKey:@"id"];
            if (![[MMUIComment instance] isCommentExist:commentId ownerId:[[MMLoginService shareInstance] getLoginUserId]]) {
                MMCommentInfo* commentInfo = [self commentFromDict:commentDict];
                commentInfo.statusId = messageInfo.statusId;
                commentInfo.ignoreTimeLine = YES;
                [[MMUIComment instance] insertComment:commentInfo];
                
                messageInfo.recentComment = commentInfo;
            }
            
            messageInfo.recentCommentId = commentId;
        }
    }
	
	//同步到微薄信息
	NSArray* syncDictArray = [messageDict objectForKey:@"sync"];
	if (syncDictArray && [syncDictArray isKindOfClass:[NSArray class]]) {
		for (NSDictionary* syncDict in syncDictArray) {
			NSString* name = [syncDict objectForKey:@"name"];
			if ([name isEqualToString:@"sina"]) {
				messageInfo.syncToSinaWeibo = YES;
				messageInfo.syncToSinaWeiboSuccess = [[syncDict objectForKey:@"is_sync"] boolValue];
				break;
			}
		}
	}
	
	//accessory 附件
	NSArray* accessoryDictArray = [messageDict objectForKey:@"accessory"];
	if (accessoryDictArray && 
		[accessoryDictArray isKindOfClass:[NSArray class]] && 
		accessoryDictArray.count > 0) {
		NSMutableArray* accessoryArray = [NSMutableArray array];
		NSMutableArray* notImageAccessoryArray = [NSMutableArray array];
		for (NSDictionary* accessoryDict in accessoryDictArray) {
			MMAccessoryInfo* accessoryInfo = [MMAccessoryInfo accessoryInfoFromDict:accessoryDict];
			
			//将图片附件放到前面
			if (accessoryInfo.accessoryType == MMAccessoryTypeImage) {
				MMImageAccessoryInfo* imageAccessoryInfo = (MMImageAccessoryInfo*)accessoryInfo;
				if (!imageAccessoryInfo.url || 
					![imageAccessoryInfo.url isKindOfClass:[NSString class]] 
					|| imageAccessoryInfo.url.length == 0) {
					continue;
				}
				
				[accessoryArray addObject:accessoryInfo];
			} else {
				[notImageAccessoryArray addObject:accessoryInfo];
			}
		}
		messageInfo.accessoryArray = [accessoryArray arrayByAddingObjectsFromArray:notImageAccessoryArray];
	}
    
	[[MMMomoUserMgr shareInstance] setUserId:messageInfo.uid 
									realName:messageInfo.realName 
							  avatarImageUrl:messageInfo.avatarImageUrl];
	
	return messageInfo;
}

- (NSArray*)downRecentMessageByURL:(NSString*)requestUrl 
			   withDeletedMessages:(NSMutableArray*)deleteArray
				   withErrorString:(NSString**)errorString {
	NSDictionary* dicObject = [MMUapRequest getSync:requestUrl compress:YES];
	lastError = [[dicObject valueForKey:@"status"] intValue];
	if (lastError != 200) {
		*errorString = [self errorStringWithResponseDict:dicObject statusCode:lastError];
		return [NSArray array];
	}
	
	NSArray* messageDictList = [dicObject valueForKey:@"data"];
    NSLog(@"message list:%@", messageDictList);
    
	NSMutableArray* retArray = [NSMutableArray array];
	if (messageDictList && messageDictList.count > 0) {
		for (NSDictionary* messageDict in messageDictList) {
			MMMessageInfo* messageInfo = [self messageFromDict:messageDict];
			if (messageInfo) {
				[retArray addObject:messageInfo];
			}
		}
	}
	
	NSArray* deletedDictArray = [dicObject valueForKey:@"delete"];
	if (deletedDictArray && 
		[deletedDictArray isKindOfClass:[NSArray class]] && 
		deletedDictArray.count > 0 && 
		deleteArray) {
		for (NSDictionary* deleteDict in deletedDictArray) {
			MMMessageInfo* messageInfo = [[MMMessageInfo alloc] init];
			messageInfo.statusId = [deleteDict objectForKey:@"id"];
			[deleteArray addObject:messageInfo];
			[messageInfo release];
		}
	}
	
	return retArray;
}

- (NSArray*)downRecentMessage:(uint64_t)lastDate 
		  withDeletedMessages:(NSMutableArray*)deleteArray
			  withErrorString:(NSString**)errorString{
	NSString *requestUrl = nil;
	if (lastDate == 0) {
		requestUrl = [NSString stringWithFormat:@"statuses/index.json?pagesize=20"];
	} else {
		requestUrl = [NSString stringWithFormat:@"statuses/index.json?pagesize=50&uptime=%llu", lastDate];
	}
	
	return [self downRecentMessageByURL:requestUrl withDeletedMessages:deleteArray withErrorString:errorString];
}

- (NSArray*)downOldMessageByURL:(NSString*)requestUrl
				withErrorString:(NSString**)errorString{
	NSDictionary* dicObject = [MMUapRequest getSync:requestUrl compress:YES];
	lastError = [[dicObject valueForKey:@"status"] intValue];
	if (lastError != 200) {
		*errorString = [self errorStringWithResponseDict:dicObject statusCode:lastError];
		return nil;
	}
	
	NSArray* messageDictList = [dicObject valueForKey:@"data"];
	if (messageDictList.count == 0) {
		return nil;
	}
	
	NSMutableArray* retArray = [NSMutableArray arrayWithCapacity:messageDictList.count];
	for (NSDictionary* messageDict in messageDictList) {
		MMMessageInfo* messageInfo = [self messageFromDict:messageDict];
		if (messageInfo) {
			[retArray addObject:messageInfo];
		}
	}
	return retArray;
}

- (NSArray*)downOldMessage:(uint64_t)earliestDate
		   withErrorString:(NSString**)errorString {
	NSString *requestUrl = [NSString stringWithFormat:@"statuses/index.json?pagesize=20&downtime=%llu", earliestDate];
	return [self downOldMessageByURL:requestUrl withErrorString:errorString];
}


- (NSArray*)downUserRecentMessage:(NSUInteger)uid 
						 lastDate:(uint64_t)lastDate 
			  withDeletedMessages:(NSMutableArray*)deleteArray
				  withErrorString:(NSString**)errorString {
	NSString *requestUrl = nil;
	if (lastDate == 0) {
		requestUrl = [NSString stringWithFormat:@"statuses/user.json?user_id=%u&pagesize=20", uid];
	} else {
		requestUrl = [NSString stringWithFormat:@"statuses/user.json?user_id=%u&pagesize=200&uptime=%llu", uid, lastDate];
	}
	
	return [self downRecentMessageByURL:requestUrl withDeletedMessages:deleteArray withErrorString:errorString];
}

- (NSArray*)downUserOldMessage:(NSUInteger)uid earliestDate:(uint64_t)earliestDate
			   withErrorString:(NSString**)errorString {
	NSString *requestUrl = [NSString stringWithFormat:@"statuses/user.json?user_id=%u&pagesize=20&downtime=%llu", uid, earliestDate];
	return [self downOldMessageByURL:requestUrl withErrorString:errorString];
}


//群组动态
- (NSArray*)downGroupRecentMessage:(NSUInteger)groupId 
						  lastDate:(uint64_t)lastDate 
			   withDeletedMessages:(NSMutableArray*)deleteArray
				   withErrorString:(NSString**)errorString {
	NSString *requestUrl = nil;
	if (lastDate == 0) {
		requestUrl = [NSString stringWithFormat:@"/statuses/group.json?group_id=%u&pagesize=20", groupId];
	} else {
		requestUrl = [NSString stringWithFormat:@"/statuses/group.json?group_id=%u&pagesize=200&uptime=%llu", groupId, lastDate];
	}
	return [self downRecentMessageByURL:requestUrl withDeletedMessages:deleteArray withErrorString:errorString];
}

- (NSArray*)downGroupOldMessage:(NSUInteger)groupId 
				   earliestDate:(uint64_t)earliestDate 
				withErrorString:(NSString**)errorString {
	NSString *requestUrl = [NSString stringWithFormat:@"/statuses/group.json?group_id=%u&pagesize=20&downtime=%llu", groupId, earliestDate];
	return [self downOldMessageByURL:requestUrl withErrorString:errorString];
}

- (NSArray*)downRecentMessageByType:(NSUInteger)typeId 
						   lastDate:(uint64_t)lastDate 
				withDeletedMessages:(NSMutableArray*)deleteArray 
					withErrorString:(NSString**)errorString {
	NSString *requestUrl = nil;
	if (lastDate == 0) {
		requestUrl = [NSString stringWithFormat:@"/statuses/type.json?type_id=%u&pagesize=20", typeId];
	} else {
		requestUrl = [NSString stringWithFormat:@"/statuses/type.json?type_id=%u&pagesize=200&uptime=%llu", typeId, lastDate];
	}
	return [self downRecentMessageByURL:requestUrl withDeletedMessages:deleteArray withErrorString:errorString];
}

- (NSArray*)downOldMessageByType:(NSUInteger)typeId 
					earliestDate:(uint64_t)earliestDate 
				 withErrorString:(NSString**)errorString {
	NSString *requestUrl = [NSString stringWithFormat:@"/statuses/type.json?type_id=%u&pagesize=20&downtime=%llu", typeId, earliestDate];
	return [self downOldMessageByURL:requestUrl withErrorString:errorString];
}

- (MMMessageInfo*)downSingleMessage:(NSString*)statusId 
                    withErrorString:(NSString**)errorString{
	NSString *requestUrl = [NSString stringWithFormat:@"statuses/im/%@.json", statusId];
	NSDictionary* dicRet = [MMUapRequest getSync:requestUrl compress:YES];
	lastError = [[dicRet valueForKey:@"status"] intValue];
	if (lastError != 200) {
        *errorString = [self errorStringWithResponseDict:dicRet statusCode:lastError];
		return nil;
	}
	
	MMMessageInfo* messageInfo = [self messageFromDict:dicRet];
	return messageInfo;
}

- (NSArray*)downComment:(NSString*)statusId 
			   pageSize:(NSInteger)pageSize 
				preTime:(uint64_t)preTime 
			   nextTime:(uint64_t)nextTime 
        withErrorString:(NSString**)errorString{
	NSString *strSource = [NSString stringWithFormat:@"comment.json?statuses_id=%@&pagesize=%d", statusId, pageSize];
	if (preTime > 0) {
		strSource = [strSource stringByAppendingFormat:@"&pre=%llu", preTime];
	} else if (nextTime > 0){
		strSource = [strSource stringByAppendingFormat:@"&next=%llu", nextTime];
	}
	
    SBJSON* sbjson = [[[SBJSON alloc] init] autorelease];
    NSString* json = nil;
	lastError = [MMUapRequest getSync:strSource responseString:&json compress:YES];
	if (lastError != 200) {
        if (lastError != 0) {
            *errorString = [self errorStringWithResponseJSON:json statusCode:lastError];
        }
		return nil;
	}
	
    NSArray* serverComments = [sbjson objectWithString:json];
	if (!serverComments 
		|| ![serverComments isKindOfClass:[NSArray class]]
		|| serverComments.count == 0) {
		return nil;
	}
	
	NSMutableArray* retArray = [NSMutableArray arrayWithCapacity:serverComments.count];
	for (NSDictionary* commentDict in serverComments) {
		MMCommentInfo* commentInfo = [self commentFromDict:commentDict];
		commentInfo.statusId = statusId;
		if (commentInfo) {
			[retArray addObject:commentInfo];
		}
	}
	return retArray;
}

- (BOOL)postPraise:(NSString*)statusId withErrorString:(NSString**)errorString{
	NSMutableDictionary* postObject = [NSMutableDictionary dictionary];
	[postObject setObject:statusId forKey:@"statuses_id"];
	
	NSString* strSource = @"praise/create.json";
    NSString* json = nil;
	lastError = [MMUapRequest postSync:strSource withObject:postObject responseString:&json];
	if (lastError != 200) {
		NSLog(@"send praise failed, status code = %d", lastError);
        
        *errorString = [self errorStringWithResponseJSON:json statusCode:lastError];
		return NO;
	}
	
	return YES;
}

- (BOOL)postMoMessage:(NSString*)statusId withErrorString:(NSString**)errorString {
    NSMutableDictionary* postObject = [NSMutableDictionary dictionary];
	[postObject setObject:statusId forKey:@"statuses_id"];
	
	NSString* strSource = @"statuses/at_sms.json";
    NSString* json = nil;
	lastError = [MMUapRequest postSync:strSource withObject:postObject responseString:&json];
	if (lastError != 200) {
		NSLog(@"send at_sms failed, status code = %d", lastError);
        
        *errorString = [self errorStringWithResponseJSON:json statusCode:lastError];
		return NO;
	}
	
	return YES;
}

- (BOOL)deleteMessageRequest:(NSString*)statusId withErrorString:(NSString**)errorString{
	NSString* strSource = [NSString stringWithFormat:@"statuses/destroy/%@.json", statusId];
	NSString* json = nil;
	lastError = [MMUapRequest getSync:strSource responseString:&json compress:YES];
	if (lastError != 200) {
		NSLog(@"delete message failed, status code = %d", lastError);
        *errorString = [self errorStringWithResponseJSON:json statusCode:lastError];
		return NO;
	}
	
	return YES;
}

- (BOOL)storeMessage:(NSString*)statusId isStoreMessage:(BOOL)isStoreMessage withErrorString:(NSString**)errorString{
	NSMutableDictionary* postObject = [NSMutableDictionary dictionary];
	[postObject setObject:statusId forKey:@"id"];
	
	if (isStoreMessage) {
		[postObject setObject:@"add" forKey:@"act"];
	} else {
		[postObject setObject:@"del" forKey:@"act"];
	}
	
	NSString* strSource = @"statuses/store.json";
	NSString* json = nil;
	lastError = [MMUapRequest postSync:strSource withObject:postObject responseString:&json];
	if (lastError != 200) {
		NSLog(@"store message failed, status code = %d", lastError);
        *errorString = [self errorStringWithResponseJSON:json statusCode:lastError];
		return NO;
	}
	
	return YES;
}

- (BOOL)hideMessage:(NSString*)statusId withErrorString:(NSString**)errorString{
	NSMutableDictionary* postObject = [NSMutableDictionary dictionary];
	[postObject setObject:statusId forKey:@"id"];
	[postObject setObject:@"add" forKey:@"act"];
	
	NSString* strSource = @"statuses/hide.json";
	NSString* json = nil;
	lastError = [MMUapRequest postSync:strSource withObject:postObject responseString:&json];
	if (lastError != 200) {
		NSLog(@"hide message failed, status code = %d", lastError);
        *errorString = [self errorStringWithResponseJSON:json statusCode:lastError];
		return NO;
	}
	
	return YES;
}

- (BOOL)deleteComment:(NSString*)commentId withErrorString:(NSString**)errorString{
	NSString* strSource = [NSString	stringWithFormat:@"comment/destroy/%@.json", commentId];
	NSString* json = nil;
	lastError = [MMUapRequest getSync:strSource responseString:&json compress:YES];
	if (lastError != 200) {
		NSLog(@"delete comment failed, status code = %d", lastError);
        *errorString = [self errorStringWithResponseJSON:json statusCode:lastError];
		return NO;
	}
	
	return YES;
}

- (BOOL)changedMySignature:(NSString*)newSignature withErrorString:(NSString**)errorString{
	NSMutableDictionary* postObject = [NSMutableDictionary dictionary];
	[postObject setObject:newSignature forKey:@"text"];
	[postObject setObject:[NSNumber numberWithInt:2] forKey:@"source"];
	NSString* strSource = @"user/update_sign.json";
	NSDictionary *dicRet = [MMUapRequest postSync:strSource withObject:postObject];
	lastError = [[dicRet valueForKey:@"status"] intValue];
	if (lastError != 200) {
		NSLog(@"changed signature failed, status code = %d", lastError);
        if (dicRet && [dicRet isKindOfClass:[NSDictionary class]]) {
			*errorString = [dicRet objectForKey:@"error"];
		}
        if (lastError == 0) {
            *errorString = @"网络连接失败";
        }
		return NO;
	}
	
	return YES;
}

- (NSString*)changedMyAvatar:(NSData*)avatarImageData originImage:(NSData*)originImageData withErrorString:(NSString**)errorString{
	if (!avatarImageData || avatarImageData.length == 0) {
		return NO;
	}
	
	NSMutableDictionary* postObject = [NSMutableDictionary dictionary];
	NSString *strEncodeData = [GTMBase64 stringByEncodingBytes:[avatarImageData bytes] length:[avatarImageData length]];
	[postObject setObject:strEncodeData forKey:@"middle_content"];
    
	if (originImageData) {
		NSString *strOriginEncodeData = [GTMBase64 stringByEncodingBytes:[originImageData bytes] length:[originImageData length]];
		[postObject setObject:strOriginEncodeData forKey:@"original_content"];
	}
	
	NSString* strSource = @"photo/update_avatar.json";
	NSDictionary *dicRet = [MMUapRequest postSync:strSource withObject:postObject];
	lastError = [[dicRet valueForKey:@"status"] intValue];
	if (lastError != 200) {
		NSLog(@"changed avatar failed, status code = %d", lastError);
        *errorString = [self errorStringWithResponseDict:dicRet statusCode:lastError];
		return nil;
	}
	
	return [dicRet objectForKey:@"src"];
}

- (NSInteger)getNewMessageNum:(int64_t)startTime withErrorString:(NSString**)errorString{
	NSString* strSource = [NSString stringWithFormat:@"statuses/new_count.json?modified_at=%llu", startTime];
	NSDictionary *dicRet = [MMUapRequest getSync:strSource compress:YES];
	lastError = [[dicRet valueForKey:@"status"] intValue];
	if (lastError != 200) {
		NSLog(@"get message num failed, status code = %d", lastError);
        *errorString = [self errorStringWithResponseDict:dicRet statusCode:lastError];
		return 0;
	}
	
	return [[dicRet objectForKey:@"statuses_count"] integerValue];
}

//linsz 下载动态长文本内容
- (NSString*)getLongText:(NSString*)statusId withErrorString:(NSString**)errorString{
    NSString *requestUrl = [NSString stringWithFormat:@"statuses/long_text.json?statuses_id=%@", statusId];
    NSDictionary *dicRet = [MMUapRequest getSync:requestUrl compress:YES];
    lastError = [[dicRet valueForKey:@"status"] intValue];
    if (lastError != 200) {
        NSLog(@"get message longText failed, status code = %d", lastError);
        *errorString = [self errorStringWithResponseDict:dicRet statusCode:lastError];
        return nil;
    }
    
    NSString* longText = [dicRet objectForKey:@"text"];
    
    //at information
	NSArray* atList = [dicRet objectForKey:@"at"];
	for (NSUInteger i = 0; i < [atList count]; i++) {
		NSDictionary* atDict = [atList objectAtIndex:i];
		
		NSUInteger uid = [[atDict objectForKey:@"id"] intValue];
		NSString*  userName = [atDict objectForKey:@"name"];
		NSString* atLink = [NSString stringWithFormat:@"<A href=\"momo://user=%d\">@%@</A>", uid, userName]; 
		NSString* target = [NSString stringWithFormat:@"[@%d]", i];
		longText = [longText stringByReplacingOccurrencesOfString:target withString:atLink];
        
        [[MMMomoUserMgr shareInstance] setUserId:uid realName:userName avatarImageUrl:nil];
	}
    
    return longText;
}



- (NSArray*)getUidsByFriends:(NSArray*)friends withErrorString:(NSString**)errorString {
	
	NSMutableArray* postArray = [NSMutableArray array];
    for (int i = 0; i < friends.count; i++) {
        MMMomoUserInfo *friend = [friends objectAtIndex:i];
		
        NSMutableDictionary* tmpDict = [NSMutableDictionary dictionary];
        [tmpDict setObject:friend.registerNumber forKey:@"mobile"];
        [tmpDict setObject:friend.realName forKey:@"name"];
		
        [postArray addObject:tmpDict];
    }
    
    NSArray* retArray = nil;
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithPath:@"register/create_at.json" withObject:postArray];
    [ASIHTTPRequest startSynchronous:request];
    NSObject *retObject = [request responseObject];
    if ([request responseStatusCode] != 200) {
        NSDictionary* dicRet = (NSDictionary*)retObject;
        *errorString = [self errorStringWithResponseDict:dicRet statusCode:lastError];
		return nil;
	}
	
    retArray = (NSArray*)retObject;
    if (!retArray || ![retArray isKindOfClass:[NSArray class]]) {
        *errorString = @"下载好友uid失败";
        return nil;
    }
    
    return retArray;
	
}

- (NSDictionary*)getUidByFriend:(MMMomoUserInfo*)friend withErrorString:(NSString**)errorString {
    NSArray *array = [self getUidsByFriends:[NSArray arrayWithObject:friend] withErrorString:errorString];
    if (![array isKindOfClass:[NSArray class]] || [array count] == 0) {
        return nil;
    }
    return [array objectAtIndex:0];
}

- (NSInteger)getUidByNumber:(NSString*)number realName:(NSString*)name withErrorString:(NSString**)errorString {
    MMMomoUserInfo *friend = [[[MMMomoUserInfo alloc] init] autorelease];
    friend.realName = name;
	friend.registerNumber = number;
	NSDictionary *dic = [self getUidByFriend:friend withErrorString:errorString];
    if (nil == dic) {
        return 0;
    }
	return [[dic objectForKey:@"user_id"] intValue];
}

- (NSDictionary*)getAppUpdateInfo:(float)localVersion withErrorString:(NSString**)errorString {
	NSMutableDictionary* postObject = [NSMutableDictionary dictionary];
	[postObject setObject:[NSNumber numberWithFloat:localVersion] forKey:@"version"];
	[postObject setObject:[NSNumber numberWithInt:2] forKey:@"source"];
	NSString* strSource = @"upgrade.json";
	NSDictionary *dicRet = [MMUapRequest postSync:strSource withObject:postObject];
	lastError = [[dicRet valueForKey:@"status"] intValue];
	if (lastError != 200) {
        if (dicRet && [dicRet isKindOfClass:[NSDictionary class]]) {
			*errorString = [dicRet objectForKey:@"error"];
		}
        if (lastError == 0) {
            *errorString = @"网络连接失败";
        }
		return nil;
	}
    return dicRet;
}

#pragma mark Group
- (NSArray*)getGroupList:(NSString**)errorString {
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithPath:@"group.json"];
    [ASIHTTPRequest startSynchronous:request];
    NSObject *retObject = [request responseObject];
    if ([request responseStatusCode] != 200) {
        NSDictionary* dicRet = (NSDictionary*)retObject;
        *errorString = [self errorStringWithResponseDict:dicRet statusCode:lastError];
		return nil;
	}
	
    NSArray* tmpArray = (NSArray*)retObject;
    if (!tmpArray || ![tmpArray isKindOfClass:[NSArray class]]) {
        *errorString = @"获取群组列表失败";
        return nil;
    }
    
    NSMutableArray* retArray = [NSMutableArray array];
    for (NSDictionary* dict in tmpArray) {
        MMGroupInfo* groupInfo = [MMGroupInfo groupInfoFromDict:dict];
        [retArray addObject:groupInfo];
    }
    
    return retArray;
}

- (NSArray*)getGroupMemberList:(NSInteger)groupID withErrorString:(NSString**)errorString {
    NSString* strSource = [NSString stringWithFormat:@"group_member/%d.json", groupID];
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithPath:strSource];
    [ASIHTTPRequest startSynchronous:request];
    NSObject *retObject = [request responseObject];
    if ([request responseStatusCode] != 200) {
        NSDictionary* dicRet = (NSDictionary*)retObject;
        *errorString = [self errorStringWithResponseDict:dicRet statusCode:lastError];
		return nil;
	}
	
    NSArray* tmpArray = (NSArray*)retObject;
    if (!tmpArray || ![tmpArray isKindOfClass:[NSArray class]]) {
        *errorString = @"获取群成员列表失败";
        return nil;
    }
    
    NSMutableArray* retArray = [NSMutableArray array];
    for (NSDictionary* dict in tmpArray) {
        MMGroupMemberInfo* memberInfo = [MMGroupMemberInfo groupMemberInfoFromDict:dict];
        [retArray addObject:memberInfo];
    }
    
    return retArray;
}

- (BOOL)createGroup:(NSString*)name 
               type:(NSInteger)type 
       introduction:(NSString*)introduction 
             notice:(NSString*)notice
    withErrorString:(NSString**)errorString {
    NSMutableDictionary* postObject = [NSMutableDictionary dictionary];
    [postObject setObject:name forKey:@"name"];
    [postObject setObject:[NSNumber numberWithInt:type] forKey:@"type"];
    [postObject setObject:introduction forKey:@"introduction"];
    [postObject setObject:notice forKey:@"notice"];
    
    NSString* strSource = @"group/create.json";
    NSString* json = nil;
    lastError = [MMUapRequest postSync:strSource withObject:postObject responseString:&json];
	if (lastError != 200) {
		NSLog(@"createGroup failed, status code = %d", lastError);
        
        *errorString = [self errorStringWithResponseJSON:json statusCode:lastError];
		return NO;
	}
	
	return YES;
}

- (BOOL)updateGroup:(NSInteger)groupID
               name:(NSString*)name 
       introduction:(NSString*)introduction 
             notice:(NSString*)notice
    withErrorString:(NSString**)errorString {
    NSMutableDictionary* postObject = [NSMutableDictionary dictionary];
    [postObject setObject:name forKey:@"name"];
    [postObject setObject:introduction forKey:@"introduction"];
    [postObject setObject:notice forKey:@"notice"];
    
    NSString* strSource = [NSString stringWithFormat:@"group/update/%d.json", groupID];
    NSString* json = nil;
    lastError = [MMUapRequest postSync:strSource withObject:postObject responseString:&json];
	if (lastError != 200) {
		NSLog(@"createGroup failed, status code = %d", lastError);
        
        *errorString = [self errorStringWithResponseJSON:json statusCode:lastError];
		return NO;
	}
	
	return YES;
}

- (MMGroupInfo*)getGroupInfoByGroupID:(NSInteger)groupID withErrorString:(NSString**)errorString {
    NSString* strSource = [NSString stringWithFormat:@"group/get/%d.json", groupID];
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithPath:strSource];
    [ASIHTTPRequest startSynchronous:request];
    NSObject *retObject = [request responseObject];
    if ([request responseStatusCode] != 200) {
        NSDictionary* dicRet = (NSDictionary*)retObject;
        *errorString = [self errorStringWithResponseDict:dicRet statusCode:lastError];
		return nil;
	}
	
    NSDictionary* tmpDict = (NSDictionary*)retObject;
    if (!tmpDict || ![tmpDict isKindOfClass:[NSDictionary class]]) {
        *errorString = @"获取群组信息失败";
        return nil;
    }
    
    MMGroupInfo* groupInfo = [MMGroupInfo groupInfoFromDict:tmpDict];
    
    return groupInfo;
}

- (BOOL)addGroupMember:(NSInteger)groupID  memberIDs:(NSArray*)memberIDs withErrorString:(NSString**)errorString {
    NSMutableDictionary* postObject = [NSMutableDictionary dictionary];
    [postObject setObject:[memberIDs componentsJoinedByString:@","] forKey:@"uid"];
    
    NSString* strSource = [NSString stringWithFormat:@"group_member/add/%d.json", groupID];
    NSString* json = nil;
    lastError = [MMUapRequest postSync:strSource withObject:postObject responseString:&json];
	if (lastError != 200) {
		NSLog(@"addGroupMember failed, status code = %d", lastError);
        
        *errorString = [self errorStringWithResponseJSON:json statusCode:lastError];
		return NO;
	}
	
	return YES;
}

- (BOOL)deleteGroupMember:(NSInteger)groupID  memberIDs:(NSArray*)memberIDs withErrorString:(NSString**)errorString {
    NSMutableDictionary* postObject = [NSMutableDictionary dictionary];
    [postObject setObject:[memberIDs componentsJoinedByString:@","] forKey:@"uid"];
    
    NSString* strSource = [NSString stringWithFormat:@"group_member/delete/%d.json", groupID];
    NSString* json = nil;
    lastError = [MMUapRequest postSync:strSource withObject:postObject responseString:&json];
	if (lastError != 200) {
		NSLog(@"deleteGroupMember failed, status code = %d", lastError);
        
        *errorString = [self errorStringWithResponseJSON:json statusCode:lastError];
		return NO;
	}
	
	return YES;
}

- (BOOL)quitGroup:(NSInteger)groupID withErrorString:(NSString**)errorString {
    NSString* strSource = [NSString stringWithFormat:@"group/quit/%d.json", groupID];
    NSString* json = nil;
    lastError = [MMUapRequest postSync:strSource withObject:nil responseString:&json];
	if (lastError != 200) {
		NSLog(@"quitGroup failed, status code = %d", lastError);
        
        *errorString = [self errorStringWithResponseJSON:json statusCode:lastError];
		return NO;
	}
	
	return YES;
}

- (BOOL)destroyGroup:(NSInteger)groupID withErrorString:(NSString**)errorString {
    NSString* strSource = [NSString stringWithFormat:@"group/destroy/%d.json", groupID];
    NSString* json = nil;
    lastError = [MMUapRequest postSync:strSource withObject:nil responseString:&json];
	if (lastError != 200) {
		NSLog(@"destroyGroup failed, status code = %d", lastError);
        
        *errorString = [self errorStringWithResponseJSON:json statusCode:lastError];
		return NO;
	}
	
	return YES;
}

@end
