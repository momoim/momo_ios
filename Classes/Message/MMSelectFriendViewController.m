    //
//  MMSelectFriendViewController.m
//  momo
//
//  Created by wangsc on 11-1-24.
//  Copyright 2011 ND. All rights reserved.
//

#import "MMSelectFriendViewController.h"
#import "MMThemeMgr.h"
#import "MMGlobalPara.h"
#import "MMGlobalData.h"
#import <QuartzCore/QuartzCore.h>
#import "MMGlobalStyle.h"
#import "MMUIDefines.h"
#import "MMAvatarImageView.h"
#import "MMCommonAPI.h"
#import "MMMomoUserMgr.h"
#import "MMPhoneticAbbr.h"
#import "MMUapRequest.h"
#import "MMMessageSyncer.h"
#import "MMLoginService.h"

@implementation MMSelectFriendViewController
@synthesize searchFriendsArray, allFriendsArray, selectedFriends, delegate, selectedMultiFriend;
@synthesize needUidFriends, invalidUidFriends; 

- (void)sortByIndex:(NSArray *)sortArray {
    
	[friendDictionary_ removeAllObjects];
	[friendNameIndexArray_ removeAllObjects];
    
    
	for (MMMomoUserInfo *friendInfo in sortArray) {
		
		NSString* name_phonetic = [MMPhoneticAbbr getPinyin:friendInfo.realName];
		NSString *firstLetter = [MMCommonAPI getStringFirstLetter:name_phonetic];
        
		NSMutableArray *existingArray;
		
		if ((existingArray = [friendDictionary_ valueForKey:firstLetter])) {
			[existingArray addObject:friendInfo];
		} 
		else {
			NSMutableArray *tempArray = [[NSMutableArray alloc]init];
			[tempArray addObject:friendInfo];
			[friendDictionary_ setObject:tempArray forKey:firstLetter];
			[tempArray release];
		}
		
	}
    
	[friendNameIndexArray_ setArray:
	 [[friendDictionary_ allKeys] sortedArrayUsingSelector:@selector(compareWithOther:)]];
    
        //for sort		
	for (NSInteger i = 0; i < [friendNameIndexArray_ count]; i++) {
		NSString *strkey = [friendNameIndexArray_ objectAtIndex:i];
        
		NSArray *array = [friendDictionary_ objectForKey:strkey];	
		array = [MMCommonAPI sortArrayByAbbr:array key:@"realName"];
        [friendDictionary_ setObject:array forKey:strkey];
	}	
}

- (void)sortByIndexForFilter:(NSArray *)sortArray {
	
	[filterFriendDictionary_ removeAllObjects];
	[filterFriendNameIndexArray_ removeAllObjects];
    
    
	for (MMMomoUserInfo *friendInfo in sortArray) {
		
		NSString* name_phonetic = [MMPhoneticAbbr getPinyin:friendInfo.realName];
		NSString *firstLetter = [MMCommonAPI getStringFirstLetter:name_phonetic];
		
		NSMutableArray *existingArray;
		
		if ((existingArray = [filterFriendDictionary_ valueForKey:firstLetter])) {
			[existingArray addObject:friendInfo];
		} 
		else {
			NSMutableArray *tempArray = [[NSMutableArray alloc]init];
			[tempArray addObject:friendInfo];
			[filterFriendDictionary_ setObject:tempArray forKey:firstLetter];
			[tempArray release];
		}
		
	}
	
	[filterFriendNameIndexArray_ setArray:
	 [[filterFriendDictionary_ allKeys] sortedArrayUsingSelector:@selector(compareWithOther:)]];
	
        //for sort		
	for (NSInteger i = 0; i < [filterFriendNameIndexArray_ count]; i++) {
		NSString *strkey = [filterFriendNameIndexArray_ objectAtIndex:i];
		
		NSArray *array = [filterFriendDictionary_ objectForKey:strkey];	
		array = [MMCommonAPI sortArrayByAbbr:array key:@"realName"];
        [filterFriendDictionary_ setObject:array forKey:strkey];
	}	
}


- (void)getFriendList {
    [[MMLoginService shareInstance] increaseActiveCount];
    
    
    //todo
//    NSArray* contactArray = [[MMContactManager instance] getSimpleContactList:nil];
//	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
//        NSArray *tmpArr = [[MMContactManager instance] getFriendListNeedName:YES needPhone:YES inArray:contactArray];        
//        
//            //把与UI相关的数据操作放在主线程
//		dispatch_async(dispatch_get_main_queue(), ^{
//            self.allFriendsArray = tmpArr;
//            currentArray = allFriendsArray;
//            [self sortByIndex:currentArray];
//            [friendsTable reloadData];
//            
//            [progressHub hide:NO];
//		});
//		
//        [[MMLoginService shareInstance] decreaseActiveCount];
//	});
}

- (id)init {
    self = [super init];
    if (self) {
        selectedMultiFriend = YES;
		selectedFriends = [[NSMutableArray alloc] init];
		
		friendDictionary_		= [[NSMutableDictionary alloc] init];
        friendNameIndexArray_	= [[NSMutableArray alloc] init];
		
		filterFriendDictionary_ = [[NSMutableDictionary alloc] init];
		filterFriendNameIndexArray_ = [[NSMutableArray alloc] init];
		
        backgroundThreads = [[NSMutableArray alloc] init];
		
		selectCount = 0;
    }
    return self;
}

- (void)loadView {
	[super loadView];
    [self.navigationController navigationBar].tintColor = [UIColor colorWithRed:0.29 green:0.72 blue:0.87 alpha:1.0];
	

	self.navigationItem.title = @"选择好友名片(0)";
	
	self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"取消" 
																			  style:UIBarButtonItemStyleBordered 
																			 target:self 
																			 action:@selector(actionLeft:)] autorelease];
    
	    
    if (selectedMultiFriend) {    
		self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"完成" 
																				   style:UIBarButtonItemStyleBordered 
																				  target:self 
																				  action:@selector(actionRight:)] autorelease];
		self.navigationItem.rightBarButtonItem.enabled = NO;
	}
		
	CGFloat height = self.view.frame.size.height - 44;
	friendsTable = [[[UITableView alloc] initWithFrame:CGRectMake(0, 0, 320, height) style:UITableViewStylePlain] autorelease];
	friendsTable.delegate = self;
	friendsTable.dataSource = self;
	[self.view addSubview:friendsTable];
	friendsTable.tableFooterView = [[[UIView alloc] init] autorelease];
	
	UISearchBar *searchBar = [[[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)] autorelease];
    searchBar.delegate = self;
	searchBar.placeholder = @"查找名片";
    friendsTable.tableHeaderView = searchBar;
	
    searchCtr = [[UISearchDisplayController alloc] initWithSearchBar:searchBar contentsController:self];
    searchCtr.delegate = self;
    searchCtr.searchResultsDelegate = self;
    searchCtr.searchResultsDataSource = self;
	
	
    progressHub = [[MBProgressHUD alloc] initWithView:self.view];
	[self.view addSubview:progressHub];
	[self.view bringSubviewToFront:progressHub];
    [progressHub show:YES];
	progressHub.labelText = @"加载好友信息...";
    
    [self getFriendList];
}

- (void)viewDidAppear:(BOOL)animated {

}

- (void)viewDidUnload {
    [super viewDidUnload];
    
    searchCtr = nil;
	friendsTable = nil;
}

- (void)actionLeft:(id)sender {
    [MMCommonAPI waitHTTPThreadsQuit:backgroundThreads];
    

    if ([(NSObject*)delegate respondsToSelector:@selector(didSelectFriend:)]) {
		[delegate didSelectFriend:[NSArray array]];
	}
    
	[[self navigationController] popViewControllerAnimated:YES];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return toInterfaceOrientation == UIInterfaceOrientationPortrait;
}

- (BOOL)getSelectedFriends {
	
	[selectedFriends removeAllObjects];
	for (MMMomoUserInfo *friendInfo in self.allFriendsArray) {
		if (friendInfo.isSelected) {
			[selectedFriends addObject:friendInfo];
		}
	}
	
	if (selectedFriends.count) {
		return YES;
	} else {
		return NO;
	}

}

- (void)actionRight:(id)sender {
	
	if (![self getSelectedFriends]) {
		[MMCommonAPI alert:@"您还未选择好友名片,请选择"];
		return;
	}
		
	self.needUidFriends = [NSMutableArray array];
	self.invalidUidFriends = [NSMutableArray array];
		
    //todo
	for (MMMomoUserInfo *friendInfo in selectedFriends) {
				
		if (friendInfo.uid == 0 || friendInfo.uid == mobileNotRegister) {
			[self.needUidFriends addObject:friendInfo];
		} else if (friendInfo.uid == mobileInvalid) {
			[self.invalidUidFriends addObject:friendInfo];
		} else {
			//do nothing
		}
	}
	

        
    NSArray* selectFriendArray = [selectedFriends sortedArrayUsingComparator:^(id obj1, id obj2) {
        MMMomoUserInfo* friendInfo1 = (MMMomoUserInfo*)obj1;
        MMMomoUserInfo* friendInfo2 = (MMMomoUserInfo*)obj2;
        
        if (friendInfo1.uid < friendInfo2.uid) {
            return NSOrderedAscending;
        } else if (friendInfo1.uid == friendInfo2.uid) {
            return NSOrderedSame;
        } else {
            return NSOrderedDescending;
        }
    }];
    
    if ([(NSObject*)delegate respondsToSelector:@selector(didSelectFriend:)]) {
        [delegate didSelectFriend:selectFriendArray];
    }
    
    [[self navigationController] popViewControllerAnimated:YES];

}

- (void)dealloc {
    [MMCommonAPI waitHTTPThreadsQuit:backgroundThreads];
    [backgroundThreads release];
    
    
	self.searchFriendsArray = nil;
	self.allFriendsArray = nil;
	[searchCtr release];
    searchCtr = nil;
	[selectedFriends release];
	
	[friendDictionary_ release];
	[friendNameIndexArray_ release];

    backgroundThreads = nil;
	
	[filterFriendDictionary_ release];
	[filterFriendNameIndexArray_ release];
	
	self.invalidUidFriends = nil;
	self.needUidFriends = nil;
	
    [super dealloc];
}

#pragma mark -
#pragma mark UISearchDisplayDelegate
- (void)searchBarTextDidBeginEditing:(UISearchBar *)hsearchBar {
    hsearchBar.showsCancelButton = YES;
    for(id cc in [hsearchBar subviews]) {
        if([cc isKindOfClass:[UIButton class]]) {
            UIButton *btn = (UIButton *)cc;
            [btn setTitle:@"完成"  forState:UIControlStateNormal];
            [btn addTarget:self action:@selector(actionRight:) forControlEvents:UIControlEventTouchUpInside];
        }
    }
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
	[friendsTable reloadData];
}


- (void)filterContentForSearchText:(NSString *)searchString {
	
	if (searchString.length == 0) {
		if (searchFriendsArray) {
			[searchFriendsArray release];
			searchFriendsArray = nil;
		}
		currentArray = allFriendsArray;
	} else {
		//todo 
//		self.searchFriendsArray = [[MMContact instance] searchFriend:searchString];
//        
//        if (selectedMultiFriend) {
//            NSMutableArray* tmpArray = [NSMutableArray arrayWithArray:searchFriendsArray];
//            for (int i = 0; i < tmpArray.count; i++) {
//				
//				MMMomoUserInfo *friendInfo = [tmpArray objectAtIndex:i];
//                if ([allFriendsArray indexOfObject:friendInfo] == NSNotFound) {
//                    [tmpArray removeObject:friendInfo];
//                    i--;
//                }
//            }
//            self.searchFriendsArray = tmpArray;
//        }
//        
//		if (searchFriendsArray) {
//			currentArray = searchFriendsArray;
//		} else {
//			currentArray = nil;
//		}
	}
	
	[self sortByIndexForFilter:currentArray];
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        
	[self filterContentForSearchText:searchString];
    // Return YES to cause the search result table view to be reloaded.
    return YES;
}


- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption {
	NSString *searchText = [self.searchDisplayController.searchBar text];
	[self filterContentForSearchText:searchText];
    
    // Return YES to cause the search result table view to be reloaded.
    return YES;
}

#pragma mark -
#pragma mark UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	return CONTACT_TABLE_HEADVIEW_HEIGHT;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return CONTACT_TABLE_CELL_HEIGHT;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {

	UIView *imageView = nil;
	imageView = [[[UIImageView alloc] initWithImage:[MMThemeMgr imageNamed:@"mainbar_shadow.png"]]autorelease];
	imageView.backgroundColor = [UIColor clearColor];
	
	UILabel *letter = [[UILabel alloc] initWithFrame:CGRectMake(15, 0, 200, 20)];
	letter.backgroundColor = [UIColor clearColor];
	letter.font = [UIFont fontWithName:@"Helvetica" size:16];
	letter.textColor = NOMAL_COLOR;
	
	if (tableView == self.searchDisplayController.searchResultsTableView) {
		letter.text = [filterFriendNameIndexArray_ objectAtIndex:section];
	} else {
		letter.text = [friendNameIndexArray_ objectAtIndex:section];
	}

	
	[imageView addSubview:letter];
	[letter release];
    
    return imageView;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

	[tableView deselectRowAtIndexPath:indexPath animated:YES];
		
	UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
	UIImageView* checkImageView = (UIImageView*)[cell.contentView viewWithTag:3];
	
	NSString *strkey = nil;
	NSArray *array = nil;                  
	if (tableView == self.searchDisplayController.searchResultsTableView) {
		strkey = [filterFriendNameIndexArray_ objectAtIndex:indexPath.section];
		array = [filterFriendDictionary_ objectForKey:strkey];
	} else {
		strkey = [friendNameIndexArray_ objectAtIndex:indexPath.section];
		array = [friendDictionary_ objectForKey:strkey];
	}	
		
	
	MMMomoUserInfo* selectedFriendInfo = [array objectAtIndex:indexPath.row];
	
	selectedFriendInfo.isSelected = !selectedFriendInfo.isSelected;
	if (selectedFriendInfo.isSelected) {
		selectCount++;
		checkImageView.image = [MMThemeMgr imageNamed:@"momo_setting_ic_hook_orange.png"];
	} else {
		selectCount--;
		checkImageView.image = [MMThemeMgr imageNamed:@"momo_setting_ic_hook_unclick.png"];
	}

	self.navigationItem.title = [NSString stringWithFormat:@"选择好友名片(%d)", selectCount];
	
	if (selectCount) {
		self.navigationItem.rightBarButtonItem.enabled = YES;
	} else {
		self.navigationItem.rightBarButtonItem.enabled = NO;
	}

    if (!selectedMultiFriend) {
        [self actionRight:nil];
    }
}

#pragma mark UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	if (tableView == self.searchDisplayController.searchResultsTableView) {
		return [filterFriendNameIndexArray_ count];
	} else {
		return [friendNameIndexArray_ count];
	}

}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	
	NSString *strkey = nil;
	NSArray *array = nil;
	if (tableView == self.searchDisplayController.searchResultsTableView) {
		strkey = [filterFriendNameIndexArray_ objectAtIndex:section];
		array = [filterFriendDictionary_ objectForKey:strkey];
	} else {
		strkey = [friendNameIndexArray_ objectAtIndex:section];
		array = [friendDictionary_ objectForKey:strkey];
	}	
	
	return [array count];
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
	if (title == UITableViewIndexSearch) 
	{
		[tableView scrollRectToVisible:tableView.tableHeaderView.frame animated:NO];
		return -1;
	}
	return index-1;
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
	
	NSMutableArray *indices = [NSMutableArray arrayWithObject:UITableViewIndexSearch];
	if (tableView == self.searchDisplayController.searchResultsTableView) {
		return [indices arrayByAddingObjectsFromArray:filterFriendNameIndexArray_];
	} else {
		return [indices arrayByAddingObjectsFromArray:friendNameIndexArray_];
	}
	
	
	return nil; 
	
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

	NSString *strkey = nil;
	NSArray *array = nil;
	if (tableView == self.searchDisplayController.searchResultsTableView) {
		strkey = [filterFriendNameIndexArray_ objectAtIndex:indexPath.section];
		array = [filterFriendDictionary_ objectForKey:strkey];
	} else {
		strkey = [friendNameIndexArray_ objectAtIndex:indexPath.section];
		array = [friendDictionary_ objectForKey:strkey];
	}	
	

	MMMomoUserInfo* friendInfo = [array objectAtIndex:indexPath.row];
	
	UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"MMSelectFriendCell"];
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"MMSelectImageCell"] autorelease];
		
		
		MMAvatarImageView* imageView = [[MMAvatarImageView alloc] initWithAvatarImageURL:nil];
		imageView.frame = CGRectMake(15, 8, 41, 41);
		imageView.tag = 1;
		imageView.layer.masksToBounds = YES;
		imageView.layer.cornerRadius = 3.0;
		[cell.contentView addSubview:imageView];
		[imageView release];
		
		UILabel* nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(68, 0, 190, 40)];		
		nameLabel.backgroundColor = [UIColor clearColor];
		nameLabel.font = [UIFont fontWithName:@"Helvetica" size:16];
		nameLabel.tag = 2;
		[cell.contentView addSubview:nameLabel];
		[nameLabel release];
		
		UILabel* numberLabel = [[UILabel alloc] initWithFrame:CGRectMake(68, 25, 190, 32)];
		numberLabel.backgroundColor = [UIColor clearColor];
		numberLabel.font = [UIFont fontWithName:@"Helvetica" size:14];
		numberLabel.tag = 4;
		[cell.contentView addSubview:numberLabel];
		[numberLabel release];
		
		UIImage *image = [MMThemeMgr imageNamed:@"momo_setting_ic_hook_unclick.png"];
		UIImageView* checkImageView = [[UIImageView alloc] initWithFrame:CGRectMake(260, 15, image.size.width, image.size.height)];
		checkImageView.image = image;
		checkImageView.tag = 3;
		[cell.contentView addSubview:checkImageView];
		[checkImageView release];
	}
	
	cell.selectedBackgroundView = [[[UIView alloc] initWithFrame:cell.frame] autorelease];
    cell.selectedBackgroundView.backgroundColor = TABLE_CELL_SELECT_COLOR;
	
	MMAvatarImageView* imageView = (MMAvatarImageView*)[cell.contentView viewWithTag:1];
    
    NSString* avatarUrl = [[MMMomoUserMgr shareInstance] avatarImageUrlByUserId:friendInfo.uid];
    if (!avatarUrl) {
		avatarUrl = friendInfo.avatarImageUrl;
    }
    imageView.imageURL = avatarUrl;
	
	UILabel* nameLabel = (UILabel*)[cell.contentView viewWithTag:2];
	nameLabel.text = friendInfo.realName;
	
	UILabel* numberLabel = (UILabel*)[cell.contentView viewWithTag:4];
	numberLabel.text = friendInfo.registerNumber;
	
	UIImageView* checkImageView = (UIImageView*)[cell.contentView viewWithTag:3];
	
	if (friendInfo.isSelected) {
		checkImageView.image = [MMThemeMgr imageNamed:@"momo_setting_ic_hook_orange.png"];
	} else {
		checkImageView.image = [MMThemeMgr imageNamed:@"momo_setting_ic_hook_unclick.png"];
	}

	return cell;
}

@end
