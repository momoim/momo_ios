//
//  MMAboutMeRootCell.h
//  momo
//
//  Created by houxh on 11-9-25.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MMMessageDelegate.h"
#import "EGORefreshTableHeaderView.h"
#import "MMHidePortionTextField.h"
#import "BCTextView.h"
extern void ReplyCornersBorder(UIView *view, CGRect rect);
@interface MMAboutMeRecord : NSObject {
	
	MMMessageInfo		*messageInfo;
    BCTextFrame			*messageText;
	MMAboutMeMessage	*message;
    BCTextFrame			*aboutMeText;
}
@property (nonatomic, retain)BCTextFrame *messageText;
@property (nonatomic, retain)BCTextFrame *aboutMeText;
@property (nonatomic, retain)MMMessageInfo *messageInfo;
@property (nonatomic, retain)MMAboutMeMessage *message;

@end

@protocol MMAboutMeRootCellDelegate;
@interface MMAboutMeRootCell : UITableViewCell {
    MMAboutMeRecord* aboutMeRecord_;
    id<MMAboutMeRootCellDelegate> delegate_;
}
@property (nonatomic, assign) id<MMAboutMeRootCellDelegate> delegate;
@property (nonatomic, retain) MMAboutMeRecord* aboutMeRecord;

-(void)setRecord:(MMAboutMeRecord*)rcd;
@end

@protocol MMAboutMeRootCellDelegate <NSObject>

@optional
- (void)didClickAtAvatar:(MMAboutMeRootCell*)cell;
- (void)didSwipeToLeft:(MMAboutMeRootCell*)cell;

@end
