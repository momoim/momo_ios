//
//  MMGroupListMgr.m
//  momo
//
//  Created by  on 12-7-23.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "MMGroupListMgr.h"
#import "MMMessageSyncer.h"

@implementation MMGroupListMgr
@synthesize groupList = groupList_;
@synthesize isRefreshing = isRefreshing_;

+ (MMGroupListMgr*)shareInstance {
    static MMGroupListMgr* instance = nil;
    if (!instance) {
        @synchronized (self) {
            if (!instance) {
                instance = [[MMGroupListMgr alloc] init];
            }
        }
    }
    return instance;
}

- (void)dealloc {
    self.groupList = nil;
    [super dealloc];
}

- (void)refreshGroupOnSuccess:(BKBlock)successBlock
                     onFailed:(BKBlock)failBlock {
    if (isRefreshing_) {
        return;
    }
    isRefreshing_ = YES;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSString* errorString = nil;
        NSArray* groupList = [[MMMessageSyncer shareInstance] getGroupList:&errorString];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!errorString) {
                self.groupList = groupList;
                if (successBlock) {
                    successBlock();
                }
            } else {
                if (failBlock) {
                    failBlock();
                }
            }
            isRefreshing_ = NO;
        });
    });
}

- (MMGroupInfo*)groupInfoByGroupID:(NSInteger)groupID {
    for (MMGroupInfo* groupInfo in groupList_) {
        if (groupInfo.groupId == groupID) {
            return groupInfo;
        }
    }
    return nil;
}

@end
