//
//  MMMessageDataSource.m
//  momo
//
//  Created by wangsc on 10-12-24.
//  Copyright 2010 ND. All rights reserved.
//

#import "MMMessageDataSource.h"
#import "MMMessageCell.h"
#import "MMUapRequest.h"
#import "MMGlobalData.h"
#import "DbStruct.h"
#import "MMUIMessage.h"
#import "MMMessageDelegate.h"
#import "MMMessageCell.h"
#import "DbStruct.h"
#import "MMModel.h"
#import "RegexKitLite.h"
#import "MMMessageSyncer.h"
#import "MMUIComment.h"
#import "MMLoginService.h"
#import "MMCommonAPI.h"

#define INITIAL_READ_COUNT 30
#define NORMAL_READ_COUNT 20
#define CONTRAINT_MAX_MESSAGE_COUNT 50

@implementation MMMessageDataSource
@synthesize messageArray, downLoadState, messageDelegate, messageCellDelegate, uploadMessageArray;
@synthesize localDBReachEnd;
@synthesize currentGroupInfo = currentGroupInfo_;

- (id)init {
	if (self = [super init]) {
		backgroundThreads = [[NSMutableArray alloc] init];
		uploadMessageArray = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void)initData {
	downLoadState = MMDownNone;
	localDBReachEnd = NO;
	
	//initial read
	self.messageArray = [[MMUIMessage instance] getLimitMessageList:INITIAL_READ_COUNT startTime:0 ownerId:[[MMLoginService shareInstance] getLoginUserId]];
	if (messageArray.count < INITIAL_READ_COUNT) {
		localDBReachEnd = YES;
	}
	
	//load recent comment
	for (MMMessageInfo* messageInfo in messageArray) {
		messageInfo.recentComment = [[MMUIComment instance] getComment:messageInfo.recentCommentId ownerId:[[MMLoginService shareInstance] getLoginUserId]];
	}
	
    [self downMessage:MMDownInitial];
}

- (void)reset {
	[self cancelThreads];
	
	downLoadState = MMDownNone;
	localDBReachEnd = NO;
    self.currentGroupInfo = nil;
	[messageArray removeAllObjects];
	[uploadMessageArray removeAllObjects];
}

- (void)cancelThreads {
	[MMCommonAPI waitHTTPThreadsQuit:backgroundThreads];
}

- (BOOL)downMessage:(MMMessageDownloadState)downType {
	if (self.downLoadState != MMDownNone) {
		NSLog(@"already syncing");
		return NO;
	}
	
	downLoadState = downType;
	switch (downType) {
		case MMDownInitial:
		{
        MMHttpRequestThread* thread = [[MMHttpRequestThread alloc] initWithTarget:self
                                                                         selector:@selector(downInitialThread:) 
                                                                           object:nil];
        [backgroundThreads addObject:thread];
        [thread start];
        [thread release];
		}
			break;
		case MMDownRecent:
		{
        MMHttpRequestThread* thread = [[MMHttpRequestThread alloc] initWithTarget:self
                                                                         selector:@selector(downRecentMessageThread:) 
                                                                           object:nil];
        [backgroundThreads addObject:thread];
        [thread start];
        [thread release];
		}
			break;
		case MMDownOld:
		{
        MMHttpRequestThread* thread = [[MMHttpRequestThread alloc] initWithTarget:self
                                                                         selector:@selector(downOldMessageThread:) 
                                                                           object:nil];
        [backgroundThreads addObject:thread];
        [thread start];
        [thread release];
		}
			break;
		default:
			break;
	}
	return YES;
}

- (void)downInitialThread:(id)object {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	[self downRecentMessage];
	
    MMThread* currentThread = [MMThread currentThread];
	dispatch_async(dispatch_get_main_queue(), ^{
		[currentThread wait];
        int index = [backgroundThreads indexOfObject:currentThread];
        if (index != NSNotFound) {
            [currentThread wait];
            [backgroundThreads removeObjectAtIndex:index];
        }
	});
	
	[pool release];
}

- (void)downRecentMessageThread:(id)object {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	[self downRecentMessage];
	
    MMThread* currentThread = [MMThread currentThread];
	dispatch_async(dispatch_get_main_queue(), ^{
        int index = [backgroundThreads indexOfObject:currentThread];
        if (index != NSNotFound) {
            [currentThread wait];
            [backgroundThreads removeObjectAtIndex:index];
        }
	});
    
	[pool release];
}

- (void)downOldMessageThread:(id)object {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	[self downOldMessage];
	
    MMThread* currentThread = [MMThread currentThread];
	dispatch_async(dispatch_get_main_queue(), ^{
        int index = [backgroundThreads indexOfObject:currentThread];
        if (index != NSNotFound) {
            [currentThread wait];
            [backgroundThreads removeObjectAtIndex:index];
        }
	});
    
	[pool release];
}

NSInteger messageInfoCompare(MMMessageInfo* messageInfo1, MMMessageInfo* messageInfo2, void* context) {
	if (messageInfo1.modifiedDate > messageInfo2.modifiedDate) {
		return NSOrderedAscending;
	} 
	else if (messageInfo1.modifiedDate < messageInfo2.modifiedDate) {
		return NSOrderedDescending;
	} 
	else {
		return NSOrderedSame;
	}
}

- (NSArray*)downProperRecentMessage:(NSMutableArray*)deletedMessages withErrorString:(NSString**)errorString {
	NSArray* serverMessages = nil;
    
    if (!currentGroupInfo_) {
        if (self.messageArray.count == 0) {
            serverMessages = [[MMMessageSyncer shareInstance] downRecentMessage:0 
                                                            withDeletedMessages:deletedMessages
                                                                withErrorString:errorString];
        } else {
            MMMessageInfo* mostRecentMessage = [self.messageArray objectAtIndex:0];
            serverMessages = [[MMMessageSyncer shareInstance] downRecentMessage:mostRecentMessage.modifiedDate 
                                                            withDeletedMessages:deletedMessages
                                                                withErrorString:errorString];
        }
    } else {
        if (self.messageArray.count == 0) {
            serverMessages = [[MMMessageSyncer shareInstance] downGroupRecentMessage:currentGroupInfo_.groupId 
                                                                            lastDate:0 
                                                                 withDeletedMessages:deletedMessages
                                                                     withErrorString:errorString];
        } else {
            MMMessageInfo* mostRecentMessage = [self.messageArray objectAtIndex:0];
            serverMessages = [[MMMessageSyncer shareInstance] downGroupRecentMessage:currentGroupInfo_.groupId
                                                                            lastDate:mostRecentMessage.modifiedDate
                                                                 withDeletedMessages:deletedMessages
                                                                     withErrorString:errorString];
        }
    }
	
	return serverMessages;
}

- (void)afterDownRecentMessage:(NSMutableDictionary*)userInfo {
	NSArray* serverMessages = [userInfo objectForKey:@"serverMessages"];
	NSArray* deletedMessages = [userInfo objectForKey:@"deletedMessages"];
	NSString* errorString = [userInfo objectForKey:@"errorString"];
	
	NSMutableArray* newArray = nil;
	BOOL messageListChanged = NO;
    
	if (serverMessages && serverMessages.count > 0) {
		messageListChanged = YES;
		NSMutableDictionary* tempMessageDict = [NSMutableDictionary dictionary];
		for (MMMessageInfo* messageInfo in messageArray) {
			[tempMessageDict setObject:messageInfo forKey:messageInfo.statusId];
		}
		
		for (MMMessageInfo* serverMessageInfo in serverMessages) {
			[tempMessageDict setObject:serverMessageInfo forKey:serverMessageInfo.statusId];
		}
		
		//sort
		newArray = [NSMutableArray arrayWithArray:[tempMessageDict allValues]];
		[newArray sortUsingFunction:messageInfoCompare context:nil];
	}
	
	//删除服务器已删除数据
	if (deletedMessages.count > 0) {
		messageListChanged = YES;
		if (!newArray) {
			newArray = [NSMutableArray arrayWithArray:messageArray];
		}
		
		for (MMMessageInfo* deletedMessage in deletedMessages) {
			for (MMMessageInfo* messageInfo in newArray) {
				if ([messageInfo.statusId isEqualToString:deletedMessage.statusId]) {
					[newArray removeObject:messageInfo];
					[[MMUIMessage instance] deleteMessage:messageInfo];
					break;
				}
			}
		}
	}
	
	//更新时释放过多的动态，
	if (!newArray && messageArray.count > CONTRAINT_MAX_MESSAGE_COUNT) {
		newArray = [NSMutableArray arrayWithArray:messageArray];
	}
	if (newArray && newArray.count > CONTRAINT_MAX_MESSAGE_COUNT) {
		[newArray removeObjectsInRange:NSMakeRange(CONTRAINT_MAX_MESSAGE_COUNT, newArray.count - CONTRAINT_MAX_MESSAGE_COUNT)];
		messageListChanged = YES;
	}
	
	if (messageArray.count == 0) {
		if (newArray.count < 10 && !errorString) {
			[userInfo setObject:[NSNumber numberWithBool:NO] forKey:@"moreOldMessage"];
		}
	} else if (messageListChanged && newArray.count == 0) {
		[userInfo setObject:[NSNumber numberWithBool:NO] forKey:@"moreOldMessage"];
	}
    
	if (messageListChanged) {
		[userInfo setObject:[NSNumber numberWithBool:YES] forKey:@"messageChanged"];
		
		//更新动态数组
		if (newArray) {
			self.messageArray = newArray;
		}
	}
	
	for (NSUInteger i = 0; i < uploadMessageArray.count; i++) {
		MMMessageInfo* messageInfo = [uploadMessageArray objectAtIndex:i];
		if (messageInfo.uploadStatus == uploadSuccess) {
			[uploadMessageArray removeObjectAtIndex:i];
			--i;
		}
	}
	
	if (messageDelegate && [messageDelegate respondsToSelector:@selector(downloadMessageDidSuccess:)]) {
		[messageDelegate downloadMessageDidSuccess:userInfo];
	}
    
    self.downLoadState = MMDownNone;
}

- (void)downRecentMessage {
	NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
	[userInfo setObject:[NSNumber numberWithInt:downLoadState] forKey:@"downLoadState"];
	[userInfo setObject:self forKey:@"object"];
	[userInfo setObject:[NSNumber numberWithBool:YES] forKey:@"moreOldMessage"]; //判断是否有更多动态需要下载
	
    if (!currentGroupInfo_ && messageArray.count > 0) {
        MMMessageInfo* mostRecentMessage = [self.messageArray objectAtIndex:0];
        //取新动态数目
        NSString* errorString = nil;
        int serverMessageCount = [[MMMessageSyncer shareInstance] getNewMessageNum:mostRecentMessage.modifiedDate withErrorString:&errorString];
        if (serverMessageCount > 30) {
            [[MMUIMessage instance] removeAllMessage:[[MMLoginService shareInstance] getLoginUserId]];
        }
    }
    
	NSArray* serverMessages = nil;
	NSMutableArray* deletedMessages = [NSMutableArray array];
	
	NSString* errorString = nil;
	serverMessages = [self downProperRecentMessage:deletedMessages withErrorString:&errorString];
	
	//保存到数据库
	[[[MMMessage instance] db] beginTransaction];
	for (MMMessageInfo* serverMessageInfo in serverMessages) {
        if (!currentGroupInfo_) {
            [[MMUIMessage instance] saveMessage:serverMessageInfo];	//全部动态下下载的动态入库 
        }
	}
	[[[MMMessage instance] db] commitTransaction];
	
	if (serverMessages) {
		[userInfo setObject:serverMessages forKey:@"serverMessages"];
	}
	
	if (deletedMessages) {
		[userInfo setObject:deletedMessages forKey:@"deletedMessages"];
	}
	
	if (errorString) {
		[userInfo setObject:errorString forKey:@"errorString"];
	}
	
	//动态数组变更放在主线程
	[self performSelectorOnMainThread:@selector(afterDownRecentMessage:) withObject:userInfo waitUntilDone:NO];
}

- (NSArray*)downProperOldMessage:(NSString**)errorString {
	MMMessageInfo* mostOldMessage = [self.messageArray objectAtIndex:self.messageArray.count - 1];
	NSArray* serverMessages = nil;
    
    if (!currentGroupInfo_) {
        serverMessages = [[MMMessageSyncer shareInstance] downOldMessage:mostOldMessage.modifiedDate 
                                                         withErrorString:errorString];
    } else {
        serverMessages = [[MMMessageSyncer shareInstance] downGroupOldMessage:currentGroupInfo_.groupId 
                                                                 earliestDate:mostOldMessage.modifiedDate
                                                              withErrorString:errorString];
    }
	
	return serverMessages;
}

- (void)afterDownOldMessage:(NSDictionary*)userInfo {
	NSNumber* changedValue = [userInfo objectForKey:@"isMessageReceived"];
	if (changedValue && [changedValue boolValue]) {
		NSMutableArray* newArray = [userInfo objectForKey:@"newArray"];
		if (newArray) {
			self.messageArray = newArray;
		}
	}
	
	if (messageDelegate && [messageDelegate respondsToSelector:@selector(downloadMessageDidSuccess:)]) {
		[messageDelegate downloadMessageDidSuccess:userInfo];
	}
    
    self.downLoadState = MMDownNone;
}

-(void)afterSetRecentComment:(MMMessageInfo*) messageInfo{
	if (messageDelegate && [messageDelegate respondsToSelector:@selector(deleteCommentDidSuccess:)]) {
		[messageDelegate deleteCommentDidSuccess:messageInfo];
	}
}

- (void)downOldMessage {
	NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
	[userInfo setObject:[NSNumber numberWithInt:downLoadState] forKey:@"downLoadState"];
	[userInfo setObject:self forKey:@"object"];
	[userInfo setObject:[NSNumber numberWithBool:YES] forKey:@"moreOldMessage"];
	
	NSMutableArray* indexPaths = [NSMutableArray array];
	NSMutableArray* newArray = [NSMutableArray arrayWithArray:messageArray];
	
	if (!currentGroupInfo_ && !localDBReachEnd) {
        //read from local db
		uint64_t startTime = 0;
		if (messageArray.count > 0) {
			MMMessageInfo* messageInfo = [messageArray lastObject];
			startTime = messageInfo.modifiedDate;
		}
		
		NSMutableArray* moreMessageArray = [[MMUIMessage instance] getLimitMessageList:NORMAL_READ_COUNT 
                                                                             startTime:startTime 
                                                                               ownerId:[[MMLoginService shareInstance] getLoginUserId]];
		for (MMMessageInfo* serverMessageInfo in moreMessageArray) {
            serverMessageInfo.recentComment = [[MMUIComment instance] getComment:serverMessageInfo.recentCommentId ownerId:[[MMLoginService shareInstance] getLoginUserId]];
            
			[newArray addObject:serverMessageInfo];
			[indexPaths addObject:[NSIndexPath indexPathForRow:(newArray.count - 1) inSection:0]];
		}
		
		if (moreMessageArray.count >= NORMAL_READ_COUNT) {
			[userInfo setObject:newArray forKey:@"newArray"];
			if (indexPaths.count > 0) {
				[userInfo setObject:indexPaths forKey:@"IndexPaths"];
				[userInfo setObject:[NSNumber numberWithBool:YES] forKey:@"isMessageReceived"];
			}
			
			[self performSelectorOnMainThread:@selector(afterDownOldMessage:) withObject:userInfo waitUntilDone:NO];
			return;
		}
		
		localDBReachEnd = YES;
	}
	
    //down from internet
	NSString* errorString = nil;
	NSArray* serverMessages = [self downProperOldMessage:&errorString];
	
	if (serverMessages.count == 0) {
		if (!errorString) {
			[userInfo setObject:[NSNumber numberWithBool:NO] forKey:@"moreOldMessage"];
		}
		
		[self performSelectorOnMainThread:@selector(afterDownOldMessage:) withObject:userInfo waitUntilDone:NO];
		return;
	}
    
	[[[MMMessage instance] db] beginTransaction];
	for (MMMessageInfo* serverMessageInfo in serverMessages) {
        if (!currentGroupInfo_) {
            [[MMUIMessage instance] saveMessage:serverMessageInfo];	//全部动态下下载的动态入库
        }
        
		[newArray addObject:serverMessageInfo];
		[indexPaths addObject:[NSIndexPath indexPathForRow:(newArray.count - 1) inSection:0]];
	}
	[[[MMMessage instance] db] commitTransaction];
	
	//下载完成
	[userInfo setObject:newArray forKey:@"newArray"];
	if (serverMessages.count > 0) {
		[userInfo setObject:indexPaths forKey:@"IndexPaths"];
		[userInfo setObject:[NSNumber numberWithBool:YES] forKey:@"isMessageReceived"];
	}
	
	[self performSelectorOnMainThread:@selector(afterDownOldMessage:) withObject:userInfo waitUntilDone:NO];
}

- (void)setMessageRecentComment:(MMCommentInfo*)commentInfo{
	for (MMMessageInfo* messageInfo in messageArray) {
        if ([messageInfo.statusId isEqualToString:commentInfo.statusId]) {
            messageInfo.recentComment = commentInfo;
            messageInfo.commentCount--;
            if (0 == messageInfo.commentCount) {
                messageInfo.recentCommentId = nil;
            }
            
            //更改数据库
            [[MMUIMessage instance] saveMessage:messageInfo];             
            
            [self performSelectorOnMainThread:@selector(afterSetRecentComment:) withObject:messageInfo waitUntilDone:NO];
            break;
        }
	}
}

- (NSInteger)indexForMessage:(NSString*)statusId {
	for (NSUInteger i = 0; i < messageArray.count; i++) {
		MMMessageInfo* messageInfo = [messageArray objectAtIndex:i];
		if ([messageInfo.statusId isEqualToString:statusId]) {
			return i;
		}
	}
	return -1;
}

- (NSIndexPath*)indexPathForMessage:(NSString*)statusId {
	for (NSUInteger i = 0; i < messageArray.count; i++) {
		MMMessageInfo* messageInfo = [messageArray objectAtIndex:i];
		if ([messageInfo.statusId isEqualToString:statusId]) {
			return [NSIndexPath indexPathForRow:(i + uploadMessageArray.count) inSection:0];
		}
	}
	return nil;
}

- (MMMessageInfo*)getMessageInfo:(NSString*)statusId {
	for (NSUInteger i = 0; i < messageArray.count; i++) {
		MMMessageInfo* messageInfo = [messageArray objectAtIndex:i];
		if ([messageInfo.statusId isEqualToString:statusId]) {
			return messageInfo;
		}
	}
	return nil;
}

- (void)addUploadMessage:(MMMessageInfo*)newMessageInfo {
	for (NSUInteger i = 0; i < uploadMessageArray.count; i++) {
		MMMessageInfo* messageInfo = [uploadMessageArray objectAtIndex:i];
		if (messageInfo.draftId == newMessageInfo.draftId) {
			[uploadMessageArray replaceObjectAtIndex:i withObject:messageInfo];
			return;
		}
	}
	[uploadMessageArray insertObject:newMessageInfo atIndex:0];
}

- (void)updateMessageStatus:(UploadStatus)uploadStatus draftId:(NSUInteger)draftId {
	for (MMMessageInfo* messageInfo in uploadMessageArray) {
		if (messageInfo.draftId == draftId) {
			messageInfo.uploadStatus = uploadStatus;
			return;
		}
	}
}

- (void)updateMessageDraft:(MMMessageInfo*)messageDraftInfo {
	for (NSUInteger i = 0; i < uploadMessageArray.count; ++i) {
		MMMessageInfo* messageInfo = [uploadMessageArray objectAtIndex:i];
		if (messageInfo.draftId == messageDraftInfo.draftId) {
			[uploadMessageArray replaceObjectAtIndex:i withObject:messageDraftInfo];
		}
	}
}

- (NSIndexPath*)getUploadMessageIndexPath:(NSUInteger)draftId {
	for (NSUInteger i = 0; i < uploadMessageArray.count; ++i) {
		MMMessageInfo* messageInfo = [uploadMessageArray objectAtIndex:i];
		if (messageInfo.draftId == draftId) {
			NSIndexPath* indexPath = [NSIndexPath indexPathForRow:i inSection:0];
			return indexPath;
		}
	}
	return nil;
}

- (NSIndexPath*)deleteUploadMessage:(NSUInteger)draftId{
	for (NSUInteger i = 0; i < uploadMessageArray.count; ++i) {
		MMMessageInfo* messageInfo = [uploadMessageArray objectAtIndex:i];
		if (messageInfo.draftId == draftId) {
			NSIndexPath* indexPath = [NSIndexPath indexPathForRow:i inSection:0];
			[uploadMessageArray removeObjectAtIndex:i];
			return indexPath;
		}
	}
	return nil;
}

- (void)dealloc {
	[backgroundThreads release];
	[messageArray release];
	[uploadMessageArray release];
    self.currentGroupInfo = nil;
	[super dealloc];
}

#pragma mark UITableViewDataSource Methods
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return messageArray.count + uploadMessageArray.count;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	MMMessageCell* cell = (MMMessageCell*)[tableView dequeueReusableCellWithIdentifier:@"MMMessageCell"];
	if (cell == nil) {
		cell = [[[MMMessageCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"MMMessageCell"] autorelease];
	}
	
	if (uploadMessageArray.count > 0) {
		if (indexPath.row < uploadMessageArray.count) {
			[cell setUploadMessageInfo:[self.uploadMessageArray objectAtIndex:indexPath.row]];
			cell.delegate = nil;
		} else {
			MMMessageInfo* messageInfo = [self.messageArray objectAtIndex:(indexPath.row - uploadMessageArray.count)];
            cell.delegate = messageCellDelegate;
			[cell setMessageInfo:messageInfo];
		}
		
	} else {
		MMMessageInfo* messageInfo = [self.messageArray objectAtIndex:indexPath.row];
        cell.delegate = messageCellDelegate;
		[cell setMessageInfo:messageInfo];
	}
	
	return cell;
}

@end
