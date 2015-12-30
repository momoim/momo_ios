//
//  MMFriendDB.h
//  momo
//
//  Created by houxh on 15/12/31.
//
//

#import "MMModel.h"

@interface MMFriendDB : NSObject
+ (MMFriendDB*)instance;




@property(atomic) int updateTimestamp;

- (void)setFriends:(NSArray*)friends;
- (NSArray*)getFriends;

@end
