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

@interface MMSelectFriendViewController : UIViewController <UITableViewDelegate,
    UITableViewDataSource, UISearchBarDelegate, UISearchDisplayDelegate > {
    UITableView *friendsTable;
    UISearchDisplayController *searchCtr;
    MBProgressHUD *progressHub;
	NSInteger selectCount;
}

@property(nonatomic, retain) NSArray *currentArray;
@property (nonatomic, retain) NSArray* allFriendsArray;
@property (nonatomic) BOOL selectedMultiFriend;
@property (nonatomic, weak) id<MMSelectFriendViewDelegate> delegate;

@end
