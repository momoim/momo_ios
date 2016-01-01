//
//  MMBrowseMessageViewController.m
//  momo
//
//  Created by wangsc on 11-1-7.
//  Copyright 2011 ND. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "MMBrowseMessageViewController.h"
#import "MMThemeMgr.h"
#import "MMCommentCell.h"
#import "MMCommonAPI.h"
#import "MMNewCommentViewController.h"
#import "MMMessageSyncer.h"
#import "MMUIMessage.h"
#import "MMGlobalData.h"
#import "MMGlobalStyle.h"
#import "MMUIDefines.h"
#import "MMUploadQueue.h"
#import "MMDraft.h"
#import "MMRetweetViewController.h"
#import "MMDraftMgr.h"
#import "RegexKitLite.h"
#import "MMWebImageButton.h"
#import "MWPhotoBrowser.h"
#import "MMUIDefines.h"
#import "unistd.h"
#import "MMUapRequest.h"
#import "oauth.h"
#import "MMWebViewController.h"
#import "MMSelectFriendViewController.h"
#import "MMMomoUserMgr.h"
#import "MMLoginService.h"
#import "MMGlobalPara.h"
#import "MMPreference.h"
#import "MMFaceTextFrame.h"
#import "MTStatusBarOverlay.h"
#import "MMComment.h"
#import "MMMapViewController.h"
#import "UIActionSheet+MKBlockAdditions.h"

#define ATTACH_IMAGES_HEIGHT  160

#define CONTENT_WIDTH 239
#define CONTENT_MAX_HEIGHT 270
#define CONTENT_MIN_HEIGHT 68

#define CONTENT_MIDDLE_MAX_HEIGHT 230
#define CONTENT_BROWSER_MIN_HEIGHT 38
#define COMMENT_START_OFFSET 68
#define COMMENT_TABLE_HEIGHT 304

#define ATTACH_IMAGE_SIZE 56
static NSMutableDictionary* offsetDic = nil;  //动态的偏移值

@implementation MMBrowseMessageViewController
@synthesize currentMessageInfo, messageDataSource, messageDelegate;
@synthesize fromAboutMeMessage, aboutMeStatusId;	//about me
@synthesize commentArray, uploadCommentArray;

- (id)init {
    self = [super init];
    if (self) {
        isLoading = NO;
		currentSelectedUploadComment = nil;
		viewNeedDealloc = NO;
        
		backgroundThreads = [[NSMutableArray alloc] init];
        self.commentArray = [NSMutableArray array];
        self.uploadCommentArray = [NSMutableArray array];
        
        NSNotificationCenter* notificationCenter = [NSNotificationCenter defaultCenter];
        [notificationCenter addObserver:self selector:@selector(uploadCommentStatusChanged:) name:kMMDraftStatusChanged object:nil];
        [notificationCenter addObserver:self selector:@selector(uploadCommentWillStart:) name:kMMDraftStartUpload object:nil];
        [notificationCenter addObserver:self selector:@selector(removeUploadingDraft:) name:kMMDraftRemoved object:nil];
        
        if (offsetDic == nil) {
            offsetDic = [[NSMutableDictionary dictionary] retain];
        }
    }
    return self;
}

- (id)initWithStatusId:(NSString*)statusId {
	if (self = [self init]) {
		fromAboutMeMessage = YES;
		aboutMeStatusId = statusId;
		
		MMMessageInfo* messageInfo = [[MMUIMessage instance] getMessage:statusId ownerId:[[MMLoginService shareInstance] getLoginUserId]];
		if (messageInfo) {
			self.currentMessageInfo = messageInfo;
		} else {
			if (!progressHub) {
				progressHub = [[MBProgressHUD alloc] initWithView:self.view];
				[self.view addSubview:progressHub];
                
                CGRect newFrame = progressHub.frame;
                newFrame.origin.y -= 100;
                progressHub.frame = newFrame; 
                
				progressHub.labelText = @"下载中...";
                progressHub.detailsLabelText = @"";
				[self.view bringSubviewToFront:progressHub];
				[progressHub release];
				[progressHub show:YES];
			 }
			
			[self performSelectorUsingMMThread:@selector(downAboutMeMessage:) object:self];
		}
	}
	return self;
}

- (void)dealloc {
    [MMCommonAPI waitHTTPThreadsQuit:backgroundThreads];
	[backgroundThreads release];
	self.currentMessageInfo = nil;
    self.commentArray = nil;
    self.uploadCommentArray = nil;
    [progressHubDelete release];
    [contentView release];

    NSNotificationCenter* notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver:self];
    
	[super dealloc];
}

- (void)performSelectorUsingMMThread:(SEL)selector object:(id)object {
	MMHttpRequestThread* thread = [[MMHttpRequestThread alloc] initWithTarget:self 
																	 selector:selector
																	   object:object];
	[backgroundThreads addObject:thread];
	[thread start];
	[thread release];
}

- (void)afterDownAboutMeMessage:(MMMessageInfo*)messageInfo {
	if (messageInfo) {
		self.currentMessageInfo = messageInfo;
		[self loadMessage];
		
		messageInfo.ignoreDateLine = YES;
		[[MMUIMessage instance] saveMessage:messageInfo];
		
		[progressHub hide:YES];
	} else {
		progressHub.labelText = @"下载失败";
        progressHub.detailsLabelText = @"";
        [progressHub hide:YES afterDelay:PROGRESS_HUB_PRESENT_TIME];
	}
}

- (void)downAboutMeMessage:(id)object {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
    NSString* errorString = nil;
	MMMessageInfo* messageInfo = [[MMMessageSyncer shareInstance] downSingleMessage:aboutMeStatusId withErrorString:&errorString];
    dispatch_async(dispatch_get_main_queue(), ^{
        if (messageInfo) {
            self.currentMessageInfo = messageInfo;
            [self loadMessage];
            
            messageInfo.ignoreDateLine = YES;
            [[MMUIMessage instance] saveMessage:messageInfo];
            
            [progressHub hide:YES];
        } else {
            progressHub.labelText = @"下载失败";
            progressHub.detailsLabelText = @"";
            [progressHub hide:YES afterDelay:PROGRESS_HUB_PRESENT_TIME];
        }
    });
	
	[pool release];
}

- (id)initWithMessageInfo:(MMMessageInfo*)messageInfo{
	if (self = [self init]) {
		fromAboutMeMessage = NO;
		self.currentMessageInfo = messageInfo;

        NSValue* offset = [offsetDic objectForKey:messageInfo.statusId];
        if (offset) {
            self.currentMessageInfo.contentOffset = [offset CGPointValue];
        }
	}
	return self;
}

- (void)loadMessage {
    commentCountLabel.hidden = YES;
	imageBackView.hidden     = YES;
    fileDownloadBtn.hidden   = YES;
    addressBtn.hidden        = YES;
    NSUInteger topOffset     = 0;  //某个区域底部的Y坐标值
    
    //分享者头像区域
	imageAvatarView.imageURL = [[MMMomoUserMgr shareInstance] avatarImageUrlByUserId:currentMessageInfo.uid];
	
	//分享者姓名区域
	nameLabel.text = currentMessageInfo.realName;
	CGSize constraint = CGSizeMake(256, 20000.f);
	CGSize expectedLabelSize = [nameLabel.text sizeWithFont:nameLabel.font 
										  constrainedToSize:constraint 
											  lineBreakMode:UILineBreakModeWordWrap];
	CGRect newFrame = nameLabel.frame;
	newFrame.size.width = expectedLabelSize.width;
	nameLabel.frame = newFrame;
	NSInteger leftOffset = newFrame.origin.x + newFrame.size.width + MARGIN;
	
	//动态时间
	timeLabel.text = [MMCommonAPI getDateString:[NSDate dateWithTimeIntervalSince1970:currentMessageInfo.createDate]];
	constraint = CGSizeMake(310 - leftOffset, 20000.f);
	expectedLabelSize = [timeLabel.text sizeWithFont:timeLabel.font constrainedToSize:constraint lineBreakMode:UILineBreakModeWordWrap];
	newFrame = timeLabel.frame;
	newFrame.size.width = expectedLabelSize.width;
	newFrame.origin.x = 61;
	timeLabel.frame = newFrame;

    //导航栏赞按钮
    praiseBtn.enabled = !(currentMessageInfo.liked);
    
	//1:分享内容
    //1.1分享文本内容
    BCTextFrame* textFrame = nil;
    if (currentMessageInfo.isLongText && [currentMessageInfo.longText length]) {
        textFrame = [[[MMFaceTextFrame alloc] initWithHTML:currentMessageInfo.longText] autorelease];
    }else{
        textFrame = [[[MMFaceTextFrame alloc] initWithHTML:currentMessageInfo.text] autorelease];
    }

    textFrame.fontSize = 14;
    textFrame.delegate = contentLabel;
    textFrame.width = CONTENT_WIDTH;
    contentLabel.textFrame = textFrame;
    
    newFrame = contentLabel.frame;
    newFrame.size.height = textFrame.height;
    [contentLabel setFrameWithoutLayout:newFrame];
    topOffset = contentLabel.frame.origin.y + contentLabel.frame.size.height;
    
    //1.2分享图片内容
	NSUInteger imageCount = 0;
	for (MMAccessoryInfo* accessoryInfo in currentMessageInfo.accessoryArray) {
		if (accessoryInfo.accessoryType == MMAccessoryTypeImage) {
			imageCount++;
		}
	}
	
	if (imageCount > 0) {
		MMImageAccessoryInfo* accessoryInfo = [currentMessageInfo.accessoryArray objectAtIndex:0];
        NSString* imageURL = accessoryInfo.url;

        
        //图片尺寸
        if ( (accessoryInfo.height > 0) && (accessoryInfo.width> 0)) {
            NSUInteger imgHeight = 0;           
            
            if (accessoryInfo.width > accessoryInfo.height) {
                imgHeight = 242 * 3.0 / 4.0;
            }else{
                imgHeight = 242 * 4.0 / 3.0;
            }
            
            //图片尺寸
            newFrame             = imageView1.frame;
            newFrame.origin.y    = 6;
            newFrame.size.height = imgHeight;
            imageView1.frame     = newFrame;
        }

        //图片边框尺寸
        imageBackView.hidden = NO;
        newFrame             = imageBackView.frame;
		newFrame.origin.y    = topOffset + 10;
        newFrame.size.height = 6 + imageView1.frame.size.height + 6;
        if (imageCount > 1) {
            imageBackView.image = [MMThemeMgr imageNamed:@"share_photo_bg.png"];
            newFrame.size.width = 257;
        }else{
            imageBackView.image = [MMThemeMgr imageNamed:@"share_photo_single.png"];
            newFrame.size.width = 252;
        }
        imageBackView.frame  = newFrame;

        topOffset = imageBackView.frame.origin.y + imageBackView.frame.size.height;
        
        //下载320宽度尺寸图片
		[imageView1 removeAllActions];
		[imageView1 setPlaceholderImageByPhotoId:accessoryInfo.accessoryId];
        NSString* ImageURL320 = [imageURL stringByReplacingOccurrencesOfString:@"_130."withString:@"_320."];
		[imageView1 resetImageURL:ImageURL320];
        [imageView1 setTargetAndActionByImageURL:self action:@selector(actionViewAttachImage:) withPhotoId:accessoryInfo.accessoryId];
		if (accessoryInfo.accessoryId > 0) {
			[imageView1 startLoading];
		}
	}
	
    //1.2分享文件下载
	BOOL hasFile = NO;
	for (MMAccessoryInfo* accessoryInfo in currentMessageInfo.accessoryArray) {
		if (accessoryInfo.accessoryType == MMAccessoryTypeFile) {
			hasFile = YES;
		}
	}
    if (hasFile) {
        MMImageAccessoryInfo* accessoryInfo = [currentMessageInfo.accessoryArray objectAtIndex:0];
        NSString* fileName= accessoryInfo.title;
        
        fileDownloadBtn.hidden = NO;
        fileDownloadName.text = fileName;
        newFrame = fileDownloadBtn.frame;
        newFrame.origin.y = topOffset + 10;
        fileDownloadBtn.frame = newFrame;
        topOffset = fileDownloadBtn.frame.origin.y + fileDownloadBtn.frame.size.height;
    }
    
    //地理显示区域
    if ( (0.0!=currentMessageInfo.longitude) && (0.0!=currentMessageInfo.latitude) ) {
        addressBtn.hidden = NO;
        addressName.text = currentMessageInfo.address;
        newFrame = addressBtn.frame;
        newFrame.origin.y = topOffset + 10;
        addressBtn.frame = newFrame;
        topOffset = addressBtn.frame.origin.y + addressBtn.frame.size.height;
    }
    
	//评论数以及赞
    if (currentMessageInfo.commentCount || currentMessageInfo.likeList) {
        commentCountLabel.hidden = NO;
        if (currentMessageInfo.likeList) {
            commentCountLabel.text = [NSString stringWithFormat:@"评论:%d %@", currentMessageInfo.commentCount, currentMessageInfo.likeList];
        } else {
            commentCountLabel.text = [NSString stringWithFormat:@"评论:%d", currentMessageInfo.commentCount];
        }
        newFrame             = commentCountLabel.frame;
        newFrame.origin.y    = topOffset + 10;
        commentCountLabel.frame = newFrame;
        
        topOffset = commentCountLabel.frame.origin.y + commentCountLabel.frame.size.height;
    }else{
        commentCountLabel.hidden = YES;
    }
	
    //评论详情内容
    newFrame.size.height = topOffset + 10;
    contentView.frame = newFrame;
    commentTable.tableHeaderView = contentView;
    
    //comment table
	commentTable.hidden = NO;
	commentTable.dataSource = self;
    [commentTable setContentOffset:currentMessageInfo.contentOffset animated:NO];
    [self initData];
	[commentTable reloadData];
	
	//初始化下载评论
	[self startDownloadComment];
	
	sendMsgBgView.hidden = NO;
}

- (void)loadView {
	[super loadView];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    if (!gesture) {
        gesture = [[[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(actionLeft:)] autorelease];
        gesture.direction = UISwipeGestureRecognizerDirectionRight;
        [self.view addGestureRecognizer:gesture];
    }
	
    //1.1导航返回按钮
	UIButton* buttonLeft_ = [[[UIButton alloc] initWithFrame:CGRectMake(0, 0, 34, 30)] autorelease];
	UIImage* image = [MMThemeMgr imageNamed:@"topbar_back.png"];
	[buttonLeft_ setImage:image forState:UIControlStateNormal];
	[buttonLeft_ setImage:image forState:UIControlStateHighlighted];
	[buttonLeft_ setBackgroundImage:[MMThemeMgr imageNamed:@"common_topbar_ic_press.png"] forState:UIControlStateHighlighted];
	[buttonLeft_ addTarget:self action:@selector(actionLeft:) forControlEvents:UIControlEventTouchUpInside];
	self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:buttonLeft_] autorelease];
	
    //1.2导航标题
	self.navigationItem.title = @"分享详情";
	
    //1.3导航赞按钮以及转发按钮
    UIView* topButtonView= [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 74, 30)] autorelease];
    praiseBtn = [[[UIButton alloc] initWithFrame:CGRectMake(0, 0, 34, 30)] autorelease];
	image = [MMThemeMgr imageNamed:@"share_topbar_praise.png"];
	[praiseBtn setImage:image forState:UIControlStateNormal];
	[praiseBtn setImage:image forState:UIControlStateHighlighted];
    [praiseBtn setImage:[MMThemeMgr imageNamed:@"share_praise_disable.png"] forState:UIControlStateDisabled];
    [praiseBtn setBackgroundImage:[MMThemeMgr imageNamed:@"common_topbar_ic_press.png"] forState:UIControlStateHighlighted];
    [praiseBtn addTarget:self action:@selector(actionPraise:) forControlEvents:UIControlEventTouchUpInside];
    [topButtonView addSubview:praiseBtn];
    
    UIButton* cutLineButton = [[[UIButton alloc] initWithFrame:CGRectMake(35, 0, 2, 30)] autorelease];
	image = [MMThemeMgr imageNamed:@"share_topbar_cutline.png"];
	[cutLineButton setImage:image forState:UIControlStateNormal];
	[cutLineButton setImage:image forState:UIControlStateHighlighted];
    [topButtonView addSubview:cutLineButton];
    
    retweetBtn = [[[UIButton alloc] initWithFrame:CGRectMake(39, 0, 34, 30)] autorelease];
	image = [MMThemeMgr imageNamed:@"share_topbar_transmit.png"];
	[retweetBtn setImage:image forState:UIControlStateNormal];
	[retweetBtn setImage:image forState:UIControlStateHighlighted];
    [retweetBtn setBackgroundImage:[MMThemeMgr imageNamed:@"common_topbar_ic_press.png"] forState:UIControlStateHighlighted];
    [retweetBtn addTarget:self action:@selector(actionRetweet:) forControlEvents:UIControlEventTouchUpInside];
    [topButtonView addSubview:retweetBtn];
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:topButtonView] autorelease];
	
    //2动态内容部分
    contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 400)];
	contentView.backgroundColor = RGBCOLOR(249, 249, 249);
	
	//2.1头像
	imageAvatarView = [[MMAvatarImageView alloc] initWithAvatarImageURL:nil];
	imageAvatarView.frame = CGRectMake(10, CELL_CONTENT_OFFSET, 41, 41);
	imageAvatarView.layer.masksToBounds = YES;
	imageAvatarView.layer.cornerRadius = 3.0;
	[contentView addSubview:imageAvatarView];
	[imageAvatarView release];
	
    //2.2名字
	nameLabel = [[[UILabel alloc] initWithFrame:CGRectMake(61, CELL_CONTENT_OFFSET, 60, 15)] autorelease];
	nameLabel.backgroundColor = [UIColor clearColor];
	nameLabel.font = [UIFont boldSystemFontOfSize:16];
	[contentView addSubview:nameLabel];

    //2.3动态时间
	timeLabel = [[[UILabel alloc] initWithFrame:CGRectMake(61, 31, 70, 15)] autorelease];
	timeLabel.backgroundColor = [UIColor clearColor];
	timeLabel.font = [UIFont systemFontOfSize:12];
	timeLabel.textColor = GRAY_LABEL_FONT_COLOR;
	timeLabel.textAlignment = UITextAlignmentRight;
	[contentView addSubview:timeLabel];
    
    //2.4动态内容
    contentLabel = [[BCTextView alloc] initWithFrame:CGRectMake(61, 59, 249, 15)];
    contentLabel.backgroundColor = [UIColor clearColor];
    [contentView addSubview:contentLabel];
	
    //3图片区域
    //动态图片区域
    imageBackView = [[UIImageView alloc] initWithFrame:CGRectMake(59, 10, 252, 173)];
    imageBackView.image = [MMThemeMgr imageNamed:@"share_photo_single.png"];
    imageBackView.userInteractionEnabled = YES;
    [contentView addSubview:imageBackView];
    imageView1 = [[MMWebImageButton alloc] initWithDefaultPlaceholderImage];
    imageView1.frame = CGRectMake(6, 6, 239, 160);
    imageView1.layer.masksToBounds = YES;
    imageView1.backgroundColor = RGBCOLOR(198, 198, 198);
    imageView1.tag = 19;
    [imageBackView addSubview:imageView1];
    [imageView1 release];
    [imageBackView release];
    
    //附件文件下载区域
    fileDownloadBtn = [[UIButton alloc] initWithFrame:CGRectMake(61, 10, 249, 17)];
    UIImageView* downImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 19, 17)];
    downImageView.image = [MMThemeMgr imageNamed:@"share_download.png"];
    [fileDownloadBtn addSubview:downImageView];
    [downImageView release];
    fileDownloadBtn.userInteractionEnabled = YES;
    fileDownloadBtn.tag = 31;
    fileDownloadName = [[UILabel alloc] initWithFrame:CGRectMake(24, 1, 249, 15)];
    fileDownloadName.font = [UIFont systemFontOfSize:14];
    fileDownloadName.textColor= RGBCOLOR(0, 112, 191);
    fileDownloadName.backgroundColor = [UIColor clearColor];
    [fileDownloadBtn addSubview:fileDownloadName];
    [fileDownloadName release];
    fileDownloadBtn.backgroundColor = [UIColor clearColor];
    [fileDownloadBtn addTarget:self action:@selector(actionDownloadFile) forControlEvents:UIControlEventTouchUpInside];
    
    [contentView addSubview:fileDownloadBtn];
    [fileDownloadBtn release];
    
    //地址显示区域
    addressBtn = [[[UIButton alloc] initWithFrame:CGRectMake(61, 10, 249, 17)] autorelease];
    UIImageView* addressImageView = [[[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 19, 17)] autorelease];
    addressImageView.image = [MMThemeMgr imageNamed:@"share_map.png"];
    [addressBtn addSubview:addressImageView];
    addressBtn.userInteractionEnabled = YES;
    addressBtn.tag = 32;
    addressName = [[[UILabel alloc] initWithFrame:CGRectMake(24, 1, 249, 15)] autorelease];
    addressName.font = [UIFont systemFontOfSize:14];
    addressName.textColor= RGBCOLOR(0, 112, 191);
    addressName.backgroundColor = [UIColor clearColor];
    [addressBtn addSubview:addressName];
    [addressBtn addTarget:self action:@selector(actionShowAddress) forControlEvents:UIControlEventTouchUpInside];
    [contentView addSubview:addressBtn];

	//评论数
	commentCountLabel = [[[UILabel alloc] initWithFrame:CGRectMake(61, 5, 249, 12)] autorelease];
	commentCountLabel.textColor = GRAY_LABEL_FONT_COLOR;
	commentCountLabel.backgroundColor = [UIColor clearColor];
	commentCountLabel.font = [UIFont systemFontOfSize:12];
	commentCountLabel.text = @"评论";
	[contentView addSubview:commentCountLabel];
	commentCountLabel.hidden = YES;
	
	//3评论表格(contentView作为其tableHeaderView)
    commentTable = [[[UITableView alloc] initWithFrame:CGRectMake(0, 0, 320, iPhone5?371+88:371)] autorelease];
	commentTable.delegate = self;
	commentTable.backgroundColor = [UIColor	clearColor];
	commentTable.scrollsToTop = YES;
	[self.view insertSubview:commentTable atIndex:1];
	[self.view sendSubviewToBack:commentTable];
	commentTable.hidden = YES;
	
    
	//refresh footer
	footerButton = [UIButton buttonWithType:UIButtonTypeCustom];
	footerButton.frame = CGRectMake(0, 1, 320, 44);
    
//	[footerButton setBackgroundImage:[MMThemeMgr imageNamed:@"refresh_bg_normal.png"] 
//							forState:UIControlStateNormal];
//	[footerButton setBackgroundImage:[MMThemeMgr imageNamed:@"refresh_bg_press.png"] 
//							forState:UIControlStateHighlighted];
	[footerButton addTarget:self action:@selector(actionDownRecentComment) forControlEvents:UIControlEventTouchUpInside];
	[footerButton setTitle:@"获取新评论..." forState:UIControlStateNormal];
    footerButton.titleLabel.font = [UIFont systemFontOfSize:16];
	[footerButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
	
	footerRefreshSpinner = [[[UIActivityIndicatorView alloc] 
							 initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray] autorelease];
	footerRefreshSpinner.center = CGPointMake(footerButton.frame.size.width / 5, footerButton.frame.size.height / 2);
	footerRefreshSpinner.hidesWhenStopped = YES;
	[footerButton addSubview:footerRefreshSpinner];
	commentTable.tableFooterView = footerButton;
    	
	//4发送评论
	sendMsgBgView = [[[UIImageView alloc] initWithFrame:CGRectMake(0, iPhone5?371+88:371, 320, 45)] autorelease];
	sendMsgBgView.image =  [MMThemeMgr imageNamed:@"chat_basebar_bg.png"];
	sendMsgBgView.userInteractionEnabled = YES;
	[self.view addSubview:sendMsgBgView];
	sendMsgBgView.hidden = YES;
	
	UIImageView* inputboxView = [[[UIImageView alloc]initWithFrame:CGRectMake(45, 6, 230, 33)] autorelease];
	inputboxView.image = [MMThemeMgr imageNamed:@"chat_basebar_inputbox_bg.png"];
	[sendMsgBgView addSubview:inputboxView];
	
	sendMsgTextField = [[[MMHidePortionTextField alloc] initWithFrame:CGRectMake(50, 6, 220, 33)] autorelease];
	sendMsgTextField.textField.font = [UIFont systemFontOfSize:14];
	sendMsgTextField.hidePortionTextFieldDelegate = self;
	sendMsgTextField.textField.enablesReturnKeyAutomatically = YES;
	sendMsgTextField.textField.returnKeyType = UIReturnKeySend;
	sendMsgTextField.textField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
	sendMsgTextField.textField.autocorrectionType = UITextAutocorrectionTypeNo;
	
	sendMsgTextField.textField.placeholder =  @"输入评论内容...";
	[sendMsgBgView addSubview:sendMsgTextField];
	
	atButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[atButton setImage:[MMThemeMgr imageNamed:@"publish_dynamic_bottombar_at.png"] forState:UIControlStateNormal];
	[atButton setImage:[MMThemeMgr imageNamed:@"publish_dynamic_bottombar_at_press.png"] forState:UIControlStateHighlighted];
	atButton.frame = CGRectMake(0, 0, 45, 45);
	[atButton addTarget:self action:@selector(actionForSelectFriendName) forControlEvents:UIControlEventTouchUpInside];
	[sendMsgBgView addSubview:atButton];
    
    UIButton* faceButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[faceButton setImage:[MMThemeMgr imageNamed:@"chat_ic_face.png"] forState:UIControlStateNormal];
	faceButton.frame = CGRectMake(275, 0, 45, 45);
	[faceButton addTarget:self action:@selector(actionForSelectFace) forControlEvents:UIControlEventTouchUpInside];
    [sendMsgBgView addSubview:faceButton];
    
    faceBgView = [[[UIView alloc] initWithFrame:CGRectMake(0, iPhone5?416+88:416, 320, 216)] autorelease];
    faceBgView.backgroundColor = RGBCOLOR(175, 221, 234);
    [self.view addSubview:faceBgView];
    
    MMFaceView* faceView = [[[MMFaceView alloc] init] autorelease];
    [faceView initPara];
	faceView.frame = CGRectMake(0, 0, 320, 216);
	faceView.delegate_ = self;
	[faceBgView addSubview:faceView];	
	
	//取消输入焦点按钮
	hiddenDismissInputButton = [UIButton buttonWithType:UIButtonTypeCustom];
	hiddenDismissInputButton.backgroundColor = [UIColor clearColor];
	hiddenDismissInputButton.hidden = YES;
	[hiddenDismissInputButton addTarget:self action:@selector(actionDismissInput) forControlEvents:UIControlEventTouchDown];
	[self.view insertSubview:hiddenDismissInputButton belowSubview:sendMsgBgView];
	
	if (!progressHub) {
		progressHub = [[MBProgressHUD alloc] initWithView:self.view];
		[self.view addSubview:progressHub];
        CGRect newFrame = progressHub.frame;
        newFrame.origin.y -= 100;
        progressHub.frame = newFrame; 
        
		progressHub.labelText = @"下载中...";
		[self.view bringSubviewToFront:progressHub];
		[progressHub release];
	}

    //5读取内容并调整控件位置
	[self loadMessage];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    
    progressHub = nil;
    contentView = nil;
	
	contentScrollView = nil;
	contentLabel = nil;
	
	imageAvatarView = nil;
	nameLabel = nil;
	phoneIndicator = nil;
	timeLabel = nil;
	haveImageView = nil;
	commentCountLabel = nil;
    
    commentTable = nil;
	
	//footer view
	footerButton = nil;
	footerRefreshSpinner = nil;
    
	//toolbar items
	toolBarBgView = nil;
	commentBtn = nil;
	praiseBtn = nil;
	retweetBtn = nil;
	longTextBtn = nil;
	moreBtn = nil;
    
	//发评论
	sendMsgBgView = nil;
	sendMsgTextField = nil;
	atButton = nil;
	hiddenDismissInputButton = nil;
	
	faceBgView = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
}

#pragma mark Actions
- (void)actionDismissInput {
    [sendMsgTextField resignFirstResponder];
	[self pushDownTextField];
}

- (void)showAttachImage:(NSInteger)startShowImageIndex {
	NSMutableArray* photos = [NSMutableArray array];
	
	int count = 0;
	for (MMAccessoryInfo* accessoryInfo in currentMessageInfo.accessoryArray) {
		if (accessoryInfo.accessoryType == MMAccessoryTypeImage) {
			count++;
		}
	}

	for (int i = 0; i < count; i++) {
		MMImageAccessoryInfo* accessoryInfo = [currentMessageInfo.accessoryArray objectAtIndex:i];
		NSString* smallImageURL = accessoryInfo.url;
        
        //根据最短尺寸最好大于320像素的要求下载合适的图片
        NSUInteger minLength = 0;
        NSString* imgURLType = @"_780."; //780默认尺寸 1600  原图
        if ( (accessoryInfo.height > 0) && (accessoryInfo.width> 0)) {         
            if (accessoryInfo.width > accessoryInfo.height) {
                minLength = (accessoryInfo.height * 780.0)/accessoryInfo.width;
                if (minLength < 320) {
                    minLength = (accessoryInfo.height * 1600.0)/accessoryInfo.width;
                    if (minLength < 320){
                        imgURLType = @".";         //原图
                    }else{
                        imgURLType = @"_1600.";    //1600尺寸
                    }
                }
            }else{
                minLength = (780.0 * accessoryInfo.width)/accessoryInfo.height;
                if (minLength < 320) {
                    minLength = (1600.0 * accessoryInfo.width * 1.0)/accessoryInfo.height;
                    if (minLength < 320){
                        imgURLType = @".";         //原图
                    }else{
                        imgURLType = @"_1600.";    //1600尺寸
                    }
                }
            }
        }
		NSString* originImageUrl = [smallImageURL stringByReplacingOccurrencesOfString:@"_130." withString:imgURLType];
		
		MWPhoto* photoView = [[MWPhoto alloc] initWithURL:[NSURL URLWithString:originImageUrl]];
		[photos addObject:photoView];
		[photoView release];
	}
    
	MMPhotoBrowser* viewController = [[MMPhotoBrowser alloc] initWithPhotos:photos];
	viewController.hidesBottomBarWhenPushed = YES;
	[viewController setInitialPageIndex:startShowImageIndex];
    viewController.oldFrame = imageBackView.frame;
	[self.navigationController pushViewController:viewController animated:NO];
	[viewController release];
}

- (void)actionViewAttachImage:(MMWebImageButton*)imageButton {
	int count = 0;
	for (MMAccessoryInfo* accessoryInfo in currentMessageInfo.accessoryArray) {
		if (accessoryInfo.accessoryType == MMAccessoryTypeImage) {
			count++;
		}
	}

	NSString* imageURL = imageButton.imageURL;
	int startShowImageIndex = 0;
	for (int i = 0; i < count; i++) {
		MMImageAccessoryInfo* accessoryInfo = [currentMessageInfo.accessoryArray objectAtIndex:i];
		NSString* smallImageURL = accessoryInfo.url;
		if ([smallImageURL compare:imageURL options:NSCaseInsensitiveSearch] == NSOrderedSame) {
			startShowImageIndex = i;
			break;
		}
	}
	
	[self showAttachImage:startShowImageIndex];
}

- (void)actionViewMoreAttachImage {
	[self showAttachImage:3];
}

- (void)actionLeft:(id)sender {
    [offsetDic setObject: [NSValue valueWithCGPoint:commentTable.contentOffset] 
                  forKey: currentMessageInfo.statusId];
    
    [self.view removeGestureRecognizer:gesture];
    
	[imageView1 cancelImageLoad];
	viewNeedDealloc = YES;
	
	[MMCommonAPI waitHTTPThreadsQuit:backgroundThreads];
	
	[[self navigationController] popViewControllerAnimated:YES];
}

- (void)segmentChanged:(UISegmentedControl*)segment {
	if (segment.selectedSegmentIndex == 0) {
		[self preMessage:nil];
	} else {
		[self nextMessage:nil];
	}

	[segment setEnabled:YES forSegmentAtIndex:0];
	[segment setEnabled:YES forSegmentAtIndex:1];
	if (currentMessageIndex == 1) {
		[segment setEnabled:NO forSegmentAtIndex:0];
	}else if (currentMessageIndex == messageDataSource.messageArray.count) {
		[segment setEnabled:NO forSegmentAtIndex:1];
	}
}

- (void)nextMessage:(id)sender {
	if (currentMessageIndex + 1 > messageDataSource.messageArray.count) {
		return;
	}
	
	currentMessageIndex++;
	self.currentMessageInfo = [messageDataSource.messageArray objectAtIndex:currentMessageIndex - 1];
	
	[self loadMessage];
}

- (void)preMessage:(id)sender {
	if (currentMessageIndex <= 1) {
		return;
	}
	
	currentMessageIndex--;
	self.currentMessageInfo = [messageDataSource.messageArray objectAtIndex:currentMessageIndex - 1];
	
	[self loadMessage];
}

- (void)actionShowDetail {
	NSString* url = [MMCommonAPI getDetailURL:currentMessageInfo.typeId applicationId:currentMessageInfo.applicationId];
	if (!url) {
		return;
	}
	
	MMWebViewController* webController = [[[MMWebViewController alloc] init] autorelease];
	[webController loadView];
	UIWebView* webView = [webController webView];
	webView.scalesPageToFit = NO;
	[webController openURL:[NSURL URLWithString:url]];
	[self.navigationController pushViewController:webController animated:YES];
}

- (void)actionDownRecentComment {
	if (!isLoading) {
		[footerRefreshSpinner startAnimating];
		[footerButton setTitle:@"获取新评论..." forState:UIControlStateNormal];
        [self startDownloadComment];
	}
}

//////////////
//toolbar actions
- (void)actionDownloadFile{
    MMImageAccessoryInfo* accessoryInfo = [currentMessageInfo.accessoryArray objectAtIndex:0];
    NSString* fileURL = accessoryInfo.url;
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:fileURL]];
}

- (void)actionShowAddress{
    MMMapViewController *viewController = [[[MMMapViewController alloc] init] autorelease];
    CLLocationCoordinate2D addressCoordinate;
    addressCoordinate.latitude = currentMessageInfo.latitude;
    addressCoordinate.longitude= currentMessageInfo.longitude;
   
    viewController.shouldGetFriendGPSOffset = !currentMessageInfo.isCorrect;
    viewController.friendCoordinate         = addressCoordinate;
    viewController.addressName              = currentMessageInfo.address;
    viewController.friendId                 = currentMessageInfo.uid;
    
    viewController.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:viewController animated:YES];
}

- (void)actionRetweet:(id)sender {
	MMRetweetViewController* controller = [[MMRetweetViewController alloc] 
											  initWithRetweetMessage:currentMessageInfo];
	controller.hidesBottomBarWhenPushed = YES;
	controller.messageDelegate = messageDelegate;
	[self.navigationController pushViewController:controller animated:YES];
	[controller release];
}

- (void)sendPraiseInBackground:(id)object {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	NSString* result = nil;
    NSString* errorString = nil;
	if (![[MMMessageSyncer shareInstance] postPraise:currentMessageInfo.statusId withErrorString:&errorString]) {
		result = @"赞失败";
		currentMessageInfo.liked = NO;
        dispatch_async(dispatch_get_main_queue(), ^{
            praiseBtn.enabled = YES;
            
            progressHub.labelText = result;
            progressHub.detailsLabelText = errorString ? errorString : @"";
            [progressHub show:YES];
            [progressHub hide:YES afterDelay:PROGRESS_HUB_PRESENT_TIME];
        });
		
	} else {
		result = @"赞成功";
        dispatch_async(dispatch_get_main_queue(), ^{
            praiseBtn.enabled = NO;
            [[MTStatusBarOverlay sharedInstance] postImmediateFinishMessage:result 
                                                                   duration:STATUSBAR_OVERLAY_HIDE_DELAY_TIME 
                                                                   animated:YES];
        });
	}
	
	[pool drain];
}

- (void)actionPraise:(id)sender {
    CHECK_NETWORK;
    
	if (!currentMessageInfo.liked) {
		currentMessageInfo.liked = YES;
		praiseBtn.enabled = NO;
		
		[self performSelectorUsingMMThread:@selector(sendPraiseInBackground:) object:nil];
	}
}

- (void)actionComment:(id)sender {
	[sendMsgTextField becomeFirstResponder];
}

- (void)actionHomePage:(id)sender {
	[self actionViewHomePage:currentMessageInfo];
}

- (void)actionViewLongText:(id)sender {
    CHECK_NETWORK;
    
    NSString* url = [MMCommonAPI getLongTextURL:currentMessageInfo.statusId];
    [MMCommonAPI openUrl:url];
}

- (void)actionViewHomePage:(MMMessageInfo*)messageInfo {
    //todo
}

- (void)actionForSelectFriendName {
	MMSelectFriendViewController* selectViewController = [[MMSelectFriendViewController alloc] init];
	selectViewController.hidesBottomBarWhenPushed = YES;
	selectViewController.delegate = self;
	[self.navigationController pushViewController:selectViewController animated:YES];
	[selectViewController release];
}

- (void)actionForSelectFace {
    if ([sendMsgTextField isFirstResponder]) {
        [sendMsgTextField resignFirstResponder];
        if ((int)faceBgView.frame.origin.y < iPhone5?416+88:416) {
            [self pushUpTextField];
        }
        [self pushUpTextField];
    } else {
        if ((int)faceBgView.frame.origin.y == iPhone5?416+88:416) {
            [self pushUpTextField];
        } else {
            [sendMsgTextField becomeFirstResponder];
        }
    }
}

- (void)pushDownTextField {
    hiddenDismissInputButton.hidden = YES;
	
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:0.3];
    
	sendMsgBgView.frame = CGRectMake(0, iPhone5?371+88:371, 320, 45);
    faceBgView.frame = CGRectMake(0, iPhone5?416+88:416, 320, 216);
    commentTable.height = sendMsgBgView.top;
    
	[UIView commitAnimations];
}

- (void)pushUpTextField {
    [UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:0.3];
	
	sendMsgBgView.frame = CGRectMake(0, iPhone5?155+88:155, 320, 45);
    faceBgView.frame = CGRectMake(0, iPhone5?200+88:200, 320, 216);
    commentTable.height = sendMsgBgView.top;
    
	[UIView commitAnimations];
	
	hiddenDismissInputButton.frame = contentView.frame;
	hiddenDismissInputButton.hidden = NO;
}

- (void)deleteCommentDidSuccess:(MMCommentInfo*)commentInfo {
    
    MMCommentInfo* recentComment = [commentArray lastObject];
    //UI界面上删除
	for (NSUInteger i = 0; i < self.commentArray.count; i++) {
		MMCommentInfo* tmpCommentInfo = [commentArray objectAtIndex:i];
		if ([tmpCommentInfo.commentId isEqualToString:commentInfo.commentId]) {
            if ( (i == self.commentArray.count-1) && (commentArray.count>1)) {
                recentComment = [commentArray objectAtIndex:i-1];
            }
			[self.commentArray removeObjectAtIndex:i];
			NSIndexPath* indexPath = [NSIndexPath indexPathForRow:(i + self.uploadCommentArray.count) 
														inSection:0];
			[commentTable deleteRowsAtIndexPaths:[NSArray arrayWithObjects:indexPath, nil] 
								withRowAnimation:UITableViewRowAnimationFade];
            
            // comment count
            //评论数以及赞
            if (commentArray.count || currentMessageInfo.likeList) {
                commentCountLabel.hidden = NO;
                if (currentMessageInfo.likeList) {
                    commentCountLabel.text = [NSString stringWithFormat:@"评论:%d %@", commentArray.count, currentMessageInfo.likeList];
                } else {
                    commentCountLabel.text = [NSString stringWithFormat:@"评论:%d", commentArray.count];
                }
            }else{
                commentCountLabel.hidden = YES;
                CGRect newFrame          = contentView.frame;
                newFrame.size.height     -= commentCountLabel.frame.size.height;
                contentView.frame = newFrame;
            }
            
			break;
		}
	}
	
    //数据库删除
	[[MMUIMessage instance] deleteComment:commentInfo];
    
    //动态界面刷新
    [messageDataSource setMessageRecentComment:recentComment];
}

//删除动态
- (void)deleteCommentInBackground: (id)object {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    MMCommentCell* commentCell = (MMCommentCell*)object;
	if (!commentCell) {
		[pool drain];
		return;
	}
	
	NSString* result;
    NSString* errorString = nil;
	if (![[MMMessageSyncer shareInstance] deleteComment:commentCell.currentCommentInfo.commentId withErrorString:&errorString]) {
        [progressHubDelete hide:YES];
		result = @"评论删除失败";
        dispatch_async(dispatch_get_main_queue(), ^{
            progressHub.labelText = result;
            progressHub.detailsLabelText = errorString ? errorString : @"";
            [progressHub show:YES];
            [progressHub hide:YES afterDelay:1.5f];
        });
	} else {
        [progressHubDelete hide:YES];
		result = @"评论删除成功";
        dispatch_async(dispatch_get_main_queue(), ^{
            progressHub.labelText = result;
            progressHub.detailsLabelText = @"";
            [progressHub show:YES];
            [progressHub hide:YES afterDelay:1.5f];
            [self deleteCommentDidSuccess:commentCell.currentCommentInfo];
            [[MTStatusBarOverlay sharedInstance] postImmediateFinishMessage:result 
                                                                   duration:STATUSBAR_OVERLAY_HIDE_DELAY_TIME 
                                                                   animated:YES];
        });
	}
    
    //删除线程对象
    MMThread* currentThread = [MMThread currentThread];
	dispatch_async(dispatch_get_main_queue(), ^{
		[currentThread wait];
        int index = [backgroundThreads indexOfObject:currentThread];
        if (index != NSNotFound) {
            [currentThread wait];
            [backgroundThreads removeObjectAtIndex:index];
        }
	});
	
	[pool drain];
}

- (void)currentMessageChanged {
	MMMessageInfo* newMessageInfo = [messageDataSource getMessageInfo:currentMessageInfo.statusId];
	if (!newMessageInfo || newMessageInfo.modifiedDate == currentMessageInfo.modifiedDate) {
		return;
	}
	
	self.currentMessageInfo = newMessageInfo;
	// comment count
	if (currentMessageInfo.likeList) {
		commentCountLabel.text = [NSString stringWithFormat:@"评论:%d %@", currentMessageInfo.commentCount, currentMessageInfo.likeList];
	} else {
		commentCountLabel.text = [NSString stringWithFormat:@"评论:%d", currentMessageInfo.commentCount];
	}
}

#pragma mark Comment Data
- (void)initData {
    NSArray* tmpArray = [[MMComment instance] getCommentListByStatusId:currentMessageInfo.statusId
                                                               ownerId:[[MMLoginService shareInstance] getLoginUserId]];
    [self.commentArray setArray:tmpArray];
}

- (void)downAllCommentThread {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
    //下载全部评论
    NSString* errorString = nil;
	NSArray* serverComments = [[MMMessageSyncer shareInstance] downComment:currentMessageInfo.statusId 
																  pageSize:10000 
																   preTime:0 
																  nextTime:0
                                                           withErrorString:&errorString];

    if (serverComments.count > 0) {
        for (MMCommentInfo* commentInfo in serverComments) {
            [[MMComment instance] saveComment:commentInfo];
        }
        [self.commentArray setArray:serverComments];
    } else {
        if (errorString) {
			MLOG(@"Down all comment failed, error:%@", errorString);
		}
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        isLoading = NO;
        [footerRefreshSpinner stopAnimating];
        
        if (serverComments.count > 0) {
            [commentTable reloadData];
        }
    });
	
	[pool release];
}

- (void)downRecentCommentThread {
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
    //下载全部评论
	uint64_t recentTime = 0;
	if (commentArray.count > 0) {
		MMCommentInfo* commentInfo = [commentArray lastObject];
		recentTime = commentInfo.createDate;
	}
	
    NSString* errorString = nil;
	NSArray* serverComments = [[MMMessageSyncer shareInstance] downComment:currentMessageInfo.statusId 
																  pageSize:10000 
																   preTime:recentTime 
																  nextTime:0
                                                           withErrorString:&errorString];
    
    if (serverComments.count > 0) {
        for (MMCommentInfo* commentInfo in serverComments) {
            [[MMComment instance] saveComment:commentInfo];
        }
    } else {
        if (errorString) {
			MLOG(@"Down recent comment failed, error:%@", errorString);
		}
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        isLoading = NO;
        [footerRefreshSpinner stopAnimating];
        
        if (serverComments.count > 0) {
            [commentArray addObjectsFromArray:serverComments];
            [commentTable reloadData];
            
            // comment count
            if (currentMessageInfo.likeList) {
                commentCountLabel.text = [NSString stringWithFormat:@"评论:%d %@", commentArray.count,
                                          currentMessageInfo.likeList];
            } else {
                commentCountLabel.text = [NSString stringWithFormat:@"评论:%d", commentArray.count];
            }
        }
    });
	
	[pool release];
}

- (void)startDownloadComment {
    CHECK_NETWORK;
    
    if (isLoading) {
        return;
    }
    
    isLoading = YES;
    [footerRefreshSpinner startAnimating];
    
    if (commentArray.count > 0) {
        [self performSelectorUsingMMThread:@selector(downRecentCommentThread) object:nil];
    } else {
        [self performSelectorUsingMMThread:@selector(downAllCommentThread) object:nil];
    }
}

//upload
- (void)addUploadComment:(MMCommentInfo*)commentInfo {
    [uploadCommentArray insertObject:commentInfo atIndex:0];
}

- (void)updateCommentStatus:(UploadStatus)uploadStatus draftId:(NSUInteger)draftId {
    for (MMCommentInfo* commentInfo in uploadCommentArray) {
		if (commentInfo.draftId == draftId) {
			commentInfo.uploadStatus = uploadStatus;
			return;
		}
	}
}

- (NSIndexPath*)getUploadCommentIndexPath:(NSUInteger)draftId {
    for (NSUInteger i = 0; i < uploadCommentArray.count; ++i) {
		MMCommentInfo* commentInfo = [uploadCommentArray objectAtIndex:i];
		if (commentInfo.draftId == draftId) {
			NSIndexPath* indexPath = [NSIndexPath indexPathForRow:(i + commentArray.count) inSection:0];
			return indexPath;
		}
	}
	return nil;
}
- (NSIndexPath*)deleteUploadComment:(NSUInteger)draftId {
    for (NSUInteger i = 0; i < uploadCommentArray.count; ++i) {
		MMCommentInfo* commentInfo = [uploadCommentArray objectAtIndex:i];
		if (commentInfo.draftId == draftId) {
			NSIndexPath* indexPath = [NSIndexPath indexPathForRow:(i + commentArray.count) inSection:0];
			[uploadCommentArray removeObjectAtIndex:i];
			return indexPath;
		}
	}
	return nil;
}

- (void)uploadCommentWillStart:(NSNotification*)notification {
    MMDraftInfo* draftInfo = [notification object];
    if (draftInfo.draftType != draftComment || ![draftInfo.replyStatusId isEqualToString:currentMessageInfo.statusId]) {
        return;
    }
    
	MMCommentInfo* newCommentInfo = [[[MMCommentInfo alloc] init] autorelease];
	newCommentInfo.ownerId = draftInfo.ownerId;
	newCommentInfo.statusId = draftInfo.replyStatusId;
	newCommentInfo.uid = [[MMLoginService shareInstance] getLoginUserId];
    newCommentInfo.realName = [[MMLoginService shareInstance] getLoginRealName];
	newCommentInfo.text = [draftInfo textWithoutUid];
	newCommentInfo.uploadStatus = draftInfo.uploadStatus;
	newCommentInfo.draftId = draftInfo.draftId;
	newCommentInfo.createDate = draftInfo.createDate;
	
	NSIndexPath* indexPath = [self getUploadCommentIndexPath:newCommentInfo.draftId];
	if (indexPath) {
		[commentTable reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
	} else {
		[self addUploadComment:newCommentInfo];
		NSIndexPath* indexPath = [self getUploadCommentIndexPath:newCommentInfo.draftId];
		[commentTable insertRowsAtIndexPaths:[NSArray arrayWithObjects:indexPath, nil] withRowAnimation:UITableViewRowAnimationNone];
	}
}

- (void)uploadCommentStatusChanged:(NSNotification*)notification {
    MMDraftInfo* draftInfo = [notification object];
    if (draftInfo.draftType != draftComment || ![draftInfo.replyStatusId isEqualToString:currentMessageInfo.statusId]) {
        return;
    }
    
	[self updateCommentStatus:draftInfo.uploadStatus draftId:draftInfo.draftId];
	NSIndexPath* indexPath = [self getUploadCommentIndexPath:draftInfo.draftId];
	if (indexPath) {
		[commentTable reloadRowsAtIndexPaths:[NSArray arrayWithObjects:indexPath, nil] withRowAnimation:UITableViewRowAnimationNone];
	}
	
	//auto refresh after success upload
	if (draftInfo.uploadStatus == uploadSuccess) {
		[messageDataSource downMessage:MMDownRecent];
		[self actionDownRecentComment];
	}
}

- (void)removeUploadingDraft:(NSNotification*)notification {
    MMDraftInfo* draftInfo = [notification object];
    if (draftInfo.draftType != draftComment || 
        ![draftInfo.replyStatusId isEqualToString:currentMessageInfo.statusId]) {
        return;
    }
    
	NSIndexPath* deletePath = [self deleteUploadComment:draftInfo.draftId];
	if (deletePath) {
		[commentTable deleteRowsAtIndexPaths:[NSArray arrayWithObject:deletePath] withRowAnimation:UITableViewRowAnimationNone];
	}
}

#pragma mark UIScrollViewDelegate
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
	if (scrollView == commentTable) {
		if (isLoading) 
			return;
        

	}
}

#pragma mark UITableViewDataSource
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return commentArray.count + uploadCommentArray.count;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	MMCommentCell* cell = (MMCommentCell*)[tableView dequeueReusableCellWithIdentifier:@"MMCommentCell"];
	if (cell == nil) {
		cell = [[[MMCommentCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"MMCommentCell"] autorelease];
		cell.delegate = self;
	}
	
	if (indexPath.row >= commentArray.count) {
		[cell setCommentInfo:[self.uploadCommentArray objectAtIndex:indexPath.row - commentArray.count]];
	} else {
		[cell setCommentInfo:[self.commentArray objectAtIndex:indexPath.row]];
	}
    
	return cell;
}

#pragma mark UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	MMCommentInfo* commentInfo = nil;
	if (indexPath.row >= self.commentArray.count) {
		commentInfo = [self.uploadCommentArray objectAtIndex:indexPath.row - self.commentArray.count];
	} else {
		commentInfo = [self.commentArray objectAtIndex:indexPath.row];
	}
	
	return [MMCommentCell computeCellHeight:commentInfo];
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	MMCommentInfo* commentInfo = nil;
	if (indexPath.row >= commentArray.count) {
		commentInfo = [uploadCommentArray objectAtIndex:indexPath.row - commentArray.count];
	} else {
		commentInfo = [commentArray objectAtIndex:indexPath.row];
	}
	
	if (commentInfo.draftId == 0) {
		if (commentInfo.uid == [[MMLoginService shareInstance] getLoginUserId]) {
			return;
		}
        
		currentReplyComment = commentInfo;
        [sendMsgTextField clearTextAndHidePortion];
        
        MMHidePortionText* hidePortionText = [MMHidePortionText hidePortionTextWithUserName:commentInfo.realName
                                                                                        uid:commentInfo.uid];
        [sendMsgTextField appendHidePortionText:hidePortionText];
        
        if (![sendMsgTextField.textField isFirstResponder]) {
            [sendMsgTextField.textField becomeFirstResponder];
        }
        [tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
	} else {
		//uploading comment
		currentSelectedUploadComment = commentInfo;
		[currentSelectedUploadComment retain];
		switch (commentInfo.uploadStatus) {
			case uploadUploading:
			case uploadWait:
			{
				UIActionSheet* actionSheet = [[UIActionSheet alloc] initWithTitle:@"提示" delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:@"删除" otherButtonTitles:@"取消发送",nil];
				actionSheet.tag = 201;
				[actionSheet showInView:self.view];
				[actionSheet release];
			}
				break;
			case uploadFailed:
			{
				UIActionSheet* actionSheet = [[UIActionSheet alloc] initWithTitle:@"提示" delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:@"删除" otherButtonTitles:@"重新发送",nil];
				actionSheet.tag = 201;
				[actionSheet showInView:self.view];
				[actionSheet release];
			}
				break;
				
			default:
				break;
		}
	}
}

#pragma mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	switch (alertView.tag) {
		case  101:
		{
			if (buttonIndex == 1) {
				[self performSelectorUsingMMThread:@selector(deleteMessageInBackground) object:nil];
			}
		}
			break;
		case 102:
		{
			if (buttonIndex == 1) {
				//隐藏动态
				[self performSelectorUsingMMThread:@selector(hideMessageInBackground) object:nil];
			}
		}
			break;

		default:
			break;
	}
}

#pragma mark UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	switch (actionSheet.tag) {
		case 201:
		{
			if (currentSelectedUploadComment.uploadStatus == uploadSuccess) {
				[currentSelectedUploadComment release];
				currentSelectedUploadComment = nil;
				return;
			}
			
			if (buttonIndex == actionSheet.destructiveButtonIndex) {
				//stop upload and delete
				MMDraftInfo* draftInfo = [[MMDraftMgr shareInstance] getDraftInfo:currentSelectedUploadComment.draftId];
				if (draftInfo) {
					[[MMDraftMgr shareInstance] deleteDraftInfo:draftInfo];
				}
				[currentSelectedUploadComment release];
				currentSelectedUploadComment = nil;
			} else if (buttonIndex == 1) {
				if (currentSelectedUploadComment.uploadStatus == uploadFailed) {
					//resend
					MMDraftInfo* draftInfo = [[MMDraftMgr shareInstance] getDraftInfo:currentSelectedUploadComment.draftId];
					if (draftInfo) {
						[[MMDraftMgr shareInstance] resendDraft:draftInfo];
					}
				} else {
					//stop send
					MMDraftInfo* draftInfo = [[MMDraftMgr shareInstance] getDraftInfo:currentSelectedUploadComment.draftId];
					if (draftInfo) {
						[[MMDraftMgr shareInstance] stopUploadDraft:draftInfo];
					}
				}
				[currentSelectedUploadComment release];
				currentSelectedUploadComment = nil;
			}
		}
			break;
		case 202:
		{
			//时间线动态更多操作
			switch (buttonIndex) {
				case 0:
				{
                    CHECK_NETWORK;
					if (currentMessageInfo.uid == [[MMLoginService shareInstance] getLoginUserId]) {
						//自己的动态,删除
						//[self deleteMessageInBackground];
						UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"提示" 
																		message:@"是否删除分享" 
																	   delegate:self 
															  cancelButtonTitle:@"取消" 
															  otherButtonTitles:@"确定", nil];
						alert.tag = 101;
						[alert show];
						[alert release];
					} else {
						//别人的动态隐藏
						//[self hideMessageInBackground];
						UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"提示" 
																		message:@"是否隐藏分享" 
																	   delegate:self 
															  cancelButtonTitle:@"取消" 
															  otherButtonTitles:@"确定", nil];
						alert.tag = 102;
						[alert show];
						[alert release];
					}
				}
					break;
				case 1:
				{
                    CHECK_NETWORK;
					if (currentMessageInfo.storaged) {
						[self performSelectorUsingMMThread:@selector(unStoreMessageInBackground) object:nil];
					} else {
						[self performSelectorUsingMMThread:@selector(storeMessageInBackground) object:nil];
					}
				}
					break;
                case 2:
                {
                    [self actionViewHomePage:currentMessageInfo];
                }
                    break;
				default:
					break;
			}
		}
			break;
		default:
			break;
	}
}

#pragma mark -
#pragma mark MMCommentCellDelegate
- (void)actionForCellHomePage:(MMCommentCell*)commentCell {
    //todo
}

- (void)actionForCellLongPress:(MMCommentCell*)commentCell {
    
    [UIActionSheet actionSheetWithTitle:@"删除评论"
                                message:nil 
                                buttons:[NSArray arrayWithObject:@"确认删除"] 
                             showInView:[MMGlobalPara getTabBarController].tabBar
                              onDismiss:^(int buttonIndex)
     {
         CHECK_NETWORK;
         
         if (!progressHubDelete) {
             progressHubDelete = [[MBProgressHUD alloc] initWithWindow:[UIApplication sharedApplication].keyWindow];
             progressHub.opacity = 1.0;
             [[UIApplication sharedApplication].keyWindow addSubview:progressHubDelete];
             progressHubDelete.labelText = @"正在删除...";
             progressHubDelete.detailsLabelText = @"";
             [progressHubDelete show:YES];
         }
         
         [self performSelectorUsingMMThread:@selector(deleteCommentInBackground:) object:commentCell];
         
     } onCancel:nil];
}
#pragma mark -
#pragma mark MMHidePortionTextFieldDelegate
//- (void)textFieldDidBeginEditing:(UITextField *)textField {
//    [self pushUpTextField];
//}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if ([MMCommonAPI getNetworkStatus] == kNotReachable) {
		[MMCommonAPI showAlertHud:@"网络连接失败!" detailText:nil];
		return NO;
	}
	
	NSInteger wordCount = [MMCommonAPI countWord:sendMsgTextField.text];
    if (wordCount == 0) {
        return NO;
    }
    
	if (wordCount > 500) {
		[MMCommonAPI showFailAlertViewTitle:@"提示" andMessage:@"字数超过500"];
		return NO;
	}
    
    //提醒用户输入一些内容
    NSString* realString = [[sendMsgTextField textWithHiddenPortion] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (currentReplyComment) {
        NSString* replyBaseString = [NSString stringWithFormat:@"@%@հ%dհ", currentReplyComment.realName, currentReplyComment.uid];
        if ([realString isEqualToString:replyBaseString]) {
            [progressHub show:YES];
            progressHub.labelText = @"请输入回复内容";
            progressHub.detailsLabelText = @"";
            [progressHub hide:YES afterDelay:PROGRESS_HUB_PRESENT_TIME];
            return NO;
        }
    }
    
	NSString* commentId = nil;
	if (currentReplyComment && currentReplyComment.uid != [[MMLoginService shareInstance] getLoginUserId]) {
		commentId = currentReplyComment.commentId;
	}
	
	MMDraftInfo* draftInfo = [[[MMDraftInfo alloc] init] autorelease];
	draftInfo.ownerId = [[MMLoginService shareInstance] getLoginUserId];
	draftInfo.text = [sendMsgTextField textWithHiddenPortion];
	draftInfo.draftType = draftComment;
	draftInfo.replyStatusId = currentMessageInfo.statusId;
	draftInfo.replyCommentId = commentId;
	
	[[MMDraftMgr shareInstance] insertAndUploadNewDraft:draftInfo];
	
	sendMsgTextField.text = @"";
	return NO;
}

#pragma mark -
#pragma mark MMSelectFriendViewDelegate
- (void)didSelectFriend:(NSArray*)selectedFriends {
	for (MMMomoUserInfo* friendInfo in selectedFriends) {
        MMHidePortionText* hidePortionText = [MMHidePortionText hidePortionTextWithUserName:friendInfo.realName
                                                                                        uid:friendInfo.uid];
        [sendMsgTextField appendHidePortionText:hidePortionText];
	}
}

#pragma mark MMFaceDelegate
-(void)selectFace:(NSString*)strFace {
    [sendMsgTextField appendText:strFace];
	[sendMsgTextField becomeFirstResponder];
}

#pragma mark -
#pragma mark Responding to keyboard events

- (void)keyboardWillShow:(NSNotification *)notification {
    
    /*
     Reduce the size of the text view so that it's not obscured by the keyboard.
     Animate the resize so that it's in sync with the appearance of the keyboard.
     */
    
    NSDictionary *userInfo = [notification userInfo];
    
    // Get the origin of the keyboard when it's displayed.
    NSValue* aValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    
    // Get the top of the keyboard as the y coordinate of its origin in self's view's coordinate system. The bottom of the text view's frame should align with the top of the keyboard's final position.
    CGRect keyboardRect = [aValue CGRectValue];
    keyboardRect = [self.view convertRect:keyboardRect fromView:nil];
    
    CGRect sendMsgViewNewFrame = sendMsgBgView.frame;
    sendMsgViewNewFrame.origin.y = keyboardRect.origin.y - sendMsgViewNewFrame.size.height;
    
    CGRect faceViewNewFrame = faceBgView.frame;
    faceViewNewFrame.origin.y = keyboardRect.origin.y;
    
    // Get the duration of the animation.
    NSValue *animationDurationValue = [userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSTimeInterval animationDuration;
    [animationDurationValue getValue:&animationDuration];
    
    // Animate the resize of the text view's frame in sync with the keyboard's appearance.
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:animationDuration];
    
    sendMsgBgView.frame = sendMsgViewNewFrame;
    faceBgView.frame = faceViewNewFrame;
    commentTable.height = sendMsgBgView.top;
    
    [UIView commitAnimations];
    
    hiddenDismissInputButton.frame = contentView.frame;
	hiddenDismissInputButton.hidden = NO;
}

@end
