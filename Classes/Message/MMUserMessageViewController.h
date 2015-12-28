//
//  MMUserMessageViewController.h
//  momo
//
//  Created by  on 11-9-26.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DbStruct.h"
#import "MBProgressHUD.h"
#import "MMFriendMessageDataSource.h"
#import "MMMessageCell.h"
#import "EGORefreshTableHeaderView.h"
#import "MMScrollPageViewController.h"

@interface MMUserMessageViewController : MMScrollPageViewController
<UITableViewDelegate, MMMessageDelegate, UIAlertViewDelegate, UIActionSheetDelegate, 
MMMessageCellDelegate, EGORefreshTableHeaderDelegate>{
	BOOL viewNeedDealloc;
	UIButton* buttonLeft_;
	UIButton* buttonRight_;
	
	MMMomoUserInfo*  currentFriendInfo;
	
	//好友动态列表相关
    BOOL isInit;
	BOOL isDragging;
	BOOL isLoading;
	MMFriendMessageDataSource* messageDataSource;
    
	UITableView*	messageTable;
    //header
    EGORefreshTableHeaderView* refreshHeaderView;
    
    //footer view
    UIButton*	footerButton;
    UIActivityIndicatorView* footerRefreshSpinner;
    
	MBProgressHUD*	progressHub;
	NSMutableArray* backgroundThreads;
}
@property (nonatomic) BOOL viewNeedDealloc;
@property (nonatomic, retain) MMMomoUserInfo* currentFriendInfo;
@property (nonatomic, retain) MMFriendMessageDataSource* messageDataSource;

- (id)initWithFriendInfo:(MMMomoUserInfo*)friendInfo;

- (void)performSelectorUsingMMThread:(SEL)selector object:(id)object;
- (void)actionLeft:(id)sender;
- (void)actionRight:(id)sender;

- (void)showDownloadFailed;

- (void)startLoading;
- (void)stopLoading:(BOOL)reloadData;

- (void)actionDownMoreMessage;

- (void)setScrollToTop:(BOOL)scrollToTop;

@end