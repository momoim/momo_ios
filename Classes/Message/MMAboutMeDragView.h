//
//  MMAboutMeDragView.h
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

@interface MMAboutMeDragView : UIImageView {

	UIButton* hiddenDismissInputButton;
}
@property(nonatomic, readonly) MMHidePortionTextField *inputTextField;
@property(nonatomic, readonly) UIButton *faceButton;
@property(nonatomic, readonly) UIButton *atButton;
@property(nonatomic, readonly) UIButton *gotoMessage;

- (void) setMessage:(MMAboutMeMessage*)message srcStatus:(MMMessageInfo*)messageInfo;
@end