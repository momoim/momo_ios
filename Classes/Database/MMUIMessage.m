//
//  MMUIMessage.m
//  Db
//
//  Created by wangsc on 10-12-27.
//  Copyright 2010 ND. All rights reserved.
//

#import "MMUIMessage.h"
#import "MMMessage.h"
#import "MMComment.h"
#import "MMHttpDownloadMgr.h"
#import "MMGlobalData.h"
#import "MMLoginService.h"

@implementation MMUIMessage

+ (id)instance {
	static id _instance = nil;
    @synchronized(self) {
        if(_instance == nil) 
            _instance = [[self class] new];
    }
    return _instance;
}

- (MMErrorType)insertMessage:(MMMessageInfo*)messageInfo {
	return [[MMMessage instance] insertMessage:messageInfo];
}

- (MMErrorType)saveMessage:(MMMessageInfo*)messageInfo {
	return [[MMMessage instance] saveMessage:messageInfo];
}

- (NSMutableArray*)getMessageList:(NSUInteger)ownerId {
	return [[MMMessage instance] getMessageList:ownerId];
}

- (MMMessageInfo*)getMessage:(NSString*)statusId ownerId:(NSUInteger)ownerId {
	return [[MMMessage instance] getMessage:statusId ownerId:ownerId];
}
- (MMMessageInfo*)getMessage:(NSString*)statusId {
	return [[MMMessage instance] getMessage:statusId ownerId:[[MMLoginService shareInstance] getLoginUserId]];
}
- (BOOL)isMessageExist:(NSString*)statusId ownerId:(NSUInteger)ownerId {
	MMErrorType error = MM_DB_OK;
	return [[MMMessage instance] isMessageExist:statusId ownerId:ownerId withError:&error];
}

- (MMErrorType)deleteMessage:(MMMessageInfo*)messageInfo {
	MMErrorType ret = [[MMMessage instance] deleteMessage:messageInfo];
	if (ret != MM_DB_OK)
		return ret;
	
	ret = [[MMComment instance] deleteCommentByStatusId:messageInfo.statusId ownerId:messageInfo.ownerId];
	if (ret != MM_DB_OK)
		return ret;
	
	dispatch_async(dispatch_get_main_queue(), ^{
		[[NSNotificationCenter defaultCenter] postNotificationName:kMMMessageDeleted object:messageInfo];
	});

	return ret;
}

- (NSMutableArray*)getLimitMessageList:(NSUInteger)count startTime:(uint64_t)startTime ownerId:(NSUInteger)ownerId {
	return [[MMMessage instance] getLimitMessageList:count startTime:startTime ownerId:ownerId];
}

- (MMErrorType)removeAllMessage:(NSUInteger)ownerId {
//	[[MMHttpDownloadMgr shareInstance] removeAllCache];
	NSArray* messages = [[MMMessage instance] getMessageList:ownerId];
	for (MMMessageInfo* messageInfo in messages) {
		for (MMImageAccessoryInfo* accessoryInfo in messageInfo.accessoryArray) {
			if ([accessoryInfo isKindOfClass:[MMImageAccessoryInfo class]]) {
				[[MMHttpDownloadMgr shareInstance] removeCacheForUrl:accessoryInfo.url];
			}
		}
	}
	
	MMErrorType ret = [[MMMessage instance] removeAllMessage:ownerId];
	if (ret != MM_DB_OK) {
		return ret;
	}
	
	ret = [[MMComment instance] removeAllComment:ownerId];
	if (ret != MM_DB_OK) {
		return ret;
	}
	
	dispatch_async(dispatch_get_main_queue(), ^{
		[[NSNotificationCenter defaultCenter] postNotificationName:kMMAllMessageDeleted object:nil];
	});
	
	return ret;
}

- (MMErrorType)deleteComment:(MMCommentInfo*)commentInfo {
	MMErrorType ret = [[MMComment instance] deleteCommentByCommentId:commentInfo.commentId ownerId:commentInfo.ownerId];
	if (ret != MM_DB_OK)
		return ret;
	
//    dispatch_async(dispatch_get_main_queue(), ^{
//		[[NSNotificationCenter defaultCenter] postNotificationName:kMMMessageDeleted object:commentInfo];
//	});
	return ret;
}

@end
