//
//  MMMessageCell.m
//  momo
//
//  Created by wangsc on 10-12-27.
//  Copyright 2010 ND. All rights reserved.
//

#import "MMMessageCell.h"
#import <QuartzCore/QuartzCore.h>
#import "RegexKitLite.h"
#import "MMThemeMgr.h"
#import "MMUIComment.h"
#import "MMCommonAPI.h"
#import "MMGlobalData.h"
#import "MMGlobalStyle.h"
#import "MMUIDefines.h"
#import "MMUploadQueue.h"
#import "MMWebImageButton.h"
#import "MMMomoUserMgr.h"
#import "MMPreference.h"
#import "MMLoginService.h"
#import "MMFaceTextFrame.h"
#import "MMDraftMgr.h"
#import "MMMapViewController.h"
#import "MMGlobalCategory.h"
#import "MMGlobalPara.h"

//SIZE
#define MIN_HEIGHT 64
#define MOST_RIGHT 310

#define NAME_LABEL_HEIGHT 16
#define NAME_LABEL_FONT_SIZE 16

#define TIME_LABEL_FONT_SIZE 12

#define GROUP_LABEL_FONT_SIZE 13

#define CONTENT_LABEL_WIDTH 249
#define CONTENT_FONT_SIZE 14.0f

#define ATTACH_IMAGE_SIZE 249

#define COMMENT_COUNT_HEIGHT 12
#define COMMENT_COUNT_FONT_SIZE 12

//动态文本与顶部的距离
#define CONTENT_LABEL_CTL 59
// comment
#define COMMENT_NAME_FONT_SIZE 13

#define COMMENT_FONT_SIZE 12.0F
#define COMMENT_CONTENT_WIDTH 230

//bar
#define BAR_HEIGHT 60

#define ANIMATION_VIEW_TAG 201

@implementation MMMessageCell
@synthesize currentMessageInfo, delegate;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
	if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        avatarBackgroundView = [[UIButton alloc] initWithFrame:CGRectMake(10, CELL_CONTENT_OFFSET, 41, 41)];
		avatarBackgroundView.userInteractionEnabled = YES;
        UIImage* image = [MMThemeMgr imageNamed:@"momo_dynamic_head_portrait_rightcolor.png"];
        [avatarBackgroundView setBackgroundImage:image forState:UIControlStateNormal];
        [avatarBackgroundView setBackgroundImage:image forState:UIControlStateHighlighted];
        [avatarBackgroundView addTarget:self action:@selector(actionHomePage) forControlEvents:UIControlEventTouchUpInside];
		[self.contentView addSubview:avatarBackgroundView];
		[avatarBackgroundView release];
		
		imageAvatarView = [[[MMAvatarImageView alloc] initWithAvatarImageURL:nil] autorelease];
		imageAvatarView.frame = CGRectMake(0, 0, 41, 41);
		imageAvatarView.layer.masksToBounds = YES;
		imageAvatarView.layer.cornerRadius = 2.0;
		imageAvatarView.tag	= 1;
		[avatarBackgroundView addSubview:imageAvatarView];
		
		nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(61, CELL_CONTENT_OFFSET, 60, 15)];
		nameLabel.font = [UIFont boldSystemFontOfSize:NAME_LABEL_FONT_SIZE];
		nameLabel.tag = 2;
		nameLabel.backgroundColor = [UIColor clearColor];
		[self.contentView addSubview:nameLabel];
		[nameLabel release];
		
		timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(61, 31, 70, 15)];
		timeLabel.font = [UIFont systemFontOfSize:TIME_LABEL_FONT_SIZE];
		timeLabel.textColor = GRAY_LABEL_FONT_COLOR;
		timeLabel.tag = 6;
		timeLabel.backgroundColor = [UIColor clearColor];
		timeLabel.textAlignment = UITextAlignmentRight;
		[self.contentView addSubview:timeLabel];
		[timeLabel release];
		
		smaillPictureView_ = [[[UIImageView alloc] initWithFrame:CGRectMake(135, 33, 9, 11)] autorelease];
		smaillPictureView_.image = [MMThemeMgr imageNamed:@"draft_box_ic_picture.png"];
		smaillPictureView_.hidden = YES;
		[self.contentView addSubview:smaillPictureView_];

        
		praiseBtn = [UIButton buttonWithType:UIButtonTypeCustom];
		praiseBtn.frame = CGRectMake(279, 9, 31, 29);
		image = [MMThemeMgr imageNamed:@"share_praise.png"];
		[praiseBtn setImage:image forState:UIControlStateNormal];
		[praiseBtn setImage:image forState:UIControlStateHighlighted];
		[praiseBtn setImage:[MMThemeMgr imageNamed:@"share_praise_disable.png"] forState:UIControlStateDisabled];
		praiseBtn.backgroundColor = [UIColor clearColor];
		[praiseBtn addTarget:self action:@selector(actionPraise) forControlEvents:UIControlEventTouchUpInside];
		praiseBtn.tag = 27;
		[self.contentView addSubview:praiseBtn];
        
        //分享具体内容
		contentLabel = [[BCTextView alloc] initWithFrame:CGRectMake(61, 59, 249, 15)];
		contentLabel.backgroundColor = [UIColor clearColor];
		contentLabel.tag = 7;
		[self.contentView addSubview:contentLabel];
		[contentLabel release];
        
        //群组
        groupButton = [UIButton buttonWithType:UIButtonTypeCustom];
        groupButton.frame = CGRectMake(0, 0, 20, 20);
        groupButton.titleLabel.font = [UIFont systemFontOfSize:13];
        [groupButton setTitleColor:RGBCOLOR(51, 204, 255) forState:UIControlStateNormal];
        groupButton.titleLabel.lineBreakMode = UILineBreakModeTailTruncation;
        groupButton.hidden = YES;
        [self.contentView addSubview:groupButton];
        
        [groupButton addTarget:self action:@selector(actionShowGroup) forControlEvents:UIControlEventTouchUpInside];
        
        UILabel* groupTipLabel = [[[UILabel alloc] initWithFrame:CGRectMake(0, 0, 20, 20)] autorelease];
        groupTipLabel.font = [UIFont systemFontOfSize:12];
        groupTipLabel.textAlignment = UITextAlignmentCenter;
        groupTipLabel.text = @"来自";
        groupTipLabel.backgroundColor = [UIColor clearColor];
        [groupTipLabel sizeToFit];
        groupTipLabel.height = 20;
        groupTipLabel.left -= groupTipLabel.width + 5;
        [groupButton addSubview:groupTipLabel];
		
        //动态图片区域
        imageBackView = [[UIImageView alloc] initWithFrame:CGRectMake(59, 10, 252, 173)];
        imageBackView.image = [MMThemeMgr imageNamed:@"share_photo_single.png"];
        imageBackView.userInteractionEnabled = YES;
        [self.contentView addSubview:imageBackView];
		imageBigView = [[MMWebImageButton alloc] initWithDefaultPlaceholderImage];
		imageBigView.frame = CGRectMake(6, 6, 239, 160);
        imageBigView.backgroundColor = RGBCOLOR(198, 198, 198);
		imageBigView.layer.masksToBounds = YES;
		imageBigView.tag = 40;
		[imageBackView addSubview:imageBigView];
		[imageBigView release];
        [imageBackView release];
        
        imageView1 = [[MMWebImageButton alloc] initWithDefaultPlaceholderImage];
		imageView1.frame = CGRectMake(59, 10, 56, 56);
		imageView1.layer.masksToBounds = YES;
		imageView1.layer.cornerRadius = 5.0;
		imageView1.tag = 19;
		[self.contentView addSubview:imageView1];
		[imageView1 release];
		
		imageView2 = [[MMWebImageButton alloc] initWithDefaultPlaceholderImage];
		imageView2.frame = CGRectMake(120, 10, 56, 56);
		imageView2.layer.masksToBounds = YES;
		imageView2.layer.cornerRadius = 5.0;
		imageView2.tag = 20;
		[self.contentView addSubview:imageView2];
		[imageView2 release];
		
		imageView3 = [[MMWebImageButton alloc] initWithDefaultPlaceholderImage];
		imageView3.frame = CGRectMake(181, 10, 56, 56);
		imageView3.layer.masksToBounds = YES;
		imageView3.layer.cornerRadius = 5.0;
		imageView3.tag = 21;
		[self.contentView addSubview:imageView3];
		[imageView3 release];
		
		imageView4 = [[MMWebImageButton alloc] initWithDefaultPlaceholderImage];
		imageView4.frame = CGRectMake(242, 10, 56, 56);
		imageView4.layer.masksToBounds = YES;
		imageView4.layer.cornerRadius = 5.0;
        imageView4.tag = 42;
		[self.contentView addSubview:imageView4];
		[imageView4 release];
		
		moreAttachImageView = [UIButton buttonWithType:UIButtonTypeCustom];
		moreAttachImageView.frame = CGRectMake(254, 10, 50, 56);
		[moreAttachImageView setImage:[MMThemeMgr imageNamed:@"momo_dynamic_picture_more.png"] forState:UIControlStateNormal];
		[moreAttachImageView addTarget:self action:@selector(actionViewMoreAttachImage) forControlEvents:UIControlEventTouchUpInside];
		moreAttachImageView.tag = 22;
		[self.contentView addSubview:moreAttachImageView];
		
		moreAttachImageCountLabel = [[UILabel alloc] initWithFrame:CGRectMake(2, 0, 32, 56)];
		moreAttachImageCountLabel.font = [UIFont boldSystemFontOfSize:12];
		moreAttachImageCountLabel.tag = 23;
		moreAttachImageCountLabel.backgroundColor = [UIColor clearColor];
		moreAttachImageCountLabel.textAlignment = UITextAlignmentCenter;
		[moreAttachImageView addSubview:moreAttachImageCountLabel];
		[moreAttachImageCountLabel release];
        
        //附件文件下载区域
        fileDownloadBtn = [[UIButton alloc] initWithFrame:CGRectMake(61, 10, 249, 17)];
        UIImageView* downImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 19, 17)];
        downImageView.image = [MMThemeMgr imageNamed:@"share_download.png"];
        [fileDownloadBtn addSubview:downImageView];
        [downImageView release];
        fileDownloadBtn.userInteractionEnabled = YES;
		fileDownloadBtn.tag = 31;
        fileDownloadName = [[UILabel alloc] initWithFrame:CGRectMake(24, 1, 249, 15)];
        fileDownloadName.font = [UIFont systemFontOfSize:CONTENT_FONT_SIZE];
        fileDownloadName.textColor= RGBCOLOR(0, 112, 191);
        fileDownloadName.backgroundColor = [UIColor clearColor];
        [fileDownloadBtn addSubview:fileDownloadName];
        [fileDownloadName release];
		[fileDownloadBtn addTarget:self action:@selector(actionDownloadFile) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:fileDownloadBtn];
		[fileDownloadBtn release];
        
        //地址显示区域
        addressBtn = [[[UIButton alloc] initWithFrame:CGRectMake(61, 10, 249, 17)] autorelease];
        UIImageView* addressImageView = [[[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 19, 17)] autorelease];
        addressImageView.image = [MMThemeMgr imageNamed:@"share_map.png"];
        [addressBtn addSubview:addressImageView];
        addressBtn.userInteractionEnabled = YES;
		addressBtn.tag = 32;
        addressName = [[[UILabel alloc] initWithFrame:CGRectMake(24, 1, 249, 15)] autorelease];
        addressName.font = [UIFont systemFontOfSize:CONTENT_FONT_SIZE];
        addressName.textColor= RGBCOLOR(0, 112, 191);
        addressName.backgroundColor = [UIColor clearColor];
        [addressBtn addSubview:addressName];
		[addressBtn addTarget:self action:@selector(actionShowAddress) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:addressBtn];
        
		//评论区域
		commentContainterView = [[UIImageView alloc] initWithFrame:CGRectMake(61, 5, 249, 5)];
		commentContainterView.image = [MMThemeMgr imageNamed:@"momo_dynamic_dialog_box.png"];
        commentContainterView.userInteractionEnabled = YES;
		commentContainterView.tag = 11;
		[self.contentView addSubview:commentContainterView];
		[commentContainterView release];
        
        //评论数与赞数
        commentCountLabel = [[UILabel alloc] initWithFrame:CGRectMake(5, 12, 249, COMMENT_COUNT_HEIGHT)];
		commentCountLabel.font = [UIFont systemFontOfSize:COMMENT_COUNT_FONT_SIZE];
		commentCountLabel.textColor = GRAY_LABEL_FONT_COLOR;
		commentCountLabel.backgroundColor = [UIColor clearColor];
		commentCountLabel.textAlignment = UITextAlignmentLeft;
		commentCountLabel.tag = 8;
		commentCountLabel.text = @"评论:";
		[commentContainterView addSubview:commentCountLabel];
		[commentCountLabel release];
        
        //评论数分割线
        commentCutLine = [[UIImageView alloc] initWithFrame:CGRectMake(5, 31, 239, 2)];
        commentCutLine.image = [MMThemeMgr imageNamed:@"share_cutline.png"];
        [commentContainterView addSubview:commentCutLine];
		[commentCutLine release];
        
        //最新评论内容
        commentContentLabel = [[BCTextView alloc] initWithFrame:CGRectMake(5, 38, 239, 15)];
		commentContentLabel.backgroundColor = [UIColor clearColor];
		commentContentLabel.tag = 15;
		[commentContainterView addSubview:commentContentLabel];
		[commentContentLabel release];
		
        //发送状态标签
		uploadStatusLabel = [[UILabel alloc] initWithFrame:CGRectMake(61, 31, 100, 15)];
		uploadStatusLabel.font = [UIFont systemFontOfSize:TIME_LABEL_FONT_SIZE];
		uploadStatusLabel.textColor = BROWN_LABEL_TEXT_COLOR;
		uploadStatusLabel.tag = 17;
		uploadStatusLabel.backgroundColor = [UIColor clearColor];
		[self.contentView addSubview:uploadStatusLabel];
		[uploadStatusLabel release];

		self.clipsToBounds = YES;
        
        UILongPressGestureRecognizer* longPressGesture = [[[UILongPressGestureRecognizer alloc] initWithTarget:self 
                                                                                                        action:@selector(handleLongPress:)] autorelease];
        [self addGestureRecognizer:longPressGesture];
	}
	return self;
}

- (void)retrieveSubViews {
	imageAvatarView = (MMAvatarImageView*)[self.contentView viewWithTag:1];
	nameLabel = (UILabel*)[self.contentView viewWithTag:2];
	timeLabel = (UILabel*)[self.contentView viewWithTag:6];
	contentLabel = (BCTextView*)[self.contentView viewWithTag:7];
	commentCountLabel = (UILabel*)[self.contentView viewWithTag:8];
	commentContainterView = (UIImageView*)[self.contentView viewWithTag:11];
	uploadStatusLabel = (UILabel*)[self.contentView viewWithTag:17];
	imageBigView = (MMWebImageButton*)[self.contentView viewWithTag:40];
    imageView1 = (MMWebImageButton*)[self.contentView viewWithTag:19];
	imageView2 = (MMWebImageButton*)[self.contentView viewWithTag:20];
	imageView3 = (MMWebImageButton*)[self.contentView viewWithTag:21];
    imageView4 = (MMWebImageButton*)[self.contentView viewWithTag:42];
	moreAttachImageView = (UIButton*)[self.contentView viewWithTag:22];
	moreAttachImageCountLabel = (UILabel*)[self.contentView viewWithTag:23];
	praiseBtn = (UIButton*)[self.contentView viewWithTag:27];
    fileDownloadBtn = (UIButton*)[self.contentView viewWithTag:31];
    addressBtn = (UIButton*)[self.contentView viewWithTag:32];
}

- (void)setUploadMessageInfo:(MMMessageInfo*)messageInfo {
	if (messageInfo.draftId == 0) 
		return;
    
	self.contentView.backgroundColor = [UIColor whiteColor];
	if (messageInfo.uploadStatus == uploadUploading || messageInfo.uploadStatus == uploadWait) {
		self.contentView.backgroundColor = UPLOADING_BACKGROUND_COLOR;
	} else if (messageInfo.uploadStatus == uploadFailed) {
		self.contentView.backgroundColor = UPLOAD_FAILED_BACKGROUND_COLOR;
	}
	self.selectedBackgroundView = [[[UIView alloc] initWithFrame:self.frame] autorelease];
    self.selectedBackgroundView.backgroundColor = TABLE_CELL_SELECT_COLOR;
	
	[self retrieveSubViews];
	timeLabel.hidden = YES;
	commentCountLabel.hidden = YES;
	commentContainterView.hidden = YES;
    commentContentLabel.hidden = YES;
	uploadStatusLabel.hidden = NO;
	imageBackView.hidden = YES;
    imageView1.hidden = YES;
	imageView2.hidden = YES;
	imageView3.hidden = YES;
	imageView4.hidden = YES;
	moreAttachImageView.hidden = YES;
	moreAttachImageCountLabel.hidden = YES;
    addressBtn.hidden = YES;
    fileDownloadBtn.hidden   = YES;
    groupButton.hidden = YES;
	imageAvatarView.imageURL = [[MMLoginService shareInstance] avatarImageURL];
	
	NSUInteger leftOffset = imageAvatarView.frame.origin.x + imageAvatarView.frame.size.width + 15;
	
	//name label
	NSString* strRealName = [[MMLoginService shareInstance] userName];
	nameLabel = (UILabel*)[self.contentView viewWithTag:2];
	nameLabel.text = strRealName;
	CGSize constraint = CGSizeMake(320 - leftOffset, NAME_LABEL_HEIGHT);
	CGSize expectedLabelSize = [nameLabel.text sizeWithFont:[UIFont boldSystemFontOfSize:NAME_LABEL_FONT_SIZE]
										  constrainedToSize:constraint 
											  lineBreakMode:UILineBreakModeWordWrap];
	CGRect newFrame = nameLabel.frame;
	newFrame.size.width = expectedLabelSize.width;
	nameLabel.frame = newFrame;
	
	//content
	contentLabel = (BCTextView*)[self.contentView viewWithTag:7];
    contentLabel.delegate = (id<BCTextViewDelegate>)delegate;
    
    BCTextFrame* textFrame = [[[BCTextFrame alloc] initWithHTML:messageInfo.text] autorelease];
    textFrame.fontSize = CONTENT_FONT_SIZE;
    textFrame.width = CONTENT_LABEL_WIDTH;
    contentLabel.textFrame = textFrame;
    
    newFrame = contentLabel.frame;
    newFrame.size.height = textFrame.height;
    newFrame.origin.y = CONTENT_LABEL_CTL;
    [contentLabel setFrameWithoutLayout:newFrame];
    
    //upload status label
	if (messageInfo.uploadStatus == uploadUploading || messageInfo.uploadStatus == uploadWait) {
		uploadStatusLabel.textColor = UPLOADING_TEXT_COLOR;
		if (messageInfo.draftId == [MMUploadQueue shareInstance].currentDraft.draftId) {
			if ([MMUploadQueue shareInstance].currentUploadProgress) {
				uploadStatusLabel.text = [NSString stringWithFormat:@"发送中(%@)...", [MMUploadQueue shareInstance].currentUploadProgress];
			}
		} else {
			uploadStatusLabel.text = @"发送中...";
		}
	} else if (messageInfo.uploadStatus == uploadFailed) {
        MMDraftInfo* draftInfo = [[MMDraftMgr shareInstance] getDraftInfo:messageInfo.draftId];
        if (draftInfo.uploadErrorString.length > 0) {
            uploadStatusLabel.text = [NSString stringWithFormat:@"发送失败:%@", draftInfo.uploadErrorString];
        } else {
            uploadStatusLabel.text = @"发送失败";
        }
        
		uploadStatusLabel.textColor = UPLOAD_FAILED_TEXT_COLOR;
	} else if (messageInfo.uploadStatus == uploadSuccess) {
		uploadStatusLabel.textColor = BROWN_LABEL_TEXT_COLOR;
		uploadStatusLabel.text = @"发送成功";
	}
}

- (void)setMessageInfo:(MMMessageInfo*)messageInfo {
	self.currentMessageInfo = messageInfo;
	[self retrieveSubViews];
	timeLabel.hidden         = NO;
	commentCountLabel.hidden = NO;
	commentContainterView.hidden = YES;
    commentContentLabel.hidden = YES;
	uploadStatusLabel.hidden = YES;
    fileDownloadBtn.hidden   = YES;
    addressBtn.hidden        = YES;
    imageBackView.hidden     = YES;
    imageView1.hidden        = YES;
	imageView2.hidden        = YES;
	imageView3.hidden        = YES;
	imageView4.hidden        = YES;
    moreAttachImageView.hidden = YES;
	moreAttachImageCountLabel.hidden = YES;
    groupButton.hidden = YES;
	smaillPictureView_.hidden = YES;
    
    NSUInteger topOffset     = 0;  //某个区域底部的Y坐标值
	self.contentView.backgroundColor = [UIColor whiteColor];
	self.selectedBackgroundView = [[[UIView alloc] initWithFrame:self.frame] autorelease];
    self.selectedBackgroundView.backgroundColor = RGBCOLOR(178, 230, 244);
	
    //分享者头像区域
	imageAvatarView.imageURL = [[MMMomoUserMgr shareInstance] avatarImageUrlByUserId:messageInfo.uid];
	NSUInteger leftOffset = imageAvatarView.frame.origin.x + imageAvatarView.frame.size.width + 15;
		
	//分享者姓名区域
	NSString* strRealName = [[MMMomoUserMgr shareInstance] realNameByUserId:messageInfo.uid];
	nameLabel.text = strRealName;
	CGSize constraint = CGSizeMake(320 - leftOffset, NAME_LABEL_HEIGHT);
	CGSize expectedLabelSize = [nameLabel.text sizeWithFont:[UIFont boldSystemFontOfSize:NAME_LABEL_FONT_SIZE]
										   constrainedToSize:constraint 
											lineBreakMode:UILineBreakModeWordWrap];
    CGRect newFrame = nameLabel.frame;
	newFrame.size.width = expectedLabelSize.width;
	nameLabel.frame = newFrame;
	leftOffset = newFrame.origin.x + newFrame.size.width + MARGIN;
	topOffset = newFrame.origin.y + newFrame.size.height + MARGIN;
	
    //分享时间
	NSDate* date = [NSDate dateWithTimeIntervalSince1970:messageInfo.createDate];
	timeLabel.text = [MMCommonAPI getDateString:date];	
	constraint = CGSizeMake(MOST_RIGHT - leftOffset, NAME_LABEL_HEIGHT);
	expectedLabelSize = [timeLabel.text sizeWithFont:[UIFont systemFontOfSize:TIME_LABEL_FONT_SIZE]
										  constrainedToSize:constraint 
											  lineBreakMode:UILineBreakModeWordWrap];
	newFrame = timeLabel.frame;
	newFrame.size.width = expectedLabelSize.width;
	timeLabel.frame = newFrame;
	
	newFrame = smaillPictureView_.frame;
	newFrame.origin.x = timeLabel.frame.origin.x+timeLabel.frame.size.width + 5;
	smaillPictureView_.frame = newFrame;
    
    //赞状态
    praiseBtn.enabled = !currentMessageInfo.liked;

	//1:分享内容
    //1.1分享文本内容
    contentLabel.delegate = (id<BCTextViewDelegate>)delegate;
    NSString* msgText = [NSString stringWithString:messageInfo.text];
    if (messageInfo.isLongText) {
        msgText = [msgText stringByAppendingString:@"......"];
    }
    BCTextFrame* textFrame = [[[MMFaceTextFrame alloc] initWithHTML:msgText] autorelease];
    textFrame.fontSize = CONTENT_FONT_SIZE;
    textFrame.delegate = contentLabel;
    textFrame.width = CONTENT_LABEL_WIDTH;
    contentLabel.textFrame = textFrame;
    newFrame = contentLabel.frame;
    newFrame.size.height = textFrame.height;
    newFrame.origin.y = CONTENT_LABEL_CTL;
    [contentLabel setFrameWithoutLayout:newFrame];
	topOffset = contentLabel.frame.origin.y + contentLabel.frame.size.height;
    
    if (messageInfo.groupId > 0) {
        groupButton.hidden = NO;
        [groupButton setTitle:messageInfo.groupName forState:UIControlStateNormal];
        [groupButton sizeToFit];
        groupButton.width = MIN(200, groupButton.width);
        groupButton.right = 300;
        groupButton.height = 20;
        groupButton.top = topOffset + MARGIN;
        topOffset = groupButton.bottom;
    }
	
    //1.2分享图片内容
    NSUInteger imageCount = 0;
	for (MMAccessoryInfo* accessoryInfo in currentMessageInfo.accessoryArray) {
		if (accessoryInfo.accessoryType == MMAccessoryTypeImage) {
			imageCount++;
		}
	}
    if (imageCount > 0) {
        switch ([MMPreference shareInstance].showMessagePhotoType) {
            case kMMShowBigPhoto:
            {
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
                    newFrame             = imageBigView.frame;
                    newFrame.origin.y    = 6;
                    newFrame.size.height = imgHeight;
                    imageBigView.frame     = newFrame;
                }
                
                //图片边框尺寸
                imageBackView.hidden = NO;
                newFrame             = imageBackView.frame;
                newFrame.origin.y    = topOffset + 10;
                newFrame.size.height = 6 + imageBigView.frame.size.height + 6;
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
                [imageBigView removeAllActions];
                [imageBigView setPlaceholderImageByPhotoId:accessoryInfo.accessoryId];
                NSString* ImageURL320 = [imageURL stringByReplacingOccurrencesOfString:@"_130."withString:@"_320."];
                [imageBigView resetImageURL:ImageURL320];
                [imageBigView setTargetAndActionByImageURL:self action:@selector(actionViewAttachImage:) withPhotoId:accessoryInfo.accessoryId];
                if (accessoryInfo.accessoryId > 0) {
                    [imageBigView startLoading];
                }
            }
                break;
            case kMMShowSmallPhoto:
            {
                imageView1.hidden = NO;
                newFrame = imageView1.frame;
                newFrame.origin.y = topOffset + MARGIN;
                imageView1.frame = newFrame;
                              
                MMImageAccessoryInfo* accessoryInfo = [currentMessageInfo.accessoryArray objectAtIndex:0];
                NSString* imageURL = accessoryInfo.url;
                [imageView1 removeAllActions];
                [imageView1 setPlaceholderImageByPhotoId:accessoryInfo.accessoryId];
                [imageView1 resetImageURL:imageURL];
                [imageView1 setTargetAndActionByImageURL:self action:@selector(actionViewAttachImage:) withPhotoId:accessoryInfo.accessoryId];
                if (accessoryInfo.accessoryId > 0) {
                    [imageView1 startLoading];
                }
                
                if (imageCount > 1) {
                    imageView2.hidden = NO;
                    newFrame = imageView2.frame;
                    newFrame.origin.y = topOffset + MARGIN;
                    imageView2.frame = newFrame;
                    
                    accessoryInfo = [currentMessageInfo.accessoryArray objectAtIndex:1];
                    imageURL = accessoryInfo.url;
                    [imageView2 removeAllActions];
                    [imageView2 setPlaceholderImageByPhotoId:accessoryInfo.accessoryId];
                    [imageView2 resetImageURL:imageURL];
                    [imageView2 setTargetAndActionByImageURL:self action:@selector(actionViewAttachImage:) withPhotoId:accessoryInfo.accessoryId];
                    if (accessoryInfo.accessoryId > 0) {
                        [imageView2 startLoading];
                    }
                }
                
                if (imageCount > 2) {
                    imageView3.hidden = NO;
                    newFrame = imageView3.frame;
                    newFrame.origin.y = topOffset + MARGIN;
                    imageView3.frame = newFrame;
                    
                    accessoryInfo = [currentMessageInfo.accessoryArray objectAtIndex:2];
                    imageURL = accessoryInfo.url;
                    [imageView3 removeAllActions];
                    [imageView3 setPlaceholderImageByPhotoId:accessoryInfo.accessoryId];
                    [imageView3 resetImageURL:imageURL];
                    [imageView3 setTargetAndActionByImageURL:self action:@selector(actionViewAttachImage:) withPhotoId:accessoryInfo.accessoryId];
                    if (accessoryInfo.accessoryId > 0) {
                        [imageView3 startLoading];
                    }
                }
                
                if (imageCount == 4) {
                    imageView4.hidden = NO;
                    newFrame = imageView4.frame;
                    newFrame.origin.y = topOffset + MARGIN;
                    imageView4.frame = newFrame;
                    
                    accessoryInfo = [currentMessageInfo.accessoryArray objectAtIndex:3];
                    imageURL = accessoryInfo.url;
                    [imageView4 removeAllActions];
                    [imageView4 setPlaceholderImageByPhotoId:accessoryInfo.accessoryId];
                    [imageView4 resetImageURL:imageURL];
                    [imageView4 setTargetAndActionByImageURL:self action:@selector(actionViewAttachImage:) withPhotoId:accessoryInfo.accessoryId];
                    if (accessoryInfo.accessoryId > 0) {
                        [imageView4 startLoading];
                    }
                }
                
                if (imageCount > 4) {
                    moreAttachImageView.hidden = NO;
                    newFrame = moreAttachImageView.frame;
                    newFrame.origin.y = topOffset + MARGIN;
                    moreAttachImageView.frame = newFrame;
                    
                    moreAttachImageCountLabel.hidden = NO;
                    moreAttachImageCountLabel.text = [NSString stringWithFormat:@"+%d", messageInfo.accessoryArray.count - 3];
                }
                
                topOffset = newFrame.origin.y + newFrame.size.height;
            }
                break;
            case kMMShowNoPhoto:
            {
				smaillPictureView_.hidden = NO;
            }
                break;
            default:
                break;
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
    if ( (0.0!=messageInfo.longitude) && (0.0!=messageInfo.latitude) ) {
        addressBtn.hidden = NO;
        addressName.text = messageInfo.address;
        newFrame = addressBtn.frame;
        newFrame.origin.y = topOffset + 10;
        addressBtn.frame = newFrame;
        topOffset = addressBtn.frame.origin.y + addressBtn.frame.size.height;
    }
    
	//评论数以及赞
	if ([messageInfo.likeList length]) {
        commentContainterView.hidden = NO;
		commentCountLabel.text = [NSString stringWithFormat:@"评论:%d %@", messageInfo.commentCount, messageInfo.likeList];
	} else {
		commentCountLabel.text = [NSString stringWithFormat:@"评论:%d", messageInfo.commentCount];
	}

	//评论区域
	if (messageInfo.recentCommentId && messageInfo.commentCount) {
		commentContainterView.hidden = NO;
        commentContentLabel.hidden = NO;
        NSString* commentText = [NSString stringWithFormat:@"<a href=\"momo://user=%d\">%@</a>: %@", 
                                 messageInfo.recentComment.uid,
                                 messageInfo.recentComment.realName,
                                 messageInfo.recentComment.text];
        
        //计算高度
        commentContentLabel.delegate = (id<BCTextViewDelegate>)delegate;
        textFrame = [[[MMFaceTextFrame alloc] initWithHTML:commentText] autorelease];
        textFrame.fontSize = COMMENT_FONT_SIZE;
        textFrame.delegate = commentContentLabel;
        textFrame.width = commentContentLabel.frame.size.width;
        commentContentLabel.textFrame = textFrame;
        
        newFrame = commentContentLabel.frame;
        newFrame.size.height = textFrame.height;
        [commentContentLabel setFrameWithoutLayout:newFrame];
	}
    
    if (!commentContainterView.hidden) {
        newFrame = commentContainterView.frame;
        newFrame.origin.y = topOffset + 5;
        if (messageInfo.recentCommentId && messageInfo.commentCount) {
            newFrame.size.height = 38 + commentContentLabel.frame.size.height + 7;
            [commentCutLine setHidden:NO];
        }else{
            newFrame.size.height = 24 + 7;
            [commentCutLine setHidden:YES];
        }
        commentContainterView.frame = newFrame;
    }
}

- (void)showPraise:(BOOL)show {
	praiseBtn.enabled = show;
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
	[super willMoveToSuperview:newSuperview];
	
	if (!newSuperview) {
		self.currentMessageInfo = nil;
		[imageBigView cancelImageLoad];
        [imageView1 cancelImageLoad];
		[imageView2 cancelImageLoad];
		[imageView3 cancelImageLoad];
		[imageView4 cancelImageLoad];
	}
}

+ (NSInteger)computeCellHeight:(MMMessageInfo*)messageInfo {
    NSUInteger topOffset = 0;  //某个控件底部的Y坐标值
    
    //动态内容区域
    NSString* msgText = [NSString stringWithString:messageInfo.text];
    if (messageInfo.isLongText) {
        msgText = [msgText stringByAppendingString:@"......"];
    }
    BCTextFrame* textFrame = [[[MMFaceTextFrame alloc] initWithHTML:msgText] autorelease];
    textFrame.fontSize = CONTENT_FONT_SIZE;
    textFrame.width = CONTENT_LABEL_WIDTH;
	topOffset = CONTENT_LABEL_CTL + textFrame.height;
    
    if (messageInfo.groupId > 0) {
        topOffset += 20;
    }
    
	//动态包含图片区域
	NSUInteger count = 0;
	for (MMAccessoryInfo* accessoryInfo in messageInfo.accessoryArray) {
		if (accessoryInfo.accessoryType == MMAccessoryTypeImage) {
			count++;
		}
	}
	if (count > 0 && messageInfo.draftId == 0) {
        MMImageAccessoryInfo* accessoryInfo = [messageInfo.accessoryArray objectAtIndex:0];
        NSUInteger imgHeight = 0;  
       
        switch ([MMPreference shareInstance].showMessagePhotoType){
            case kMMShowBigPhoto:
            {
                if (accessoryInfo.width > accessoryInfo.height) {
                    imgHeight = 242 * 3.0 / 4.0;
                }else{
                    imgHeight = 242 * 4.0 / 3.0;
                }
                topOffset += 6 + imgHeight + 6;
                //间距
                topOffset += 10;
            }
                break;
            case kMMShowSmallPhoto:
            {
                topOffset += MARGIN + 56;
            }
                break;
            case kMMShowNoPhoto:
            {
            }
                break;
            default:
                break;
        }
	}
    
    //分享文件下载
	BOOL hasFile = NO;
	for (MMAccessoryInfo* accessoryInfo in messageInfo.accessoryArray) {
		if (accessoryInfo.accessoryType == MMAccessoryTypeFile) {
			hasFile = YES;
		}
	}
    if (hasFile) {
        topOffset += 10;
        topOffset += 17;
    }
    
    //地理位置区域
    if ( (0.0!=messageInfo.longitude) && (0.0!=messageInfo.latitude) ){
        topOffset += 10;
        topOffset += 17;
    }
    
    //评论区域
	if (messageInfo.recentCommentId) {
		if (!messageInfo.recentComment) {
			messageInfo.recentComment = [[MMUIComment instance] getComment:messageInfo.recentCommentId 
                                                                   ownerId:[[MMLoginService shareInstance] getLoginUserId]];
		}
		if (messageInfo.recentComment) {
            //间距	
            topOffset += 5;
            
            NSString* commentText = [NSString stringWithFormat:@"<a href=\"momo://user=%d\">%@</a>: %@", 
                                     messageInfo.recentComment.uid,
                                     messageInfo.recentComment.realName,
                                     messageInfo.recentComment.text];
            BCTextFrame* textFrame = [[[MMFaceTextFrame alloc] initWithHTML:commentText] autorelease];
            textFrame.fontSize = COMMENT_FONT_SIZE;
            textFrame.width = 239;
            
            topOffset += 38 + textFrame.height + 7;
		}else if ([messageInfo.likeList length]) {
            topOffset += 5;
            topOffset += 24 + 7;
        }
    }else{
        if ([messageInfo.likeList length]) {
            topOffset += 5;
            topOffset += 24 + 7;
        }
    }
	
    //底部留白区域
    topOffset += 10;
    return topOffset;
}

- (void)dealloc {
	self.currentMessageInfo = nil;
	[super dealloc];
}

- (void)actionViewAttachImage:(MMWebImageButton*)imageButton {
	if (delegate && [delegate respondsToSelector:@selector(actionForCellViewAttachImage:imageIndex:)]) {
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

        [delegate actionForCellViewAttachImage:currentMessageInfo imageIndex:startShowImageIndex];
	}
}

- (void)actionViewMoreAttachImage {
	if (delegate && [delegate respondsToSelector:@selector(actionForCellViewAttachImage:imageIndex:)]) {
		if (currentMessageInfo.accessoryArray.count > 3) {
			[delegate actionForCellViewAttachImage:currentMessageInfo imageIndex:3];
		}
	}
}

- (void)actionPraise {
    CHECK_NETWORK;
    
	if (delegate && [delegate respondsToSelector:@selector(actionForCellPraise:)]) {
		[delegate actionForCellPraise:self];
	}
}

- (void)actionDownloadFile{
    MMImageAccessoryInfo* accessoryInfo = [currentMessageInfo.accessoryArray objectAtIndex:0];
    NSString* fileURL = accessoryInfo.url;
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:fileURL]];
}

- (void)actionShowAddress{
    if (delegate && [delegate respondsToSelector:@selector(showAddress:)]) {
        [delegate showAddress:currentMessageInfo];
    }
}

- (void)actionHomePage {
	if (delegate && [delegate respondsToSelector:@selector(actionForCellHomePage:)]) {
		[delegate actionForCellHomePage:self];
	}
}
		
- (void)handleLongPress :(UILongPressGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        if (delegate && [delegate respondsToSelector:@selector(actionForCellLongPress:)]) {
            [delegate actionForCellLongPress:self];
        }
    }
}

- (void)actionShowGroup {

}

@end
