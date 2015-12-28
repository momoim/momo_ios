//
//  MMDraftDataSource.m
//  momo
//
//  Created by wangsc on 11-3-1.
//  Copyright 2011 ND. All rights reserved.
//

#import "MMDraftMgr.h"
#import "MMGlobalData.h"
#import "MMGlobalPara.h"
#import "MMDraft.h"
#import "MMDraftCell.h"
#import "MMUploadQueue.h"
#import "MMMessageViewController.h"
#import "MMLoginService.h"

static MMDraftMgr* instance = nil;

@implementation MMDraftMgr
@synthesize draftArray, draftDelegate, draftCommentArray;

+ (MMDraftMgr*)shareInstance {
	if (!instance) {
		instance = [[MMDraftMgr alloc] init];
	}
	return instance;
}

NSInteger draftInfoCompare(MMDraftInfo* draftInfo1, MMDraftInfo* draftInfo2, void* context) {
	if (draftInfo1.createDate > draftInfo2.createDate) {
		return NSOrderedAscending;
	} 
	else if (draftInfo1.createDate < draftInfo2.createDate) {
		return NSOrderedDescending;
	} 
	else {
		return NSOrderedSame;
	}
}

- (id)init {
	if (self = [super init]) {
		[self willChangeValueForKey:@"draftArray"];
		self.draftArray = [[MMDraft instance] getDraftListWithoutComment:[[MMLoginService shareInstance] getLoginUserId]];
		[draftArray sortUsingFunction:draftInfoCompare context:nil];
		[self didChangeValueForKey:@"draftArray"];
		
        [[MMDraft instance] clearCommentDraft]; //清空评论草稿
		self.draftCommentArray = [NSMutableArray array];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reset) name:kMMUserLogout object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadDraftList) name:kMMUserLogin object:nil];
	}
	return self;
}

- (void)reset {
	[self.draftArray removeAllObjects];
	[self.draftCommentArray removeAllObjects];
}

- (void)reloadDraftList {
	[self willChangeValueForKey:@"draftArray"];
	self.draftArray = [[MMDraft instance] getDraftListWithoutComment:[[MMLoginService shareInstance] getLoginUserId]];
	[draftArray sortUsingFunction:draftInfoCompare context:nil];
	[self didChangeValueForKey:@"draftArray"];
	self.draftCommentArray = [NSMutableArray array];
}

- (void)deleteDraftInfo:(MMDraftInfo*)draftToDelete {
	[[MMUploadQueue shareInstance] stopUpload:draftToDelete.draftId];
	
	[[MMDraft instance] deleteDraft:draftToDelete.draftId];
	
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:kMMDraftRemoved object:draftToDelete];
    });
	
	if (draftToDelete.draftType == draftComment) {
		for (NSUInteger i = 0; i < draftCommentArray.count; i++) {
			MMDraftInfo* draftInfo = [draftCommentArray objectAtIndex:i];
			if (draftInfo.draftId == draftToDelete.draftId) {
				[draftCommentArray removeObjectAtIndex:i];
			}
			break;
		}
	} else {
		for (NSUInteger i = 0; i < draftArray.count; i++) {
			MMDraftInfo* draftInfo = [draftArray objectAtIndex:i];
			if (draftInfo.draftId == draftToDelete.draftId) {
				[self willChangeValueForKey:@"draftArray"];
				[draftArray removeObjectAtIndex:i];
				[self didChangeValueForKey:@"draftArray"];
				
				NSIndexPath* indexPath = [NSIndexPath indexPathForRow:i inSection:0];
				if (draftDelegate && [(NSObject*)draftDelegate respondsToSelector:@selector(draftDeleted:)]) {
					[draftDelegate draftDeleted:indexPath];
				}
				break;
			}
		}
	}
}

- (void)clearDraftBox {
	[self willChangeValueForKey:@"draftArray"];
	for (NSInteger i = (int)draftArray.count - 1; i >= 0; --i) {
		MMDraftInfo* draftInfo = [draftArray objectAtIndex:i];
		[self deleteDraftInfo:draftInfo];
	}
	[self didChangeValueForKey:@"draftArray"];
	[draftCommentArray removeAllObjects];
}

- (void)insertDraftInfo:(MMDraftInfo*)draftInfo {
    draftInfo.draftId = [[MMDraft instance] insertDraft:draftInfo];
	if (draftInfo.draftType == draftComment) {
		[draftCommentArray insertObject:draftInfo atIndex:0];
	} else {
		[self willChangeValueForKey:@"draftArray"];
		[draftArray insertObject:draftInfo atIndex:0];
		[self didChangeValueForKey:@"draftArray"];
		
		NSIndexPath* indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
		if (draftDelegate && [(NSObject*)draftDelegate respondsToSelector:@selector(draftInserted:)]) {
			[draftDelegate draftInserted:indexPath];
		}
	}
}

- (MMDraftInfo*)getDraftInfo:(NSUInteger)draftId {
	for (NSUInteger i = 0; i < draftArray.count; i++) {
		MMDraftInfo* draftInfo = [draftArray objectAtIndex:i];
		if (draftInfo.draftId == draftId) {
			return draftInfo;
		}
	}
	
	for (NSUInteger i = 0; i < draftCommentArray.count; i++) {
		MMDraftInfo* draftInfo = [draftCommentArray objectAtIndex:i];
		if (draftInfo.draftId == draftId) {
			return draftInfo;
		}
	}
	return nil;
}

- (void)uploadDraftWillStart:(MMDraftInfo *)draftInfo {
	draftInfo.uploadStatus = uploadWait;
	[self changeDraftStatus:draftInfo];
	
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:kMMDraftStartUpload object:draftInfo];
    });
	
	[[MMUploadQueue shareInstance] addUploadTask:draftInfo];
}

- (void)insertAndUploadNewDraft:(MMDraftInfo*)draftInfo {
	[self insertDraftInfo:draftInfo];
	
	[self uploadDraftWillStart:draftInfo];
}

- (void)stopUploadDraft:(MMDraftInfo*)draftInfo {
	draftInfo.uploadStatus = uploadNone;
	[[MMUploadQueue shareInstance] stopUpload:draftInfo.draftId];
	
	if (draftInfo.draftType != draftComment) {
		NSIndexPath* stoppedDraftIndex = [self getDraftIndexPath:draftInfo.draftId];
		if (draftDelegate && [(NSObject*)draftDelegate respondsToSelector:@selector(draftNeedRefresh:)]) {
			[draftDelegate draftNeedRefresh:stoppedDraftIndex];
		}
	}
	
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:kMMDraftRemoved object:draftInfo];
    });
}

- (void)resendDraft:(MMDraftInfo*)draftInfo {
	[self uploadDraftWillStart:draftInfo];
}

- (void)updateDraftInfo:(MMDraftInfo*)newDraftInfo {
	[[MMDraft instance] saveDraft:newDraftInfo];
	
	for (NSUInteger i = 0; i < draftArray.count; i++) {
		MMDraftInfo* draftInfo = [draftArray objectAtIndex:i];
		if (draftInfo.draftId == newDraftInfo.draftId) {
			[draftArray replaceObjectAtIndex:i withObject:newDraftInfo];
			[[MMDraft instance] saveDraft:newDraftInfo];
			
			NSIndexPath* indexPath = [NSIndexPath indexPathForRow:i inSection:0];
			if (draftDelegate && [(NSObject*)draftDelegate respondsToSelector:@selector(draftNeedRefresh:)]) {
				[draftDelegate draftNeedRefresh:indexPath];
			}
			
			break;
		}
	}
}

- (void)changeDraftStatus:(MMDraftInfo*)newDraftInfo {
	if (newDraftInfo.draftType == draftComment) {
		for (NSUInteger i = 0; i < draftCommentArray.count; i++) {
			MMDraftInfo* draftInfo = [draftCommentArray objectAtIndex:i];
			if (draftInfo.draftId == newDraftInfo.draftId) {
				draftInfo.uploadStatus = newDraftInfo.uploadStatus;
				
				dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:kMMDraftStatusChanged object:draftInfo];
				});
				
				if (draftInfo.uploadStatus == uploadSuccess) {
					[self deleteDraftInfo:draftInfo];
				}
				break;
			}
		}
	} else {
		for (NSUInteger i = 0; i < draftArray.count; i++) {
			MMDraftInfo* draftInfo = [draftArray objectAtIndex:i];
			if (draftInfo.draftId == newDraftInfo.draftId) {
				draftInfo.uploadStatus = newDraftInfo.uploadStatus;
				NSIndexPath* indexPath = [NSIndexPath indexPathForRow:i inSection:0];
				if (draftDelegate && [(NSObject*)draftDelegate respondsToSelector:@selector(draftNeedRefresh:)]) {
					[draftDelegate draftNeedRefresh:indexPath];
				}
				
				dispatch_async(dispatch_get_main_queue(), ^{
					[[NSNotificationCenter defaultCenter] postNotificationName:kMMDraftStatusChanged object:draftInfo];
				});
				
				if (draftInfo.uploadStatus == uploadSuccess) {
					[self deleteDraftInfo:draftInfo];
				}
				break;
			}
		}
	}
}

- (NSIndexPath*)getDraftIndexPath:(NSUInteger)draftId {
	for (NSUInteger i = 0; i < draftArray.count; i++) {
		MMDraftInfo* draftInfo = [draftArray objectAtIndex:i];
		if (draftInfo.draftId == draftId) {
			NSIndexPath* indexPath = [NSIndexPath indexPathForRow:i inSection:0];
			return indexPath;
		}
	}
	return nil;
}

- (void)dealloc {
	[draftArray release];
	[super dealloc];
}

#pragma mark UITableViewDelegate
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return draftArray.count;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	MMDraftCell* cell = (MMDraftCell*)[tableView dequeueReusableCellWithIdentifier:@"MMDraftCell"];
	if (cell == nil) {
		cell = [[[MMDraftCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"MMDraftCell"] autorelease];
	}
	
	[cell setDraftInfo:[draftArray objectAtIndex:indexPath.row]];
	return cell;
}

- (void)tableView:(UITableView *)tableView 
	commitEditingStyle:(UITableViewCellEditingStyle)editingStyle 
	forRowAtIndexPath:(NSIndexPath *)indexPath {
	switch (editingStyle) {
		case UITableViewCellEditingStyleDelete:
		{
			[self deleteDraftInfo:[draftArray objectAtIndex:indexPath.row]];
		}
			break;
		default:
			break;
	}
}

@end
