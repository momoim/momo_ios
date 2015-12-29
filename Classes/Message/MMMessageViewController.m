//
//  MMMessageViewController.m
//  momo
//
//  Created by wangsc on 10-12-23.
//  Copyright 2010 ND. All rights reserved.
//

#import "MMMessageViewController.h"
#import "MMThemeMgr.h"
#import "MMGlobalPara.h"
#import "MMGlobalData.h"
#import "MMMessageCell.h"
#import "MMBrowseMessageViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "MMNewMessageViewController.h"
#import "MMUIMessage.h"
#import "MMDraft.h"
#import "MMUploadQueue.h"
#import "MMDraftViewController.h"
#import "MMMessageSyncer.h"
#import "MWPhotoBrowser.h"
#import "MMNewCommentViewController.h"
#import "MMRetweetViewController.h"
#import "MMCommonAPI.h"
#import "unistd.h"
#import "MMUIDefines.h"
#import "MMLoginService.h"
#import "MMUapRequest.h"
#import "EGORefreshTableHeaderView.h"
#import "MMMomoUserMgr.h"
#import "MMSoundMgr.h"
#import "MMPreference.h"
#import "MMWebViewController.h"
#import "MMLoginService.h"
#import "MTStatusBarOverlay.h"
#import "RegexKitLite.h"
#import "MMAboutMeViewController.h"
#import "MMAboutMeManager.h"
#import "MMMapViewController.h"
#import "UIActionSheet+MKBlockAdditions.h"
#import "MMGlobalStyle.h"

#define SELECT_SHOW_PHOTO_TYPE 111
#define BACKGROUND_BUTTON_TAG 112

@interface MMMessageViewController ()


@end

@implementation MMMessageViewController
@synthesize messageDataSource;
@synthesize progressHub;
@synthesize currentSelectedUploadMessage;

- (id)init {
    //	if (self = [super init]) {
    //		self.navigationItem.title = NSLocalizedString(@"MMMessageNameKey", nil);
    //	}
    self = [super init];
    if (self) {
        self.navigationItem.title = @"MO分享";
        
        backgroundThreads = [[NSMutableArray alloc] init];
        
        messageDataSource = [[MMMessageDataSource alloc] init];
        messageDataSource.messageDelegate = self;
        messageDataSource.messageCellDelegate = self;
        
        [[MMUploadQueue shareInstance] addObserver:self forKeyPath:@"currentUploadProgress" options:NSKeyValueObservingOptionNew context:nil];
        [[MMAboutMeManager shareInstance] addObserver:self forKeyPath:@"unReadCount" options:NSKeyValueObservingOptionNew context:nil];
        [[MMPreference shareInstance] addObserver:self forKeyPath:@"showMessagePhotoType" options:NSKeyValueObservingOptionNew context:nil];  
        
        NSNotificationCenter* notificationCenter = [NSNotificationCenter defaultCenter];
        [notificationCenter addObserver:self selector:@selector(onMomoUserInfoChanged:) name:kMMUserInfoChanged object:nil];
        
        [notificationCenter addObserver:self selector:@selector(draftStatusChanged:) name:kMMDraftStatusChanged object:nil];
        [notificationCenter addObserver:self selector:@selector(uploadMessageWillStart:) name:kMMDraftStartUpload object:nil];
        [notificationCenter addObserver:self selector:@selector(removeUploadingDraft:) name:kMMDraftRemoved object:nil];
    }
	return self;
}

- (void)dealloc {
    self.currentSelectedUploadMessage = nil;
	self.progressHub = nil;
	[MMCommonAPI waitHTTPThreadsQuit:backgroundThreads];
	[messageDataSource release];
	[super dealloc];
}

- (void)loadView {
	[super loadView];
	
	UIButton* refreshButton = [[[UIButton alloc] initWithFrame:CGRectMake(0, 0, 34, 30)] autorelease];
	UIImage* image = [MMThemeMgr imageNamed:@"share_topbar_ic_at.png"];
	[refreshButton setImage:image forState:UIControlStateNormal];
	[refreshButton setImage:image forState:UIControlStateHighlighted];
	[refreshButton setBackgroundImage:[MMThemeMgr imageNamed:@"common_topbar_ic_press.png"] forState:UIControlStateHighlighted];
	[refreshButton addTarget:self action:@selector(actionLeft) forControlEvents:UIControlEventTouchUpInside];
	self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:refreshButton] autorelease];
    
    //关于我的数目
    unReadAboutMeBgView = [[[UIImageView alloc] initWithImage:[MMThemeMgr imageNamed:@"number_bg.png"]] autorelease];
    unReadAboutMeBgView.left = 34;
    [refreshButton addSubview:unReadAboutMeBgView];
    
    unReadAboutMeNumLabel = [[[UILabel alloc] initWithFrame:CGRectMake(0, 0, unReadAboutMeBgView.width, unReadAboutMeBgView.height)] autorelease];
    unReadAboutMeNumLabel.textAlignment = UITextAlignmentCenter;
    unReadAboutMeNumLabel.font = [UIFont fontWithName:@"Helvetica" size:12];
    unReadAboutMeNumLabel.textColor = [UIColor whiteColor];
    unReadAboutMeNumLabel.backgroundColor = [UIColor clearColor];
    [unReadAboutMeBgView addSubview:unReadAboutMeNumLabel];
    [self refreshAboutMeNumberLabel];
	
	UIButton* editButton = [[[UIButton alloc] initWithFrame:CGRectMake(0, 0, 34, 30)] autorelease];
	image = [MMThemeMgr imageNamed:@"momo_dynamic_topbar_write.png"];
	[editButton setImage:image forState:UIControlStateNormal];
	[editButton setImage:image forState:UIControlStateHighlighted];
	[editButton setBackgroundImage:[MMThemeMgr imageNamed:@"common_topbar_ic_press.png"] forState:UIControlStateHighlighted];
	[editButton addTarget:self action:@selector(actionForNewMessage) forControlEvents:UIControlEventTouchUpInside];
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:editButton] autorelease];
    
    titleButton_ = [UIButton buttonWithType:UIButtonTypeCustom];
	image = [MMThemeMgr imageNamed:@"momo_dynamic_topbar_button.png"];
	[titleButton_ setBackgroundImage:image forState:UIControlStateNormal];
	[titleButton_ setBackgroundImage:[MMThemeMgr imageNamed:@"momo_dynamic_topbar_button_press.png"] forState:UIControlStateHighlighted];
	titleButton_.frame = CGRectMake(0, 0, 120, 29);
	titleButton_.titleLabel.font = [UIFont systemFontOfSize:14];
    
    if (messageDataSource.currentGroupInfo) {
        [titleButton_ setTitle:messageDataSource.currentGroupInfo.groupName forState:UIControlStateNormal];
    } else {
        [titleButton_ setTitle:@"全部分享" forState:UIControlStateNormal];
    }
	
	titleButton_.titleLabel.lineBreakMode   = UILineBreakModeTailTruncation;
	titleButton_.frame = [MMCommonAPI properRectForButton:titleButton_ maxSize:CGSizeMake(160, 29)];
	[titleButton_ addTarget:self action:@selector(actionForSelectGroup) forControlEvents:UIControlEventTouchUpInside];
	self.navigationItem.titleView = titleButton_;
    
    //create table view
	[self createTableViews:YES];
    
    if (progressHub) {
        self.progressHub = nil;
    }
	self.progressHub = [[[MBProgressHUD alloc] initWithView:self.view] autorelease];
	[self.view addSubview:progressHub];
	[self.view bringSubviewToFront:progressHub];
	self.progressHub.labelText = @"加载中...";
    
 
    [self initDataSource];
    
}

- (void)createTableViews:(BOOL)firstCreate {
    //message table
	CGFloat height = self.view.frame.size.height;
	messageTable = [[[UITableView alloc] initWithFrame:CGRectMake(0, 0, 320, height) style:UITableViewStylePlain] autorelease];
	messageTable.backgroundColor = [UIColor clearColor];
	[messageTable setDelegate:self];
	[messageTable setDataSource:messageDataSource];
	[messageTable setAutoresizingMask: UIViewAutoresizingFlexibleHeight];
    //	messageTable.separatorStyle = UITableViewCellSeparatorStyleNone;
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
}

- (void)performSelectorUsingMMThread:(SEL)selector object:(id)object {
	MMHttpRequestThread* thread = [[MMHttpRequestThread alloc] initWithTarget:self 
																	 selector:selector
																	   object:object];
	[backgroundThreads addObject:thread];
	[thread start];
	[thread release];
}

- (void)viewWillAppear:(BOOL)animated {
	if (!viewFirstAppear) {
		viewFirstAppear = YES;
  
	}
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:YES];
}

- (void)viewDidUnload {
    [super viewDidUnload];
	
	messageTable = nil;
	refreshHeaderView = nil;
	
    footerButton = nil;
	footerRefreshSpinner = nil;
    self.progressHub = nil;
}

- (void)initDataSource {
	if (!isAllMessageInit) {
		[self startLoading];
        [messageDataSource initData];
	}
}

- (void)reloadUploadVisiableCell {
    NSArray* indexPathsForVisibleRows = [messageTable indexPathsForVisibleRows];
    NSMutableArray* reloadIndexPaths = [NSMutableArray array];
    for (NSIndexPath* indexPath in indexPathsForVisibleRows) {
        MMMessageCell* cell = (MMMessageCell*)[messageTable cellForRowAtIndexPath:indexPath];
        if (cell.currentMessageInfo.draftId > 0) {
            [reloadIndexPaths addObject:indexPath];
        }
    }
    
    if (reloadIndexPaths.count > 0) {
        [messageTable reloadRowsAtIndexPaths:reloadIndexPaths 
                            withRowAnimation:UITableViewRowAnimationNone];
    }
}

- (void)refreshAboutMeNumberLabel {
    NSInteger number = [MMAboutMeManager shareInstance].unReadCount;
    unReadAboutMeNumLabel.text = [NSString stringWithFormat:@"%d", number];
    [unReadAboutMeNumLabel sizeToFit];
    unReadAboutMeBgView.width = unReadAboutMeNumLabel.width + 14;
    unReadAboutMeNumLabel.center = CGPointMake(unReadAboutMeBgView.width / 2, unReadAboutMeBgView.height / 2 - 1);
    
    if ([MMAboutMeManager shareInstance].unReadCount == 0) {
        unReadAboutMeBgView.hidden = YES;
    } else {
        unReadAboutMeBgView.hidden = NO;
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
//    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    
	if (object == [MMUploadQueue shareInstance] && [keyPath isEqualToString:@"currentUploadProgress"]) {
		[self performSelectorOnMainThread:@selector(reloadUploadVisiableCell) withObject:nil waitUntilDone:NO];
		return;
	} else if (object == [MMAboutMeManager shareInstance] && [keyPath isEqualToString:@"unReadCount"]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self refreshAboutMeNumberLabel];
        });
    } else if (object == [MMPreference shareInstance] && [keyPath isEqualToString:@"showMessagePhotoType"]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [messageTable reloadData];
        });
    }
}

- (void)onMomoUserInfoChanged:(NSNotification*)notification {
	MMMomoUserInfo* momoUserInfo = [notification object];
	if (!momoUserInfo) {
		return;
	}
	
	NSMutableArray* rowsToReload = [NSMutableArray array];
	NSArray* visibleCells = [messageTable indexPathsForVisibleRows];
	for (NSIndexPath* indexPath in visibleCells) {
		MMMessageCell* messageCell = (MMMessageCell*)[messageTable cellForRowAtIndexPath:indexPath];
		if (messageCell.currentMessageInfo.uid == momoUserInfo.uid) {
			[rowsToReload addObject:indexPath];
		}
	}
	if (rowsToReload.count > 0) {
		[messageTable reloadRowsAtIndexPaths:rowsToReload withRowAnimation:UITableViewRowAnimationNone];
	}
}

- (void)cancelBackgroundThreads {
    [MMCommonAPI waitHTTPThreadsQuit:backgroundThreads];
}

- (void)reset {
	[[MMUploadQueue shareInstance] removeAllTask];
	[self cancelBackgroundThreads];
	
	isAllMessageInit = NO;
	viewFirstAppear = NO;
	
	[messageDataSource reset];
	footerButton.hidden = YES;
	
	[messageTable reloadData];
    
    [titleButton_ setTitle:@"全部分享" forState:UIControlStateNormal];
    titleButton_.frame = [MMCommonAPI properRectForButton:titleButton_ maxSize:CGSizeMake(160, 29)];
}

- (void)startLoading {
    CHECK_NETWORK;
    
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

- (void)actionLeft {
    MMAboutMeViewController* viewController = [[[MMAboutMeViewController alloc] init] autorelease];
    viewController.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:viewController animated:YES];
}

- (void)actionRefresh {
	if (messageDataSource.downLoadState != MMDownNone) {
        return;
    }
    
    [self startLoading];
}

- (void)actionForNewMessage {
	MMNewMessageViewController* controller = [[MMNewMessageViewController alloc] init];
	controller.messageDelegate = self;
	controller.hidesBottomBarWhenPushed = YES;
    controller.groupInfo = messageDataSource.currentGroupInfo;
	[self.navigationController pushViewController:controller animated:YES];
	[controller release];
}

- (void)actionDownMoreMessage {
	if (!isLoading  && messageDataSource.downLoadState == MMDownNone) {
		isLoading = YES;
		[footerRefreshSpinner startAnimating];
		[footerButton setTitle:@"更多分享载入中..." forState:UIControlStateNormal];
		[messageDataSource downMessage:MMDownOld];
	}
}

- (void)actionForSelectGroup {
    if (selectGroupView_) {
        [UIView animateWithDuration:0.3f animations:^{
            selectGroupView_.centerY += selectGroupView_.height;
        }completion:^(BOOL finished) {
            [selectGroupView_ removeFromSuperview];
            selectGroupView_ = nil;
        }];
    } else {
        selectGroupView_ = [[[MMSelectGroupView alloc] initWithFrame:messageTable.frame] autorelease];
        selectGroupView_.showPhotoTypeSwitcher = YES;
        selectGroupView_.delegate = self;
        [self.view addSubview:selectGroupView_];
        
        float centerY = selectGroupView_.centerY;
        selectGroupView_.centerY += selectGroupView_.height;
        [UIView beginAnimations:@"animation" context:NULL];
        [UIView setAnimationDuration:0.3f];
        selectGroupView_.centerY = centerY;
        [UIView commitAnimations];
    }
}

//时间线直接操作相关

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
            [progressHub hide:YES afterDelay:1.5f];
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
    
    //删除线程对象
    MMThread* currentThread = [MMThread currentThread];
	dispatch_async(dispatch_get_main_queue(), ^{
		[currentThread wait];
        int index = [backgroundThreads indexOfObject:currentThread];
        if (index != NSNotFound) {
            [currentThread wait];
            [backgroundThreads removeObjectAtIndex:index];
        }
	});
	
	[pool drain];
}

#pragma mark UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == messageTable) {
        if (messageDataSource.uploadMessageArray.count > 0) {
            if (indexPath.row < messageDataSource.uploadMessageArray.count) {
                return [MMMessageCell computeCellHeight:[messageDataSource.uploadMessageArray objectAtIndex:indexPath.row]];
            } else {
                MMMessageInfo* messageInfo = [messageDataSource.messageArray 
                                              objectAtIndex:(indexPath.row - messageDataSource.uploadMessageArray.count)];
                return [MMMessageCell computeCellHeight:messageInfo];
            }
            
        } else {
            MMMessageInfo* messageInfo = [messageDataSource.messageArray objectAtIndex:indexPath.row];
            return [MMMessageCell computeCellHeight:messageInfo];
        }
    } else {
        return 30;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	if (tableView  == messageTable) {
		MMMessageInfo* messageInfo = nil;
		if (messageDataSource.uploadMessageArray.count > 0) {
			if (indexPath.row < messageDataSource.uploadMessageArray.count) {
				//uploading message
				messageInfo = [messageDataSource.uploadMessageArray objectAtIndex:indexPath.row];
			} else {
				messageInfo = [messageDataSource.messageArray objectAtIndex:(indexPath.row - messageDataSource.uploadMessageArray.count)];
			}
		} else {
			messageInfo = [messageDataSource.messageArray objectAtIndex:indexPath.row];
		}
		
		if (messageInfo.draftId == 0) {
			MMBrowseMessageViewController* browserViewController = [[MMBrowseMessageViewController alloc] 
																	initWithMessageInfo:messageInfo];
			browserViewController.messageDataSource = messageDataSource;
			browserViewController.hidesBottomBarWhenPushed = YES;
			browserViewController.messageDelegate = self;
			[self.navigationController pushViewController:browserViewController animated:YES];
			[browserViewController release];
		} else { 
			//uploading message
			currentSelectedUploadMessage = messageInfo;
			[currentSelectedUploadMessage retain];
			switch (messageInfo.uploadStatus) {
				case uploadUploading:
				case uploadWait:
				{
                UIActionSheet* actionSheet = [[UIActionSheet alloc] initWithTitle:@"提示" delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:@"删除" otherButtonTitles:@"取消发送",nil];
                actionSheet.tag = 101;
                [actionSheet showFromTabBar:[MMGlobalPara getTabBarController].tabBar];
                [actionSheet release];
				}
					break;
				case uploadFailed:
				{
                UIActionSheet* actionSheet = [[UIActionSheet alloc] initWithTitle:@"提示" delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:@"删除" otherButtonTitles:@"重新发送",nil];
                actionSheet.tag = 101;
                [actionSheet showFromTabBar:[MMGlobalPara getTabBarController].tabBar];
                [actionSheet release];
				}
                    break;
					
				default:
					break;
			}
		}
	}
}

#pragma mark UITableDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView.tag == SELECT_SHOW_PHOTO_TYPE) {
        return 3;
    }
    return 0;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView.tag == SELECT_SHOW_PHOTO_TYPE) {
        UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"photoTypeCell"];
        if (!cell) {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"photoTypeCell"] autorelease];
            
            UILabel* titleLabel = [[[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, 30)] autorelease];
            titleLabel.tag = 1;
            titleLabel.font = [UIFont systemFontOfSize:16];
            titleLabel.textAlignment = UITextAlignmentCenter;
            titleLabel.backgroundColor = [UIColor clearColor];
            titleLabel.textColor = [UIColor whiteColor];
            [cell.contentView addSubview:titleLabel];
        }
        
        cell.selectedBackgroundView = [[[UIView alloc] init] autorelease];
        cell.selectedBackgroundView.backgroundColor = [UIColor grayColor];
        
        UILabel* titleLabel = (UILabel*)[cell.contentView viewWithTag:1];
        
        switch (indexPath.row) {
            case 0:
                titleLabel.text = @"大图";
                break;
            case 1:
                titleLabel.text = @"小图";
                break;
            case 2:
                titleLabel.text = @"无图";
                break;
            default:
                break;
        }
        
        return cell;
    }
    return nil;
}

#pragma mark MMMessageDelegate
- (void)showFooterButtonAfterDelay {
	footerButton.hidden = NO; 
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
					if (indexPaths && indexPaths.count > 0) {
						[messageTable insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationMiddle];
					}
					
					BOOL moreOldMessage = [[dict objectForKey:@"moreOldMessage"] boolValue];
					if (moreOldMessage) {
						footerButton.hidden = NO;
					} else {
						footerButton.hidden = YES;
					}
                    
                    if (indexPaths.count == 0) {
                        CHECK_NETWORK;
                    }
				}
			}
				break;
			case MMDownRecent: {
				BOOL needReload = NO;
				if ([dict objectForKey:@"messageChanged"]) {
					needReload = YES;
				}
				
				if (!isAllMessageInit) {
					needReload = YES;
					isAllMessageInit = YES;
				}
				
                //a message is being browsing, notify to update
				NSArray* controllers = self.navigationController.viewControllers;
				if (controllers.count >= 2) {
					for (int i = controllers.count - 1; i >= 0; i--) {
						MMBrowseMessageViewController* viewController = [controllers objectAtIndex:i];
						
						if ([viewController isKindOfClass:[MMBrowseMessageViewController class]]) {
							[viewController currentMessageChanged];
						}
					}
				}
				
				if (isLoading) {
					[self stopLoading:needReload];	//在stopLoading里面reload
				} else if (needReload) {
					[messageTable reloadData];
				}
				
				BOOL moreOldMessage = [[dict objectForKey:@"moreOldMessage"] boolValue];
				if (moreOldMessage) {
					//footerButton.hidden = NO;
					[self performSelector:@selector(showFooterButtonAfterDelay) withObject:nil afterDelay:0.3f];
				} else {
					footerButton.hidden = YES;
				}
				
				//有下载到动态, 播放声音
				if ([[MMPreference shareInstance] shouldPlaySound]) {
					NSArray* serverMessages = [dict objectForKey:@"serverMessages"];
					if (serverMessages && serverMessages.count > 0) {
						[[MMSoundMgr shareInstance] playSound:@"breeding.wav"];
					}
				}
                
                if ([self.navigationController.topViewController isKindOfClass:[self class]]) {
                    if ([MMCommonAPI getNetworkStatus] != kNotReachable) {
                        NSString* errorString = [dict objectForKey:@"errorString"];
                        if (errorString.length > 0) {
                            NSString* result = [NSString stringWithFormat:@"下载分享失败:%@", errorString];
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
                CHECK_NETWORK;
			}
				break;
			case MMDownInitial: {
				BOOL needReload = NO;
				if ([dict objectForKey:@"messageChanged"]) {
					needReload = YES;
				}
				
				if (!isAllMessageInit) {
					needReload = YES;
					isAllMessageInit = YES;
				}
				
				if (isLoading) {
					[self stopLoading:needReload];	//在stopLoading里面reload
				} else if (needReload) {
					[messageTable reloadData];
				}
				
				BOOL moreOldMessage = [[dict objectForKey:@"moreOldMessage"] boolValue];
				if (moreOldMessage) {
					//footerButton.hidden = NO;
					[self performSelector:@selector(showFooterButtonAfterDelay) withObject:nil afterDelay:0.3f];
				} else {
					footerButton.hidden = YES;
				}
				
				//有下载到动态, 播放声音
				if ([[MMPreference shareInstance] shouldPlaySound]) {
					NSArray* serverMessages = [dict objectForKey:@"serverMessages"];
					if (serverMessages && serverMessages.count > 0) {
						[[MMSoundMgr shareInstance] playSound:@"breeding.wav"];
					}
				}
                
                if ([self.navigationController.topViewController isKindOfClass:[self class]]) {
                    if ([MMCommonAPI getNetworkStatus] != kNotReachable) {
                        NSString* errorString = [dict objectForKey:@"errorString"];
                        if (errorString.length > 0) {
                            NSString* result = [NSString stringWithFormat:@"分享下载失败:%@", errorString];
                            [[MTStatusBarOverlay sharedInstance] postImmediateFinishMessage:result duration:STATUSBAR_OVERLAY_HIDE_DELAY_TIME animated:YES];
                        } else {
                            NSArray* newMessages = [dict objectForKey:@"serverMessages"];
                            if (newMessages.count > 0) {
                                NSString* message = [NSString stringWithFormat:@"下载到%d条新分享", newMessages.count];
                                [[MTStatusBarOverlay sharedInstance] postImmediateFinishMessage:message duration:1.5 animated:YES];
                            }
                        }
                    } else {
                        [[MTStatusBarOverlay sharedInstance] postImmediateFinishMessage:@"网络错误" duration:1.5 animated:YES];
                    }
                }
                
                CHECK_NETWORK;
			}
				break;
			default:
				break;
		}
	}
}

- (void)deleteMessageDidSuccess:(MMMessageInfo*)messageInfo {
	for (NSUInteger i = 0; i < messageDataSource.messageArray.count; i++) {
		MMMessageInfo* tmpMessageInfo = [messageDataSource.messageArray objectAtIndex:i];
		if ([tmpMessageInfo.statusId isEqualToString:messageInfo.statusId]) {
			[messageDataSource.messageArray removeObjectAtIndex:i];
			NSIndexPath* indexPath = [NSIndexPath indexPathForRow:(i + messageDataSource.uploadMessageArray.count) 
														inSection:0];
			[messageTable deleteRowsAtIndexPaths:[NSArray arrayWithObjects:indexPath, nil] 
								withRowAnimation:UITableViewRowAnimationFade];
			break;
		}
	}
	
    //delete from db
	[[MMUIMessage instance] deleteMessage:messageInfo];
}

- (void)deleteCommentDidSuccess:(MMMessageInfo*)messageInfo{
    for (NSUInteger i = 0; i < messageDataSource.messageArray.count; i++) {
		MMMessageInfo* tmpMessageInfo = [messageDataSource.messageArray objectAtIndex:i];
		if ([tmpMessageInfo.statusId isEqualToString:messageInfo.statusId]) {
			NSIndexPath* indexPath = [NSIndexPath indexPathForRow:(i + messageDataSource.uploadMessageArray.count) 
														inSection:0];
            if (indexPath) {
                [messageTable reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
            }
			break;
		}
	}
}

- (void)draftStatusChanged:(NSNotification*)notification {
    MMDraftInfo* draftInfo = [notification object];
    
	switch (draftInfo.draftType) {
		case draftMessage:
        case draftRetweet:
			[self uploadMessageStatusChanged:draftInfo];
			break;
		case draftComment:
		{
        if (draftInfo.uploadStatus == uploadSuccess) {
            [[MTStatusBarOverlay sharedInstance] postImmediateFinishMessage:@"评论发送成功" 
                                                                   duration:STATUSBAR_OVERLAY_HIDE_DELAY_TIME 
                                                                   animated:YES];
        } else if (draftInfo.uploadStatus == uploadFailed) {
            [[MTStatusBarOverlay sharedInstance] postImmediateFinishMessage:@"评论发送失败" 
                                                                   duration:STATUSBAR_OVERLAY_HIDE_DELAY_TIME 
                                                                   animated:YES];
        }
		}
			break;
		default:
			break;
	}
}

- (void)uploadMessageWillStart:(NSNotification*)notification {
    MMDraftInfo* draftInfo = [notification object];
    if (draftInfo.draftType != draftMessage && draftInfo.draftType != draftRetweet) {
        return;
    }
    
	MMMessageInfo* newMessageInfo = [[[MMMessageInfo alloc] init] autorelease];
	newMessageInfo.ownerId = [[MMLoginService shareInstance] getLoginUserId];
	newMessageInfo.uid = newMessageInfo.ownerId;
	newMessageInfo.text = [draftInfo textWithoutUid];
    NSLog(@"text:%@, %@", newMessageInfo.text, draftInfo.text);
	newMessageInfo.groupId = draftInfo.groupId;
	newMessageInfo.groupName = draftInfo.groupName;
	newMessageInfo.createDate = draftInfo.createDate;
	newMessageInfo.uploadStatus = draftInfo.uploadStatus;
	newMessageInfo.draftId = draftInfo.draftId;
	newMessageInfo.attachImageURLs = draftInfo.attachImagePaths;
    newMessageInfo.realName = [[MMLoginService shareInstance] getLoginRealName];
	
	NSIndexPath* indexPath = [messageDataSource getUploadMessageIndexPath:newMessageInfo.draftId];
	if (indexPath) {
		[messageTable reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
	} else {
		[messageDataSource addUploadMessage:newMessageInfo];
		NSIndexPath* indexPath = [messageDataSource getUploadMessageIndexPath:newMessageInfo.draftId];
		if (indexPath) {
			[messageTable insertRowsAtIndexPaths:[NSArray arrayWithObjects:indexPath, nil] withRowAnimation:UITableViewRowAnimationNone];
		}
	}
}

- (void)uploadMessageStatusChanged:(MMDraftInfo*)draftInfo {
	[messageDataSource updateMessageStatus:draftInfo.uploadStatus draftId:draftInfo.draftId];
	NSIndexPath* indexPath = [messageDataSource getUploadMessageIndexPath:draftInfo.draftId];
	if (indexPath) {
		[messageTable reloadRowsAtIndexPaths:[NSArray arrayWithObjects:indexPath, nil] withRowAnimation:UITableViewRowAnimationNone];
	}
	
	//auto refresh after success upload
	if (draftInfo.uploadStatus == uploadSuccess) {
		isLoading = YES;
		[messageDataSource downMessage:MMDownRecent];
	}
	
	//在时间性直接转发,显示发送结果
	if (draftInfo.draftType == draftRetweet) {
		if (draftInfo.uploadStatus == uploadSuccess) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[MTStatusBarOverlay sharedInstance] postImmediateFinishMessage:@"转发成功" duration:STATUSBAR_OVERLAY_HIDE_DELAY_TIME animated:YES];
            });
		} else if (draftInfo.uploadStatus == uploadFailed) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[MTStatusBarOverlay sharedInstance] postImmediateFinishMessage:@"转发失败" duration:STATUSBAR_OVERLAY_HIDE_DELAY_TIME animated:YES];
            });
		}
	}
}

- (void)removeUploadingDraft:(NSNotification*)notification {
    MMDraftInfo* draftInfo = [notification object];
    if (draftInfo.draftType != draftMessage && draftInfo.draftType != draftRetweet) {
        return;
    }
    
    NSIndexPath* deletePath = [messageDataSource deleteUploadMessage:draftInfo.draftId];
    if (deletePath) {
        [messageTable deleteRowsAtIndexPaths:[NSArray arrayWithObject:deletePath] withRowAnimation:UITableViewRowAnimationNone];
    }
}

#pragma mark UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	[refreshHeaderView egoRefreshScrollViewDidScroll:scrollView];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (messageDataSource.downLoadState != MMDownNone) {
        return;
    }
	
	//down new message
	if (scrollView.contentOffset.y < 0) {
		[refreshHeaderView egoRefreshScrollViewDidEndDragging:scrollView];
		return;
    }
	
	//down old message
	if (scrollView.contentOffset.y > 0 && !footerButton.hidden) {
		if (scrollView.contentSize.height - (scrollView.contentOffset.y + messageTable.frame.size.height) < -REFRESH_HEADER_HEIGHT) {
			dragUpToDownOldMessage = YES;
		}
	}
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
	if (dragUpToDownOldMessage) {
		dragUpToDownOldMessage = NO;
		[self actionDownMoreMessage];
	}
}

#pragma mark -
#pragma mark EGORefreshTableHeaderDelegate
- (void)egoRefreshTableHeaderDidTriggerRefresh:(EGORefreshTableHeaderView*)view{
	isLoading = YES;
    
	if (!isAllMessageInit) {
		[messageDataSource initData];
		if (viewFirstAppear) {
			viewFirstAppear = YES;
			[messageDataSource downMessage:MMDownInitial];
			return;
		}
	}
	[messageDataSource downMessage:MMDownRecent];
}

- (BOOL)egoRefreshTableHeaderDataSourceIsLoading:(EGORefreshTableHeaderView*)view{
	return messageDataSource.downLoadState != MMDownNone;
}

- (NSDate*)egoRefreshTableHeaderDataSourceLastUpdated:(EGORefreshTableHeaderView*)view{
	return [NSDate date]; // should return date data source was last changed
}

#pragma mark UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	switch (actionSheet.tag) {
		case 101:
		{
        //时间线中的上传动态操作
        if (buttonIndex == actionSheet.destructiveButtonIndex) {
            if (currentSelectedUploadMessage.uploadStatus == uploadSuccess) {
                [currentSelectedUploadMessage release];
                currentSelectedUploadMessage = nil;
                return;
            }
            
            //stop upload and delete
            MMDraftInfo* draftInfo = [[MMDraft instance] getDraft:currentSelectedUploadMessage.draftId];
            if (draftInfo) {
                [[MMDraftMgr shareInstance] deleteDraftInfo:draftInfo];
            }
            
            [currentSelectedUploadMessage release];
            currentSelectedUploadMessage = nil;
        } else if (buttonIndex == 1) {
            if (currentSelectedUploadMessage.uploadStatus == uploadFailed) {
                CHECK_NETWORK;
                //resend
                MMDraftInfo* draftInfo = [[MMDraftMgr shareInstance] getDraftInfo:currentSelectedUploadMessage.draftId];
                if (draftInfo) {
                    [[MMDraftMgr shareInstance] resendDraft:draftInfo];
                }
            } else {
                //stop send
                MMDraftInfo* draftInfo = [[MMDraftMgr shareInstance] getDraftInfo:currentSelectedUploadMessage.draftId];
                if (draftInfo) {
                    [[MMDraftMgr shareInstance] stopUploadDraft:draftInfo];
                }
            }
            [currentSelectedUploadMessage release];
            currentSelectedUploadMessage = nil;
        }
		}
			break;
		default:
			break;
	}
}

#pragma mark -
#pragma mark MMMessageCellDelegate
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
	
	MMPhotoBrowser* viewController = [[MMPhotoBrowser alloc] initWithPhotos:photos];
	viewController.hidesBottomBarWhenPushed = YES;
	[viewController setInitialPageIndex:imageIndex];
	[self.navigationController pushViewController:viewController animated:NO];
	[viewController release];
}

//发评论
- (void)actionForCellNewComment:(MMMessageCell*)messageCell {
	MMNewCommentViewController* controller = [[MMNewCommentViewController alloc] 
											  initWithMessageInfo:messageCell.currentMessageInfo replyComment:nil];
	controller.hidesBottomBarWhenPushed = YES;
	controller.messageDelegate = self;
	[self.navigationController pushViewController:controller animated:YES];
	[controller release];
}

- (void)showAddress:(MMMessageInfo *)messageInfo{
    MMMapViewController *viewController = [[[MMMapViewController alloc] init] autorelease];
    CLLocationCoordinate2D addressCoordinate;
    addressCoordinate.latitude = messageInfo.latitude;
    addressCoordinate.longitude= messageInfo.longitude;
    
    viewController.friendCoordinate = addressCoordinate;
    viewController.shouldGetFriendGPSOffset = !messageInfo.isCorrect;
    viewController.friendId  = messageInfo.uid;
    
    viewController.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:viewController animated:YES];
}

- (void)actionForCellPraise:(MMMessageCell*)messageCell {
	if (!messageCell.currentMessageInfo.liked) {
		messageCell.currentMessageInfo.liked = YES;
		[messageCell showPraise:NO];
		
		[self performSelectorUsingMMThread:@selector(sendPraiseInBackground:) object:messageCell];
	}
}

- (void)actionRetweet:(MMMessageInfo*)messageInfo {
    MMRetweetViewController* controller = [[MMRetweetViewController alloc] 
										   initWithRetweetMessage:messageInfo];
	controller.hidesBottomBarWhenPushed = YES;
	controller.messageDelegate = self;
	[self.navigationController pushViewController:controller animated:YES];
	[controller release];
}

- (void)actionForCellRetweet:(MMMessageCell*)messageCell {
    [self actionRetweet:messageCell.currentMessageInfo];
}

- (void)actionViewHomePage:(MMMessageInfo*)messageInfo {
    //todo
}

- (void)actionForCellHomePage:(MMMessageCell*)messageCell {
    [self actionViewHomePage:messageCell.currentMessageInfo];
}

- (void)actionForCellViewLongText:(MMMessageCell*)messageCell {
    NSString* url = [MMCommonAPI getLongTextURL:messageCell.currentMessageInfo.statusId];
    [MMCommonAPI openUrl:url];
}

- (void)actionForCellLongPress:(MMMessageCell*)messageCell {
    NSString *title  = @"提示";
    NSString* confirm = @"隐藏分享";
    
    if (messageCell.currentMessageInfo.uid == [[MMLoginService shareInstance] getLoginUserId]) {
        confirm = @"删除分享";
    }
    
    NSArray* array = [NSArray arrayWithObjects:@"复制", confirm, nil];
    
    [UIActionSheet actionSheetWithTitle:title
                                message:nil 
                                buttons:array 
                             showInView:[MMGlobalPara getTabBarController].tabBar
                              onDismiss:^(int buttonIndex)
     {
     if (buttonIndex == 1) {
         CHECK_NETWORK;
         if (messageCell.currentMessageInfo.uid == [[MMLoginService shareInstance] getLoginUserId]) {
             //自己动态，删除
             [self performSelectorUsingMMThread:@selector(deleteMessageInBackground:) object:messageCell];
         }else{
             //别人的动态，隐藏
             [self performSelectorUsingMMThread:@selector(hideMessageInBackground:) object:messageCell];
         }
     } else {
         NSString* content = [messageCell.currentMessageInfo plainText];
         content = [content stringByReplacingOccurrencesOfString:@"&lt;" withString:@"<"];
         content = [content stringByReplacingOccurrencesOfString:@"&gt;" withString:@">"];
         [UIPasteboard generalPasteboard].string = content;
     }
     } onCancel:nil];
}

//删除动态
- (void)deleteMessageInBackground: (id)object {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    MMMessageCell* messageCell = (MMMessageCell*)object;
	if (!messageCell) {
		[pool drain];
		return;
	}
	
	NSString* result;
    NSString* errorString = nil;
	if (![[MMMessageSyncer shareInstance] deleteMessageRequest:messageCell.currentMessageInfo.statusId  withErrorString:&errorString]) {
		result = @"分享删除失败";
        dispatch_async(dispatch_get_main_queue(), ^{
            progressHub.labelText = result;
            progressHub.detailsLabelText = errorString ? errorString : @"";
            [progressHub show:YES];
            [progressHub hide:YES afterDelay:1.5f];
        });
	} else {
		result = @"分享删除成功";
        dispatch_async(dispatch_get_main_queue(), ^{
            [self deleteMessageDidSuccess:messageCell.currentMessageInfo];
            [[MTStatusBarOverlay sharedInstance] postImmediateFinishMessage:result 
                                                                   duration:STATUSBAR_OVERLAY_HIDE_DELAY_TIME 
                                                                   animated:YES];
        });
	}
    
    //删除线程对象
    MMThread* currentThread = [MMThread currentThread];
	dispatch_async(dispatch_get_main_queue(), ^{
		[currentThread wait];
        int index = [backgroundThreads indexOfObject:currentThread];
        if (index != NSNotFound) {
            [currentThread wait];
            [backgroundThreads removeObjectAtIndex:index];
        }
	});
	
	[pool drain];
}

//隐藏动态
- (void)hideMessageInBackground: (id)object {
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	MMMessageCell* messageCell = (MMMessageCell*)object;
    if (!messageCell) {
		[pool drain];
		return;
	}
	
	NSString* result = nil;
    NSString* errorString = nil;
	if (![[MMMessageSyncer shareInstance] hideMessage:messageCell.currentMessageInfo.statusId withErrorString:&errorString]) {
		result = @"隐藏分享失败";
        dispatch_async(dispatch_get_main_queue(), ^{
            progressHub.labelText = result;
            progressHub.detailsLabelText = errorString ? errorString : @"";
            [progressHub show:YES];
            [progressHub hide:YES afterDelay:1.5f];
        });
	} else {
		result = @"隐藏分享成功";
        dispatch_async(dispatch_get_main_queue(), ^{
            [self deleteMessageDidSuccess:messageCell.currentMessageInfo];
            [[MTStatusBarOverlay sharedInstance] postImmediateFinishMessage:result 
                                                                   duration:STATUSBAR_OVERLAY_HIDE_DELAY_TIME 
                                                                   animated:YES];
        });
	}
    
    //删除线程对象
    MMThread* currentThread = [MMThread currentThread];
	dispatch_async(dispatch_get_main_queue(), ^{
		[currentThread wait];
        int index = [backgroundThreads indexOfObject:currentThread];
        if (index != NSNotFound) {
            [currentThread wait];
            [backgroundThreads removeObjectAtIndex:index];
        }
	});
	
	[pool drain];
}

#pragma mark MMSelectGroupViewDelegate
- (void)selectGroupView:(MMSelectGroupView *)selectGroupView didSelectGroup:(MMGroupInfo *)groupInfo {
    [UIView animateWithDuration:0.3f animations:^{
        selectGroupView_.centerY += selectGroupView_.height;
    }completion:^(BOOL finished) {
        [selectGroupView_ removeFromSuperview];
        selectGroupView_ = nil;
    }];
    
    if (messageDataSource.currentGroupInfo == groupInfo) {
        return;
    }
    
    messageDataSource.currentGroupInfo = groupInfo;
    
	//取消可能正在下载动态的线程
	[messageDataSource cancelThreads];
	[refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:messageTable];
    
    //修改标题
	if (!groupInfo) {
		[titleButton_ setTitle:@"全部分享" forState:UIControlStateNormal];
    } else {
        [titleButton_ setTitle:groupInfo.groupName forState:UIControlStateNormal];
    }
    titleButton_.frame = [MMCommonAPI properRectForButton:titleButton_ maxSize:CGSizeMake(160, 29)];
	footerButton.hidden = YES;
    
    [messageDataSource reset];
    messageDataSource.currentGroupInfo = groupInfo;
    
    if (!groupInfo) {
		isAllMessageInit = NO;
	}
    [messageTable reloadData];
    [self performSelector:@selector(startLoading) withObject:nil afterDelay:0.2];
}

- (void)selectGroupViewDidChangePhotoShowType:(MMSelectGroupView *)selectGroupView {
    [UIView animateWithDuration:0.3f animations:^{
        selectGroupView_.centerY += selectGroupView_.height;
    }completion:^(BOOL finished) {
        [selectGroupView_ removeFromSuperview];
        selectGroupView_ = nil;
    }];
}

@end
