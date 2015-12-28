//
//  MMAboutMeManager.h
//  momo
//
//  Created by houxh on 11-8-1.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MMModel.h"

@interface MMAboutMeManager : MMModel
{
	NSInteger unReadCount_;
    NSMutableArray* allAboutMeList_;
}
@property (nonatomic) NSInteger unReadCount;
@property (nonatomic, retain) NSMutableArray* allAboutMeList;

+(MMAboutMeManager *)shareInstance;

- (NSInteger)getUnreadMessageCount;
- (NSArray *)readUnreadMessageList;
- (NSArray *)getAboutMessageList:(BOOL)includeReaded listCount:(NSInteger)count;

- (NSArray *)getStatusIdList;
- (NSInteger)getUnreadCountWithStatusId:(NSString *)statusId ;
- (MMAboutMeMessage *)getNewestMessageWithStatusId:(NSString *)statusId;
- (NSArray *)getAboutMeListWithStatusId:(NSString *)statusId;
- (int64_t)getMaxDateLine;
- (BOOL)isExist:(NSString *)msgid;
- (BOOL)clearUnreadFlag;
- (BOOL)clearUnreadFlagWithStatusId:(NSString *)statusId;
- (BOOL)clearUnReadFlagWithMessageId:(NSString *)msgid;
- (BOOL)insertMessage:(MMAboutMeMessage *)message;
- (BOOL)deleteAllMessage;
- (NSInteger)refreshAboutMe;
- (BOOL)deleteMessageWithStatusId:(NSString *)statusId; 

@end

