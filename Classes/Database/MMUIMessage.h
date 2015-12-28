//
//  MMUIMessage.h
//  Db
//
//  Created by wangsc on 10-12-27.
//  Copyright 2010 ND. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MMMessage.h"

@interface MMUIMessage : NSObject {
	
}

+ (id)instance;

- (MMErrorType)insertMessage:(MMMessageInfo*)messageInfo;

- (MMErrorType)saveMessage:(MMMessageInfo*)messageInfo;

- (NSMutableArray*)getMessageList:(NSUInteger)ownerId;

- (MMMessageInfo*)getMessage:(NSString*)statusId ownerId:(NSUInteger)ownerId;
- (MMMessageInfo*)getMessage:(NSString*)statusId;

- (BOOL)isMessageExist:(NSString*)statusId ownerId:(NSUInteger)ownerId;

- (MMErrorType)deleteMessage:(MMMessageInfo*)messageInfo;

- (NSMutableArray*)getLimitMessageList:(NSUInteger)count startTime:(uint64_t)startTime ownerId:(NSUInteger)ownerId;

- (MMErrorType)removeAllMessage:(NSUInteger)ownerId;

- (MMErrorType)deleteComment:(MMCommentInfo*)commentInfo;
@end
