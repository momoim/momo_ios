//
//  MMNewCommentViewController.m
//  momo
//
//  Created by wangsc on 11-1-30.
//  Copyright 2011 ND. All rights reserved.
//

#import "MMNewCommentViewController.h"
#import "MMMessageSyncer.h"
#import "MMCommonAPI.h"
#import "MMGlobalData.h"
#import "MMUploadQueue.h"
#import "MMDraft.h"
#import "MMDraftMgr.h"
#import "MMLoginService.h"
#import "MMSelectFriendViewController.h"

#import "MMGlobalDefine.h"

@implementation MMNewCommentViewController
@synthesize replyCommentInfo, replyMessageInfo, startString;

- (id)initWithMessageInfo:(MMMessageInfo*)messageInfo replyComment:(MMCommentInfo*)commentInfo {
	if (self = [super init]) {
		self.replyMessageInfo = messageInfo;
		self.replyCommentInfo = commentInfo;
		
		if (replyCommentInfo) {
			self.startString = [NSString stringWithFormat:@"@%@(%d) ", replyCommentInfo.realName, replyCommentInfo.uid];
		}
        
        wordCountLimit = 500;   //评论限制500字
	}
	return self;
}

- (void)dealloc {
	self.replyCommentInfo = nil;
	self.replyMessageInfo = nil;
	self.startString = nil;
	[super dealloc];
}

- (void)loadView {
	[super loadView];
	
	[toolBar setItems:[NSArray arrayWithObjects:atItem, flexItem, faceItem, flexItem, flexItem, flexItem, flexItem, wordCountItem, nil]];
	
	self.navigationItem.title = @"发评论";
	
//	messageTextView.text = startString;
    if (replyCommentInfo) {
        MMHidePortionText* hidePortionText = [MMHidePortionText hidePortionTextWithUserName:replyCommentInfo.realName
                                                                                        uid:replyCommentInfo.uid];
        [messageTextView appendHidePortionText:hidePortionText];
    }
}

- (BOOL)checkNeedSave {
	NSString* content = messageTextView.text;
	if (!content || content.length == 0) {
		return NO;
	}
	
	if ([startString isEqualToString:content]) {
		return NO;
	}
	return YES;
}

- (void)actionForSelectFriendName {
	[messageTextView backupSelectedRange];
	MMSelectFriendViewController* selectViewController = [[MMSelectFriendViewController alloc] 
                                                          init];
	selectViewController.hidesBottomBarWhenPushed = YES;
	selectViewController.delegate = self;
	[self.navigationController pushViewController:selectViewController animated:YES];
	[selectViewController release];
}

- (void)actionForSelectFace {
    if ([messageTextView isFirstResponder]) {
        [messageTextView resignFirstResponder];
    } else {
        [messageTextView becomeFirstResponder];
    }
}

- (void)actionLeft:(id)sender {
	if (isSending) {
		return;
	}
	
	if ([self checkNeedSave]) {
		UIActionSheet* actionSheet = [[UIActionSheet alloc] initWithTitle:@"评论还未发送，是否返回？" 
																 delegate:self 
														cancelButtonTitle:nil 
												   destructiveButtonTitle:nil 
														otherButtonTitles:@"是", @"否", nil];
		actionSheet.tag = 201;
		[actionSheet showInView:self.view];
		[actionSheet release];
	} else {
		[[self navigationController] popViewControllerAnimated:YES];
	}
}

- (void)actionRight:(id)sender {
	if (isSending) {
		return;
	}
	
    CHECK_NETWORK;
	
	isSending = YES;
	
	NSString* content = [messageTextView textWithHiddenPortion];
	NSString* commentId = nil;
	if (replyCommentInfo && replyCommentInfo.uid != [[MMLoginService shareInstance] getLoginUserId]) {
		commentId = replyCommentInfo.commentId;
	}
	
	MMDraftInfo* draftInfo = [[[MMDraftInfo alloc] init] autorelease];
	draftInfo.ownerId = [[MMLoginService shareInstance] getLoginUserId];
	draftInfo.text = content;
	draftInfo.draftType = draftComment;
	draftInfo.replyStatusId = replyMessageInfo.statusId;
	draftInfo.replyCommentId = commentId;
	
	[[MMDraftMgr shareInstance] insertAndUploadNewDraft:draftInfo];
	
	[[self navigationController] popViewControllerAnimated:YES];
}

#pragma mark UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (actionSheet.tag == 201) {
		switch (buttonIndex) {
			case 0:
			{
				//return
				[self.navigationController popViewControllerAnimated:YES];
			}
				break;
			default:
				break;
		}
	}
}

@end
