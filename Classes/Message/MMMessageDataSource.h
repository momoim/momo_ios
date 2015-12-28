//
//  MMMessageDataSource.h
//  momo
//
//  Created by wangsc on 10-12-24.
//  Copyright 2010 ND. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MMMessageDelegate.h"
#import "MMMessageCell.h"

typedef enum {
	MMDownNone,
	MMDownInitial,
	MMDownRecent,
	MMDownOld,
} MMMessageDownloadState;
NSInteger messageInfoCompare(MMMessageInfo* messageInfo1, MMMessageInfo* messageInfo2, void* context);

@interface MMMessageDataSource : NSObject <UITableViewDataSource> {
	NSMutableArray* uploadMessageArray;
	NSMutableArray* messageArray;
	
	MMMessageDownloadState	downLoadState;
	id<MMMessageDelegate> messageDelegate;
	id<MMMessageCellDelegate> messageCellDelegate;
	
	BOOL localDBReachEnd;
    
    //当前查看的群组动态信息
	MMGroupInfo* currentGroupInfo_;
	
	NSMutableArray* backgroundThreads;
}
@property (nonatomic, retain) NSMutableArray* messageArray;
@property (nonatomic, retain) NSMutableArray* uploadMessageArray;
@property (nonatomic) MMMessageDownloadState downLoadState;
@property (nonatomic, assign) id<MMMessageDelegate> messageDelegate;
@property (nonatomic, assign) id<MMMessageCellDelegate> messageCellDelegate;
@property (nonatomic) BOOL localDBReachEnd;

@property (nonatomic, retain) MMGroupInfo*		currentGroupInfo;

- (void)initData;

- (void)cancelThreads;
- (BOOL)downMessage:(MMMessageDownloadState)downType;

- (void)downInitialThread:(id)object;
- (void)downRecentMessageThread:(id)object;
- (void)downOldMessageThread:(id)object;

- (void)downRecentMessage;
- (void)afterDownRecentMessage:(NSMutableDictionary*)userInfo;
- (void)downOldMessage;
- (void)afterDownOldMessage:(NSDictionary*)userInfo;
- (void)setMessageRecentComment:(MMCommentInfo*)commentInfo;

- (NSInteger)indexForMessage:(NSString*)statusId;
- (NSIndexPath*)indexPathForMessage:(NSString*)statusId;

- (MMMessageInfo*)getMessageInfo:(NSString*)statusId;

- (void)reset;

//uploading message
- (void)addUploadMessage:(MMMessageInfo*)newMessageInfo;
- (void)updateMessageStatus:(UploadStatus)uploadStatus draftId:(NSUInteger)draftId;
- (void)updateMessageDraft:(MMMessageInfo*)messageDraftInfo;
- (NSIndexPath*)getUploadMessageIndexPath:(NSUInteger)draftId;
- (NSIndexPath*)deleteUploadMessage:(NSUInteger)draftId;

@end
