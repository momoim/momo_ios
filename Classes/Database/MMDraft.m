//
//  MMDraft.m
//  momo
//
//  Created by wangsc on 11-2-11.
//  Copyright 2011 ND. All rights reserved.
//

#import "MMDraft.h"
#import "SBJSON.h"

@implementation MMDraft

+ (id)instance {
	static id _instance = nil;
    @synchronized(self) {
        if(_instance == nil) 
            _instance = [[self class] new];
    }
    return _instance;
}

- (NSInteger)getLastInsertId:(MMErrorType*)error{
    // 错误码
    MMErrorType ret = MM_DB_OK;
    NSInteger last_insert_id = 0;
    
    NSError* nserror = nil;
    
    PLResultSetStatus status;
    do{
        // 如果数据没打开
        if(![[self db] goodConnection]) {
            ret = MM_DB_FAILED_OPEN;
            break;
        }
        
        // 返回结果
        id<PLResultSet> results = [[self db] executeQueryAndReturnError:&nserror statement:@"SELECT last_insert_rowid() last_insert_id "];
		
        // 如果出错        
        if(nserror && [nserror code] != SQLITE_OK) {
            ret = MM_DB_FAILED_QUERY;
            break;
        }
        
        status = [results nextAndReturnError:nil];
        
        // 循环返回结果
        if(status) {
            last_insert_id = [results intForColumn:@"last_insert_id"];
        }
        [results close];
    }
    while(0);
    
    // 返回错误码
    if(error != nil)
        *error = ret;
    
    return last_insert_id;
}

- (NSInteger)insertDraft:(MMDraftInfo*)draftInfo {
	if ([self saveDraft:draftInfo]) {
		return 0;
	}
		 
	return [self getLastInsertId:nil];
}

- (MMErrorType)saveDraft:(MMDraftInfo*)draftInfo {
		// 如果数据没打开
	if(![[self db]  goodConnection]) {
		return MM_DB_FAILED_OPEN;
	}
	
	NSString* sql = nil;
	NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
	if (draftInfo.draftId == 0) {
		sql = @"replace into draft (owner_id, text, draft_type, attach_images, group_id, \
		app_type, group_name, retweet_status_id, reply_status_id, reply_comment_id, create_date, sync_to_weibo, extend_json)	\
		values(:owner_id, :text, :draft_type, :attach_images, :group_id, :app_type, :group_name,	\
		:retweet_status_id, :reply_status_id, :reply_comment_id, :create_date, :sync_to_weibo, :extend_json);";
	} else {
		sql = @"replace into draft (draft_id, owner_id, text, draft_type, attach_images, group_id, \
		app_type, group_name, retweet_status_id, reply_status_id, reply_comment_id, create_date, sync_to_weibo, extend_json)	\
		values(:draft_id, :owner_id, :text, :draft_type, :attach_images, :group_id, :app_type, :group_name,	\
		:retweet_status_id, :reply_status_id, :reply_comment_id, :create_date, :sync_to_weibo, :extend_json);";
		[parameters setObject:[NSNumber numberWithInt:draftInfo.draftId] forKey:@"draft_id"];
	}
	
	[parameters setObject:[NSNumber numberWithInt:draftInfo.ownerId] forKey:@"owner_id"];
	[parameters setObject:PARSE_NULL_STR(draftInfo.text) forKey:@"text"];
	[parameters setObject:[NSNumber numberWithInt:draftInfo.draftType] forKey:@"draft_type"];
	[parameters setObject:[NSNumber numberWithInt:draftInfo.groupId] forKey:@"group_id"];
	[parameters setObject:[NSNumber numberWithInt:draftInfo.appType] forKey:@"app_type"];
	[parameters setObject:PARSE_NULL_STR(draftInfo.groupName) forKey:@"group_name"];
	[parameters setObject:PARSE_NULL_STR(draftInfo.retweetStatusId) forKey:@"retweet_status_id"];
	[parameters setObject:PARSE_NULL_STR(draftInfo.replyStatusId) forKey:@"reply_status_id"];
	[parameters setObject:PARSE_NULL_STR(draftInfo.replyCommentId) forKey:@"reply_comment_id"];
	[parameters setObject:[NSNumber numberWithInt:draftInfo.createDate] forKey:@"create_date"];
	[parameters setObject:[NSNumber numberWithBool:draftInfo.syncToWeibo] forKey:@"sync_to_weibo"];
    
    SBJSON* sbjson = [[SBJSON alloc] init];
	NSString* extendJson = [sbjson stringWithObject:draftInfo.extendInfo];
	[sbjson release];
	
	[parameters setObject:PARSE_NULL_STR(extendJson) forKey:@"extend_json"];

		//拼接附件图片URL
	NSMutableString* attachImageUrl = [NSMutableString stringWithFormat:@""];
	for (NSString *imageUrl in draftInfo.attachImagePaths) {
		if (attachImageUrl.length == 0) {
			[attachImageUrl appendString:imageUrl];
		}
		else {
			[attachImageUrl appendFormat:@"|%@", imageUrl];
		}
	}
	
	if (attachImageUrl == nil) {
		[parameters setObject:[NSNull null] forKey:@"attach_images"];
	} else {
		[parameters setObject:attachImageUrl forKey:@"attach_images"];
	}
	
	
	id<PLPreparedStatement> stmt = [[self db]  prepareStatement: sql];
	
		// 绑定参数
	[stmt bindParameterDictionary:parameters];		
	
		// 如果执行失败
	if(![stmt executeUpdate]) {
		
		return MM_DB_FAILED_INVALID_STATEMENT;
	}
	
	
	return MM_DB_OK;
}

- (MMErrorType)deleteDraft:(NSInteger)draftId {
		// 如果数据没打开
	if(![[self db]  goodConnection]) {
		return MM_DB_FAILED_OPEN;
	}
	
	NSString* sql = [NSString stringWithFormat:@"delete from draft where draft_id = %d", draftId];
	
	
	id<PLPreparedStatement> stmt = [[self db]  prepareStatement:sql];   
	
        // 如果执行失败
	if(![stmt executeUpdate]) {
		
		return MM_DB_FAILED_INVALID_STATEMENT;
	}
	
	
	return MM_DB_OK;
}

- (NSMutableArray*)getDraftList:(NSUInteger)ownerId {
		// 如果数据没打开
	if(![[self db]  goodConnection]) {
		return nil;
	}
	
	NSError* outError = nil;
	NSString * sql = @"select * from draft where owner_id=?;";
	id<PLResultSet> results = [[self db]  executeQueryAndReturnError:&outError statement:sql
							   , [NSNumber numberWithUnsignedInteger:ownerId]];        
	if(SQLITE_OK != [outError code]) {
		return nil;
	}
	
	NSMutableArray* draftArray = [NSMutableArray array];
	PLResultSetStatus status = [results nextAndReturnError:nil];
	while (status) {
		MMDraftInfo* draftInfo = [self draftInfoFromPLResultSet:results];
		[draftArray addObject:draftInfo];
		
		status = [results nextAndReturnError:nil];
	}
	[results close];
	
	return draftArray;
}

- (NSMutableArray*)getDraftListWithoutComment:(NSUInteger)ownerId {
	// 如果数据没打开
	if(![[self db]  goodConnection]) {
		return nil;
	}
	
	NSError* outError = nil;
	NSString * sql = [NSString stringWithFormat:@"select * from draft where owner_id=%u and draft_type <> %d;",
								ownerId, draftComment];
	id<PLResultSet> results = [[self db]  executeQueryAndReturnError:&outError statement:sql];        
	if(SQLITE_OK != [outError code]) {
		return nil;
	}
	
	NSMutableArray* draftArray = [NSMutableArray array];
	PLResultSetStatus status = [results nextAndReturnError:nil];
	while (status) {
		MMDraftInfo* draftInfo = [self draftInfoFromPLResultSet:results];
		[draftArray addObject:draftInfo];
		
		status = [results nextAndReturnError:nil];
	}
	[results close];
	
	return draftArray;
}

- (MMErrorType)clearCommentDraft {
	// 如果数据没打开
	if(![[self db]  goodConnection]) {
		return MM_DB_FAILED_OPEN;
	}
	
	NSString* sql = [NSString stringWithFormat:@"delete from draft where draft_type = %d", draftComment];
	
	
	id<PLPreparedStatement> stmt = [[self db]  prepareStatement:sql];   
	
	// 如果执行失败
	if(![stmt executeUpdate]) {
		
		return MM_DB_FAILED_INVALID_STATEMENT;
	}
	
	
	return MM_DB_OK;
}

- (MMDraftInfo*)draftInfoFromPLResultSet:(id)object {
	id<PLResultSet> results = object;
	
	MMDraftInfo* draftInfo = [[[MMDraftInfo alloc] init] autorelease];
	draftInfo.ownerId =  [results intForColumn:@"owner_id"];
	draftInfo.text = [results stringForColumn:@"text"];
	draftInfo.draftType = [results intForColumn:@"draft_type"];
	draftInfo.groupId =  [results intForColumn:@"group_id"];
	draftInfo.appType =  [results intForColumn:@"app_type"];
	draftInfo.groupName = [results stringForColumn:@"group_name"];
	draftInfo.retweetStatusId = [results stringForColumn:@"retweet_status_id"];
	draftInfo.replyStatusId = [results stringForColumn:@"reply_status_id"];
	draftInfo.replyCommentId = [results stringForColumn:@"reply_comment_id"];
	draftInfo.draftId =  [results intForColumn:@"draft_id"];
	draftInfo.createDate = [results	intForColumn:@"create_date"];
	draftInfo.syncToWeibo = [results boolForColumn:@"sync_to_weibo"];
	
	NSString* strUrls = [results stringForColumn:@"attach_images"];
	if (strUrls.length > 0) {
		draftInfo.attachImagePaths = [strUrls componentsSeparatedByString:@"|"];
	}
    
    SBJSON* sbsjon = [[[SBJSON alloc] init] autorelease];
	NSString* extendJson = [results stringForColumn:@"extend_json"];
    if (extendJson.length > 0) {
        NSDictionary* extendDict = [sbsjon objectWithString:extendJson];
        draftInfo.extendInfo = [NSMutableDictionary dictionaryWithDictionary:extendDict];
    }
	
	return draftInfo;
}

- (MMDraftInfo*)getDraft:(NSUInteger)draftId {
	NSError* outError = nil;
	MMDraftInfo* draftInfo = nil;
	// 如果数据没打开
	do {
		if(![[self db]  goodConnection]) {
            break;
		}
		
		NSString* sql = @"select * from draft where draft_id=?;";
		id<PLResultSet> results = [[self db]  executeQueryAndReturnError:&outError statement:sql, 
								   [NSNumber numberWithLongLong:draftId]];        
		if(SQLITE_OK != [outError code]) {
            break;
		}
		
		PLResultSetStatus status = [results nextAndReturnError:nil];
		if(status) {
			draftInfo = [self draftInfoFromPLResultSet:results];
		}
		[results close];
	}
    while(0);
	
	return draftInfo;
}

@end
