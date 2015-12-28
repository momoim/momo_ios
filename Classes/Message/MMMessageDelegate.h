//
//  MMMessageDelegate.h
//  momo
//
//  Created by wangsc on 10-12-30.
//  Copyright 2010 ND. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DbStruct.h"

#define MMNotificationMessageDidReceived @"MMNotificationMessageDidReceived"

@protocol MMMessageDelegate<NSObject>

@optional
- (void)uapLoginDidSuccess;

- (void)downloadMessageDidSuccess:(NSDictionary*)userInfo;

- (void)deleteMessageDidSuccess:(MMMessageInfo*)message;

- (void)deleteCommentDidSuccess:(MMMessageInfo*)messageInfo;

@end

@protocol MMNewMessageDelegate<NSObject>

@optional
- (void)attachImagesChanged:(NSMutableArray*)changedImageArray;

- (void)attachImageChangedAtIndex:(UIImage*)image index:(NSUInteger)index;
@end

@protocol MMSelectFriendViewDelegate<NSObject>
@optional
- (void)didSelectFriend:(NSArray*)selectedFriends;

@end

@protocol MMSelectContactViewDelegate<NSObject>
@optional
- (void)didSelectContact:(NSArray*)selectedContacts;

@end

@protocol MMDraftBoxDelegate<NSObject>
@optional

- (void)draftDeleted:(NSIndexPath*)indexPath;

- (void)draftNeedRefresh:(NSIndexPath*)indexPath;

- (void)draftInserted:(NSIndexPath*)indexPath;

@end

@protocol MMMyMomoDelegate<NSObject>
@optional

- (void)momoCardDidChange:(MMCard *)fullContact;
- (void)mobileDidChange:(NSString *)newMobile withPassword:(NSString *)password;
- (void)weiboDidBinding:(NSDictionary *)weiboDic;

@end