//
//  MMGroupListMgr.h
//  momo
//
//  Created by  on 12-7-23.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DbStruct.h"

@interface MMGroupListMgr : NSObject {
    NSArray* groupList_;
    BOOL isRefreshing_;
}
@property (nonatomic, retain) NSArray* groupList;
@property (nonatomic) BOOL isRefreshing;

+ (MMGroupListMgr*)shareInstance;

- (void)refreshGroupOnSuccess:(BKBlock)successBlock
                     onFailed:(BKBlock)failBlock;

- (MMGroupInfo*)groupInfoByGroupID:(NSInteger)groupID;

@end
