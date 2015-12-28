//
//  MMFriendMessageDataSource.m
//  momo
//
//  Created by jackie on 11-6-14.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MMFriendMessageDataSource.h"
#import "MMMessageSyncer.h"

#define INITIAL_READ_COUNT 30
#define NORMAL_READ_COUNT 20
#define CONTRAINT_MAX_MESSAGE_COUNT 50

@implementation MMFriendMessageDataSource
@synthesize currentFriendInfo;

- (id)initWithFriendInfo:(MMMomoUserInfo*)friendInfo {
	if (self = [super init]) {
		self.currentFriendInfo = friendInfo;
	}
	return self;
}

- (void)initData {
	self.messageArray = [NSMutableArray	array];
	downLoadState = MMDownNone;
	[self downMessage:MMDownInitial];
}

- (void)downInitialThread:(id)object {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	[self downRecentMessage];
	
	[pool release];
}

- (void)downRecentMessage {
	NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
	[userInfo setObject:[NSNumber numberWithInt:downLoadState] forKey:@"downLoadState"];
	[userInfo setObject:self forKey:@"object"];
	[userInfo setObject:[NSNumber numberWithBool:YES] forKey:@"moreOldMessage"];
	
	NSArray* serverMessages = nil;
	NSMutableArray* deletedMessages = [NSMutableArray array];
	
	NSString* errorString = nil;
	if (self.messageArray.count == 0) {
		serverMessages = [[MMMessageSyncer shareInstance] downUserRecentMessage:currentFriendInfo.uid
																	   lastDate:0
															withDeletedMessages:deletedMessages
																withErrorString:&errorString];
	} else {
		MMMessageInfo* mostRecentMessage = [self.messageArray objectAtIndex:0];
		serverMessages = [[MMMessageSyncer shareInstance] downUserRecentMessage:currentFriendInfo.uid
																	   lastDate:mostRecentMessage.modifiedDate 
															withDeletedMessages:deletedMessages
																withErrorString:&errorString];
	}
	
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
	dispatch_async(dispatch_get_main_queue(), ^{
		[super afterDownRecentMessage:userInfo];
	});
}

- (void)downOldMessage {
	NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
	[userInfo setObject:[NSNumber numberWithInt:downLoadState] forKey:@"downLoadState"];
	[userInfo setObject:self forKey:@"object"];
	[userInfo setObject:[NSNumber numberWithBool:YES] forKey:@"moreOldMessage"];
	
	if (self.messageArray.count == 0) {
		dispatch_async(dispatch_get_main_queue(), ^{
			if (messageDelegate && [messageDelegate respondsToSelector:@selector(downloadMessageDidSuccess:)]) {
				[messageDelegate downloadMessageDidSuccess:userInfo];
			}
		});
		return;
	}
	
	NSMutableArray* indexPaths = [NSMutableArray array];
	
	//down from internet
	NSString* errorString = nil;
	MMMessageInfo* mostOldMessage = [self.messageArray objectAtIndex:self.messageArray.count - 1];
	NSArray* serverMessages = [[MMMessageSyncer shareInstance] downUserOldMessage:currentFriendInfo.uid
																	 earliestDate:mostOldMessage.modifiedDate
																  withErrorString:&errorString];
	if (serverMessages.count == 0) {
		if ([[MMMessageSyncer shareInstance] lastError] != 200) {
			NSLog(@"statusCode = %d", [[MMMessageSyncer shareInstance] lastError]);
		}
		
		if (!errorString) {
			[userInfo setObject:[NSNumber numberWithBool:NO] forKey:@"moreOldMessage"];
		}
		
		dispatch_async(dispatch_get_main_queue(), ^{
			[super afterDownOldMessage:userInfo];
		});
		return;
	}

	NSMutableArray* newArray = [NSMutableArray arrayWithArray:messageArray];
	for (MMMessageInfo* serverMessageInfo in serverMessages) {
		[newArray addObject:serverMessageInfo];
		[indexPaths addObject:[NSIndexPath indexPathForRow:(newArray.count - 1) inSection:0]];
	}
	
	//下载完成
	[userInfo setObject:newArray forKey:@"newArray"];
	if (serverMessages.count > 0) {
		[userInfo setObject:indexPaths forKey:@"IndexPaths"];
		[userInfo setObject:[NSNumber numberWithBool:YES] forKey:@"isMessageReceived"];
	} else if (!errorString) {	//正常下载数量为0,没有旧动态需要下载 
		[userInfo setObject:[NSNumber numberWithBool:NO] forKey:@"moreOldMessage"];
	}
	
	dispatch_async(dispatch_get_main_queue(), ^{
		[super afterDownOldMessage:userInfo];
	});
}

- (void)dealloc {
	self.currentFriendInfo = nil;
	[super dealloc];
}

#pragma mark UITableViewDataSource Methods
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return messageArray.count;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	MMMessageCell* cell = (MMMessageCell*)[tableView dequeueReusableCellWithIdentifier:@"MMMessageCell"];
	if (cell == nil) {
		cell = [[[MMMessageCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"MMMessageCell"] autorelease];
         cell.delegate = messageCellDelegate;
	}
	
	@synchronized(self) {
		MMMessageInfo* messageInfo = [self.messageArray objectAtIndex:indexPath.row];
		[cell setMessageInfo:messageInfo];
	}
	
	return cell;
}

@end
