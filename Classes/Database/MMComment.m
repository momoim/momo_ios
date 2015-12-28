//
//  MMComment.m
//  Db
//
//  Created by wangsc on 10-12-27.
//  Copyright 2010 ND. All rights reserved.
//

#import "MMComment.h"
#import "SBJSON.h"

@implementation MMComment

+ (id)instance {
	static id _instance = nil;
    @synchronized(self) {
        if(_instance == nil) 
            _instance = [[self class] new];
    }
    return _instance;
}

- (MMErrorType)insertComment:(MMCommentInfo*)commentInfo {
	// 如果数据没打开
	if(![[self db]  goodConnection]) {
		return MM_DB_FAILED_OPEN;
	}
	
	MMErrorType ret = MM_DB_OK;
	if ([self isCommentExist:commentInfo.commentId ownerId:commentInfo.ownerId withError:&ret]) {
		return MM_DB_KEY_EXISTED;
	}
	if (ret != MM_DB_OK) {
		return ret;
	}

	return [self saveComment:commentInfo];
}

- (MMErrorType)saveComment:(MMCommentInfo*)commentInfo {
		// 如果数据没打开
	if(![[self db]  goodConnection]) {
		return MM_DB_FAILED_OPEN;
	}
	
	NSString* sql = @"replace into comment (owner_id, comment_id, status_id, uid, real_name, avatar_image_url, text, create_date, source_name, extend_json) \
	values (:owner_id, :comment_id, :status_id, :uid, :real_name, :avatar_image_url, :text, :create_date, :source_name, :extend_json);";
	NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
	[parameters setObject:[NSNumber numberWithInt:commentInfo.ownerId] forKey:@"owner_id"];
	[parameters setObject:PARSE_NULL_STR(commentInfo.commentId) forKey:@"comment_id"];
	[parameters setObject:PARSE_NULL_STR(commentInfo.statusId) forKey:@"status_id"];
	[parameters setObject:[NSNumber numberWithInt:commentInfo.uid] forKey:@"uid"];
	[parameters setObject:PARSE_NULL_STR(commentInfo.realName) forKey:@"real_name"];
	[parameters setObject:PARSE_NULL_STR(commentInfo.avatarImageUrl) forKey:@"avatar_image_url"];
	[parameters setObject:PARSE_NULL_STR(commentInfo.text) forKey:@"text"];
	[parameters setObject:[NSNumber numberWithUnsignedLongLong:commentInfo.createDate] forKey:@"create_date"];
	[parameters setObject:PARSE_NULL_STR(commentInfo.sourceName) forKey:@"source_name"];
	
    // 以后需要扩展的数据都放到json里面
	NSMutableDictionary* extendDict = [NSMutableDictionary dictionary];
    [extendDict setObject:PARSE_NULL_STR(commentInfo.srcText) forKey:@"strText"];
    [extendDict setObject:[NSNumber numberWithBool:commentInfo.ignoreTimeLine] forKey:@"ignore_time_line"];
    
    SBJSON* sbjson = [[SBJSON alloc] init];
	NSString* extendJson = [sbjson stringWithObject:extendDict];
	[sbjson release];
	
	[parameters setObject:PARSE_NULL_STR(extendJson) forKey:@"extend_json"];
	
	id<PLPreparedStatement> stmt = [[self db]  prepareStatement:sql];   
		// 绑定参数
	[stmt bindParameterDictionary:parameters];
	
        // 如果执行失败
	if(![stmt executeUpdate]) {
		
		return MM_DB_FAILED_INVALID_STATEMENT;
	}
	
	
	return MM_DB_OK;
}

- (NSArray*)getCommentListByStatusId:(NSString*)statusId ownerId:(NSUInteger)ownerId {
	// 如果数据没打开
	if(![[self db]  goodConnection]) {
		return nil;
	}
	
	NSError* outError = nil;
	NSString * sql = @"select * from comment where status_id = ? and owner_id = ?;";
	id<PLResultSet> results = [[self db]  executeQueryAndReturnError:&outError statement:sql, 
							   statusId, 
							   [NSNumber numberWithUnsignedInteger:ownerId]];        
	if(SQLITE_OK != [outError code]) {
		return nil;
	}
	
	NSMutableArray* commentArray = [NSMutableArray array];
	PLResultSetStatus status = [results nextAndReturnError:nil];
	while (status) {
		MMCommentInfo* commentInfo = [self commentInfoFromPLResultSet:results];
        if (!commentInfo.ignoreTimeLine) {
            [commentArray addObject:commentInfo];
        }
		
		status = [results nextAndReturnError:nil];
	}
	[results close];
	
	return commentArray;
}

- (MMCommentInfo*)commentInfoFromPLResultSet:(id)object {
	id<PLResultSet> results = object;
	
	MMCommentInfo* commentInfo = [[[MMCommentInfo alloc] init] autorelease];
	commentInfo.ownerId = [results intForColumn:@"owner_id"];
	commentInfo.statusId = [results stringForColumn:@"status_id"];
	commentInfo.commentId = [results stringForColumn:@"comment_id"];
	commentInfo.uid = [results intForColumn:@"uid"];
	commentInfo.realName = [results stringForColumn:@"real_name"];
	commentInfo.avatarImageUrl = [results stringForColumn:@"avatar_image_url"];
	commentInfo.text = [results stringForColumn:@"text"];
	commentInfo.sourceName = [results stringForColumn:@"source_name"];
	commentInfo.createDate = [results bigIntForColumn:@"create_date"];
    
    SBJSON* sbsjon = [[SBJSON alloc] init];
	NSString* extendJson = [results stringForColumn:@"extend_json"];
	NSDictionary* extendDict = [sbsjon objectWithString:extendJson];
	[sbsjon release];
    
    commentInfo.srcText = [extendDict objectForKey:@"strText"];
    commentInfo.ignoreTimeLine = [[extendDict objectForKey:@"ignore_time_line"] boolValue];
    
	return commentInfo;
}

- (BOOL)isCommentExist:(NSString*)commentId ownerId:(NSUInteger)ownerId withError:(MMErrorType*)error {
	MMErrorType ret = MM_DB_OK;
	NSError* outError = [NSError new];
	BOOL isExist = NO;
		// 如果数据没打开
	do {
		if(![[self db]  goodConnection]) {
			ret = MM_DB_FAILED_OPEN;
            break;
		}
		
		NSString* sql = @"select count(*) num from comment where comment_id = ? and owner_id=?;";
		id<PLResultSet> results = [[self db]  executeQueryAndReturnError:&outError statement:sql, 
								   commentId, [NSNumber numberWithUnsignedInteger:ownerId]];        
		if(SQLITE_OK != [outError code]) {
			ret = MM_DB_FAILED_QUERY;
            break;
		}
		
		PLResultSetStatus status = [results nextAndReturnError:nil];
		if(status) {
			NSInteger count = [results intForColumn:@"num"];
			if (count > 0) {
				isExist = (count > 0);
			}
		}
		[results close];
	}
    while(0);
	
	if(error)
        *error = ret;
	
	[outError release];
	return isExist;
}

- (MMCommentInfo*)getComment:(NSString*)commentId ownerId:(NSUInteger)ownerId {
    if (!commentId || commentId.length == 0) {
        return nil;
    }
    
	NSError* outError = [NSError new];
	MMCommentInfo* commentInfo = nil;
		// 如果数据没打开
	do {
		if(![[self db]  goodConnection]) {
            break;
		}
		
		NSString* sql = @"select * from comment where comment_id = ? and owner_id=?;";
		id<PLResultSet> results = [[self db]  executeQueryAndReturnError:&outError statement:sql, 
								   commentId, [NSNumber numberWithUnsignedInteger:ownerId]];        
		if(SQLITE_OK != [outError code]) {
            break;
		}
		
		PLResultSetStatus status = [results nextAndReturnError:nil];
		if(status) {
			commentInfo = [self commentInfoFromPLResultSet:results];
		}
		[results close];
	}
    while(0);
	
	[outError release];
	return commentInfo;
}

- (MMErrorType)deleteCommentByStatusId:(NSString*)statusId ownerId:(NSUInteger)ownerId {
	// 如果数据没打开
	if(![[self db]  goodConnection]) {
		return MM_DB_FAILED_OPEN;
	}
	
	NSString* sql = [NSString stringWithFormat:@"delete from comment where status_id = '%@' and owner_id=%u", 
					 statusId, ownerId];
	
	
	id<PLPreparedStatement> stmt = [[self db]  prepareStatement:sql];   
	
	// 如果执行失败
	if(![stmt executeUpdate]) {
		return MM_DB_FAILED_INVALID_STATEMENT;
	}
	
	return MM_DB_OK;
}

//删除动态中某条评论
- (MMErrorType)deleteCommentByCommentId:(NSString*)commentId ownerId:(NSUInteger)ownerId {
	// 如果数据没打开
	if(![[self db]  goodConnection]) {
		return MM_DB_FAILED_OPEN;
	}
	
	NSString* sql = [NSString stringWithFormat:@"delete from comment where comment_id = '%@' and owner_id=%u", 
					 commentId, ownerId];
	
	
	id<PLPreparedStatement> stmt = [[self db]  prepareStatement:sql];   
	
	// 如果执行失败
	if(![stmt executeUpdate]) {
		return MM_DB_FAILED_INVALID_STATEMENT;
	}
	
	return MM_DB_OK;
}

- (MMErrorType)removeAllComment:(NSUInteger)ownerId {
	// 如果数据没打开
	if(![[self db]  goodConnection]) {
		return MM_DB_FAILED_OPEN;
	}
	
	NSString* sql = [NSString stringWithFormat:@"delete from comment where owner_id=%u", ownerId];
	
	id<PLPreparedStatement> stmt = [[self db]  prepareStatement:sql];   
	
	// 如果执行失败
	if(![stmt executeUpdate]) {
		return MM_DB_FAILED_INVALID_STATEMENT;
	}
	
	return MM_DB_OK;
}

@end
