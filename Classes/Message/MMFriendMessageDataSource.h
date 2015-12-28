//
//  MMFriendMessageDataSource.h
//  momo
//
//  Created by jackie on 11-6-14.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DbStruct.h"
#import "MMMessageDataSource.h"

@interface MMFriendMessageDataSource : MMMessageDataSource <UITableViewDataSource>{
	MMMomoUserInfo* currentFriendInfo;
}
@property (nonatomic, retain) MMMomoUserInfo* currentFriendInfo;

- (id)initWithFriendInfo:(MMMomoUserInfo*)friendInfo;

@end
