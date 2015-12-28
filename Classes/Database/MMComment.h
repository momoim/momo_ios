//
//  MMComment.h
//  Db
//
//  Created by wangsc on 10-12-27.
//  Copyright 2010 ND. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MMModel.h"
#import "DbStruct.h"

@interface MMComment : MMModel {

}

+ (id)instance;

- (MMErrorType)insertComment:(MMCommentInfo*)commentInfo;

- (MMErrorType)saveComment:(MMCommentInfo*)commentInfo;

- (NSArray*)getCommentListByStatusId:(NSString*)statusId ownerId:(NSUInteger)ownerId;

- (BOOL)isCommentExist:(NSString*)commentId ownerId:(NSUInteger)ownerId withError:(MMErrorType*)error;

- (MMCommentInfo*)commentInfoFromPLResultSet:(id)object;

- (MMCommentInfo*)getComment:(NSString*)commentId ownerId:(NSUInteger)ownerId;

- (MMErrorType)deleteCommentByStatusId:(NSString*)statusId ownerId:(NSUInteger)ownerId;

- (MMErrorType)deleteCommentByCommentId:(NSString*)commentId ownerId:(NSUInteger)ownerId;

- (MMErrorType)removeAllComment:(NSUInteger)ownerId;

@end
