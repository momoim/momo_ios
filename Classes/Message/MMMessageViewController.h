//
//  MMMessageViewController.h
//  momo
//
//  Created by wangsc on 10-12-23.
//  Copyright 2010 ND. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MMMessageDataSource.h"
#import "MMMessageDelegate.h"
#import "MBProgressHUD.h"
#import "EGORefreshTableHeaderView.h"
#import "MMGIFImageView.h"
#import "MMSelectGroupView.h"

@interface MMMessageViewController : UIViewController <UITableViewDelegate, MMMessageDelegate, UIAlertViewDelegate, UIActionSheetDelegate, MMMessageCellDelegate, EGORefreshTableHeaderDelegate, UITableViewDataSource, MMSelectGroupViewDelegate> {
	BOOL		isAllMessageInit;
	BOOL		viewFirstAppear;
	NSUInteger	currentUserId;
    UIButton* titleButton_;
	UITableView* messageTable;
	MMMessageDataSource* messageDataSource;
	
	MMMessageInfo*	currentSelectedUploadMessage;
	
    //scroll
	BOOL isDragging;
	BOOL isLoading;
	BOOL dragUpToDownOldMessage;
	
	EGORefreshTableHeaderView* refreshHeaderView;
	
    //footer view
	UIButton*	footerButton;
	UIActivityIndicatorView* footerRefreshSpinner;
    
	MBProgressHUD*	progressHub;
	NSMutableArray* backgroundThreads;
    
    UILabel* unReadAboutMeNumLabel;
    UIImageView* unReadAboutMeBgView;
    MMSelectGroupView* selectGroupView_;
}
@property (nonatomic, retain) MMMessageDataSource* messageDataSource;
@property (nonatomic, retain) MBProgressHUD*	progressHub;
@property (nonatomic, retain) MMMessageInfo* currentSelectedUploadMessage;

- (void)createTableViews:(BOOL)firstCreate;

- (void)initDataSource;

- (void)startLoading;
- (void)stopLoading:(BOOL)reloadData;

- (void)actionDownMoreMessage;
- (void)actionRefresh;
- (void)actionForNewMessage;
- (void)actionViewHomePage:(MMMessageInfo*)messageInfo;
- (void)actionRetweet:(MMMessageInfo*)messageInfo;

- (void)cancelBackgroundThreads;
- (void)reset;
- (void)onLogout;

- (void)onMomoUserInfoChanged:(NSNotification*)notification;	//MOMO用户信息变更

- (void)draftStatusChanged:(NSNotification*)notification;
- (void)uploadMessageWillStart:(NSNotification*)notification;
- (void)uploadMessageStatusChanged:(MMDraftInfo*)draftInfo;
- (void)removeUploadingDraft:(NSNotification*)notification;

- (void)performSelectorUsingMMThread:(SEL)selector object:(id)object;

- (void)refreshAboutMeNumberLabel;

@end
