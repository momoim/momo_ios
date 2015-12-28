//
//  MMAboutMeViewController.h
//  momo
//
//  Created by houxh on 11-5-4.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MMMessageDelegate.h"
#import "EGORefreshTableHeaderView.h"
#import "MMHidePortionTextField.h"
#import "BCTextView.h"
#import "MMAboutMeRootCell.h"
#import "MMAboutMeDragView.h"
#import "MMFaceView.h"

@interface MMAboutMeViewController : UIViewController< UITableViewDelegate, UITableViewDataSource,
														UITextFieldDelegate, MMSelectFriendViewDelegate,
														EGORefreshTableHeaderDelegate, BCTextViewDelegate,
														MMHidePortionTextFieldDelegate, MMFaceDelegate, UIGestureRecognizerDelegate,
                                                        MMAboutMeRootCellDelegate> 
{
	UITableView					*tableView_;

	UILabel						*footerLabel_;
	CGFloat						firstX_;
    
   	BOOL						refreshing_;
    BOOL                        viewFirstLoad_;
    
    NSMutableArray				*records_;			//关于我的对应的动态

	EGORefreshTableHeaderView	*refreshHeaderView;
    
    MMAboutMeMessage	*replyTarget_;
    UIView				*linearLayout_;
	UIView				*faceBgView;
    BOOL                pushUp_;
	//footer view
	UIButton*	footerButton_;
	UIActivityIndicatorView* footerRefreshSpinner_;
	BOOL isLoading_;
}

@property(nonatomic, retain)	NSMutableArray	*records;
@property(nonatomic)			BOOL			refreshing;

- (NSMutableArray *)mutableUnreadedMessages;

- (void)actionLeft:(id)sender;
- (void)actionRight:(id)sender; 

- (void)refresh;

- (BOOL)addMessage:(MMAboutMeMessage *)message;

- (void)reload;
//- (NSArray *)getAboutMeList;

- (void)startLoading;

- (void)clearUnReadFlagByRecord:(MMAboutMeRecord*)record;

@end
