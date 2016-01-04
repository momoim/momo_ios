//
//  MMRetweetViewController.m
//  momo
//
//  Created by wangsc on 11-2-25.
//  Copyright 2011 ND. All rights reserved.
//

#import "MMRetweetViewController.h"
#import "MMGlobalData.h"
#import "MMDraft.h"
#import "MMUploadQueue.h"
#import "RegexKitLite.h"
#import "MMDraftMgr.h"
#import "MMCommonAPI.h"
#import "MMHidePortionTextView.h"
#import "MMLoginService.h"
#import "MMGlobalDefine.h"

@implementation MMRetweetViewController
@synthesize retweetMessage;

- (id)initWithRetweetMessage:(MMMessageInfo *)messageInfo {
	if (self = [super init]) {
		self.retweetMessage = messageInfo;
        
//        self.navigationItem.title = @"转发";
	}
	return self;
}

- (void)loadView {
	[super loadView];
	
    [toolBar setItems:[NSArray arrayWithObjects:atItem, flexItem, faceItem, flexItem, nil]];
}

- (void)actionLeft:(id)sender {
	if (isSending) {
		return;
	}
    
    if ([messageTextView.text length] > 0) {
        UIActionSheet* actionSheet = [[UIActionSheet alloc] initWithTitle:@"转发内容还未发送, 是否保存到草稿箱？" 
                                                                 delegate:self 
                                                        cancelButtonTitle:@"取消" 
                                                   destructiveButtonTitle:nil 
                                                        otherButtonTitles:@"保存", @"不保存", nil];
        actionSheet.tag = 201;
        [actionSheet showInView:self.view];
        [actionSheet release];
        
        return;
    }
	
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)actionRight:(id)sender {
	if (isSending) {
		return;
	}
	
    CHECK_NETWORK;
    
	isSending = YES;
	MMDraftInfo* draftInfo = [self createDraftInfo];
	[[MMDraftMgr shareInstance] insertAndUploadNewDraft:draftInfo];
	
	[[self navigationController] popViewControllerAnimated:YES];
}

- (MMDraftInfo*)createDraftInfo {
	NSString* content = [messageTextView textWithHiddenPortion];
	if ((content == nil || content.length == 0) && selectedImages.count > 0) {
		content = @"分享照片";
	}
	
	MMDraftInfo* draftInfo = [[[MMDraftInfo alloc] init] autorelease];
	draftInfo.ownerId = [[MMLoginService shareInstance] getLoginUserId];
	draftInfo.text = content;
	draftInfo.draftType = draftRetweet;
	draftInfo.syncToWeibo = syncToWeibo;
	
	draftInfo.retweetStatusId = retweetMessage.statusId;
    
    if (groupInfo_) {
        draftInfo.groupId = groupInfo_.groupId;
        draftInfo.groupName = groupInfo_.groupName;
    }
	
	return draftInfo;
}

#pragma mark UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (actionSheet.tag == 201) {
		switch (buttonIndex) {
			case 0:
			{
				//save and return
				MMDraftInfo* draftInfo = [self createDraftInfo];
				[[MMDraftMgr shareInstance] insertDraftInfo:draftInfo];
				[self.navigationController popViewControllerAnimated:YES];
			}
				break;
			case 1:
			{
				[self.navigationController popViewControllerAnimated:YES];
			}
				break;
			default:
				break;
		}
	}
}

- (void)dealloc {
	[retweetMessage release];
	[super dealloc];
}

@end
