//
//  MMCommentCell.m
//  momo
//
//  Created by wangsc on 11-1-28.
//  Copyright 2011 ND. All rights reserved.
//

#import "MMCommentCell.h"
#import <QuartzCore/QuartzCore.h>
#import "RegexKitLite.h"
#import "MMCommonAPI.h"
#import "MMThemeMgr.h"
#import "MMGlobalStyle.h"
#import "MMUIDefines.h"
#import "MMMomoUserMgr.h"
#import "MMGlobalData.h"
#import "MMLoginService.h"
#import "MMFaceTextFrame.h"

#define NAME_LABEL_HEIGHT 15
#define NAME_LABEL_FONT_SIZE 16
#define CONTENT_LABEL_WIDTH 250
#define CONTENT_FONT_SIZE 14
#define MIN_HEIGHT 57
#define TIME_LABEL_FONT_SIZE 12
#define MOST_RIGHT 310

@implementation MMCommentCell
@synthesize currentCommentInfo, delegate;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
		imageAvatarView = [[MMAvatarImageButton alloc] initWithAvatarImageURL:nil];
		imageAvatarView.frame = CGRectMake(10, CELL_CONTENT_OFFSET, 41, 41);
		imageAvatarView.layer.masksToBounds = YES;
		imageAvatarView.layer.cornerRadius = 3.0;
		[imageAvatarView addTarget:self action:@selector(actionHomePage) forControlEvents:UIControlEventTouchUpInside];
		imageAvatarView.tag	= 1;
		[self.contentView addSubview:imageAvatarView];
		[imageAvatarView release];
		
		nameLabel = [[[UILabel alloc] initWithFrame:CGRectMake(61, CELL_CONTENT_OFFSET, 100, 15)] autorelease];
		nameLabel.font = [UIFont boldSystemFontOfSize:16];
		nameLabel.tag = 2;
		nameLabel.backgroundColor = [UIColor clearColor];
		[self.contentView addSubview:nameLabel];
		
		timeLabel = [[[UILabel alloc] initWithFrame:CGRectMake(230, CELL_CONTENT_OFFSET, 70, 15)] autorelease];
		timeLabel.font = [UIFont systemFontOfSize:TIME_LABEL_FONT_SIZE];
		timeLabel.textColor = GRAY_LABEL_FONT_COLOR;
		timeLabel.tag = 3;
		timeLabel.backgroundColor = [UIColor clearColor];
		timeLabel.textAlignment = UITextAlignmentRight;
		[self.contentView addSubview:timeLabel];
		
		contentLabel = [[[BCTextView alloc] initWithFrame:CGRectMake(61, 28, CONTENT_LABEL_WIDTH, 15)] autorelease];
        contentLabel.fontSize = CONTENT_FONT_SIZE;
		contentLabel.backgroundColor = [UIColor clearColor];
		contentLabel.tag = 4;
		[self.contentView addSubview:contentLabel];
		
//		fromPhoneView = [[[UIImageView alloc] initWithFrame:CGRectMake(80, CELL_CONTENT_OFFSET + 2, 8, 12)] autorelease];
//		fromPhoneView.image = [MMThemeMgr imageNamed:@"momo_dynamic_ic_phone.png"];
//		fromPhoneView.backgroundColor = [UIColor clearColor];
//		fromPhoneView.tag = 5;
//		[self.contentView addSubview:fromPhoneView];
		
		uploadStatusLabel = [[[UILabel alloc] initWithFrame:CGRectMake(220, 5, 70, 15)] autorelease];
		uploadStatusLabel.font = [UIFont systemFontOfSize:TIME_LABEL_FONT_SIZE];
		uploadStatusLabel.textColor = BLUE_LABEL_TEXT_COLOR;
		uploadStatusLabel.tag = 6;
		uploadStatusLabel.backgroundColor = [UIColor clearColor];
		uploadStatusLabel.textAlignment = UITextAlignmentRight;
		[self.contentView addSubview:uploadStatusLabel];
    }
    return self;
}

- (void)setCommentInfo:(MMCommentInfo*)commentInfo {
	self.currentCommentInfo = commentInfo;
	
	self.contentView.backgroundColor = [UIColor whiteColor];
	self.selectedBackgroundView = [[[UIView alloc] initWithFrame:self.frame] autorelease];
    self.selectedBackgroundView.backgroundColor = TABLE_CELL_SELECT_COLOR;
	
	imageAvatarView = (MMAvatarImageButton*)[self.contentView viewWithTag:1];
	imageAvatarView.imageURL = [[MMMomoUserMgr shareInstance] avatarImageUrlByUserId:commentInfo.uid];
	
		//name label
	NSString* strRealName = commentInfo.realName;
	nameLabel = (UILabel*)[self.contentView viewWithTag:2];
	nameLabel.text = strRealName;
	CGSize constraint = CGSizeMake(320 - 48, NAME_LABEL_HEIGHT);
	CGSize expectedLabelSize = [nameLabel.text sizeWithFont:[UIFont boldSystemFontOfSize:NAME_LABEL_FONT_SIZE]
										  constrainedToSize:constraint 
											  lineBreakMode:UILineBreakModeWordWrap];
	CGRect newFrame = nameLabel.frame;
	newFrame.size.width = expectedLabelSize.width;
	nameLabel.frame = newFrame;
	NSInteger leftOffset = newFrame.origin.x + newFrame.size.width + MARGIN;
	
//	fromPhoneView = (UIImageView*)[self.contentView viewWithTag:5];
//	fromPhoneView.hidden = YES;
	
	if (commentInfo.draftId > 0) {
		imageAvatarView.imageURL = [[MMLoginService shareInstance] avatarImageURL];
		
//		fromPhoneView.hidden = YES;
		uploadStatusLabel.hidden = NO;
		timeLabel.hidden = YES;
		if (commentInfo.uploadStatus == uploadUploading || commentInfo.uploadStatus == uploadWait) {
			self.contentView.backgroundColor = UPLOADING_BACKGROUND_COLOR;
			uploadStatusLabel.text = @"发送中...";
			uploadStatusLabel.textColor = UPLOADING_TEXT_COLOR;
		} else if (commentInfo.uploadStatus == uploadFailed) {
			self.contentView.backgroundColor = UPLOAD_FAILED_BACKGROUND_COLOR;
			uploadStatusLabel.text = @"发送失败";
			uploadStatusLabel.textColor = UPLOAD_FAILED_TEXT_COLOR;
		} else {
			uploadStatusLabel.textColor = BROWN_LABEL_TEXT_COLOR;
			uploadStatusLabel.text = @"发送成功";
		}
	} else {
		uploadStatusLabel.hidden = YES;
		timeLabel.hidden = NO;
		
		//create time
		timeLabel = (UILabel*)[self.contentView viewWithTag:3];
		//time label
		NSDate* date = [NSDate dateWithTimeIntervalSince1970:commentInfo.createDate / 10000];
		timeLabel.text = [MMCommonAPI getDateString:date];
		
		constraint = CGSizeMake(MOST_RIGHT - leftOffset, NAME_LABEL_HEIGHT);
		expectedLabelSize = [timeLabel.text sizeWithFont:[UIFont systemFontOfSize:TIME_LABEL_FONT_SIZE]
									   constrainedToSize:constraint 
										   lineBreakMode:UILineBreakModeWordWrap];
		newFrame = timeLabel.frame;
		newFrame.size.width = expectedLabelSize.width;
		newFrame.origin.x = MOST_RIGHT - expectedLabelSize.width;
		timeLabel.frame = newFrame;
//		NSUInteger rightOffset = newFrame.origin.x - MARGIN;
		
//		if (commentInfo.sourceName != nil && commentInfo.sourceName.length > 0) {
//			fromPhoneView.hidden = NO;
//			newFrame = fromPhoneView.frame;
//			newFrame.origin.x = rightOffset - newFrame.size.width;
//			fromPhoneView.frame = newFrame;
//		}
	}
	
	contentLabel = (BCTextView*)[self.contentView viewWithTag:4];
	contentLabel.delegate = (id<BCTextViewDelegate>)delegate;
    
    BCTextFrame* textFrame = [[[MMFaceTextFrame alloc] initWithHTML:commentInfo.text] autorelease];
    textFrame.fontSize = CONTENT_FONT_SIZE;
    textFrame.delegate = contentLabel;
    textFrame.width = CONTENT_LABEL_WIDTH;
    contentLabel.textFrame = textFrame;
    
    newFrame = contentLabel.frame;
    newFrame.size.height = textFrame.height;
    [contentLabel setFrameWithoutLayout:newFrame];
    
    UILongPressGestureRecognizer* longPressGesture = [[[UILongPressGestureRecognizer alloc] initWithTarget:self 
                                                                          action:@selector(handleLongPress:)] autorelease];
    [self addGestureRecognizer:longPressGesture];
}

+ (NSInteger)computeCellHeight:(MMCommentInfo*)commentInfo {
    BCTextFrame* textFrame = [[[MMFaceTextFrame alloc] initWithHTML:commentInfo.text] autorelease];
    textFrame.fontSize = CONTENT_FONT_SIZE;
    textFrame.width = CONTENT_LABEL_WIDTH;
	
	NSInteger height = NAME_LABEL_HEIGHT + textFrame.height + MARGIN + 2 * CELL_CONTENT_OFFSET;
	return MAX(height, MIN_HEIGHT);
}

- (void)actionHomePage {
	if (currentCommentInfo.draftId > 0) {
		return;
	}
	
	if (delegate && [delegate respondsToSelector:@selector(actionForCellHomePage:)]) {
		[delegate actionForCellHomePage:self];
	}
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)recognizer {
    if ( (currentCommentInfo.uid == [[MMLoginService shareInstance] getLoginUserId]) && (currentCommentInfo.draftId == 0) ){
            if (recognizer.state == UIGestureRecognizerStateBegan) {
                if (delegate && [delegate respondsToSelector:@selector(actionForCellLongPress:)]) {
                    [delegate actionForCellLongPress:self];
            }
        }
    }
}

- (void)dealloc {
	self.currentCommentInfo = nil;
    [super dealloc];
}


@end
