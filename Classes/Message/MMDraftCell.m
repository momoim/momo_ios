//
//  MMDraftCell.m
//  momo
//
//  Created by wangsc on 11-3-1.
//  Copyright 2011 ND. All rights reserved.
//

#import "MMDraftCell.h"
#import <QuartzCore/QuartzCore.h>
#import "RegexKitLite.h"
#import "MMThemeMgr.h"
#import "MMUIComment.h"
#import "MMCommonAPI.h"
#import "MMGlobalData.h"
#import "MMGlobalStyle.h"
#import "MMUIDefines.h"

//SIZE
#define MOST_RIGHT 310
#define UPLOAD_STATUS_LABEL_FONT 16
#define MIN_HEIGHT 58

#define NAME_LABEL_HEIGHT 25
#define NAME_LABEL_FONT_SIZE 15

#define TIME_LABEL_FONT_SIZE 11

#define GROUP_LABEL_FONT_SIZE 13

#define CONTENT_LABEL_WIDTH 255
#define CONTENT_FONT_SIZE 14.0f

@implementation MMDraftCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
	self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
	if (self) {
		uploadStatusLabel = [[[UILabel alloc] initWithFrame:CGRectMake(10, 5, 70, 20)] autorelease];
		uploadStatusLabel.font = [UIFont systemFontOfSize:UPLOAD_STATUS_LABEL_FONT];
		uploadStatusLabel.textColor = BROWN_LABEL_TEXT_COLOR;
		uploadStatusLabel.tag = 1;
		uploadStatusLabel.backgroundColor = [UIColor clearColor];
		uploadStatusLabel.textAlignment = UITextAlignmentRight;
		[self.contentView addSubview:uploadStatusLabel];
		
		groupBackgroundView = [[[UIView alloc] initWithFrame:CGRectMake(120, 5, 90, 15)] autorelease];
		groupBackgroundView.backgroundColor = GROUP_BACKGROUND_COLOR;
		groupBackgroundView.layer.masksToBounds = YES;
		groupBackgroundView.layer.cornerRadius = 3.0;
		groupBackgroundView.tag = 2;
		[self.contentView addSubview:groupBackgroundView];
		
		groupLabel = [[[UILabel alloc] initWithFrame:CGRectMake(0, 0, 10, 15)] autorelease];
		groupLabel.font = [UIFont systemFontOfSize:GROUP_LABEL_FONT_SIZE];
		groupLabel.textAlignment = UITextAlignmentCenter;
		groupLabel.backgroundColor = [UIColor clearColor];
		groupLabel.textColor = [UIColor whiteColor];
		groupLabel.tag = 3;
		[groupBackgroundView addSubview:groupLabel];
		
		haveImageView = [[[UIImageView alloc] initWithFrame:CGRectMake(210, 6, 11, 13)] autorelease];
		haveImageView.image = [MMThemeMgr imageNamed:@"draft_box_topbar_picture_more.png"];
		haveImageView.tag = 4;
		[self.contentView addSubview:haveImageView];
		
		timeLabel = [[[UILabel alloc] initWithFrame:CGRectMake(230, 5, 70, 15)] autorelease];
		timeLabel.font = [UIFont systemFontOfSize:TIME_LABEL_FONT_SIZE];
		timeLabel.textColor = BLUE_LABEL_TEXT_COLOR;
		timeLabel.tag = 5;
		timeLabel.backgroundColor = [UIColor clearColor];
		timeLabel.textAlignment = UITextAlignmentRight;
		[self.contentView addSubview:timeLabel];
		
		contentLabel = [[[UILabel alloc] initWithFrame:CGRectMake(10, 30, CONTENT_LABEL_WIDTH, 15)] autorelease];
		contentLabel.font = [UIFont systemFontOfSize:CONTENT_FONT_SIZE];
		contentLabel.backgroundColor = [UIColor clearColor];
		contentLabel.lineBreakMode = UILineBreakModeWordWrap;
		contentLabel.numberOfLines = 0;
		contentLabel.tag = 6;
		[self.contentView addSubview:contentLabel];
		

	}
	return self;
}

- (void)setDraftInfo:(MMDraftInfo *)draftInfo {
	self.selectedBackgroundView = [[[UIView alloc] initWithFrame:self.frame] autorelease];
    self.selectedBackgroundView.backgroundColor = TABLE_CELL_SELECT_COLOR;
	
//	self.contentView.backgroundColor = [UIColor clearColor];
//	if (draftInfo.uploadStatus == uploadUploading || draftInfo.uploadStatus == uploadWait) {
//		self.contentView.backgroundColor = UPLOADING_BACKGROUND_COLOR;
//	} else if (draftInfo.uploadStatus == uploadFailed) {
//		self.contentView.backgroundColor = UPLOAD_FAILED_BACKGROUND_COLOR;
//	}
	//upload status label
	if (draftInfo.uploadStatus == uploadUploading || draftInfo.uploadStatus == uploadWait) {
		uploadStatusLabel.text = @"发送中";
		uploadStatusLabel.textColor = GREEN_LABEL_TEXT_COLOR;
	} else if (draftInfo.uploadStatus == uploadFailed) {
		uploadStatusLabel.text = @"发送失败";
		uploadStatusLabel.textColor = [UIColor redColor];
	} else if (draftInfo.uploadStatus == uploadSuccess) {
		uploadStatusLabel.textColor = GREEN_LABEL_TEXT_COLOR;
		uploadStatusLabel.text = @"发送成功";
	} else {
		uploadStatusLabel.text = @"未发送";
		uploadStatusLabel.textColor = BROWN_LABEL_TEXT_COLOR;
	}
	
	CGSize constraint = CGSizeMake(310, 20);
	CGSize expectedLabelSize = [uploadStatusLabel.text sizeWithFont:[UIFont systemFontOfSize:UPLOAD_STATUS_LABEL_FONT]
												  constrainedToSize:constraint 
													  lineBreakMode:UILineBreakModeWordWrap];
	CGRect newFrame = uploadStatusLabel.frame;
	newFrame.size.width = expectedLabelSize.width;
	uploadStatusLabel.frame = newFrame;
	NSUInteger leftOffset = newFrame.size.width + newFrame.origin.x + MARGIN;
	
	timeLabel.hidden = NO;
		
	//time label
	NSDate* date = [NSDate dateWithTimeIntervalSince1970:draftInfo.createDate];
	timeLabel.text = [MMCommonAPI getDateString:date];
	
	constraint = CGSizeMake(MOST_RIGHT, NAME_LABEL_HEIGHT);
	expectedLabelSize = [timeLabel.text sizeWithFont:[UIFont systemFontOfSize:TIME_LABEL_FONT_SIZE]
								   constrainedToSize:constraint 
									   lineBreakMode:UILineBreakModeWordWrap];
	newFrame = timeLabel.frame;
	newFrame.size.width = expectedLabelSize.width;
	newFrame.origin.x = MOST_RIGHT - expectedLabelSize.width;
	timeLabel.frame = newFrame;
	NSUInteger rightOffset = newFrame.origin.x - MARGIN;
	
	//group name label
	groupBackgroundView.hidden = YES;
	groupLabel.hidden = YES;
	if (draftInfo.groupId > 0) {
		groupLabel.text = draftInfo.groupName;
		groupLabel.hidden = NO;
		groupBackgroundView.hidden = NO;
		
		constraint = CGSizeMake(rightOffset - leftOffset - 2 * MARGIN - haveImageView.frame.size.width, NAME_LABEL_HEIGHT);
		expectedLabelSize = [groupLabel.text sizeWithFont:[UIFont systemFontOfSize:GROUP_LABEL_FONT_SIZE]
										constrainedToSize:constraint 
											lineBreakMode:UILineBreakModeWordWrap];
		newFrame.origin.x = rightOffset - expectedLabelSize.width - 2 * MARGIN;
		newFrame.origin.x = MAX(leftOffset,newFrame.origin.x);
		newFrame.size.width = rightOffset - newFrame.origin.x;
		groupBackgroundView.frame = newFrame;
		rightOffset = newFrame.origin.x - MARGIN;
		
		newFrame = groupLabel.frame;
		newFrame.origin.x = MARGIN;
		newFrame.size.width = MAX(0, groupBackgroundView.frame.size.width - 2 * MARGIN);
		groupLabel.frame = newFrame;
	}	
	
	//indicate whether have image 
	haveImageView.hidden = YES;
	if (draftInfo.attachImagePaths.count > 0) {
		haveImageView.hidden = NO;
		
		newFrame = haveImageView.frame;
		newFrame.origin.x = rightOffset - newFrame.size.width;
		haveImageView.frame = newFrame;
//		rightOffset = newFrame.origin.x - MARGIN;
		if (draftInfo.attachImagePaths.count == 1) {
			haveImageView.image = [MMThemeMgr imageNamed:@"draft_box_ic_picture.png"];
		} else {
			haveImageView.image = [MMThemeMgr imageNamed:@"draft_box_topbar_picture_more.png"];
		}
	}

	//content
	contentLabel.text = [draftInfo textWithoutUid];
	constraint = CGSizeMake(CONTENT_LABEL_WIDTH, 20000.f);
	expectedLabelSize = [contentLabel.text sizeWithFont:contentLabel.font constrainedToSize:constraint lineBreakMode:UILineBreakModeWordWrap];
	newFrame = contentLabel.frame;
	newFrame.size.width = CONTENT_LABEL_WIDTH;
	newFrame.size.height = expectedLabelSize.height;
	contentLabel.frame = newFrame;
	[contentLabel sizeToFit];
}

+ (NSInteger)computeCellHeight:(MMDraftInfo *)draftInfo {
	NSString* text = [draftInfo textWithoutUid];
	CGSize constraint = CGSizeMake(CONTENT_LABEL_WIDTH, 20000.f);
	CGSize expectedLabelSize = [text sizeWithFont:[UIFont systemFontOfSize:CONTENT_FONT_SIZE]
								constrainedToSize:constraint 
									lineBreakMode:UILineBreakModeWordWrap];
	return NAME_LABEL_HEIGHT + expectedLabelSize.height + 3 * MARGIN;
}

@end
