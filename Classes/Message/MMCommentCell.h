//
//  MMCommentCell.h
//  momo
//
//  Created by wangsc on 11-1-28.
//  Copyright 2011 ND. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DbStruct.h"
#import "MMWebImageButton.h"
#import "MMAvatarImageButton.h"
#import "BCTextView.h"

@protocol MMCommentCellDelegate;
@interface MMCommentCell : UITableViewCell {
	MMAvatarImageButton *imageAvatarView;
	UILabel *nameLabel;
	UIImageView *fromPhoneView;
	UILabel *timeLabel;
	BCTextView *contentLabel;
	
	// upload status
	UILabel	*uploadStatusLabel;
	
	MMCommentInfo* currentCommentInfo;
	id<MMCommentCellDelegate> delegate;
}
@property (nonatomic, retain) MMCommentInfo* currentCommentInfo;
@property (nonatomic, assign) id<MMCommentCellDelegate> delegate;

- (void)setCommentInfo:(MMCommentInfo*)commentInfo;

+ (NSInteger)computeCellHeight:(MMCommentInfo*)commentInfo;

- (void)actionHomePage;

@end

@protocol MMCommentCellDelegate<NSObject>

- (void)actionForCellHomePage:(MMCommentCell*)commentCell;
- (void)actionForCellLongPress:(MMCommentCell*)commentCell;
@end

