//
//  MMNewMessageViewController.m
//  momo
//
//  Created by wangsc on 11-1-10.
//  Copyright 2011 ND. All rights reserved.
//

#import "MMNewMessageViewController.h"
#import "MMThemeMgr.h"
#import "MMGlobalPara.h"
#import "MMGlobalData.h"
#import "MMMessageSyncer.h"
#import <QuartzCore/QuartzCore.h>
#import "MMCommonAPI.h"
#import "MMSelectFriendViewController.h"
#import "MMUploadQueue.h"
#import "MMDraft.h"
#import "MMGlobalStyle.h"
#import "MMUIDefines.h"
#import "MMDraftMgr.h"
#import "MMGlobalCategory.h"
#import "MMRetweetViewController.h"
#import "MMEditDraftViewController.h"
#import "RegexKitLite.h"
#import "MMPreference.h"
#import "MMFaceView.h"
#import "MMLoginService.h"
#import "MMUapRequest.h"
#import "AlbumPicker/MMAlbumPickerController.h"
#import "MMSelectImageCollection.h"
#import "FTUtils.h"

@interface MMNewMessageViewController ()

@property (nonatomic, retain) MMHidePortionTextView* messageTextView;

@end

@implementation MMNewMessageViewController
@synthesize selectedImages, messageDelegate, messageGroupArray, initialAtFriends;
@synthesize addressInfo = addressInfo_;
@synthesize groupInfo = groupInfo_;
@synthesize messageTextView;

- (id)init {
	if (self = [super init]) {
		selectedImages = [[NSMutableArray alloc] init];
        backgroundThreads = [[NSMutableArray alloc] init];
        self.addressInfo = [[[MMAddressInfo alloc] init] autorelease];
		isSelectImageFromCamera = NO;
		syncToWeibo = NO;
        
        wordCountLimit = 0;
	}
	return self;
}

- (id)initWithAtFriends:(NSArray*)friendArray {
    self = [self init];
    if (self) {
        self.initialAtFriends = friendArray;
    }
    return self;
}

- (void)dealloc {
	NSString* selectImageDirectory = [NSHomeDirectory() stringByAppendingString:@"/tmp/tmp_selected_images/"];
	if ([[NSFileManager defaultManager] fileExistsAtPath:selectImageDirectory]) {
		[[NSFileManager defaultManager] removeItemAtPath:selectImageDirectory error:nil];
	}
    
	self.selectedImages    = nil;
	self.messageGroupArray = nil;
    self.initialAtFriends  = nil;
    self.addressInfo       = nil;
    self.groupInfo = nil;
    
    //background threads
	for (MMHttpRequestThread* thread in backgroundThreads) {
		[thread cancel];
		[thread wait];
	}
	[backgroundThreads release];
    backgroundThreads = nil;
    self.messageTextView = nil;
    [super dealloc];
}

- (void)loadView {
	[super loadView];
	UIImage* image = nil;

    self.view.backgroundColor = [UIColor whiteColor];
    
	cursorPosition = NSMakeRange(0, 0);
    
    titleButton_ = [UIButton buttonWithType:UIButtonTypeCustom];
	image = [MMThemeMgr imageNamed:@"momo_dynamic_topbar_button.png"];
	[titleButton_ setBackgroundImage:image forState:UIControlStateNormal];
	[titleButton_ setBackgroundImage:[MMThemeMgr imageNamed:@"momo_dynamic_topbar_button_press.png"] forState:UIControlStateHighlighted];
	titleButton_.frame = CGRectMake(0, 0, 120, 29);
	titleButton_.titleLabel.font = [UIFont systemFontOfSize:14];
    
    if (groupInfo_) {
        [titleButton_ setTitle:groupInfo_.groupName forState:UIControlStateNormal];
    } else {
        [titleButton_ setTitle:@"MO分享" forState:UIControlStateNormal];
    }
	
	titleButton_.titleLabel.lineBreakMode   = UILineBreakModeTailTruncation;
	titleButton_.frame = [MMCommonAPI properRectForButton:titleButton_ maxSize:CGSizeMake(160, 29)];
	[titleButton_ addTarget:self action:@selector(actionForSelectGroup) forControlEvents:UIControlEventTouchUpInside];
	self.navigationItem.titleView = titleButton_;
	
	buttonLeft_ = [[[UIButton alloc] initWithFrame:CGRectMake(0, 0, 34, 30)] autorelease];
	image = [MMThemeMgr imageNamed:@"topbar_back.png"];
	[buttonLeft_ setImage:image forState:UIControlStateNormal];
	[buttonLeft_ setImage:image forState:UIControlStateHighlighted];
	[buttonLeft_ setBackgroundImage:[MMThemeMgr imageNamed:@"common_topbar_ic_press.png"] forState:UIControlStateHighlighted];
	[buttonLeft_ addTarget:self action:@selector(actionLeft:) forControlEvents:UIControlEventTouchUpInside];
	self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:buttonLeft_] autorelease];
	
	buttonRight_ = [[[UIButton alloc] initWithFrame:CGRectMake(0, 0, 46, 34)] autorelease];
	image = [MMThemeMgr imageNamed:@"user_feedback_topbar_send.png"];
	[buttonRight_ setImage:image forState:UIControlStateNormal];
	[buttonRight_ setImage:image forState:UIControlStateHighlighted];
	[buttonRight_ setBackgroundImage:[MMThemeMgr imageNamed:@"common_topbar_ic_press.png"] forState:UIControlStateHighlighted];
	[buttonRight_ addTarget:self action:@selector(actionRight:) forControlEvents:UIControlEventTouchUpInside];
	buttonRight_.enabled = NO;
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:buttonRight_] autorelease];
	
    if (!messageTextView) {
        //防止内存不足时页面释放导致文本框内容丢失
        self.messageTextView = [[[MMHidePortionTextView alloc] initWithFrame:CGRectMake(0, 0, 320, 156)] autorelease];
        messageTextView.backgroundColor = [UIColor clearColor];
        messageTextView.textView.font = [UIFont systemFontOfSize:15];
        [messageTextView becomeFirstResponder];
        messageTextView.hidePotionTextViewDelegate = self;
        messageTextView.textView.returnKeyType = UIReturnKeySend;
        messageTextView.textView.enablesReturnKeyAutomatically = YES;
        messageTextView.textView.autocorrectionType = UITextAutocorrectionTypeNo;
        messageTextView.placeholder = @"点击下方@图标，选择最想通知的好友，把你的分享立即推送到他的手机上吧！";
    }
	[self.view addSubview:messageTextView];
	
	//tool bar
	toolBar = [[[MMToolbar alloc] initWithFrame:CGRectMake(0, iPhone5?156+88:156, 320, 44)] autorelease];
	toolBar.barStyle = UIBarStyleBlackTranslucent;
	toolBar.opaque = NO;
	
	UIButton* atButton = [UIButton buttonWithType:UIButtonTypeCustom];
	image = [MMThemeMgr imageNamed:@"publish_dynamic_bottombar_at.png"];
	[atButton setImage:image forState:UIControlStateNormal];
	[atButton setImage:[MMThemeMgr imageNamed:@"publish_dynamic_bottombar_at_press.png"] forState:UIControlStateHighlighted];
	atButton.frame = CGRectMake(0, 0, image.size.width, image.size.height);
	[atButton addTarget:self action:@selector(actionForSelectFriendName) forControlEvents:UIControlEventTouchUpInside];
	atItem = [[[UIBarButtonItem alloc] initWithCustomView:atButton] autorelease];
    
    UIButton* faceButton = [UIButton buttonWithType:UIButtonTypeCustom];
    image = [MMThemeMgr imageNamed:@"chat_ic_face.png"];
    [faceButton setImage:image forState:UIControlStateNormal];
	faceButton.frame = CGRectMake(0, 0, image.size.width, image.size.height);
	[faceButton addTarget:self action:@selector(actionForSelectFace) forControlEvents:UIControlEventTouchUpInside];
	faceItem = [[[UIBarButtonItem alloc] initWithCustomView:faceButton] autorelease];
	
	UIButton* cameraButton = [UIButton buttonWithType:UIButtonTypeCustom];
	image = [MMThemeMgr imageNamed:@"publish_dynamic_bottombar_camera.png"];
	[cameraButton setImage:image forState:UIControlStateNormal];
	[cameraButton setImage:[MMThemeMgr imageNamed:@"publish_dynamic_bottombar_camera_press.png"] forState:UIControlStateHighlighted];
	cameraButton.frame = CGRectMake(0, 0, image.size.width, image.size.height);
	[cameraButton addTarget:self action:@selector(actionPhoto) forControlEvents:UIControlEventTouchUpInside];
	cameraItem = [[[UIBarButtonItem alloc] initWithCustomView:cameraButton] autorelease];
	
	UIButton* photoLibraryButton = [UIButton buttonWithType:UIButtonTypeCustom];
	image = [MMThemeMgr imageNamed:@"publish_dynamic_bottombar_laptop.png"];
	[photoLibraryButton setImage:image forState:UIControlStateNormal];
	[photoLibraryButton setImage:[MMThemeMgr imageNamed:@"publish_dynamic_bottombar_laptop_press.png"] forState:UIControlStateHighlighted];
	photoLibraryButton.frame = CGRectMake(0, 0, image.size.width, image.size.height);
	[photoLibraryButton addTarget:self action:@selector(actionForSelectAddress) forControlEvents:UIControlEventTouchUpInside];
	photoLibraryItem = [[[UIBarButtonItem alloc] initWithCustomView:photoLibraryButton] autorelease];
	
	weiboButton = [UIButton buttonWithType:UIButtonTypeCustom];
	image = [MMThemeMgr imageNamed:@"ic_sina_normal.png"];
	[weiboButton setImage:image forState:UIControlStateNormal];
	[weiboButton setImage:[MMThemeMgr imageNamed:@"ic_sina_press.png"] forState:UIControlStateHighlighted];
	weiboButton.frame = CGRectMake(0, 0, image.size.width, image.size.height);
	[weiboButton addTarget:self action:@selector(actionForSendToWeibo) forControlEvents:UIControlEventTouchUpInside];
	weiboItem = [[[UIBarButtonItem alloc] initWithCustomView:weiboButton] autorelease];
	
	wordCountLabel = [[[UILabel alloc] initWithFrame:CGRectMake(0, 0, 40, 20)] autorelease];
	wordCountLabel.text = [NSString stringWithFormat:@"%d", wordCountLimit ? wordCountLimit : 140];
	wordCountLabel.backgroundColor = [UIColor clearColor];
	wordCountLabel.textAlignment = UITextAlignmentCenter;
	wordCountItem = [[[UIBarButtonItem alloc] initWithCustomView:wordCountLabel] autorelease];
	
	flexItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
																			  target:nil
																			  action:nil] autorelease];
	[toolBar setItems:[NSArray arrayWithObjects:atItem, flexItem, faceItem, flexItem, cameraItem, flexItem, photoLibraryItem, 
												flexItem, weiboItem, nil]];
	[self.view addSubview:toolBar];
	
	selectedImagesButton  = [UIButton buttonWithType:UIButtonTypeCustom];
	[selectedImagesButton setBackgroundImage:[MMThemeMgr imageNamed:@"publish_dynamic_picture_number.png"] forState:UIControlStateNormal];
	selectedImagesButton.frame = CGRectMake(10, 120, 51, image.size.height);
	[selectedImagesButton addTarget:self action:@selector(actionForSelectFromPhotoLibrary) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview:selectedImagesButton];
	selectedImagesButton.hidden = YES;
    selectedImagesButton.top = toolBar.top - selectedImagesButton.height - 15;
	
	selectedImagesCountLabel = [[UILabel alloc] initWithFrame:CGRectMake(25, 2, 20, 22)];
	selectedImagesCountLabel.text = @"0";
	selectedImagesCountLabel.textColor = [UIColor redColor];
	selectedImagesCountLabel.textAlignment = UITextAlignmentCenter;
	selectedImagesCountLabel.backgroundColor = [UIColor clearColor];
	[selectedImagesButton addSubview:selectedImagesCountLabel];
	
	
    //地址显示区域
    addressBtn = [[[UIButton alloc] initWithFrame:CGRectMake(10, iPhone5?120+88:120, 249, 17)] autorelease];
    addressBtn.top = toolBar.top - selectedImagesButton.height - 10;;
    UIImageView* addressImageView = [[[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 19, 17)] autorelease];
    addressImageView.image = [MMThemeMgr imageNamed:@"share_map.png"];
    [addressBtn addSubview:addressImageView];
    addressBtn.userInteractionEnabled = YES;
    addressBtn.hidden = YES;
    addressBtn.tag = 32;
    addressName = [[[UILabel alloc] initWithFrame:CGRectMake(24, 1, 249, 15)] autorelease];
    addressName.font = [UIFont systemFontOfSize:14];
    addressName.textColor= RGBCOLOR(0, 112, 191);
    addressName.backgroundColor = [UIColor clearColor];
    [addressBtn addSubview:addressName];
    [addressBtn addTarget:self action:@selector(actionForSelectAddress) forControlEvents:UIControlEventTouchUpInside];
    [self.view  addSubview:addressBtn];
    
    syncToWeibo = [MMPreference shareInstance].syncToWeibo;
    if (syncToWeibo) {
        [weiboButton setImage:[MMThemeMgr imageNamed:@"ic_sina_have.png"] forState:UIControlStateNormal];
    }
    
    faceBgView = [[UIView alloc] initWithFrame:CGRectMake(0, iPhone5?204+88:204, 320, 216)];
    faceBgView.backgroundColor = RGBCOLOR(175, 221, 234);
    [self.view addSubview:faceBgView];
    
    faceView = [[[MMFaceView alloc] init] autorelease];
    [faceView initPara];
	faceView.frame = CGRectMake(0, 0, 320, 216);
	faceView.delegate_ = self;
	[faceBgView addSubview:faceView];	
    
    
    //插入初始的@好友
    if (self.initialAtFriends.count > 0) {
        for (MMMomoUserInfo* friendInfo in initialAtFriends) {
            MMHidePortionText* portionText = [MMHidePortionText hidePortionTextWithUserName:friendInfo.realName uid:friendInfo.uid];
            if (portionText) {
                [messageTextView appendHidePortionText:portionText];
            }
        }
        [self verifyUploadButton];
    }
    
    progressHub = [[[MBProgressHUD alloc] initWithView:self.view] autorelease];
    progressHub.yOffset -= 100;
	[self.view addSubview:progressHub];
	[self.view bringSubviewToFront:progressHub];
	progressHub.labelText = @"加载中...";
}

- (void)viewWillAppear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    
	progressHub = nil;
	selectedImagesCountLabel = nil;
	selectedImagesButton = nil;
	wordCountLabel = nil;
	
    //tool bar buttons
	toolBar = nil;
	weiboButton = nil;
}

- (void)actionPhoto {
	UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil 
															 delegate:self 
													cancelButtonTitle:@"取消" 
											   destructiveButtonTitle:nil
													otherButtonTitles:@"拍照获取", @"从相册中选取",nil];
	actionSheet.tag = 102;
	[actionSheet showInView:self.view];
	[actionSheet release];
}

- (void)actionForSelectAddress{
    MMSelectAddressViewController *viewController = [[[MMSelectAddressViewController alloc] init] autorelease];
    viewController.selectAddressdelegate    = self;
    viewController.hidesBottomBarWhenPushed = YES;
    [[self navigationController] pushViewController:viewController animated:YES];
}

#pragma mark -
#pragma mark MMSecectAddressViewDelegate
- (void) didFinishSelectAddress:(MMAddressInfo*) addressInfo{
    self.addressInfo = addressInfo;
    addressBtn.hidden= NO;
    addressName.text = addressInfo.addressName;

	[self updateImageAndAddressButton];
	[self verifyUploadButton];
}

- (void)didCancelSelectAddress{
}

#pragma mark -

- (void)actionForSelectFromCamera {
#if !TARGET_IPHONE_SIMULATOR
	isSelectImageFromCamera = YES;
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        UIImagePickerController* picker = [[UIImagePickerController alloc] init];
        picker.delegate = self;
        picker.sourceType = UIImagePickerControllerSourceTypeCamera;
        [self presentModalViewController:picker animated:YES];
        [picker release];
    }
#endif
}

- (void)actionForSelectFromPhotoLibrary {
	isSelectImageFromCamera = NO;
    
    [[MMSelectImageCollection shareInstance] removeAll];
    [MMSelectImageCollection shareInstance].originSelectAsset = selectedImages;
    
    for (MMSelectImageInfo* indexObj in selectedImages) {
        [[MMSelectImageCollection shareInstance] addSelectImageInfo:indexObj];
    }
    
    MMAlbumPickerController* viewController = [[[MMAlbumPickerController alloc] init] autorelease];
    UINavigationController *navigationController = [[[UINavigationController alloc]
                                                     initWithRootViewController:viewController] autorelease];
    viewController.albumdelegate = self;
    [self presentModalViewController:navigationController animated:YES];
}

- (void)actionForSelectFriendName {
	[messageTextView backupSelectedRange];
    
    MMSelectFriendViewController* viewController = [[[MMSelectFriendViewController alloc] init] autorelease];
    viewController.delegate = self;
    viewController.selectedMultiFriend = YES;
    UINavigationController *navigationController = [[[MMNavigationController alloc]
                                                     initWithRootViewController:viewController] autorelease];
    [self presentModalViewController:navigationController animated:YES];
}
//该函数在主线程调用
- (void)hideHubAfterSomeTime {
	[progressHub performSelector:@selector(hide:) withObject:[NSNumber numberWithBool:YES] afterDelay:PROGRESS_HUB_PRESENT_TIME];
}

- (void)checkBindToWeiboInBackground {
}

- (void)actionForSendToWeibo {
    BOOL bindToWeibo = [[MMLoginService shareInstance] bindToWeibo];
    if (!bindToWeibo) {
        progressHub.labelText = @"获取微薄绑定信息..";
        progressHub.detailsLabelText = @"";
        [progressHub show:YES];
        
        MMHttpRequestThread* thread = [[MMHttpRequestThread alloc] initWithTarget:self 
																		 selector:@selector(checkBindToWeiboInBackground) 
																		   object:nil];
		[backgroundThreads addObject:thread];
		[thread start];
		[thread release];
        return;
    }
    
	if (syncToWeibo) {
		syncToWeibo = NO;
		[weiboButton setImage:[MMThemeMgr imageNamed:@"ic_sina_normal.png"] forState:UIControlStateNormal];
        [MMPreference shareInstance].syncToWeibo = NO;
	} else {
		syncToWeibo = YES;
		[weiboButton setImage:[MMThemeMgr imageNamed:@"ic_sina_have.png"] forState:UIControlStateNormal];
		[MMPreference shareInstance].syncToWeibo = YES;
	}
}

- (void)actionForSelectFace {
    if ([messageTextView isFirstResponder]) {
        [messageTextView resignFirstResponder];
    } else {
        [messageTextView becomeFirstResponder];
    }
}

- (BOOL)checkNeedSave {
	if (messageTextView.text.length > 0 || selectedImages.count > 0) {
		return YES;
	}
	return NO;
}

- (void)actionLeft:(id)sender {
	if (isSending) {
		return;
	}
	
//	[[self navigationController] popViewControllerAnimated:YES];
	if ([self checkNeedSave]) {
		UIActionSheet* actionSheet = [[UIActionSheet alloc] initWithTitle:@"是否保存到草稿箱？" 
																 delegate:self 
														cancelButtonTitle:@"取消" 
												   destructiveButtonTitle:nil 
														otherButtonTitles:@"保存", @"不保存", nil];
		actionSheet.tag = 201;
		[actionSheet showInView:self.view];
		[actionSheet release];
	} else {
		[[self navigationController] popViewControllerAnimated:YES];
	}
}

- (NSArray*)saveImagesToLocalPath:(NSArray*)imageArray {
	if (!imageArray || imageArray.count == 0) {
		return nil;
	}
	
	NSString* strImageDirectory = [[MMGlobalPara documentDirectory] stringByAppendingString:@"draft_images/"];
	if (![[NSFileManager defaultManager] fileExistsAtPath:strImageDirectory]) {
		[[NSFileManager defaultManager] createDirectoryAtPath:strImageDirectory withIntermediateDirectories:YES attributes:nil error:nil];
	}
	
	//using date as image file name
	NSDate *date = [NSDate date];
	NSTimeInterval currentTime = [date timeIntervalSince1970] * 1000.0;
	
	NSMutableArray* imagePathArray = [NSMutableArray array];
	for (UIImage* image in imageArray) {
		currentTime += 1;
		NSString* imagePath = [NSString stringWithFormat:@"%@/%llu.jpg", strImageDirectory, (unsigned long long)currentTime];
		NSData* imageData = UIImageJPEGRepresentation(image, 1.0);
		[imageData writeToFile:imagePath atomically:YES];
		
		[imagePathArray addObject:imagePath];
	}
	return imagePathArray;
}

- (NSArray*)applyImageSelection {
	if (!selectedImages || selectedImages.count == 0) {
		return nil;
	}
	
	NSMutableArray* imagePathArray = [NSMutableArray array];
	NSString* strImageDirectory = [[MMGlobalPara documentDirectory] stringByAppendingString:@"draft_images/"];
	if (![[NSFileManager defaultManager] fileExistsAtPath:strImageDirectory]) {
		[[NSFileManager defaultManager] createDirectoryAtPath:strImageDirectory withIntermediateDirectories:YES attributes:nil error:nil];
	}
	
	for (MMSelectImageInfo* imageInfo in selectedImages) {
		NSString* draftImagePath = [strImageDirectory stringByAppendingFormat:@"%@.jpg", [MMCommonAPI createGUIDStr]];
		if (imageInfo.tmpSelectImagePath) {
			[[NSFileManager defaultManager] copyItemAtPath:imageInfo.tmpSelectImagePath toPath:draftImagePath error:nil];
			[imagePathArray addObject:draftImagePath];
			
			if (imageInfo.draftImagePath) {
				[[NSFileManager defaultManager] removeItemAtPath:imageInfo.draftImagePath error:nil];
			}
		} else if (imageInfo.draftImagePath) {
			[imagePathArray addObject:imageInfo.draftImagePath];
		}
	}
	
	return imagePathArray;
}

- (MMDraftInfo*)createDraftInfo {
	NSString* content = [messageTextView textWithHiddenPortion];
	if ((content == nil || content.length == 0) ) {
        if(selectedImages.count > 0){
            content = @"分享照片";
        }else if(!addressBtn.hidden){
            content = @"分享位置";
        }
	}
	
	//new message
	MMDraftInfo* draftInfo = [[[MMDraftInfo alloc] init] autorelease];
	draftInfo.ownerId = [[MMLoginService shareInstance] getLoginUserId];
	draftInfo.text = content;
	draftInfo.draftType = draftMessage;
    
    //地理位置
    if (!(addressBtn.hidden)) {
        [draftInfo.extendInfo setObject:[NSNumber numberWithFloat:self.addressInfo.corrdinate.longitude] forKey: @"longitude"];
        [draftInfo.extendInfo setObject:[NSNumber numberWithFloat:self.addressInfo.corrdinate.latitude] forKey: @"latitude"];
        [draftInfo.extendInfo setObject:self.addressInfo.addressName forKey: @"address"];
        [draftInfo.extendInfo setObject:[NSNumber numberWithInt:self.addressInfo.isCorrect?1:0] forKey: @"isCorrect"];
    }

	draftInfo.attachImagePaths = [self applyImageSelection];
	draftInfo.syncToWeibo = syncToWeibo;
    
    if (groupInfo_) {
        draftInfo.groupId = groupInfo_.groupId;
        draftInfo.groupName = groupInfo_.groupName;
    }

	return draftInfo;
}

- (void)actionRight:(id)sender {
	if (isSending) {
		return;
	}
	
	CHECK_NETWORK;
    
	isSending = YES;
	MMDraftInfo* draftInfo = [self createDraftInfo];
	[[MMDraftMgr shareInstance] insertAndUploadNewDraft:draftInfo];
	[MMAlbumPickerController removeAllImage];
    
	[[self navigationController] popViewControllerAnimated:YES];
}

- (void)verifyUploadButton {
	NSInteger wordCount = [MMCommonAPI countWord:[messageTextView text]];
    
    if (wordCountLimit > 0) {
        NSInteger wordCountLeft = wordCountLimit - wordCount;
        wordCountLabel.text = [NSString stringWithFormat:@"%d", wordCountLeft];
        if (wordCountLeft < 0) {
            wordCountLabel.textColor = [UIColor redColor];
            buttonRight_.enabled = NO;
            return;
        } else {
            wordCountLabel.textColor = [UIColor blackColor];
        }
    }
	
	if ( (wordCount > 0) || (selectedImages.count != 0) || (!addressBtn.hidden) ) {
		buttonRight_.enabled = YES;
		return;
	}
	
	buttonRight_.enabled = NO;
}

- (void)updateImageAndAddressButton {
	if (!selectedImagesButton.hidden) {
		if (selectedImages.count == 0) {
			selectedImagesButton.hidden = YES;
		}
	} else {
		if (selectedImages.count > 0) {
			selectedImagesButton.hidden = NO;
		}
	}
	selectedImagesCountLabel.text = [NSString stringWithFormat:@"%d", selectedImages.count];
    
    if (!addressBtn.hidden) {
        if (selectedImagesButton.hidden) {
            addressBtn.left = 10;
        }else{
            addressBtn.left = 10 + 51 + 10;
        }
    }
}

- (void)actionForSelectGroup {
    if (selectGroupView_) {
        [UIView animateWithDuration:0.3f animations:^{
            selectGroupView_.centerY += selectGroupView_.height;
        }completion:^(BOOL finished) {
            [selectGroupView_ removeFromSuperview];
            selectGroupView_ = nil;
        }];
        
        [messageTextView becomeFirstResponder];
    } else {
        [self.view endEditing:YES];
        
        selectGroupView_ = [[[MMSelectGroupView alloc] initWithFrame:self.view.bounds] autorelease];
        selectGroupView_.delegate = self;
        [self.view addSubview:selectGroupView_];
        
        float centerY = selectGroupView_.centerY;
        selectGroupView_.centerY += selectGroupView_.height;
        [UIView beginAnimations:@"animation" context:NULL];
        [UIView setAnimationDuration:0.3f];
        selectGroupView_.centerY = centerY;
        [UIView commitAnimations];
    }
}

#pragma mark MMNewMessageDelegate
- (void)attachImagesChanged:(NSMutableArray*)changedImageArray {
	self.selectedImages = changedImageArray;

	[self updateImageAndAddressButton];
	[self verifyUploadButton];
}

- (void)didSelectFriend:(NSArray*)selectedFriends {
    [self dismissModalViewControllerAnimated:YES];
    
	if (!selectedFriends || selectedFriends.count <= 0) {
		return;
	}
	
    [messageTextView restoreSelectedRange];
	for (MMMomoUserInfo* friendInfo in selectedFriends) {	
        MMHidePortionText* hidePortionText = [MMHidePortionText hidePortionTextWithUserName:friendInfo.realName
                                                                                        uid:friendInfo.uid];
        [messageTextView insertHidePortionText:hidePortionText];
	}

	[self verifyUploadButton];
}

#pragma mark MMHidePortionTextViewDelegate
- (void)textViewDidChange:(UITextView *)textView {
	[self verifyUploadButton];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
	if ([text isEqualToString:@"\n"]) {
		if (buttonRight_.enabled == YES) {
			[self actionRight:nil];
		}
		return NO;
	}
	return YES;
}

#pragma mark MMAlbumPickerControllerDelegate
- (void)didFinishPickingAlbum: (NSMutableArray*) selectAsset{
    self.selectedImages = [NSMutableArray arrayWithArray:selectAsset];
    
    [self dismissModalViewControllerAnimated:YES]; 
    [self updateImageAndAddressButton];
    [self verifyUploadButton];
    if (selectedImagesButton.hidden) {
        addressBtn.left = 10;
    }else{
        addressBtn.left = 10 + 51 + 10;
    }
} 

- (void)didCancelPickingAlbum{
    [self dismissModalViewControllerAnimated:YES]; 
}

#pragma mark UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [self dismissModalViewControllerAnimated:YES];
    
	UIImage* image = [info objectForKey:UIImagePickerControllerOriginalImage];
	if (!image) {
		return;
	}
	
	//if from camera, save image to photo library
	if (isSelectImageFromCamera) {
		UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
	}
	
	image = [MMCommonAPI scaleAndRotateImage:image scaleSize:CONSTRAINT_UPLOAD_IMAGE_SIZE];
	
	NSString* strImageDirectory = [NSHomeDirectory() stringByAppendingString:@"/tmp/tmp_selected_images/"];
	if (![[NSFileManager defaultManager] fileExistsAtPath:strImageDirectory]) {
		[[NSFileManager defaultManager] createDirectoryAtPath:strImageDirectory withIntermediateDirectories:YES attributes:nil error:nil];
	}
	
	NSString* imagePath = [strImageDirectory stringByAppendingFormat:@"%@.jpg", [MMCommonAPI createGUIDStr]];
	NSData* imageData = UIImageJPEGRepresentation(image, CONSTRAINT_UPLOAD_IMAGE_QUALITY);
	if (![imageData writeToFile:imagePath atomically:YES]) {
		return;
	}
	
	MMSelectImageInfo* selectImageInfo = [[[MMSelectImageInfo alloc] init] autorelease];
	selectImageInfo.tmpSelectImagePath = imagePath;
    selectImageInfo.url = imagePath;
	selectImageInfo.thumbImage = [MMCommonAPI imageWithImage:image scaledToSize:CGSizeMake(SELECT_THUMB_IMAGE_SIZE, SELECT_THUMB_IMAGE_SIZE)];
	selectImageInfo.imageSize = imageData.length;
	[selectedImages addObject:selectImageInfo];
	
	[self updateImageAndAddressButton];
	[self verifyUploadButton];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController*)picker
{
	[self dismissModalViewControllerAnimated:YES];
}

#pragma mark UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (actionSheet.tag) {
        case 201:
        {
            switch (buttonIndex) {
                case 0:
                {
                    //save and return
                    MMDraftInfo* draftInfo = [self createDraftInfo];
                    [[MMDraftMgr shareInstance] insertDraftInfo:draftInfo];
                    [self.navigationController popViewControllerAnimated:YES];
                    [MMAlbumPickerController removeAllImage];
                }
                    break;
                case 1:
                {
                    [self.navigationController popViewControllerAnimated:YES];
                    [MMAlbumPickerController removeAllImage];
                }
                    break;
                default:
                    break;
            }
        }
            break;
        case 102:
        {
			switch (buttonIndex) {
				case 0:
				{
                    [self actionForSelectFromCamera];					
				}
					break;
				case 1:
				{
                    [self actionForSelectFromPhotoLibrary];
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

#pragma mark MMFaceDelegate
-(void)selectFace:(NSString*)strFace {
    [messageTextView appendText:strFace];
	[messageTextView becomeFirstResponder];
    
    [self verifyUploadButton];
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
    
    CGRect toolBarFrame = toolBar.frame;
    toolBarFrame.origin.y = keyboardRect.origin.y - toolBarFrame.size.height;
    
    CGRect faceViewNewFrame = faceBgView.frame;
    faceViewNewFrame.origin.y = keyboardRect.origin.y;
    
    // Get the duration of the animation.
    NSValue *animationDurationValue = [userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSTimeInterval animationDuration;
    [animationDurationValue getValue:&animationDuration];
    
    // Animate the resize of the text view's frame in sync with the keyboard's appearance.
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:animationDuration];
    
    toolBar.frame = toolBarFrame;
    faceBgView.frame = faceViewNewFrame;
    selectedImagesButton.top = toolBar.top - selectedImagesButton.height - 15;
    addressBtn.top = toolBar.top - selectedImagesButton.height - 10;;
    
    [UIView commitAnimations];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    
    NSDictionary* userInfo = [notification userInfo];
    
    /*
     Restore the size of the text view (fill self's view).
     Animate the resize so that it's in sync with the disappearance of the keyboard.
     */
    NSValue *animationDurationValue = [userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSTimeInterval animationDuration;
    [animationDurationValue getValue:&animationDuration];
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:animationDuration];
    
    toolBar.frame = CGRectMake(0, iPhone5?156+88:156, 320, 44);
    faceBgView.top = toolBar.bottom;
    selectedImagesButton.top = toolBar.top - selectedImagesButton.height - 15;
    addressBtn.top = toolBar.top - selectedImagesButton.height - 10;;
    
    [UIView commitAnimations];
}

#pragma mark MMMyMomoDelegate
- (void)bingWeiboIsSuccess:(BOOL)isSuccess withErrorString:(NSString *)errorString {

}

- (void)bindingWeibo:(NSDictionary *)weiboDic {
	
}

- (void)weiboDidBinding:(NSDictionary *)weiboDic {
	[self bindingWeibo:weiboDic];
}

#pragma mark MMSelectGroupViewDelegate 
- (void)selectGroupView:(MMSelectGroupView *)selectGroupView didSelectGroup:(MMGroupInfo *)groupInfo {
    [UIView animateWithDuration:0.3f animations:^{
        selectGroupView_.centerY += selectGroupView_.height;
    }completion:^(BOOL finished) {
        [selectGroupView removeFromSuperview];
        selectGroupView_ = nil;
    }];
    
    [messageTextView becomeFirstResponder];
    
    self.groupInfo = groupInfo;
    
    //修改标题
	if (!groupInfo) {
		[titleButton_ setTitle:@"MO分享" forState:UIControlStateNormal];
    } else {
        [titleButton_ setTitle:groupInfo.groupName forState:UIControlStateNormal];
    }
    titleButton_.frame = [MMCommonAPI properRectForButton:titleButton_ maxSize:CGSizeMake(160, 29)];
}

@end
