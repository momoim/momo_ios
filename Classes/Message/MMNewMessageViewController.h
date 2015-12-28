//
//  MMNewMessageViewController.h
//  momo
//
//  Created by wangsc on 11-1-10.
//  Copyright 2011 ND. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "MMMessageDelegate.h"
#import "MMHidePortionTextView.h"
#import "MMFaceView.h"
#import "MBProgressHUD.h"
#import "MMAlbumPickerController.h"
#import "MMSelectAddressViewController.h"
#import "MMSelectGroupView.h"

@interface MMNewMessageViewController : UIViewController <UITextViewDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, MMNewMessageDelegate, UIActionSheetDelegate, MMSelectFriendViewDelegate, MMHidePortionTextViewDelegate, MMFaceDelegate, MMMyMomoDelegate,MMAlbumPickerControllerDelegate, MMSelectAddressViewDelegate, MMSelectGroupViewDelegate> {
                
	NSMutableArray* selectedImages;
	BOOL		isSending;
	BOOL		isSelectImageFromCamera;
	BOOL		syncToWeibo;		//是否发送到新浪微薄
	
	UIButton *buttonLeft_;   //取消按钮
	UIButton *buttonRight_;     //保存按钮
	
	MMHidePortionTextView*		messageTextView;
	NSRange			cursorPosition;
	
	UILabel*		selectedImagesCountLabel;
	UIButton*		selectedImagesButton;
	UILabel*		wordCountLabel;
    
    //group
    MMGroupInfo*    groupInfo_;
    UIButton*       titleButton_;
    MMSelectGroupView* selectGroupView_;
                
    //地址区域
    UIButton* addressBtn;
    UILabel* addressName;
    MMAddressInfo* addressInfo_;
	
		//tool bar buttons
	UIToolbar* toolBar;
	UIBarButtonItem* atItem;
	UIBarButtonItem* cameraItem;
	UIBarButtonItem* photoLibraryItem;
	UIBarButtonItem* wordCountItem;
	UIBarButtonItem *flexItem;
    UIBarButtonItem* faceItem;
	UIBarButtonItem* weiboItem;
	UIButton*		 weiboButton;
    
    UIView*          faceBgView;
    MMFaceView*      faceView;
	
    NSInteger        wordCountLimit;    //为0即不限制
	id<MMMessageDelegate> messageDelegate;
                
    NSArray*        initialAtFriends;
                
    NSMutableArray*		backgroundThreads;
    MBProgressHUD*      progressHub;
}
@property (nonatomic, retain) NSMutableArray* selectedImages; 
@property (nonatomic, retain) NSArray*	      messageGroupArray; 
@property (nonatomic, assign) id<MMMessageDelegate> messageDelegate;
@property (nonatomic, retain) NSArray*        initialAtFriends;
@property (nonatomic, retain) MMAddressInfo*  addressInfo;
@property (nonatomic, retain) MMGroupInfo* groupInfo;

- (id)initWithAtFriends:(NSArray*)friendArray;

- (void)actionForSelectFromCamera;
- (void)actionForSelectFromPhotoLibrary;
- (void)actionForSelectFriendName;
- (void)actionForSendToWeibo;
- (void)actionForSelectFace;

- (void)actionLeft:(id)sender;
- (void)actionRight:(id)sender;

- (void)updateImageAndAddressButton;
- (void)verifyUploadButton;

- (BOOL)checkNeedSave;

- (MMDraftInfo*)createDraftInfo;

- (NSArray*)applyImageSelection;
- (NSArray*)saveImagesToLocalPath:(NSArray*)imageArray;

@end
