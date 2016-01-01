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
#import "MMFriendDB.h"

@interface MMSelectFriendViewController()


@end

@implementation MMSelectFriendViewController
@synthesize  delegate, selectedMultiFriend;


- (NSArray*)sortByPhonetic:(NSArray *)sortArray {
    for (MMMomoUserInfo *friendInfo in sortArray) {
        NSString* name_phonetic = [MMPhoneticAbbr getPinyin:friendInfo.realName];
        friendInfo.namePhonetic = name_phonetic;
    }
    
    return [sortArray sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        MMMomoUserInfo *f1 = obj1;
        MMMomoUserInfo *f2 = obj2;
        
        return [f1.namePhonetic compare:f2.namePhonetic];
    }];
}


- (void)getFriendList {
    [[MMLoginService shareInstance] increaseActiveCount];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        int now = (int)time(NULL);
        int ts = [MMFriendDB instance].updateTimestamp;
        
        NSArray *friends = nil;
        if (now - ts > 60*60) {
            NSInteger statusCode = 0;
            friends = [[MMLoginService shareInstance] getFreinds:&statusCode];
            if (statusCode != 200) {
                NSLog(@"get friends fail");
                return;
            }
            NSLog(@"friends:%@", friends);
            [[MMFriendDB instance] setFriends:friends];
            [MMFriendDB instance].updateTimestamp = now;

        } else {
            friends = [[MMFriendDB instance] getFriends];
        }
        
        NSMutableArray *tmp = [NSMutableArray array];
        for (NSDictionary *dict in friends) {
            MMMomoUserInfo *user = [[[MMMomoUserInfo alloc] init] autorelease];
            user.uid = [[dict objectForKey:@"id"] longLongValue];
            user.avatarImageUrl = [dict objectForKey:@"avatar"];
            user.realName = [dict objectForKey:@"name"];
            [tmp addObject:user];
        }
        
        [[MMLoginService shareInstance] decreaseActiveCount];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.allFriendsArray = tmp;
            self.currentArray = [self sortByPhonetic:self.allFriendsArray];
            [friendsTable reloadData];
            [progressHub hide:NO];
        });
    });
}

- (id)init {
    self = [super init];
    if (self) {
        selectedMultiFriend = YES;
        self.currentArray = [NSMutableArray array];
        self.allFriendsArray = [NSMutableArray array];
    }
    return self;
}


- (void)dealloc {
    self.allFriendsArray = nil;
    self.currentArray = nil;
    [searchCtr release];
    searchCtr = nil;
    
    [super dealloc];
}


- (void)loadView {
	[super loadView];

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

- (void)actionLeft:(id)sender {
    if ([(NSObject*)delegate respondsToSelector:@selector(didSelectFriend:)]) {
		[delegate didSelectFriend:[NSArray array]];
	}
    
	[[self navigationController] popViewControllerAnimated:YES];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return toInterfaceOrientation == UIInterfaceOrientationPortrait;
}

- (void)actionRight:(id)sender {
    
    NSMutableArray *array = [NSMutableArray array];
    for (MMMomoUserInfo *friendInfo in self.allFriendsArray) {
        if (friendInfo.isSelected) {
            [array addObject:friendInfo];
        }
    }
    
	if (array.count == 0) {
		[MMCommonAPI alert:@"您还未选择好友名片,请选择"];
		return;
	}

    
    NSArray* selectFriendArray = [array sortedArrayUsingComparator:^(id obj1, id obj2) {
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


- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        
    // Return YES to cause the search result table view to be reloaded.
    return YES;
}


- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption {
	NSString *searchText = [self.searchDisplayController.searchBar text];
//	[self filterContentForSearchText:searchText];
    
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
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

	[tableView deselectRowAtIndexPath:indexPath animated:YES];
		
	UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
	UIImageView* checkImageView = (UIImageView*)[cell.contentView viewWithTag:3];
	
	MMMomoUserInfo* selectedFriendInfo = [self.currentArray objectAtIndex:indexPath.row];
	
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


-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.currentArray.count;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    return  1;
}


- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

	MMMomoUserInfo* friendInfo = [self.currentArray objectAtIndex:indexPath.row];
	
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
