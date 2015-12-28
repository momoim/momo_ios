//
//  MMChatFriend.h
//  momo
//
//  Created by liaoxh on 11-2-12.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MMModel.h"
#import "DbStruct.h"

@interface MMChatFriend : MMModel {

}

+ (id)instance;

- (NSArray*)getChatFriendList;
- (BOOL)isChatFriendExist:(NSInteger)uid withError:(MMErrorType*)error;

- (MMMomoUserInfo*)friendInfoFromPLResultSet:(id)object;


- (MMErrorType)insertFriend:(NSInteger)friendId;
- (MMErrorType)deleteFriend:(NSInteger)friendId; 
@end
