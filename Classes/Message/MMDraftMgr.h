//
//  MMDraftDataSource.h
//  momo
//
//  Created by wangsc on 11-3-1.
//  Copyright 2011 ND. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MMMessageDelegate.h"

#define kMMDraftStartUpload @"MMDraftStartUpload"
#define kMMDraftRemoved @"MMDraftRemoved"
#define kMMDraftStatusChanged @"MMDraftStatusChanged"

@interface MMDraftMgr : NSObject <UITableViewDataSource>{
	NSMutableArray* draftArray;	//动态，转发
	NSMutableArray* draftCommentArray; //评论，不显示
	
	id<MMDraftBoxDelegate> draftDelegate;
}
@property (nonatomic, retain) NSMutableArray* draftArray;
@property (nonatomic, retain) NSMutableArray* draftCommentArray;
@property (nonatomic, assign) id<MMDraftBoxDelegate> draftDelegate;

+ (MMDraftMgr*)shareInstance;

- (void)reset;

- (void)reloadDraftList;

- (void)deleteDraftInfo:(MMDraftInfo*)draftToDelete;

- (void)clearDraftBox;

- (void)insertDraftInfo:(MMDraftInfo*)draftInfo;

- (MMDraftInfo*)getDraftInfo:(NSUInteger)draftId;

- (void)uploadDraftWillStart:(MMDraftInfo *)draftInfo;

- (void)insertAndUploadNewDraft:(MMDraftInfo*)draftInfo;

- (void)stopUploadDraft:(MMDraftInfo*)draftInfo;

- (void)resendDraft:(MMDraftInfo*)draftInfo;

- (void)updateDraftInfo:(MMDraftInfo*)newDraftInfo;

- (void)changeDraftStatus:(MMDraftInfo*)newDraftInfo;

- (NSIndexPath*)getDraftIndexPath:(NSUInteger)draftId;

@end
