//
//  MMUserMessageViewController.m
//  momo
//
//  Created by  on 11-9-26.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import "MMUserMessageViewController.h"
#import "MMMessageSyncer.h"
#import "MMUIDefines.h"
#import "MMThemeMgr.h"
#import "MMBrowseMessageViewController.h"
#import "MWPhotoBrowser.h"
#import "MMNewCommentViewController.h"
#import "MMRetweetViewController.h"
#import "unistd.h"
#import "MMGlobalData.h"
#import "MMUapRequest.h"
#import "MMCommonAPI.h"
#import "MMSoundMgr.h"
#import "MMPreference.h"
#import "MMWebViewController.h"
#import "MMGlobalStyle.h"
#import "MMLoginService.h"
#import "MTStatusBarOverlay.h"
#import "MMMapViewController.h"

@implementation MMUserMessageViewController
@synthesize viewNeedDealloc, currentFriendInfo, messageDataSource;

- (id)initWithFriendInfo:(MMMomoUserInfo*)friendInfo {
	if (self = [super init]) {
		self.currentFriendInfo = friendInfo;
		viewNeedDealloc = NO;
		backgroundThreads = [[NSMutableArray alloc] init];
        isInit = NO;
        
        self.messageDataSource = [[[MMFriendMessageDataSource alloc] init] autorelease];
		messageDataSource.messageDelegate = self;
		messageDataSource.messageCellDelegate = self;
		messageDataSource.currentFriendInfo = currentFriendInfo;
	}
	return self;
}

- (void)loadView {
	[super loadView];
	self.view.backgroundColor = RGBCOLOR(224, 232, 235);
    
    if (!self.pageContainerViewController) {
        self.navigationItem.title = currentFriendInfo.realName;
        
        buttonLeft_ = [[[UIButton alloc] initWithFrame:CGRectMake(0, 0, 34, 30)] autorelease];
        UIImage* image = [MMThemeMgr imageNamed:@"topbar_back.png"];
        [buttonLeft_ setImage:image forState:UIControlStateNormal];
        [buttonLeft_ setImage:image forState:UIControlStateHighlighted];
        [buttonLeft_ setBackgroundImage:[MMThemeMgr imageNamed:@"common_topbar_ic_press.png"] forState:UIControlStateHighlighted];
        [buttonLeft_ addTarget:self action:@selector(actionLeft:) forControlEvents:UIControlEventTouchUpInside];
        self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:buttonLeft_] autorelease];
        
        buttonRight_ = [[[UIButton alloc] initWithFrame:CGRectMake(0, 0, 34, 30)] autorelease];
        image = [MMThemeMgr imageNamed:@"topbar_new.png"];
        [buttonRight_ setImage:image forState:UIControlStateNormal];
        [buttonRight_ setImage:image forState:UIControlStateHighlighted];
        [buttonLeft_ setBackgroundImage:[MMThemeMgr imageNamed:@"common_topbar_ic_press.png"] forState:UIControlStateHighlighted];
        [buttonRight_ addTarget:self action:@selector(actionRight:) forControlEvents:UIControlEventTouchUpInside];
        self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:buttonRight_] autorelease];
        buttonRight_.enabled = NO;
    }
    
    //message table
	CGFloat height = self.view.frame.size.height;
	messageTable = [[[UITableView alloc] initWithFrame:CGRectMake(0, 0, 320, height) style:UITableViewStylePlain] autorelease];
	messageTable.backgroundColor = [UIColor clearColor];
	[messageTable setDelegate:self];
	[messageTable setDataSource:messageDataSource];
	[messageTable setAutoresizingMask: UIViewAutoresizingFlexibleHeight];
	[self.view addSubview:messageTable];
	
	//header
	CGRect tableBounds = messageTable.bounds;
	refreshHeaderView = [[EGORefreshTableHeaderView alloc] initWithFrame:CGRectMake(0.0f, 0.0f - tableBounds.size.height, tableBounds.size.width, tableBounds.size.height)];
	refreshHeaderView.delegate = self;
	[messageTable addSubview:refreshHeaderView];
	[refreshHeaderView release];
	[refreshHeaderView refreshLastUpdatedDate];
	
    //refresh footer
	footerButton = [UIButton buttonWithType:UIButtonTypeCustom];
	footerButton.frame = CGRectMake(0, 1, 320, 44);
	[footerButton setBackgroundImage:[MMThemeMgr imageNamed:@"refresh_bg_normal.png"] 
							forState:UIControlStateNormal];
	[footerButton setBackgroundImage:[MMThemeMgr imageNamed:@"refresh_bg_press.png"] 
							forState:UIControlStateHighlighted];
	[footerButton addTarget:self action:@selector(actionDownMoreMessage) forControlEvents:UIControlEventTouchUpInside];
	[footerButton setTitle:@"更多分享..." forState:UIControlStateNormal];
    footerButton.titleLabel.font = [UIFont systemFontOfSize:14];
	[footerButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
	footerButton.hidden = YES;
	
	footerRefreshSpinner = [[[UIActivityIndicatorView alloc] 
							 initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray] autorelease];
	footerRefreshSpinner.center = CGPointMake(footerButton.frame.size.width / 5, footerButton.frame.size.height / 2);
	footerRefreshSpinner.hidesWhenStopped = YES;
	[footerButton addSubview:footerRefreshSpinner];
	messageTable.tableFooterView = footerButton;
    
    if (!progressHub) {
        progressHub = [[MBProgressHUD alloc] initWithView:self.view];
        [self.view addSubview:progressHub];
        [self.view bringSubviewToFront:progressHub];
        [progressHub release];
    }

}

- (void)viewDidAppear:(BOOL)animated {
    if (!isInit && [self currentPageViewController] == self) {
        isInit = YES;
        [self startLoading];
        [messageDataSource initData];
    }
}

- (void)viewDidUnload {
    [super viewDidUnload];
    
    messageTable = nil;
    progressHub = nil;
    refreshHeaderView = nil;
    footerButton = nil;
    footerRefreshSpinner = nil;
}

- (void)performSelectorUsingMMThread:(SEL)selector object:(id)object {
	MMHttpRequestThread* thread = [[MMHttpRequestThread alloc] initWithTarget:self 
																	 selector:selector
																	   object:object];
	[backgroundThreads addObject:thread];
	[thread start];
	[thread release];
}

- (void)hideHubAfterSomeTime {
	[progressHub performSelector:@selector(hide:) withObject:[NSNumber numberWithBool:YES] afterDelay:PROGRESS_HUB_PRESENT_TIME];
}

- (void)actionLeft:(id)sender {
	if (viewNeedDealloc) {
		return;
	}
	
	refreshHeaderView.delegate = nil;
	messageTable.delegate = nil;
	messageTable.dataSource = nil;
    
	viewNeedDealloc = YES;
	if (messageDataSource) {
		messageDataSource.messageDelegate = nil;
		[messageDataSource cancelThreads];
	}
	
	//background threads
	[MMCommonAPI waitHTTPThreadsQuit:backgroundThreads];
	
	[self.navigationController popViewControllerAnimated:YES];
}

- (void)actionRight:(id)sender {

}

- (void)showDownloadFailed {
	progressHub.labelText = @"下载失败";
    progressHub.detailsLabelText = @"";
	[self hideHubAfterSomeTime];
}

- (void)startLoading {
    isLoading = YES;
	[refreshHeaderView egoRefreshScrollViewAutoScrollToLoading:messageTable];
}

- (void)stopLoading:(BOOL)reloadData {
    isLoading = NO;
	
	[refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:messageTable];
	
	if (reloadData) {
        [messageTable reloadData];
	}
}

- (void)actionDownMoreMessage {
	if (!isLoading  && messageDataSource.downLoadState == MMDownNone) {
		isLoading = YES;
		[footerRefreshSpinner startAnimating];
		[footerButton setTitle:@"更多分享载入中..." forState:UIControlStateNormal];
		[messageDataSource downMessage:MMDownOld];
	}
}

- (void)setScrollToTop:(BOOL)scrollToTop {
    messageTable.scrollsToTop = scrollToTop;
}

- (void)dealloc {
    [MMCommonAPI waitHTTPThreadsQuit:backgroundThreads];
	[backgroundThreads release];
	self.messageDataSource = nil;
	self.currentFriendInfo = nil;
	[super dealloc];
}

- (void)mySleep {
	sleep(1.5);
}

#pragma mark UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	MMMessageInfo* messageInfo = [messageDataSource.messageArray objectAtIndex:indexPath.row];
	return [MMMessageCell computeCellHeight:messageInfo];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	MMMessageInfo* messageInfo = [messageDataSource.messageArray objectAtIndex:indexPath.row];
	MMBrowseMessageViewController* browserViewController = [[MMBrowseMessageViewController alloc] 
															initWithMessageInfo:messageInfo];
	browserViewController.messageDataSource = messageDataSource;
	browserViewController.hidesBottomBarWhenPushed = YES;
	browserViewController.messageDelegate = self;
	[[self properNavigationController] pushViewController:browserViewController animated:YES];
	[browserViewController release];
}

#pragma mark MMMessageDelegate
- (void)showFooterButtonAfterDelay {
	footerButton.hidden = NO; 
}

- (BOOL)shouldShowDownMessageResult {
    if (![self.properNavigationController.topViewController isKindOfClass:[self.properViewController class]]) {
        return NO;
    }
    if ([self currentPageViewController] != self) {
        return NO;
    }
    return YES;
}

- (void)downloadMessageDidSuccess:(NSDictionary*)userInfo {
	NSDictionary* dict = userInfo;
	MMMessageDownloadState downState = [[dict objectForKey:@"downLoadState"] intValue];
	id objectFrom = [dict objectForKey:@"object"];
	if (objectFrom == messageDataSource) {
		switch (downState) {
			case MMDownOld: {
                if (isLoading) {
                    isLoading = NO;
                    [footerButton setTitle:@"更多分享..." forState:UIControlStateNormal];
                    [footerRefreshSpinner stopAnimating];
                    
                    NSArray* indexPaths = [dict objectForKey:@"IndexPaths"];
                    if (indexPaths) {
                        [messageTable insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationMiddle];
                    }
                    
                    BOOL moreOldMessage = [[dict objectForKey:@"moreOldMessage"] boolValue];
                    if (moreOldMessage) {
                        footerButton.hidden = NO;
                    } else {
                        footerButton.hidden = YES;
                    }
                }
			}
				break;
			case MMDownRecent: {
                BOOL needReload = NO;
                if ([dict objectForKey:@"messageChanged"]) {
                    needReload = YES;
                }
                
                if (isLoading) {
                    [self stopLoading:needReload];	//在stopLoading里面reload
                } else if (needReload) {
                    [messageTable reloadData];
                }
                
                BOOL moreOldMessage = [[dict objectForKey:@"moreOldMessage"] boolValue];
                if (moreOldMessage) {
                    [self performSelector:@selector(showFooterButtonAfterDelay) withObject:nil afterDelay:0.3f];
                } else {
                    footerButton.hidden = YES;
                }
                
                if ([self shouldShowDownMessageResult]) {
                    if ([MMCommonAPI getNetworkStatus] != NotReachable) {
                        NSString* errorString = [dict objectForKey:@"errorString"];
                        if (errorString.length > 0) {
                            NSString* result = [NSString stringWithFormat:@"分享下载失败:%@", errorString];
                            [[MTStatusBarOverlay sharedInstance] postImmediateFinishMessage:result duration:STATUSBAR_OVERLAY_HIDE_DELAY_TIME animated:YES];
                        } else {
                            NSArray* newMessages = [dict objectForKey:@"serverMessages"];
                            if (newMessages.count > 0) {
                                NSString* message = [NSString stringWithFormat:@"下载到%d条新分享", newMessages.count];
                                [[MTStatusBarOverlay sharedInstance] postImmediateFinishMessage:message duration:STATUSBAR_OVERLAY_HIDE_DELAY_TIME animated:YES];
                            }
                        }
                    } else {
                        [[MTStatusBarOverlay sharedInstance] postImmediateFinishMessage:@"网络错误" duration:STATUSBAR_OVERLAY_HIDE_DELAY_TIME animated:YES];
                    }
                }
            }
                break;
            case MMDownInitial: {
                BOOL needReload = NO;
                if ([dict objectForKey:@"messageChanged"]) {
                    needReload = YES;
                }
                
                if (isLoading) {
                    [self stopLoading:needReload];	//在stopLoading里面reload
                } else if (needReload) {
                    [messageTable reloadData];
                }
                
                BOOL moreOldMessage = [[dict objectForKey:@"moreOldMessage"] boolValue];
                if (moreOldMessage) {
                    [self performSelector:@selector(showFooterButtonAfterDelay) withObject:nil afterDelay:0.3f];
                } else {
                    footerButton.hidden = YES;
                }
                
                if ([self shouldShowDownMessageResult]) {
                    if ([MMCommonAPI getNetworkStatus] != NotReachable) {
                        NSString* errorString = [dict objectForKey:@"errorString"];
                        if (errorString.length > 0) {
                            NSString* result = [NSString stringWithFormat:@"下载分享失败:%@", errorString];
                            [[MTStatusBarOverlay sharedInstance] postImmediateFinishMessage:result duration:STATUSBAR_OVERLAY_HIDE_DELAY_TIME animated:YES];
                        } else {
                            NSArray* newMessages = [dict objectForKey:@"serverMessages"];
                            if (newMessages) {
                                NSString* message = [NSString stringWithFormat:@"下载到%d条新分享", newMessages.count];
                                [[MTStatusBarOverlay sharedInstance] postImmediateFinishMessage:message duration:STATUSBAR_OVERLAY_HIDE_DELAY_TIME animated:YES];
                            }
                        }
                    } else {
                        [[MTStatusBarOverlay sharedInstance] postImmediateFinishMessage:@"网络错误" duration:STATUSBAR_OVERLAY_HIDE_DELAY_TIME animated:YES];
                    }
                }
			}
				break;
			default:
				break;
		}
	}
    CHECK_NETWORK;
}

#pragma mark UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	[refreshHeaderView egoRefreshScrollViewDidScroll:scrollView];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (isLoading) 
		return;
    isDragging = NO;
	
	//down new message
	if (scrollView.contentOffset.y < 0) {
		[refreshHeaderView egoRefreshScrollViewDidEndDragging:scrollView];
		return;
    }
	
	//down old message
	if (scrollView.contentOffset.y > 0 && !footerButton.hidden) {
		if (scrollView.contentSize.height - (scrollView.contentOffset.y + messageTable.frame.size.height) < -REFRESH_HEADER_HEIGHT) {
			if (!isLoading  && messageDataSource.downLoadState == MMDownNone) {
				isLoading = YES;
				[footerRefreshSpinner startAnimating];
				[footerButton setTitle:@"更多分享载入中..." forState:UIControlStateNormal];
				[messageDataSource downMessage:MMDownOld];
			}
		}
	}
}

#pragma mark -
#pragma mark EGORefreshTableHeaderDelegate
- (void)egoRefreshTableHeaderDidTriggerRefresh:(EGORefreshTableHeaderView*)view{
	isLoading = YES;
	
	[messageDataSource downMessage:MMDownRecent];
    CHECK_NETWORK;
}

- (BOOL)egoRefreshTableHeaderDataSourceIsLoading:(EGORefreshTableHeaderView*)view{
	return messageDataSource.downLoadState != MMDownNone;
}

- (NSDate*)egoRefreshTableHeaderDataSourceLastUpdated:(EGORefreshTableHeaderView*)view{
	return [NSDate date]; // should return date data source was last changed
}

#pragma mark -
#pragma mark MMMessageCellDelegate

- (void)showAddress:(MMMessageInfo *)messageInfo{
    MMMapViewController *viewController = [[[MMMapViewController alloc] init] autorelease];
    CLLocationCoordinate2D addressCoordinate;
    addressCoordinate.latitude = messageInfo.latitude;
    addressCoordinate.longitude= messageInfo.longitude;
    
    viewController.friendCoordinate = addressCoordinate;
    viewController.shouldGetFriendGPSOffset = !messageInfo.isCorrect;
    viewController.friendId  = messageInfo.uid;

    viewController.hidesBottomBarWhenPushed = YES;
    [[self properNavigationController] pushViewController:viewController animated:YES];
}

//发赞
- (void)sendPraiseInBackground:(id)object {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	MMMessageCell* messageCell = (MMMessageCell*)object;
	
	NSString* result = nil;
    NSString* errorString = nil;
	if (![[MMMessageSyncer shareInstance] postPraise:messageCell.currentMessageInfo.statusId withErrorString:&errorString]) {
        result = @"赞失败";
        messageCell.currentMessageInfo.liked = NO;
        dispatch_async(dispatch_get_main_queue(), ^{
            [messageCell showPraise:YES];
            progressHub.labelText = result;
            progressHub.detailsLabelText = errorString ? errorString : @"";
            [progressHub show:YES];
            [self hideHubAfterSomeTime];
        });
	} else {
		result = @"赞成功";
        dispatch_async(dispatch_get_main_queue(), ^{
            [messageCell showPraise:NO];
            [[MTStatusBarOverlay sharedInstance] postImmediateFinishMessage:result 
                                                                   duration:STATUSBAR_OVERLAY_HIDE_DELAY_TIME 
                                                                   animated:YES];
        });
	}
	
	[pool drain];
}

- (void)actionForCellViewAttachImage:(MMMessageInfo*)messageInfo imageIndex:(NSInteger)imageIndex {
	NSMutableArray* photos = [NSMutableArray array];
	
	int count = 0;
	for (MMAccessoryInfo* accessoryInfo in messageInfo.accessoryArray) {
		if (accessoryInfo.accessoryType == MMAccessoryTypeImage) {
			count++;
		}
	}
	
	for (int i = 0; i < count; i++) {
		MMImageAccessoryInfo* accessoryInfo = [messageInfo.accessoryArray objectAtIndex:i];
		NSString* smallImageURL = accessoryInfo.url;
		NSString* originImageUrl = [smallImageURL stringByReplacingOccurrencesOfString:@"_130." withString:@"_780."];
		
		MWPhoto* photoView = [[MWPhoto alloc] initWithURL:[NSURL URLWithString:originImageUrl]];
		[photos addObject:photoView];
		[photoView release];
	}
	
	MWPhotoBrowser* viewController = [[MWPhotoBrowser alloc] initWithPhotos:photos];
	viewController.hidesBottomBarWhenPushed = YES;
	[viewController setInitialPageIndex:imageIndex];
	[[self properNavigationController] pushViewController:viewController animated:YES];
	[viewController release];
}

- (void)actionForCellPraise:(MMMessageCell*)messageCell {
	if (!messageCell.currentMessageInfo.liked) {
		messageCell.currentMessageInfo.liked = YES;
		[messageCell showPraise:NO];
		
		[self performSelectorUsingMMThread:@selector(sendPraiseInBackground:) object:messageCell];
	}
}

- (void)actionForCellHomePage:(MMMessageCell*)messageCell {

}

- (void)actionForCellMoreOperation:(MMMessageCell*)messageCell {
	MMMessageInfo* messageInfo = messageCell.currentMessageInfo;
	NSString* firstMenu;
	NSString* secondeMenu;
	if (messageInfo.uid == [[MMLoginService shareInstance] getLoginUserId]) {
		if (messageInfo.storaged) {
			firstMenu = @"删除分享";
			secondeMenu = @"取消收藏";
		}else {
			firstMenu = @"删除分享";
			secondeMenu = @"收藏分享";
		}
	} else {
		if (messageInfo.storaged) {
			firstMenu = @"隐藏分享";
			secondeMenu = @"取消收藏";
		}else {
			firstMenu = @"隐藏分享";
			secondeMenu = @"收藏分享";
		}
	}
	
	UIActionSheet* actionSheet = [[UIActionSheet alloc] initWithTitle:@"提示" 
															 delegate:self 
													cancelButtonTitle:@"取消" 
											   destructiveButtonTitle:nil
													otherButtonTitles:firstMenu, secondeMenu, nil];
	actionSheet.tag = 201;
	[actionSheet showInView:[self properNavigationController].view];
	[actionSheet release];
}

- (void)didSwitchToPage:(UIViewController *)viewController {
    if (self == viewController) {
        [self properViewController].navigationItem.rightBarButtonItem = nil;
    }
}

@end

