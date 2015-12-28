//
//  MMMessage.m
//  Db
//
//  Created by wangsc on 10-12-27.
//  Copyright 2010 ND. All rights reserved.
//

#import "MMMessage.h"
#import "SBJSON.h"

@implementation MMMessage

+ (id)instance {
	static id _instance = nil;
    @synchronized(self) {
        if(_instance == nil) 
            _instance = [[self class] new];
    }
    return _instance;
}

- (MMErrorType)insertMessage:(MMMessageInfo*)messageInfo {
	// 如果数据没打开
	if(![[self db]  goodConnection]) {
		return MM_DB_FAILED_OPEN;
	}
	
	MMErrorType ret = MM_DB_OK;
	if ([self isMessageExist:messageInfo.statusId ownerId:messageInfo.ownerId withError:&ret]) {
		return MM_DB_KEY_EXISTED;
	}
	if (ret != MM_DB_OK) {
		return ret;
	}
	
	return [self saveMessage:messageInfo];
}

- (MMErrorType)saveMessage:(MMMessageInfo*)messageInfo {
		// 如果数据没打开
	if(![[self db]  goodConnection]) {
		return MM_DB_FAILED_OPEN;
	}
	
	NSString* sql = @"replace into message (status_id, owner_id, uid, real_name, avatar_image_url, text, create_date, modified_date, \
					liked, like_count, like_list, storaged, source_name, comment_count, recent_comment_id, \
					group_type, group_id, group_name, ignore_date_line, type_id, \
					allow_rt, allow_comment, allow_praise, allow_del, allow_hide, rt_status_id, application_id, application_title, \
					application_title, application_url, extend_json) \
					values (:status_id, :owner_id, :uid, :real_name, :avatar_image_url, :text, :create_date, :modified_date, \
					:liked, :like_count, :like_list, :storaged, :source_name, :comment_count, :recent_comment_id, \
					:group_type, :group_id, :group_name, :ignore_date_line, :type_id, \
					:allow_rt, :allow_comment, :allow_praise, :allow_del, :allow_hide, :rt_status_id, :application_id, :application_title, \
					:application_title, :application_url, :extend_json);";
	
	NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
	[parameters setObject:[NSNumber numberWithInt:messageInfo.ownerId] forKey:@"owner_id"];
	[parameters setObject:PARSE_NULL_STR(messageInfo.statusId) forKey:@"status_id"];
	[parameters setObject:[NSNumber numberWithInt:messageInfo.uid] forKey:@"uid"];
	[parameters setObject:PARSE_NULL_STR(messageInfo.realName) forKey:@"real_name"];
	[parameters setObject:PARSE_NULL_STR(messageInfo.avatarImageUrl) forKey:@"avatar_image_url"];
	[parameters setObject:PARSE_NULL_STR(messageInfo.text) forKey:@"text"];
	[parameters setObject:[NSNumber numberWithInt:messageInfo.createDate] forKey:@"create_date"];
	[parameters setObject:[NSNumber numberWithLongLong:messageInfo.modifiedDate] forKey:@"modified_date"];
	[parameters setObject:[NSNumber numberWithInt:messageInfo.liked] forKey:@"liked"];
	[parameters setObject:[NSNumber numberWithInt:messageInfo.likeCount] forKey:@"like_count"];
	[parameters setObject:PARSE_NULL_STR(messageInfo.likeList) forKey:@"like_list"];
	[parameters setObject:[NSNumber numberWithInt:messageInfo.storaged] forKey:@"storaged"];
	[parameters setObject:PARSE_NULL_STR(messageInfo.sourceName) forKey:@"source_name"];
	[parameters setObject:[NSNumber numberWithInt:messageInfo.commentCount] forKey:@"comment_count"];
	[parameters setObject:PARSE_NULL_STR(messageInfo.recentCommentId) forKey:@"recent_comment_id"];
	[parameters setObject:[NSNumber numberWithInt:messageInfo.groupType] forKey:@"group_type"];
	[parameters setObject:[NSNumber numberWithInt:messageInfo.groupId] forKey:@"group_id"];
	[parameters setObject:PARSE_NULL_STR(messageInfo.groupName) forKey:@"group_name"];
	[parameters setObject:[NSNumber numberWithInt:messageInfo.ignoreDateLine] forKey:@"ignore_date_line"];
	[parameters setObject:[NSNumber numberWithInt:messageInfo.typeId] forKey:@"type_id"];
	[parameters setObject:[NSNumber numberWithBool:messageInfo.allowRetweet] forKey:@"allow_rt"];
	[parameters setObject:[NSNumber numberWithBool:messageInfo.allowComment] forKey:@"allow_comment"];
	[parameters setObject:[NSNumber numberWithBool:messageInfo.allowPraise] forKey:@"allow_praise"];
	[parameters setObject:[NSNumber numberWithBool:messageInfo.allowDel] forKey:@"allow_del"];
	[parameters setObject:[NSNumber numberWithBool:messageInfo.allowHide] forKey:@"allow_hide"];
	[parameters setObject:PARSE_NULL_STR(messageInfo.retweetStatusId) forKey:@"rt_status_id"];
	[parameters setObject:[NSNumber numberWithUnsignedLongLong:messageInfo.applicationId] forKey:@"application_id"];
	[parameters setObject:PARSE_NULL_STR(messageInfo.applicationTitle) forKey:@"application_title"];
	[parameters setObject:PARSE_NULL_STR(messageInfo.applicationUrl) forKey:@"application_url"];
	
	// 以后需要扩展的数据都放到json里面
	NSMutableDictionary* extendDict = [NSMutableDictionary dictionary];

	//组合附件信息
	NSMutableArray* accessoryDictArray = [NSMutableArray array];
	for (MMAccessoryInfo* accessoryInfo in messageInfo.accessoryArray) {
		NSDictionary* accessoryDictInfo = [accessoryInfo toDict];
		[accessoryDictArray addObject:accessoryDictInfo];
	}
	[extendDict setObject:accessoryDictArray forKey:@"accessory"];
	[extendDict setObject:[NSNumber numberWithBool:messageInfo.syncToSinaWeibo] forKey:@"syncToSinaWeibo"];
	[extendDict setObject:[NSNumber numberWithBool:messageInfo.syncToSinaWeiboSuccess] forKey:@"syncToSinaWeiboSuccess"];
    [extendDict setObject:[NSNumber numberWithBool:messageInfo.isLongText] forKey:@"isLongText"];
    [extendDict setObject:PARSE_NULL_STR(messageInfo.longTextUrl) forKey:@"longTextUrl"];
    
    //location
    [extendDict setObject:[NSNumber numberWithDouble:messageInfo.longitude] forKey:@"longitude"];
    [extendDict setObject:[NSNumber numberWithDouble:messageInfo.latitude] forKey:@"latitude"];
    [extendDict setObject:PARSE_NULL_STR(messageInfo.address) forKey:@"address"];
	
    //长文本
    [extendDict setObject:PARSE_NULL_STR(messageInfo.longText) forKey:@"longText"];
    
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

- (NSMutableArray*)getMessageList:(NSUInteger)ownerId {
		// 如果数据没打开
	if(![[self db]  goodConnection]) {
		return nil;
	}
	
	NSError* outError = nil;
	NSString * sql = @"select * from message where owner_id=? order by modified_date DESC;";
	id<PLResultSet> results = [[self db]  executeQueryAndReturnError:&outError statement:sql
							   , [NSNumber numberWithUnsignedInteger:ownerId]];        
	if(SQLITE_OK != [outError code]) {
		return nil;
	}
	
	NSMutableArray* messageArray = [NSMutableArray array];
	PLResultSetStatus status = [results nextAndReturnError:nil];
	while (status) {
		MMMessageInfo* messageInfo = [self messageInfoFromPLResultSet:results];
		[messageArray addObject:messageInfo];
		
		status = [results nextAndReturnError:nil];
	}
	[results close];
	
	return messageArray;
}

- (NSInteger)getMessageCount:(NSUInteger)ownerId {
	// 如果数据没打开
	if(![[self db]  goodConnection]) {
		return 0;
	}
	
	NSError* outError = nil;
	NSString * sql = @"select count(*) as num from message where owner_id=? and ignore_date_line=0;";
	id<PLResultSet> results = [[self db]  executeQueryAndReturnError:&outError statement:sql
							   , [NSNumber numberWithUnsignedInteger:ownerId]];        
	if(SQLITE_OK != [outError code]) {
		return 0;
	}
	
	NSInteger messageCount = 0;
	PLResultSetStatus status = [results nextAndReturnError:nil];
	if (status) {
		messageCount = [results intForColumn:@"num"];
	}
	[results close];
	
	return messageCount;
}

- (NSMutableArray*)getLimitMessageList:(NSUInteger)count startTime:(uint64_t)startTime ownerId:(NSUInteger)ownerId {
		// 如果数据没打开
	if(![[self db]  goodConnection]) {
		return nil;
	}
	
	NSError* outError = nil;
	NSString * sql = nil;
	if (startTime == 0) {
		sql = [NSString stringWithFormat:@"select * from message where owner_id=%u and ignore_date_line=0 order by modified_date DESC limit %d;", 
											ownerId, count];
	} else {
		sql = [NSString stringWithFormat:@"select * from message where owner_id=%u and ignore_date_line=0 and modified_date < %llu \
											order by modified_date DESC limit %d;", ownerId, startTime, count];
	}
	
	id<PLResultSet> results = [[self db]  executeQueryAndReturnError:&outError statement:sql];        
	if(SQLITE_OK != [outError code]) {
		return nil;
	}
	
	NSMutableArray* messageArray = [NSMutableArray array];
	PLResultSetStatus status = [results nextAndReturnError:nil];
	while (status) {
		MMMessageInfo* messageInfo = [self messageInfoFromPLResultSet:results];
		[messageArray addObject:messageInfo];
		
		status = [results nextAndReturnError:nil];
	}
	[results close];
	
	return messageArray;
}

- (MMMessageInfo*)getMessage:(NSString*)statusId ownerId:(NSUInteger)ownerId {
	// 如果数据没打开
	if(![[self db]  goodConnection]) {
		return nil;
	}
	
	NSError* outError = nil;
	NSString * sql = @"select * from message where status_id=? and owner_id=?;";
	id<PLResultSet> results = [[self db]  executeQueryAndReturnError:&outError statement:sql, statusId, 
							   [NSNumber numberWithUnsignedInteger:ownerId]];   
	if(SQLITE_OK != [outError code]) {
		return nil;
	}
	
	MMMessageInfo* messageInfo = nil;
	PLResultSetStatus status = [results nextAndReturnError:nil];
	if(status) {
		messageInfo = [self messageInfoFromPLResultSet:results];
	}
	[results close];
	
	return messageInfo;
}

- (BOOL)isMessageExist:(NSString*)statusId ownerId:(NSUInteger)ownerId withError:(MMErrorType*)error {
	MMErrorType ret = MM_DB_OK;
	NSError* outError = nil;
	BOOL isExist = NO;
	// 如果数据没打开
	do {
		if(![[self db]  goodConnection]) {
			ret = MM_DB_FAILED_OPEN;
            break;
		}
		
		NSString* sql = @"select count(*) num from message where status_id=? and owner_id=?;";
		id<PLResultSet> results = [[self db]  executeQueryAndReturnError:&outError statement:sql, statusId,  
								   [NSNumber numberWithUnsignedInteger:ownerId]];        
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
	
	return isExist;
}

- (MMMessageInfo*)messageInfoFromPLResultSet:(id)object {
	id<PLResultSet> results = object;
	
	MMMessageInfo* messageInfo = [[[MMMessageInfo alloc] init] autorelease];
	messageInfo.statusId = [results stringForColumn:@"status_id"];
	messageInfo.ownerId = [results intForColumn:@"owner_id"];
	messageInfo.uid = [results intForColumn:@"uid"];
	messageInfo.realName = [results stringForColumn:@"real_name"];
	messageInfo.avatarImageUrl = [results stringForColumn:@"avatar_image_url"];
	messageInfo.text = [results stringForColumn:@"text"];
	messageInfo.createDate = [results intForColumn:@"create_date"];
	messageInfo.modifiedDate = [results bigIntForColumn:@"modified_date"];
	messageInfo.liked = [results intForColumn:@"liked"];
	messageInfo.likeCount = [results intForColumn:@"like_count"];
	messageInfo.likeList = [results stringForColumn:@"like_list"];
	messageInfo.storaged = [results intForColumn:@"storaged"];
	messageInfo.sourceName = [results stringForColumn:@"source_name"];
	messageInfo.commentCount = [results intForColumn:@"comment_count"];
	messageInfo.recentCommentId = [results stringForColumn:@"recent_comment_id"];
	
	messageInfo.groupType = [results intForColumn:@"group_type"];
	messageInfo.groupId = [results intForColumn:@"group_id"];
	messageInfo.typeId = [results intForColumn:@"type_id"];
	
	if (![results isNullForColumn:@"group_name"]) {
		messageInfo.groupName = [results stringForColumn:@"group_name"];
	}

	messageInfo.ignoreDateLine = [results intForColumn:@"ignore_date_line"];
	
	messageInfo.allowRetweet = [results boolForColumn:@"allow_rt"];
	messageInfo.allowComment = [results boolForColumn:@"allow_comment"];
	messageInfo.allowPraise = [results boolForColumn:@"allow_praise"];
	messageInfo.allowDel = [results boolForColumn:@"allow_del"];
	messageInfo.allowHide = [results boolForColumn:@"allow_hide"];
	
	messageInfo.retweetStatusId = [results stringForColumn:@"rt_status_id"];
	messageInfo.applicationId = [results bigIntForColumn:@"application_id"];
	messageInfo.applicationTitle = [results stringForColumn:@"application_title"];
	messageInfo.applicationUrl = [results stringForColumn:@"application_url"];
	
	
	SBJSON* sbsjon = [[SBJSON alloc] init];
	NSString* extendJson = [results stringForColumn:@"extend_json"];
	NSDictionary* extendDict = [sbsjon objectWithString:extendJson];
	[sbsjon release];
	
	if (extendDict && [extendDict isKindOfClass:[NSDictionary class]]) {
		NSArray* accessoryDictArray = [extendDict objectForKey:@"accessory"];
		if (accessoryDictArray && 
			[accessoryDictArray isKindOfClass:[NSArray class]] && 
			accessoryDictArray.count > 0) {
			NSMutableArray* accessoryArray = [NSMutableArray array];
			for (NSDictionary* accessoryDict in accessoryDictArray) {
				MMAccessoryInfo* accessoryInfo = [MMAccessoryInfo accessoryInfoFromDict:accessoryDict];
				[accessoryArray addObject:accessoryInfo];
			}
			messageInfo.accessoryArray = accessoryArray;
		}
		
		messageInfo.syncToSinaWeibo = [[extendDict objectForKey:@"syncToSinaWeibo"] boolValue];
		messageInfo.syncToSinaWeiboSuccess = [[extendDict objectForKey:@"syncToSinaWeiboSuccess"] boolValue];
        
        messageInfo.isLongText = [extendDict objectForKey:@"isLongText"] ? [[extendDict objectForKey:@"isLongText"] boolValue] : NO;
        messageInfo.longTextUrl = [extendDict objectForKey:@"longTextUrl"];
        messageInfo.longText = [extendDict objectForKey:@"longText"];
        messageInfo.longitude = [extendDict objectForKey:@"longitude"] ? [[extendDict objectForKey:@"longitude"] doubleValue] : 0.0f;
        messageInfo.latitude = [extendDict objectForKey:@"latitude"] ? [[extendDict objectForKey:@"latitude"] doubleValue] : 0.0f;
        messageInfo.address = [extendDict objectForKey:@"address"];
	}
	
	return messageInfo;
}

- (MMErrorType)deleteMessage:(MMMessageInfo*)messageInfo{
		// 如果数据没打开
	if(![[self db]  goodConnection]) {
		return MM_DB_FAILED_OPEN;
	}
	
	NSString* sql = [NSString stringWithFormat:@"delete from message where status_id = '%@' and owner_id=%u", 
					 messageInfo.statusId, messageInfo.ownerId];
	
	
	id<PLPreparedStatement> stmt = [[self db]  prepareStatement:sql];   
	
        // 如果执行失败
	if(![stmt executeUpdate]) {
		
		return MM_DB_FAILED_INVALID_STATEMENT;
	}
	
	
	return MM_DB_OK;
}

- (NSUInteger)sameMessageCount:(NSString*)statusId {
	NSError* outError = nil;
	NSUInteger messageCount = 0;
	
		// 如果数据没打开
	do {
		if(![[self db]  goodConnection]) {
            break;
		}
		
		NSString* sql = @"select count(*) num from message where status_id = ?;";
		id<PLResultSet> results = [[self db]  executeQueryAndReturnError:&outError statement:sql, statusId];        
		if(SQLITE_OK != [outError code]) {
            break;
		}
		
		PLResultSetStatus status = [results nextAndReturnError:nil];
		if(status) {
			messageCount = [results intForColumn:@"num"];
		}
		[results close];
	}
    while(0);
	
	return messageCount;
}

- (MMErrorType)removeAllMessage:(NSUInteger)ownerId {
	// 如果数据没打开
	if(![[self db]  goodConnection]) {
		return MM_DB_FAILED_OPEN;
	}
	
	NSString* sql = [NSString stringWithFormat:@"delete from message where owner_id=%u;", ownerId];
	
	
	id<PLPreparedStatement> stmt = [[self db]  prepareStatement:sql];   
	
	// 如果执行失败
	if(![stmt executeUpdate]) {
		
		return MM_DB_FAILED_INVALID_STATEMENT;
	}
	
	return MM_DB_OK;
}

@end
