//
//  MMAboutMeManager.m
//  momo
//
//  Created by houxh on 11-8-1.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MMAboutMeManager.h"

#import "DefineEnum.h"
#import "MMUIMessage.h"
#import "MMGlobalData.h"
#import "MMMessageSyncer.h"
#import "MMThemeMgr.h"
#import "MMCommonAPI.h"
#import "MMRelativeLayout.h"
#import "MMUapRequest.h"
#import "MMGlobalData.h"
#import "MMViewXmlParser.h"
#import "MMLayoutParams.h"
#import "MMLoginService.h"
#import "MMAvatarMgr.h"
#import "MMAvatarImageView.h"
#import "MMUapRequest.h"
#import "MMMomoUserMgr.h"

@interface MMAboutMeMessage(MMAboutMe)
-(id)initWithResultSet:(id<PLResultSet>)results;
@end

@implementation MMAboutMeMessage(MMAboutMe)
-(id)initWithResultSet:(id<PLResultSet>)results {
	self = [super init];
	if (self) {
		self.id = [results stringForColumn:@"id"];
		self.kind = [results intForColumn:@"kind"];
		self.statusId = [results stringForColumn:@"status_id"];
		self.dateLine = [results bigIntForColumn:@"dateline"];
		self.isRead = [results boolForColumn:@"is_read"];
		self.ownerId = [results intForColumn:@"uid"];
		self.ownerName = [results stringForColumn:@"real_name"];
		if (![results isNullForColumn:@"comment_id"]) {
			self.commentId = [results stringForColumn:@"comment_id"];
		} else {
			self.commentId = @"";
		}
		
		if(![results isNullForColumn:@"comment"])
			self.comment = [results stringForColumn:@"comment"];
		else 
			self.comment = @"";			
		
		if(![results isNullForColumn:@"src_comment"])
			self.sourceComment = [results stringForColumn:@"src_comment"];
		else
			self.sourceComment = @"";
	}
	return self;
}

@end



@implementation MMAboutMeManager
@synthesize unReadCount = unReadCount_;
@synthesize allAboutMeList = allAboutMeList_;

+ (MMAboutMeManager *)shareInstance {
	static MMAboutMeManager *instance = nil;
	if(!instance) {
		@synchronized(self) {
			if(!instance) {
				instance = [[MMAboutMeManager alloc] init];
			}
		}
	}
	return instance;
}

- (id)init {
    self = [super init];
    if (self) {
        NSNotificationCenter * center = [NSNotificationCenter defaultCenter];
//		[center addObserver:self selector:@selector(onUserLogin:) name:kMMUserLogin object:nil];
        [center addObserver:self selector:@selector(getNewMessage:) name:kMMMQAboutMeMsg object:nil];
        
        self.allAboutMeList = [NSMutableArray array];
//        [allAboutMeList_ setArray:[self getAboutMessageList:YES]];
    }
    return self;
}

- (NSInteger)getUnreadMessageCount {
	int count = 0;
    for (MMAboutMeMessage* aboutMe in allAboutMeList_) {
        if (!aboutMe.isRead) {
            count++;
        }
    }
	
	return count;
}


- (NSArray *)readUnreadMessageList {
	
	if(![[self db]  goodConnection]) {
		return nil;
	}
	
	NSError *outError = nil;
	NSString *sql = nil;
	
	sql = @"select * from about where is_read = 0 order by dateline DESC";
	
	id<PLResultSet> results = [[self db]  executeQueryAndReturnError:&outError statement:sql];        
	if(SQLITE_OK != [outError code]) {
		return nil;
	}
	NSMutableArray *array = [NSMutableArray array];
	PLResultSetStatus status = [results nextAndReturnError:nil];
	while (status) {
		MMAboutMeMessage *message = [[[MMAboutMeMessage alloc] initWithResultSet:results] autorelease];
		[array addObject:message];
		status = [results nextAndReturnError:nil];
	}
	[results close];
	return array;
}

- (NSArray *)getAboutMessageList:(BOOL)includeReaded listCount:(NSInteger)count{
    if(![[self db]  goodConnection]) {
		return nil;
	}
	
	NSError *outError = nil;
	NSString *sql = nil;
    
    if (includeReaded) {
		sql = [NSString stringWithFormat:@"select * from about order by dateline DESC limit %d", count];
    } else {
		sql = [NSString stringWithFormat:@"select * from about where is_read = 0 order by dateline DESC limit %d", count];
    }
	
	id<PLResultSet> results = [[self db]  executeQueryAndReturnError:&outError statement:sql];        
	if(SQLITE_OK != [outError code]) {
		return nil;
	}
	NSMutableArray *array = [NSMutableArray array];
	PLResultSetStatus status = [results nextAndReturnError:nil];
	while (status) {
		MMAboutMeMessage *message = [[[MMAboutMeMessage alloc] initWithResultSet:results] autorelease];
		[array addObject:message];
		status = [results nextAndReturnError:nil];
	}
	[results close];
	return array;
}

- (NSArray *)getStatusIdList {
	
	NSError *outError = nil;
	NSString *sql = nil;
	
	sql = @"select status_id from about group by status_id";
	
	
	id<PLResultSet> results = [[self db]  executeQueryAndReturnError:&outError statement:sql];        
	if(SQLITE_OK != [outError code]) {
		return 0;
	}
	PLResultSetStatus status = [results nextAndReturnError:nil];
	NSMutableArray *array = [NSMutableArray array];
	while (status) {
		NSString* statusId = [results stringForColumn:@"status_id"];
		[array addObject:statusId];
	    status = [results nextAndReturnError:nil];
	}
	[results close];	   
	return array;
}

- (NSInteger)getUnreadCountWithStatusId:(NSString *)statusId {
	NSError *outError = nil;
	NSString *sql = [NSString stringWithFormat:@"select sum(1-is_read) as unread_count from about "
					 @"where status_id='%@' ", statusId];
	
	id<PLResultSet> results = [[self db]  executeQueryAndReturnError:&outError statement:sql];        
	if(SQLITE_OK != [outError code]) {
		return 0;
	}
	PLResultSetStatus status = [results nextAndReturnError:nil];
	NSInteger unreadCount = 0;
	if(status)
		unreadCount = [results intForColumn:@"unread_count"];
	[results close];
	return unreadCount;
}

- (MMAboutMeMessage *)getNewestMessageWithStatusId:(NSString *)statusId {
	NSError *outError = nil;
	NSString *sql = [NSString stringWithFormat:@"select * from about where status_id='%@' order by dateline desc limit 1",  
					 statusId];
	
	
	id<PLResultSet> results = [[self db]  executeQueryAndReturnError:&outError statement:sql];        
	if(SQLITE_OK != [outError code]) {
		return 0;
	}
	PLResultSetStatus status = [results nextAndReturnError:nil];
	MMAboutMeMessage *message = nil;
	if(status)
		message = [[[MMAboutMeMessage alloc] initWithResultSet:results] autorelease];
	[results close];
	return message;
}



- (NSArray *)getAboutMeListWithStatusId:(NSString *)statusId {
	NSError *outError = nil;
	NSString *sql = nil;
	sql = [NSString stringWithFormat:@"select * from about "
		   @"where  status_id='%@' order by dateline ASC ", statusId];
	
	id<PLResultSet> results = [[self db]  executeQueryAndReturnError:&outError statement:sql];        
	if(SQLITE_OK != [outError code]) {
		return nil;
	}
	
	PLResultSetStatus status = [results nextAndReturnError:nil];
	NSMutableArray *array = [NSMutableArray array];
	
	while (status) {
		MMAboutMeMessage *message = [[[MMAboutMeMessage alloc] initWithResultSet:results] autorelease];
		[array addObject:message];
		status = [results nextAndReturnError:nil];
	}
	[results close];
	return array;
}

- (int64_t)getMaxDateLine {
	//查出最后一条未读的关于我的时间撮
	NSError* outError = nil;
	int64_t timeLine = 0;
	NSString *sql = [NSString stringWithFormat:@"select max(dateline) dateline from about"];
	id<PLResultSet> results = [[self db]  executeQueryAndReturnError:&outError statement:sql]; 
	if(SQLITE_OK != [outError code]) {
		return 0;
	}
	
	PLResultSetStatus status = [results nextAndReturnError:nil];		
	if (status && ![results isNullForColumn:@"dateline"]) {
		timeLine = [results bigIntForColumn:@"dateline"];
	} 
	[results close];
	return timeLine;
}

- (BOOL)isExist:(NSString*)msgid {
	NSError *outError = nil;
	NSString * sql = nil;
	sql = [NSString stringWithFormat:@"select count(*) num from about "
		   @"where  id='%@' ", msgid];
	
	id<PLResultSet> results = [[self db]  executeQueryAndReturnError:&outError statement:sql];        
	if(SQLITE_OK != [outError code]) {
		return NO;
	}
	int count = 0;
	PLResultSetStatus status = [results nextAndReturnError:nil];
	
	if (status) {
		count = [results intForColumn:@"num"];
	}
	[results close];
	
	assert(count <= 1);
	return (count == 1);
}

- (BOOL)clearUnreadFlag {
	NSString *sql = nil;
	
	sql = [NSString stringWithFormat:@"update about set is_read=1 "];
	if(![[self db] executeUpdate:sql]){
		return NO;
	}
    
    for (MMAboutMeMessage* aboutMe in allAboutMeList_) {
        if (!aboutMe.isRead) {
            aboutMe.isRead = YES;
        }
    }
    
    self.unReadCount = 0;
	return YES;
}
- (BOOL)clearUnreadFlagWithStatusId:(NSString*)statusId {
	NSString *sql = nil;
	sql = [NSString stringWithFormat:@"update about set is_read=1 where status_id='%@' ", statusId];
	if(![[self db] executeUpdate:sql]){
		return NO;
	}
    
    for (MMAboutMeMessage* aboutMe in allAboutMeList_) {
        if (!aboutMe.isRead && [aboutMe.statusId isEqualToString:statusId]) {
            aboutMe.isRead = YES;
        }
    }
    
    self.unReadCount = [self getUnreadMessageCount];
	return YES;
}

- (BOOL)clearUnReadFlagWithMessageId:(NSString*)msgid {
	NSString *sql;
	sql = [NSString stringWithFormat:@"update about set is_read=1 where id='%@' ", msgid];
	if(![[self db] executeUpdate:sql]){
		return NO;
	}
    
    for (MMAboutMeMessage* aboutMe in allAboutMeList_) {
        if (!aboutMe.isRead && [aboutMe.id isEqualToString:msgid]) {
            aboutMe.isRead = YES;
            break;
        }
    }
    
    self.unReadCount = [self getUnreadMessageCount];
	return YES;	
}

- (BOOL)insertMessage:(MMAboutMeMessage*)message {
	BOOL needInsert = ![self isExist:message.id];
	if (!needInsert)
		return YES;
	id<PLPreparedStatement> stmt = [[self db]  prepareStatement:@"INSERT INTO about "
									" (id, uid, real_name, comment_id, comment, src_comment, "
									" dateline, is_read, kind, status_id) "
									" VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"];
	
	[stmt bindParameters:[NSArray arrayWithObjects:message.id,
						  [NSNumber numberWithLongLong:message.ownerId], 
						  message.ownerName,
						  message.commentId ? message.commentId : @"",
						  message.comment ? message.comment : @"",
						  message.sourceComment ? message.sourceComment : @"", 
						  [NSNumber numberWithLongLong:message.dateLine],
						  [NSNumber numberWithInt:message.isRead],
						  [NSNumber numberWithInt:message.kind],
						  message.statusId,
						  nil]];
	NSError* outError = nil;
	if(![stmt executeUpdateAndReturnError:&outError]) {
		NSLog(@"sql error:%@", [outError localizedDescription]);
		return NO;
	}
	
    [allAboutMeList_ insertObject:message atIndex:0];
    self.unReadCount = [self getUnreadMessageCount];
	return YES;
}

- (BOOL)deleteAllMessage {
	if (![[self db]  executeUpdate:@"delete from about"]) {
		NSLog(@"delete from about fail");            
	} 
    
    [allAboutMeList_ removeAllObjects];
    self.unReadCount = 0;
	return YES;
}

- (BOOL)deleteMessageWithStatusId:(NSString *)statusId {
	NSString *sql = nil;
	sql = [NSString stringWithFormat:@"delete from about where status_id='%@' ", statusId];
	
	if (![[self db]  executeUpdate:sql]) {
		NSLog(@"delete about me message with statusid from about fail");            
	}
	
    for (int i = 0; i < allAboutMeList_.count; i++) {
        MMAboutMeMessage* aboutMe = [allAboutMeList_ objectAtIndex:i];
        if (!aboutMe.isRead && [aboutMe.statusId isEqualToString:statusId]) {
            [allAboutMeList_ removeObjectAtIndex:i];
            i--;
        }
    }
    
    self.unReadCount = [self getUnreadMessageCount];
	return YES;
}



- (NSInteger)refreshAboutMe {
    NSString *requestUrl = nil;
    int64_t dateLine = [[MMAboutMeManager shareInstance] getMaxDateLine];
    if (dateLine > 0 ) {
        requestUrl = @"statuses/aboutme_alone.json?page=1&new=1";	
    } else {
        requestUrl = @"statuses/aboutme_alone.json?page=1&new=0";
    }
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithPath:requestUrl];

    [ASIHTTPRequest startSynchronous:request];

    if ([request responseStatusCode] != 200) {
         return 0;
    }
    NSInteger count = 0;
    NSArray *array = [request responseObject];

    for (NSDictionary *dic in array) {
        MMAboutMeMessage *message = [[[MMAboutMeMessage alloc] initWithDictionary:dic] autorelease];
        NSInteger userId = [[[dic objectForKey:@"user"] objectForKey:@"id"] intValue];
        NSString *userName = [[dic objectForKey:@"user"] objectForKey:@"name"];
        NSString *userAvatar = [[dic objectForKey:@"user"] objectForKey:@"avatar"];		
        [[MMMomoUserMgr shareInstance] setUserId:userId realName:userName avatarImageUrl:userAvatar];  
        
        if ([[MMAboutMeManager shareInstance] isExist:message.id]) {
            continue;
        }
        MMMessageInfo* messageInfo = [[MMUIMessage instance] getMessage:message.statusId ownerId:[[MMLoginService shareInstance] getLoginUserId]];
        if (nil == messageInfo) {
            NSString* errorString = nil;
            MMMessageInfo* messageInfo = [[MMMessageSyncer shareInstance] downSingleMessage:message.statusId
                                                                            withErrorString:&errorString];
            if (nil == messageInfo) {
                NSLog(@"error:关于我的 下载分享失败");
                continue;
              //  break;
            }
            messageInfo.ignoreDateLine = YES;
            [[MMUIMessage instance] saveMessage:messageInfo];
        }
        [[MMAboutMeManager shareInstance] insertMessage:message];
		
        count++;
    }
    return count;
}

- (void)getNewMessage:(id)sender {
	NSNotification *note = (NSNotification *)sender;
	NSDictionary *dicData = (NSDictionary*)(note.object);
	if (![dicData isKindOfClass:[NSDictionary class]]) {
		MLOG(@"error:message format error");
		return;
	}
	MMAboutMeMessage *message = [[[MMAboutMeMessage alloc] initWithDictionary:dicData] autorelease];
    NSInteger userId = [[[dicData objectForKey:@"user"] objectForKey:@"id"] intValue];
    NSString *userName = [[dicData objectForKey:@"user"] objectForKey:@"name"];
    NSString *userAvatar = [[dicData objectForKey:@"user"] objectForKey:@"avatar"];		
    message.isRead = NO;
    [[MMMomoUserMgr shareInstance] setUserId:userId realName:userName avatarImageUrl:userAvatar];  
    
	MMMessageInfo* messageInfo = [[MMUIMessage instance] getMessage:message.statusId];
	if (nil == messageInfo) {
		NSBlockOperation *op = [NSBlockOperation blockOperationWithBlock:^{
            NSString* errorString = nil;
			MMMessageInfo* messageInfo = [[MMMessageSyncer shareInstance] downSingleMessage:message.statusId
                                                                            withErrorString:&errorString];
			if (nil == messageInfo) {
				MLOG(@"error:下载分享失败");
				return;
			}
			messageInfo.ignoreDateLine = YES;
			[[MMUIMessage instance] saveMessage:messageInfo];
			[self insertMessage:message];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:kMMNewAboutMeMsg object:message];
            });		
		}];
		
		[MMHttpRequestThread detachNewThreadSelector:@selector(start) toTarget:op withObject:nil cancelOnLogout:YES];
	} else {
        [self insertMessage:message];
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:kMMNewAboutMeMsg object:message];
        });
    }
}

//- (void)onUserLogin:(NSNotification*)notification {
//	NSString *prev = [[notification userInfo] objectForKey:@"prev_user_mobile"];
//	NSString *cur = [[notification userInfo] objectForKey:@"user_mobile"];
//	if (![cur isEqualToString:prev]) {
//		[self deleteAllMessage];
//	} else {
//        [allAboutMeList_ setArray:[self getAboutMessageList:YES]];
//        self.unReadCount = [self getUnreadMessageCount];
//    }
//}

@end
