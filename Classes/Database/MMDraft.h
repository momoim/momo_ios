//
//  MMDraft.h
//  momo
//
//  Created by wangsc on 11-2-11.
//  Copyright 2011 ND. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MMModel.h"
#import "DbStruct.h"

@interface MMDraft : MMModel {

}

+ (id)instance;

- (NSInteger)insertDraft:(MMDraftInfo*)draftInfo;

- (MMErrorType)deleteDraft:(NSInteger)draftId;

- (MMErrorType)saveDraft:(MMDraftInfo*)draftInfo;

- (NSMutableArray*)getDraftList:(NSUInteger)ownerId;

- (MMErrorType)clearCommentDraft;

- (NSMutableArray*)getDraftListWithoutComment:(NSUInteger)ownerId;

- (MMDraftInfo*)draftInfoFromPLResultSet:(id)object;

- (MMDraftInfo*)getDraft:(NSUInteger)draftId;

@end
