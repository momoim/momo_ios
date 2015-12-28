//
//  MMMessageSyncer.h
//  momo
//
//  Created by wangsc on 11-1-11.
//  Copyright 2011 ND. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DbStruct.h"

@interface MMMessageSyncer : NSObject {
	NSUInteger	lastError;
}
@property (nonatomic) NSUInteger lastError;

+ (id)shareInstance;

- (MMMessageInfo*)messageFromDict:(NSDictionary*)messageDict;
- (MMCommentInfo*)commentFromDict:(NSDictionary*)commentDict;

//全部动态
- (NSArray*)downRecentMessage:(uint64_t)lastDate 
		  withDeletedMessages:(NSMutableArray*)deleteArray
			  withErrorString:(NSString**)errorString;
- (NSArray*)downOldMessage:(uint64_t)earliestDate
		   withErrorString:(NSString**)errorString;

//个人动态
- (NSArray*)downUserRecentMessage:(NSUInteger)uid 
						 lastDate:(uint64_t)lastDate 
			  withDeletedMessages:(NSMutableArray*)deleteArray
				  withErrorString:(NSString**)errorString;
- (NSArray*)downUserOldMessage:(NSUInteger)uid 
				  earliestDate:(uint64_t)earliestDate
			   withErrorString:(NSString**)errorString;

//群组动态
- (NSArray*)downGroupRecentMessage:(NSUInteger)groupId 
						  lastDate:(uint64_t)lastDate 
			   withDeletedMessages:(NSMutableArray*)deleteArray
				   withErrorString:(NSString**)errorString;
- (NSArray*)downGroupOldMessage:(NSUInteger)groupId 
				   earliestDate:(uint64_t)earliestDate
				withErrorString:(NSString**)errorString;

//按类型获取动态
- (NSArray*)downRecentMessageByType:(NSUInteger)typeId 
						   lastDate:(uint64_t)lastDate 
				withDeletedMessages:(NSMutableArray*)deleteArray
					withErrorString:(NSString**)errorString;
- (NSArray*)downOldMessageByType:(NSUInteger)typeId 
					earliestDate:(uint64_t)earliestDate
                 withErrorString:(NSString**)errorString;

- (MMMessageInfo*)downSingleMessage:(NSString*)statusId withErrorString:(NSString**)errorString;

- (NSArray*)downComment:(NSString*)statusId 
			   pageSize:(NSInteger)pageSize 
                preTime:(uint64_t)preTime 
               nextTime:(uint64_t)nextTime
        withErrorString:(NSString**)errorString;

- (BOOL)postPraise:(NSString*)statusId withErrorString:(NSString**)errorString;

- (BOOL)postMoMessage:(NSString*)statusId withErrorString:(NSString**)errorString;

- (BOOL)deleteMessageRequest:(NSString*)statusId withErrorString:(NSString**)errorString;


- (BOOL)storeMessage:(NSString*)statusId isStoreMessage:(BOOL)isStoreMessage withErrorString:(NSString**)errorString;

- (BOOL)hideMessage:(NSString*)statusId withErrorString:(NSString**)errorString;

- (BOOL)deleteComment:(NSString*)commentId withErrorString:(NSString**)errorString;

- (BOOL)changedMySignature:(NSString*)newSignature withErrorString:(NSString**)errorString;

- (NSString*)changedMyAvatar:(NSData*)avatarImageData originImage:(NSData*)originImageData withErrorString:(NSString**)errorString;

- (NSInteger)getNewMessageNum:(int64_t)startTime withErrorString:(NSString**)errorString;

- (NSString*)getLongText:(NSString*)statusId withErrorString:(NSString**)errorString;


- (NSDictionary*)getUidByFriend:(MMMomoUserInfo*)friendInfo withErrorString:(NSString**)errorString; 
- (NSInteger)getUidByNumber:(NSString*)number realName:(NSString*)name withErrorString:(NSString**)errorString; 
- (NSArray*)getUidsByFriends:(NSArray*)friends withErrorString:(NSString**)errorString; 

- (NSDictionary*)getAppUpdateInfo:(float)localVersion withErrorString:(NSString**)errorString;


//Group
- (NSArray*)getGroupList:(NSString**)errorString;

- (NSArray*)getGroupMemberList:(NSInteger)groupID withErrorString:(NSString**)errorString;

- (MMGroupInfo*)getGroupInfoByGroupID:(NSInteger)groupID withErrorString:(NSString**)errorString;

- (BOOL)createGroup:(NSString*)name 
               type:(NSInteger)type 
       introduction:(NSString*)introduction 
             notice:(NSString*)notice
    withErrorString:(NSString**)errorString;

- (BOOL)updateGroup:(NSInteger)groupID
               name:(NSString*)name 
       introduction:(NSString*)introduction 
             notice:(NSString*)notice
    withErrorString:(NSString**)errorString;

- (BOOL)addGroupMember:(NSInteger)groupID  memberIDs:(NSArray*)memberIDs withErrorString:(NSString**)errorString;

- (BOOL)deleteGroupMember:(NSInteger)groupID  memberIDs:(NSArray*)memberIDs withErrorString:(NSString**)errorString;

- (BOOL)quitGroup:(NSInteger)groupID withErrorString:(NSString**)errorString;

- (BOOL)destroyGroup:(NSInteger)groupID withErrorString:(NSString**)errorString;

@end
