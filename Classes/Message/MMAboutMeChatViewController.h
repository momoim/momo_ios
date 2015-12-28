//
//  MMAboutMeChatViewController.h
//  momo
//
//  Created by houxh on 11-5-4.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MMMessageDelegate.h"
#import "MMHidePortionTextField.h"

#import "BCTextView.h"
#import "MMFaceView.h"

@interface MMAboutMeMessageWithStyleText : MMAboutMeMessage {
	BCTextFrame *styledComment_;
	BCTextFrame *styledSrcComment_;
}
@property(nonatomic, retain) BCTextFrame *styledComment;
@property(nonatomic, retain) BCTextFrame *styledSrcComment;
@end

@interface MMAboutMeChatViewController : UIViewController 
			<UITableViewDelegate, UITextFieldDelegate, MMSelectFriendViewDelegate, 
			UITableViewDataSource, BCTextViewDelegate, MMHidePortionTextFieldDelegate , MMFaceDelegate > {
	UITableView			*tableView_;
	UIView				*linearLayout_;
	MMAboutMeMessage	*replyTarget_;
    NSMutableArray		*messages_;
	MMMessageInfo		*messageInfo_;
	

    NSString			*statusId_;
    BOOL				isViewUnload_;
	
	UIView				*faceBgView;
}

@property(nonatomic, readonly)	NSString *statusId;
@property(nonatomic)			BOOL isViewUnload;

- (id)initWithStatusId:(NSString *)statusId;
- (void)handleTapFrom:(UITapGestureRecognizer *)recognizer;
- (void)actionForAt:(id)sender;

- (void)actionToMessage:(id)sender;
- (void)actionLeft:(id)sender;
- (void)actionRight:(id)sender;

- (void)actionTitleBtn;

- (void)actionForSelectFace;
- (void)actionDismissInput;

- (void)pushDownTextField;
- (void)pushUpTextField; 
@end
