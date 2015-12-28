//
//  MMUIComment.h
//  Db
//
//  Created by wangsc on 10-12-27.
//  Copyright 2010 ND. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MMComment.h"
#import "ErrorType.h"

@interface MMUIComment : NSObject {

}

+ (id)instance;

- (MMErrorType)insertComment:(MMCommentInfo*)commentInfo;

- (MMErrorType)saveComment:(MMCommentInfo*)commentInfo;

- (MMCommentInfo*)getComment:(NSString*)commentId ownerId:(NSUInteger)ownerId;

- (BOOL)isCommentExist:(NSString*)commentId ownerId:(NSUInteger)ownerId;

- (NSArray*)getCommentListByStatusId:(NSString*)statusId ownerId:(NSUInteger)ownerId;

@end
