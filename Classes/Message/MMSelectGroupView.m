//
//  MMSelectGroupView.m
//  momo
//
//  Created by  on 12-7-26.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "MMSelectGroupView.h"
#import "MMGroupListMgr.h"
#import "MMPreference.h"
#import "MMThemeMgr.h"
#import "MMGlobalCategory.h"

@interface MMSelectGroupView ()

@property (nonatomic, retain) NSMutableArray* groupList;

@end

@implementation MMSelectGroupView
@synthesize showPhotoTypeSwitcher;
@synthesize groupList = groupList_;
@synthesize delegate = delegate_;

- (void)dealloc {
    self.groupList = nil;
    [super dealloc];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        NSArray* tmpArray = [MMGroupListMgr shareInstance].groupList;
        self.groupList = [NSMutableArray arrayWithObject:[NSNull null]];
        [groupList_ addObjectsFromArray:tmpArray];
        
        tableView_ = [[[UITableView alloc] initWithFrame:self.bounds style:UITableViewStylePlain] autorelease];
        tableView_.autoresizingMask = UIViewAutoresizingFlexibleWidth & UIViewAutoresizingFlexibleHeight;
        tableView_.delegate = self;
        tableView_.dataSource = self;
        tableView_.tableFooterView = [[[UIView alloc] init] autorelease];
        [self addSubview:tableView_];
        
        
    }
    return self;
}

- (void)onPhotoTypeChanged {
    if (delegate_ && [delegate_ respondsToSelector:@selector(selectGroupViewDidChangePhotoShowType:)]) {
        [delegate_ selectGroupViewDidChangePhotoShowType:self];
    }
}

- (void)setShowPhotoTypeSwitcher:(BOOL)show {
    if (!show) {
        tableView_.tableHeaderView = nil;
    } else if (!tableView_.tableHeaderView) {
        UIView* headerView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 60)] autorelease];
        
        //大图
        UIButton* bigPhotoBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        bigPhotoBtn.frame = CGRectMake(15, 15, 90, 30);
        [bigPhotoBtn setBackgroundImage:[MMThemeMgr imageNamed:@"change_status_image_button.png"] forState:UIControlStateNormal];
        [bigPhotoBtn setBackgroundImage:[MMThemeMgr imageNamed:@"change_status_image_button_selected.png"] forState:UIControlStateSelected];
        bigPhotoBtn.titleLabel.font = [UIFont boldSystemFontOfSize:13];
        [bigPhotoBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [bigPhotoBtn setTitle:@"大图预览" forState:UIControlStateNormal];
        bigPhotoBtn.titleEdgeInsets = UIEdgeInsetsMake(0, 15, 0, -15);
        
        UIImageView* imageView = [[[UIImageView alloc] initWithImage:[MMThemeMgr imageNamed:@"status_image_big_icon.png"]] autorelease];
        imageView.origin = CGPointMake(5, 5);
        [bigPhotoBtn addSubview:imageView];
        [headerView addSubview:bigPhotoBtn];
        
        [bigPhotoBtn addEventHandler:^(id sender) {
            [MMPreference shareInstance].showMessagePhotoType = kMMShowBigPhoto;
            [self onPhotoTypeChanged];
        }forControlEvents:UIControlEventTouchDown];
        
        if ([MMPreference shareInstance].showMessagePhotoType == kMMShowBigPhoto) {
            bigPhotoBtn.selected = YES;
        }
        
        //小图
        UIButton* smallPhotoBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        smallPhotoBtn.frame = CGRectMake(115, 15, 90, 30);
        [smallPhotoBtn setBackgroundImage:[MMThemeMgr imageNamed:@"change_status_image_button.png"] forState:UIControlStateNormal];
        [smallPhotoBtn setBackgroundImage:[MMThemeMgr imageNamed:@"change_status_image_button_selected.png"] forState:UIControlStateSelected];
        smallPhotoBtn.titleLabel.font = [UIFont boldSystemFontOfSize:13];
        [smallPhotoBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [smallPhotoBtn setTitle:@"小图预览" forState:UIControlStateNormal];
        smallPhotoBtn.titleEdgeInsets = UIEdgeInsetsMake(0, 15, 0, -15);
        
        imageView = [[[UIImageView alloc] initWithImage:[MMThemeMgr imageNamed:@"status_image_small_icon.png"]] autorelease];
        imageView.origin = CGPointMake(5, 5);
        [smallPhotoBtn addSubview:imageView];
        [headerView addSubview:smallPhotoBtn];
        
        [smallPhotoBtn addEventHandler:^(id sender) {
            [MMPreference shareInstance].showMessagePhotoType = kMMShowSmallPhoto;
            [self onPhotoTypeChanged];
        }forControlEvents:UIControlEventTouchDown];
        
        if ([MMPreference shareInstance].showMessagePhotoType == kMMShowSmallPhoto) {
            smallPhotoBtn.selected = YES;
        }
        
        //无图
        UIButton* noPhotoBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        noPhotoBtn.frame = CGRectMake(215, 15, 90, 30);
        [noPhotoBtn setBackgroundImage:[MMThemeMgr imageNamed:@"change_status_image_button.png"] forState:UIControlStateNormal];
        [noPhotoBtn setBackgroundImage:[MMThemeMgr imageNamed:@"change_status_image_button_selected.png"] forState:UIControlStateSelected];
        noPhotoBtn.titleLabel.font = [UIFont boldSystemFontOfSize:13];
        [noPhotoBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [noPhotoBtn setTitle:@"无预览" forState:UIControlStateNormal];
        [headerView addSubview:noPhotoBtn];
        
        [noPhotoBtn addEventHandler:^(id sender) {
            [MMPreference shareInstance].showMessagePhotoType = kMMShowNoPhoto;
            [self onPhotoTypeChanged];
        }forControlEvents:UIControlEventTouchDown];
        
        if ([MMPreference shareInstance].showMessagePhotoType == kMMShowNoPhoto) {
            noPhotoBtn.selected = YES;
        }
        
        tableView_.tableHeaderView = headerView;
    }
}

#pragma mark UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    MMGroupInfo* groupInfo = [groupList_ objectAtIndex:indexPath.row];

    if (0 == indexPath.row) {
        groupInfo = nil;
    }
    
    if (delegate_ && [delegate_ respondsToSelector:@selector(selectGroupView:didSelectGroup:)]) {
        [delegate_ selectGroupView:self didSelectGroup:groupInfo];
    }
}

#pragma mark UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return groupList_.count;
}

- (float)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 50;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"groupCell"];
    if (!cell) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"groupCell"] autorelease];
        UILabel* titleLabel = [[[UILabel alloc] initWithFrame:CGRectMake(15, 15, 260, 20)] autorelease];
        titleLabel.backgroundColor = [UIColor clearColor];
        titleLabel.font = [UIFont systemFontOfSize:14];
        titleLabel.tag = 1;
        [cell.contentView addSubview:titleLabel];
    }
    
    UILabel* titleLabel = (UILabel*)[cell viewWithTag:1];
    
    MMGroupInfo* groupInfo = [groupList_ objectAtIndex:indexPath.row];
    if (indexPath.row == 0) {
        titleLabel.text = @"全部分享";
    } else {
        titleLabel.text = groupInfo.groupName;
    }
    
    return cell;
}

@end
