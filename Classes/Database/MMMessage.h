//
//  MMMessage.h
//  Db
//
//  Created by wangsc on 10-12-27.
//  Copyright 2010 ND. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MMModel.h"
#import "ErrorType.h"
#import "DbStruct.h"

@interface MMMessage : MMModel {

}

+ (id)instance;

- (MMErrorType)insertMessage:(MMMessageInfo*)messageInfo;

- (MMErrorType)saveMessage:(MMMessageInfo*)messageInfo;

- (NSMutableArray*)getMessageList:(NSUInteger)ownerId;

- (NSInteger)getMessageCount:(NSUInteger)ownerId;

- (MMMessageInfo*)getMessage:(NSString*)statusId ownerId:(NSUInteger)ownerId;

- (MMMessageInfo*)getMessage:(NSString*)statusId ownerId:(NSUInteger)ownerId;

- (BOOL)isMessageExist:(NSString*)statusId ownerId:(NSUInteger)ownerId withError:(MMErrorType*)error;

- (MMMessageInfo*)messageInfoFromPLResultSet:(id)object;

- (MMErrorType)deleteMessage:(MMMessageInfo*)messageInfo;

- (NSMutableArray*)getLimitMessageList:(NSUInteger)count startTime:(uint64_t)startTime ownerId:(NSUInteger)ownerId;

- (NSUInteger)sameMessageCount:(NSString*)statusId;

- (MMErrorType)removeAllMessage:(NSUInteger)ownerId;

@end
