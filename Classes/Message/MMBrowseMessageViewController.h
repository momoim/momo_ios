//
//  MMBrowseMessageViewController.h
//  momo
//
//  Created by wangsc on 11-1-7.
//  Copyright 2011 ND. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DbStruct.h"
#import "MMMessageDataSource.h"
#import "MMMessageDelegate.h"
#import "MMWebImageButton.h"
#import "MMCommentCell.h"
#import "MBProgressHUD.h"
#import "MMAvatarImageView.h"
#import "MMHidePortionTextField.h"
#import "BCTextView.h"
#import "MMFaceView.h"
#import "BCTextView.h"
#import "MMSelectAddressViewController.h"

@interface MMBrowseMessageViewController : UIViewController
	<UIScrollViewDelegate, UITableViewDelegate, UITableViewDataSource, 
    UIActionSheetDelegate, MMCommentCellDelegate, 
    BCTextViewDelegate, UITextFieldDelegate, MMSelectFriendViewDelegate, 
    MMHidePortionTextFieldDelegate, MMFaceDelegate> {
		
    UISwipeGestureRecognizer* gesture;
	//content
	UIView*				contentView;
	
	UIScrollView*		contentScrollView;
    BCTextView*         contentLabel;
	
	MMAvatarImageView *imageAvatarView;
	UILabel*			nameLabel;
	UIImageView*		phoneIndicator;
	UILabel*			timeLabel;
	UIImageView*		haveImageView;
	UILabel*			commentCountLabel;
		
    //动态图片区域
    UIImageView* imageBackView;
    MMWebImageButton* imageView1;
        
    //附件文件区域
    UIButton* fileDownloadBtn;
    UILabel* fileDownloadName;
        
    //地址区域
    UIButton* addressBtn;
    UILabel* addressName;
		
	//comment table
	UITableView*		commentTable;

	//comment table scroll
	BOOL isLoading;	
	
	//footer view
	UIButton*	footerButton;
	UIActivityIndicatorView* footerRefreshSpinner;
		
	//toolbar items
    UIButton* longTextBtn;
    UIImageView* toolBarBgView;
    UIButton* commentBtn;
    UIButton* praiseBtn;
    UIButton* retweetBtn;
    UIButton* moreBtn;
		
	//发评论
	UIImageView* sendMsgBgView;
	MMHidePortionTextField* sendMsgTextField;
	UIButton* atButton;
	UIButton* hiddenDismissInputButton;
	MMCommentInfo* currentReplyComment;
	NSRange			cursorPosition;	//@好友时存储光标位置
    UIView*         faceBgView;
	
	//from all message
	MMMessageInfo*		currentMessageInfo;
	NSUInteger			currentMessageIndex;
	MMMessageDataSource* messageDataSource;
	MMCommentInfo*		currentSelectedUploadComment;
		
	//from about me
	BOOL				fromAboutMeMessage;
	NSString*			aboutMeStatusId;
	
	id<MMMessageDelegate> messageDelegate;
		
	BOOL				viewNeedDealloc;
	MBProgressHUD*	progressHub;
    MBProgressHUD*	progressHubDelete;
	NSMutableArray*		backgroundThreads;
        
        
    //Comment cache
    NSMutableArray* commentArray;
    NSMutableArray* uploadCommentArray;
}

@property (nonatomic, retain) MMMessageInfo* currentMessageInfo;
@property (nonatomic, assign) MMMessageDataSource* messageDataSource;
@property (nonatomic, assign) id<MMMessageDelegate> messageDelegate;
@property (nonatomic) BOOL fromAboutMeMessage;
@property (nonatomic, copy) NSString* aboutMeStatusId;
@property (nonatomic, retain) NSMutableArray* commentArray;
@property (nonatomic, retain) NSMutableArray* uploadCommentArray;

- (id)initWithStatusId:(NSString*)statusId;
- (void)downAboutMeMessage:(id)object;

- (id)initWithMessageInfo:(MMMessageInfo*)messageInfo;

- (void)loadMessage;

- (void)actionLeft:(id)sender;

- (void)segmentChanged:(UISegmentedControl*)segment;
- (void)nextMessage:(id)sender;
- (void)preMessage:(id)sender;

- (void)actionShowDetail;	//查看日志,活动,投票等详情
- (void)actionDownRecentComment;	
- (void)actionRetweet:(id)sender;
- (void)actionPraise:(id)sender;
- (void)actionComment:(id)sender;
- (void)actionHomePage:(id)sender;
- (void)actionViewLongText:(id)sender;
- (void)actionViewHomePage:(MMMessageInfo*)messageInfo;
- (void)actionForSelectFace;
- (void)actionDownloadFile;

- (void)pushDownTextField;
- (void)pushUpTextField;

- (void)currentMessageChanged;

- (void)uploadCommentWillStart:(NSNotification*)notification;
- (void)uploadCommentStatusChanged:(NSNotification*)notification;
- (void)removeUploadingDraft:(NSNotification*)notification;

- (void)performSelectorUsingMMThread:(SEL)selector object:(id)object;


- (void)actionViewAttachImage:(MMWebImageButton*)imageButton;
- (void)actionDismissInput;

//Comment Data
- (void)initData;
- (void)startDownloadComment;

//upload
- (void)addUploadComment:(MMCommentInfo*)commentInfo;
- (void)updateCommentStatus:(UploadStatus)uploadStatus draftId:(NSUInteger)draftId;
- (NSIndexPath*)getUploadCommentIndexPath:(NSUInteger)draftId;
- (NSIndexPath*)deleteUploadComment:(NSUInteger)draftId;

@end
