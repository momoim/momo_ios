//
//  MMDraftCell.h
//  momo
//
//  Created by wangsc on 11-3-1.
//  Copyright 2011 ND. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DbStruct.h"

@interface MMDraftCell : UITableViewCell {
	UILabel	*uploadStatusLabel;
	UIImageView *haveImageView;
	UIView	*groupBackgroundView;
	UILabel *groupLabel;
	UILabel *timeLabel;
	UILabel *contentLabel;
}

- (void)setDraftInfo:(MMDraftInfo*)draftInfo;

+ (NSInteger)computeCellHeight:(MMDraftInfo*)draftInfo;

@end
