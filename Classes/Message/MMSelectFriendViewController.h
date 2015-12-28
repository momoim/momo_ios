//
//  MMSelectFriendViewController.h
//  momo
//
//  Created by wangsc on 11-1-24.
//  Copyright 2011 ND. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MMMessageDelegate.h"
#import "MBProgressHUD.h"

@interface MMSelectFriendViewController : UIViewController 
<UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, UISearchDisplayDelegate > {
	
		//table
	UITableView* friendsTable;
	NSArray* searchFriendsArray;
	NSArray* allFriendsArray;
	NSArray* currentArray;
	
	NSMutableArray *selectedFriends;
	
    BOOL    selectedMultiFriend;    //是否可以选择多个好友
	
	id<MMSelectFriendViewDelegate> delegate;
    UISearchDisplayController       *searchCtr;
	
	NSMutableDictionary				*friendDictionary_;
	NSMutableArray					*friendNameIndexArray_;
	
	NSMutableDictionary				*filterFriendDictionary_;
	NSMutableArray					*filterFriendNameIndexArray_;
    
    NSMutableArray*		backgroundThreads;
    MBProgressHUD*      progressHub;
    
    //需要下载uid的好友信息与手机号
    NSMutableArray* needUidFriends;
	//选择好的联系人，号码却是无效的，即没有有效的uid的好友信息与手机号
	NSMutableArray* invalidUidFriends;
	
	NSInteger selectCount;
    
    BOOL isLoading;

}
@property (nonatomic, retain) NSArray* searchFriendsArray;
@property (nonatomic, retain) NSArray* allFriendsArray;
@property (nonatomic, retain) NSMutableArray* selectedFriends;

@property (nonatomic) BOOL    selectedMultiFriend;
@property (nonatomic, assign) id<MMSelectFriendViewDelegate> delegate;
@property (nonatomic, retain) NSMutableArray* needUidFriends;

@property (nonatomic, retain) NSMutableArray* invalidUidFriends;

- (void)downFriendUidThread:(id)object;


@end
