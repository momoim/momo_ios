//
//  MMSelectGroupView.h
//  momo
//
//  Created by  on 12-7-26.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DbStruct.h"

@class MMSelectGroupView;
@protocol MMSelectGroupViewDelegate <NSObject>

@optional
- (void)selectGroupView:(MMSelectGroupView*)selectGroupView didSelectGroup:(MMGroupInfo*)groupInfo;

- (void)selectGroupViewDidChangePhotoShowType:(MMSelectGroupView*)selectGroupView;

@end

@interface MMSelectGroupView : UIView <UITableViewDelegate, UITableViewDataSource> {
    UITableView* tableView_;
    
    NSMutableArray* groupList_;
    
    id<MMSelectGroupViewDelegate> delegate_;
}
@property (nonatomic) BOOL showPhotoTypeSwitcher;  //选择图片显示模式
@property (nonatomic, assign) id<MMSelectGroupViewDelegate> delegate;

@end
