//
//  MMMessageCell.h
//  momo
//
//  Created by wangsc on 10-12-27.
//  Copyright 2010 ND. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DbStruct.h"
#import "MMWebImageButton.h"
#import "MMAvatarImageView.h"
#import "BCTextView.h"

@protocol MMMessageCellDelegate;
@interface MMMessageCell : UITableViewCell {
    UIButton* avatarBackgroundView;
	MMAvatarImageView *imageAvatarView;
	UIImageView *operationIndicatorView;	//箭头
	
	UILabel *nameLabel;
	UILabel *timeLabel;
	UIImageView* smaillPictureView_;
	BCTextView *contentLabel;
    
    //群组
    UIButton*         groupButton;
	
	//动态图片区域
    UIImageView* imageBackView;
	MMWebImageButton* imageBigView;
    
    MMWebImageButton* imageView1;
	MMWebImageButton* imageView2;
	MMWebImageButton* imageView3;
	MMWebImageButton* imageView4;
	UIButton*		  moreAttachImageView;
	UILabel*		  moreAttachImageCountLabel;
	
    //附件文件区域
    UIButton* fileDownloadBtn;
    UILabel* fileDownloadName;
    
    //地址区域
    UIButton* addressBtn;
    UILabel* addressName;

	//评论区域
    UILabel	*commentCountLabel;
    UIImageView *commentCutLine;
	UIImageView	*commentContainterView;
	BCTextView	*commentContentLabel;
	
	UIButton* praiseBtn;
	
	//发送状态区域
	UILabel	*uploadStatusLabel;
	
	MMMessageInfo*	currentMessageInfo;
	id<MMMessageCellDelegate> delegate;
	UILabel	*mfmtest_;
}
@property (nonatomic, retain) MMMessageInfo*	currentMessageInfo;
@property (nonatomic, assign) id<MMMessageCellDelegate> delegate;

- (void)setMessageInfo:(MMMessageInfo*)messageInfo;
- (void)setUploadMessageInfo:(MMMessageInfo*)messageInfo;
+ (NSInteger)computeCellHeight:(MMMessageInfo*)messageInfo;

- (void)showPraise:(BOOL)show;

- (void)actionViewAttachImage:(MMWebImageButton*)imageButton;
- (void)actionViewMoreAttachImage;

- (void)actionPraise;
- (void)actionHomePage;

@end

@protocol MMMessageCellDelegate<NSObject>
@optional
- (void)actionForCellViewAttachImage:(MMMessageInfo*)messageInfo imageIndex:(NSInteger)imageIndex;

- (void)showAddress:(MMMessageInfo*)messageInfo;

- (void)actionForCellNewComment:(MMMessageCell*)messageCell;

- (void)actionForCellPraise:(MMMessageCell*)messageCell;

- (void)actionForCellRetweet:(MMMessageCell*)messageCell;

- (void)actionForCellHomePage:(MMMessageCell*)messageCell;

- (void)actionForCellMoreOperation:(MMMessageCell*)messageCell;

- (void)actionForCellViewLongText:(MMMessageCell*)messageCell;

- (void)actionForCellLongPress:(MMMessageCell*)messageCell;

- (void)actionForMore:(MMMessageCell*)messageCell;
@end
