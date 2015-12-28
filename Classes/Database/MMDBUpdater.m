//
//  MMDBUpdater.m
//  momo
//
//  Created by jackie on 11-4-7.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MMDBUpdater.h"
#import "MMGlobalPara.h"
#import <pthread.h>
#import "MMLogger.h"

@implementation MMUpdateInfo
@synthesize version, updateSelector, replaceDbFile;

+ (id)updateInfoWithVersionAndSelector:(NSString*)version 
						updateSelector:(SEL)updateSelector 
						 replaceDbFile:(BOOL)replaceDbFile {
	MMUpdateInfo* updateInfo = [[MMUpdateInfo alloc] init];
	updateInfo.version = version;
	updateInfo.updateSelector = updateSelector;
	updateInfo.replaceDbFile = replaceDbFile;
	return [updateInfo autorelease];
}

- (void)dealloc {
	self.version = nil;
	[super dealloc];
}

@end

///////////////////////////////////////////////////
@implementation MMDBUpdater
@synthesize updateInfoList;

+(id) instance{
    static id _instance = nil;
    @synchronized(self) {
        if(_instance == nil) 
            _instance = [[self class] new];
    }
    return _instance;
}

- (BOOL)addCardTable {
    NSString *sql = @"CREATE TABLE if not exists momo_card (uid INTEGER PRIMARY KEY ,  extend_json VARCHAR(1024))";
    
    if(![[self db] executeUpdate:sql]) {
		return NO;
	}
	
    sql = @"CREATE TABLE if not exists number_uid (number VARCHAR(32) PRIMARY KEY ,  uid INTEGER)";
    
    if(![[self db] executeUpdate:sql]) {
		return NO;
	}
	
    return YES;
}

- (BOOL)alterMomoCardTable {
	
	NSString *sql = @"ALTER TABLE momo_card ADD expired_date INTEGER";
	
	if(![[self db] executeUpdate:sql]) {
		return NO;
	}
	
	sql = @"UPDATE momo_card SET expired_date = 0";
	
	if(![[self db] executeUpdate:sql]) {
		return NO;
	}
	
	return YES;
	
}

- (id)init {
	if (self = [super init]) {
		//数据库升级信息填在这里
		updateInfoList = [[NSArray alloc] initWithObjects:
						  [MMUpdateInfo updateInfoWithVersionAndSelector:@"113" updateSelector:NULL replaceDbFile:YES],	//数据库升级到1.13
                          [MMUpdateInfo updateInfoWithVersionAndSelector:@"114" updateSelector:@selector(addCardTable) replaceDbFile:NO], //数据库升级到1.14
						  [MMUpdateInfo updateInfoWithVersionAndSelector:@"115" updateSelector:@selector(alterMomoCardTable) replaceDbFile:NO], //数据库升级到1.15
						  nil];
	}
	return self;
}

- (NSString*)dbVersion {
	NSString* version = nil;
	NSError* outError = nil;
	
	NSString* sql = @"select value from profile where key='version'";
	id<PLResultSet> results = [[self db]  executeQueryAndReturnError:&outError statement:sql];
	PLResultSetStatus status = [results nextAndReturnError:nil];
	if (status == PLResultSetStatusRow) {
		version = [results stringForColumn:@"value"];
	}
	[results close];
	
	return version;
}

- (MMErrorType)setDBVersion:(NSString*)version {
	// 如果数据没打开
	if(![[self db]  goodConnection]) {
		return MM_DB_FAILED_OPEN;
	}
	
	NSString* sql = [NSString stringWithFormat:@"replace into profile(key, value) values('version', '%@');", version];
	id<PLPreparedStatement> stmt = [[self db]  prepareStatement:sql];   
	
	// 如果执行失败
	if(![stmt executeUpdate]) {
		return MM_DB_FAILED_INVALID_STATEMENT;
	}
	
	return MM_DB_OK;
}

- (BOOL)needUpdateDB {
	// 如果数据没打开
	if(![[self db]  goodConnection]) {
		return NO;
	}
	
	NSString* version = [self dbVersion];
	if (!version) {
		return YES;
	}
	
	if (updateInfoList.count == 0) {
		return NO;
	}
	
	MMUpdateInfo* maxVersionInfo = [updateInfoList objectAtIndex:updateInfoList.count - 1];
	if ([maxVersionInfo.version compare:version] == NSOrderedDescending) {
		return YES;
	}
	
	return NO;
}

- (BOOL)startUpdateDB:(BOOL*)isDBReplaced {
	// 如果数据没打开
	if(![[self db]  goodConnection]) {
		return NO;
	}
    
    if (isDBReplaced) {
        *isDBReplaced = NO;
    }
	
	NSString* version = [self dbVersion];
	if (!version) {
		version = @"0";
	}
	
	for (MMUpdateInfo* updateInfo in updateInfoList) {
		if ([updateInfo.version compare:version] != NSOrderedDescending) {
			continue;
		}
		
		if (updateInfo.replaceDbFile) {
			[self replaceDbFile];	//替换后数据库为最新, 不需要进行后续更新了
            if (isDBReplaced) {
                *isDBReplaced = YES;
            }
			break;
		}
		
		if (![self respondsToSelector:updateInfo.updateSelector]) {
			NSLog(@"db update selector not exit!");
			continue;
		}
		
		if (![self performSelector:updateInfo.updateSelector]) {
			return NO;
        }
		
		if ([self setDBVersion:updateInfo.version] != MM_DB_OK) {
			return NO;
		}
	}
	return YES;
}

- (MMErrorType)emptyTable:(NSString*)tableName {
	// 如果数据没打开
	if(![[self db]  goodConnection]) {
		return MM_DB_FAILED_OPEN;
	}
	
	NSString* sql = [NSString stringWithFormat:@"delete from %@;", tableName];
	id<PLPreparedStatement> stmt = [[self db]  prepareStatement:sql];   
	
	// 如果执行失败
	if(![stmt executeUpdate]) {
		return MM_DB_FAILED_INVALID_STATEMENT;
	}
	
	return MM_DB_OK;
}


- (BOOL)replaceDbFile {
	pthread_key_t threadDBKey = [MMModel threadDBKey];
	//数据库已打开, 关闭数据库连接
	if (threadDBKey) {
		PLSqliteDatabase* currentThreadDB = (PLSqliteDatabase*)pthread_getspecific(threadDBKey);
		if (currentThreadDB && [currentThreadDB isKindOfClass:[PLSqliteDatabase class]]) {
			if ([currentThreadDB goodConnection]) {
				[currentThreadDB close];
			}
			
			[currentThreadDB release];
		}
		pthread_setspecific(threadDBKey, NULL);
	}
	
	NSString* dbPath = [MMModel getDbPath];
	NSError* error;
	
	// 如果文件已经存在, 删除文件
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if([fileManager fileExistsAtPath:dbPath]) {
		if (![fileManager removeItemAtPath:dbPath error:&error]) {
			DLOG(@"remove dbfile failed");
			return NO;
		}
	}
	
	NSString *defaultDBPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"momo.db"];
    if (![fileManager copyItemAtPath:defaultDBPath toPath:dbPath error:&error]) {
		DLOG(@"copy dbfile failed");
		return NO;
	}
	return YES;
}

- (void)dealloc {
	[updateInfoList release];
	[super dealloc];
}

@end
