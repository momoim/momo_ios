//
//  MMDraftViewController.h
//  momo
//
//  Created by wangsc on 11-3-1.
//  Copyright 2011 ND. All rights reserved.
//

#import <UIKit/UIKit.h>
//#import "MMCommonBack.h"
#import "MMDraftMgr.h"
#import "DbStruct.h"


@interface MMDraftViewController : UIViewController 
		<UITableViewDelegate, UIActionSheetDelegate, MMDraftBoxDelegate, UIActionSheetDelegate>{
	UITableView* draftTable;
	UIButton* buttonLeft_;
	UIButton* buttonRight_;
			
	MMDraftInfo* currentSelectedDraft;

}

@property (nonatomic, retain) MMDraftInfo* currentSelectedDraft;

- (void)updateTitle;

@end
