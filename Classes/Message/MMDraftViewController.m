//
//  MMDraftViewController.m
//  momo
//
//  Created by wangsc on 11-3-1.
//  Copyright 2011 ND. All rights reserved.
//

#import "MMDraftViewController.h"
#import "MMNewMessageViewController.h"
#import "MMDraft.h"
#import "MMDraftCell.h"
#import "MMGlobalPara.h"
#import "MMMessageViewController.h"
#import "MMEditDraftViewController.h"
#import "MMGlobalData.h"
#import "MMThemeMgr.h"

@implementation MMDraftViewController
@synthesize currentSelectedDraft;

- (void)loadView {
	[super loadView];
	
	buttonLeft_ = [[[UIButton alloc] initWithFrame:CGRectMake(0, 0, 34, 30)] autorelease];
	UIImage* image = [MMThemeMgr imageNamed:@"topbar_back.png"];
	[buttonLeft_ setImage:image forState:UIControlStateNormal];
	[buttonLeft_ setImage:image forState:UIControlStateHighlighted];
	[buttonLeft_ setBackgroundImage:[MMThemeMgr imageNamed:@"common_topbar_ic_press.png"] forState:UIControlStateHighlighted];
	[buttonLeft_ addTarget:self action:@selector(actionLeft:) forControlEvents:UIControlEventTouchUpInside];
	self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:buttonLeft_] autorelease];
	
	buttonRight_ = [[[UIButton alloc] initWithFrame:CGRectMake(0, 0, 34, 30)] autorelease];
	image = [MMThemeMgr imageNamed:@"draft_box_topbar_dustbin.png"];
	[buttonRight_ setImage:image forState:UIControlStateNormal];
	[buttonRight_ setImage:image forState:UIControlStateHighlighted];
	[buttonRight_ setBackgroundImage:[MMThemeMgr imageNamed:@"common_topbar_ic_press.png"] forState:UIControlStateHighlighted];
	[buttonRight_ addTarget:self action:@selector(actionRight:) forControlEvents:UIControlEventTouchUpInside];
	buttonRight_.enabled = NO;
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:buttonRight_] autorelease];
	
	[self updateTitle];
	
	MMDraftMgr* dataSource = [MMDraftMgr shareInstance];
	draftTable = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, 320, 416)];
	draftTable.dataSource = dataSource;
	draftTable.delegate = self;
	draftTable.backgroundColor = [UIColor clearColor];
	[self.view addSubview:draftTable];
	
	draftTable.tableFooterView = [[[UIView alloc] init] autorelease];
	
	[MMDraftMgr shareInstance].draftDelegate = self;
}

- (void)viewDidUnload {
    [super viewDidUnload];
    draftTable = nil;
}

- (void)reloadVisibleRows {
	[draftTable reloadRowsAtIndexPaths:[draftTable indexPathsForVisibleRows] 
					  withRowAnimation:UITableViewRowAnimationNone];
}

- (void)actionLeft:(id)sender {
	[[self navigationController] popViewControllerAnimated:YES];
}

- (void)actionRight:(id)sender {
	UIActionSheet* actionSheet = [[UIActionSheet alloc] initWithTitle:@"清空草稿箱" 
															 delegate:self 
													cancelButtonTitle:@"取消" 
											   destructiveButtonTitle:@"清空" 
													otherButtonTitles:nil];
	actionSheet.tag = 201;
	[actionSheet showInView:self.view];
	[actionSheet release];
}

- (void)updateTitle {
	MMDraftMgr* dataSource = [MMDraftMgr shareInstance];
	self.navigationItem.title = [NSString stringWithFormat:@"草稿箱(%d)", dataSource.draftArray.count];
	
	if (dataSource.draftArray.count == 0) {
		buttonRight_.enabled = NO;
	} else {
		buttonRight_.enabled = YES;
	}
}

- (void)draftDeleted:(NSIndexPath*)indexPath {
	if (indexPath) {
		[draftTable deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationMiddle];
	}
	[self updateTitle];
}

- (void)draftNeedRefresh:(NSIndexPath*)indexPath {
	if (indexPath) {
		[draftTable reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationMiddle];
	}
}

- (void)draftInserted:(NSIndexPath*)indexPath {
	if (indexPath) {
		[draftTable insertRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationMiddle];
	}
	[self updateTitle];
}

- (void)dealloc {
	
	[MMDraftMgr shareInstance].draftDelegate = nil;
	[draftTable release];
	[super dealloc];
}

#pragma mark UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	switch (actionSheet.tag) {
		case 101:
		{
			switch (buttonIndex) {
				case 0:
				{
					//delete draft
					[[MMDraftMgr shareInstance] deleteDraftInfo:currentSelectedDraft];
				}
					break;
				case 1:
				{
					//cancel upload
					if (currentSelectedDraft.uploadStatus == uploadUploading || currentSelectedDraft.uploadStatus == uploadWait) {
						[[MMDraftMgr shareInstance] stopUploadDraft:currentSelectedDraft];
					}
				}
					break;
				case 2:
				{
					//upload draft
					if (currentSelectedDraft.uploadStatus != uploadUploading && currentSelectedDraft.uploadStatus != uploadWait) {
						[[MMDraftMgr shareInstance] resendDraft:currentSelectedDraft];
						
					}
				}
					break;
				default:
					break;
			}
		}
			break;
		case 201:
		{
			if (buttonIndex == actionSheet.destructiveButtonIndex) {
				[[MMDraftMgr shareInstance] clearDraftBox];
				[draftTable reloadData];
				
				[self updateTitle];
			}
		}
			break;
		default:
			break;
	}

	self.currentSelectedDraft = nil;
}

#pragma mark UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return [MMDraftCell computeCellHeight:[[MMDraftMgr shareInstance].draftArray objectAtIndex:indexPath.row]];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	self.currentSelectedDraft = [[MMDraftMgr shareInstance].draftArray objectAtIndex:indexPath.row];

	if (currentSelectedDraft.uploadStatus == uploadUploading || currentSelectedDraft.uploadStatus == uploadWait) {
		UIActionSheet* actionSheet = [[UIActionSheet alloc] initWithTitle:@"提示" 
																 delegate:self 
														cancelButtonTitle:@"取消" 
												   destructiveButtonTitle:@"删除" 
														otherButtonTitles:@"取消发送", nil];
		[actionSheet showInView:self.view];
		actionSheet.tag = 101;
		[actionSheet release];
	} else {
//		actionSheet = [[UIActionSheet alloc] initWithTitle:@"提示" 
//												  delegate:self 
//										 cancelButtonTitle:@"取消" 
//									destructiveButtonTitle:@"删除" 
//										 otherButtonTitles:@"编辑", @"发送", nil];
		MMEditDraftViewController* editController = [[MMEditDraftViewController alloc] initWithDraft:currentSelectedDraft];
		editController.hidesBottomBarWhenPushed = YES;
		[self.navigationController pushViewController:editController animated:YES];
		[editController release];
	}
}



@end
