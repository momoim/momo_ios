//
//  MMChatFriend.m
//  momo
//
//  Created by liaoxh on 11-2-12.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MMChatFriend.h"
#import "MMGlobalData.h"

@implementation MMChatFriend

+ (id)instance {
	static id _instance = nil;
    @synchronized(self) {
        if(_instance == nil) 
            _instance = [[self class] new];
    }
    return _instance;
}

- (NSArray*)getChatFriendList {
	// 如果数据没打开
	if(![[self db]  goodConnection]) {
		return nil;
	}
	
	NSError* outError = nil;
	NSString * sql = @"select friend.* from chat_friend,friend where friend.uid = chat_friend.friend_id;";
	id<PLResultSet> results = [[self db]  executeQueryAndReturnError:&outError statement:sql];        
	if(SQLITE_OK != [outError code]) {
		return nil;
	}
	
	NSMutableArray* chatFriendArray = [NSMutableArray array];
	PLResultSetStatus status = [results nextAndReturnError:nil];
	while (status) {
		MMMomoUserInfo* friendInfo = [self friendInfoFromPLResultSet:results];
		[chatFriendArray addObject:friendInfo];
		
		status = [results nextAndReturnError:nil];
	}
	[results close];
	
	return chatFriendArray;
}
- (BOOL)isChatFriendExist:(NSInteger)uid withError:(MMErrorType*)error {
	MMErrorType ret = MM_DB_OK;
	NSError* outError = nil;
	BOOL isExist = NO;
	// 如果数据没打开
	do {
		if(![[self db]  goodConnection]) {
			ret = MM_DB_FAILED_OPEN;
            break;
		}
		
		NSString* sql = @"select count(*) from chat_friend where friend_id = ?;";
		id<PLResultSet> results = [[self db]  executeQueryAndReturnError:&outError statement:sql, [NSNumber numberWithInt:uid]];        
		if(SQLITE_OK != [outError code]) {
			ret = MM_DB_FAILED_QUERY;
            break;
		}
		
		PLResultSetStatus status = [results nextAndReturnError:nil];
		if(status == PLResultSetStatusRow) {
			NSInteger count = [results intForColumnIndex:0];
			if (count > 0) {
				isExist = (count > 0);
			}
		}
		[results close];
	}
    while(0);
	
	if(error)
        *error = ret;
	
	return isExist;
}

- (MMErrorType)insertFriend:(NSInteger)friendId {
    MMErrorType ret = MM_DB_OK;
	return ret;
//TODO: need modify
//	MMErrorType ret = MM_DB_OK;
//    
//    do{
//        // 如果数据没打开
//        if(![[self db]  goodConnection]) {
//            ret = MM_DB_FAILED_OPEN;
//            break;
//        }
//        
//        id<PLPreparedStatement> stmt = [[self db]  prepareStatement:@"INSERT INTO chat_friend (login_id, friend_id) VALUES(?, ?)"];
//        
//        // 绑定参数
//        [stmt bindParameters:[NSArray arrayWithObjects:[NSNumber numberWithInt:[MMGlobalData getLoginUserid]]
//                              , [NSNumber numberWithInt:friendId]
//							  ]
//		 ];
//        
//        // 如果执行失败
//        NSError* outError;
//        if(![stmt executeUpdateAndReturnError:&outError]) {
//            ret = MM_DB_FAILED_INVALID_STATEMENT;
//            break;
//        }
//		
//    }
//    while(0);
//    
//    return ret;
}

- (MMErrorType)deleteFriend:(NSInteger)friendId {
	MMErrorType ret = MM_DB_OK;
	return ret;
}

- (MMMomoUserInfo*)friendInfoFromPLResultSet:(id)object {
	
	//需增加字段
	id<PLResultSet> results = object;
	
	MMMomoUserInfo* friendInfo = [[[MMMomoUserInfo alloc] init] autorelease];
	friendInfo.uid = [results intForColumn:@"uid"];
	friendInfo.realName = [results stringForColumn:@"real_name"];
	friendInfo.avatarImageUrl = [results stringForColumn:@"avatar_image_url"];
	
	return friendInfo;
}

@end
