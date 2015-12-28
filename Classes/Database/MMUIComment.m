//
//  MMUIComment.m
//  Db
//
//  Created by wangsc on 10-12-27.
//  Copyright 2010 ND. All rights reserved.
//

#import "MMUIComment.h"


@implementation MMUIComment

+ (id)instance {
	static id _instance = nil;
    @synchronized(self) {
        if(_instance == nil) 
            _instance = [[self class] new];
    }
    return _instance;
}

- (MMErrorType)insertComment:(MMCommentInfo*)commentInfo {
	return [[MMComment instance] insertComment:commentInfo];
}

- (MMErrorType)saveComment:(MMCommentInfo*)commentInfo {
	return [[MMComment instance] saveComment:commentInfo];
}

- (BOOL)isCommentExist:(NSString*)commentId ownerId:(NSUInteger)ownerId {
	MMErrorType error;
	return [[MMComment instance] isCommentExist:commentId ownerId:ownerId withError:&error];
}

- (NSArray*)getCommentByObjid:(NSString*)objid typeId:(NSUInteger)typeId ownerId:(NSUInteger)ownerId {
	return [[MMComment instance] getCommentByObjid:objid typeId:typeId ownerId:ownerId];
}

- (NSArray*)getCommentListByStatusId:(NSString*)statusId ownerId:(NSUInteger)ownerId {
	return [[MMComment instance] getCommentListByStatusId:statusId ownerId:ownerId];
}

- (MMCommentInfo*)getComment:(NSString*)commentId ownerId:(NSUInteger)ownerId {
	return [[MMComment instance] getComment:commentId ownerId:ownerId];
}

@end
