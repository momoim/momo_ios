//
//  MMUploadQueue.m
//  momo
//
//  Created by wangsc on 11-2-12.
//  Copyright 2011 ND. All rights reserved.
//

#import "MMUploadQueue.h"
#import "MMGlobalData.h"
#import "MMDraft.h"
#import "MMMessageSyncer.h"
#import "MMGlobalPara.h"
#import "MMUapRequest.h"
#import "SBJSON.h"
#import "MMDraftMgr.h"
#import "MMLoginService.h"
#import "MMLogger.h"

static MMUploadQueue* instance = nil;

@implementation MMUploadQueue
@synthesize taskList, isUploading, currentDraft, currentUploadRequest, imgUploadId, currentUploadImageData;
@synthesize currentUploadProgress;

+ (MMUploadQueue*)shareInstance {
	if (!instance) {
		instance = [[MMUploadQueue alloc] init];
	}
	return instance;
}

- (id)init {
	if (self = [super init]) {
		taskList = [[NSMutableArray alloc] init];
		isUploading = NO;
		uploadStatus = UQ_NONE;
		currentUploadImageIndex = -1;
		currentUploadProgress = nil;
		
		uploadedImageIds = [[NSMutableArray alloc] init];
	}
	return self;
} 

- (void)dealloc {
	[taskList release];
	[uploadedImageIds release];
	[super dealloc];
}

- (void)addUploadTask:(MMDraftInfo*)draftInfo {
	@synchronized(self){
        draftInfo.uploadErrorString = nil;
		[taskList addObject:draftInfo];
	}
	
	draftInfo.uploadStatus = uploadWait;
	if (!isUploading) {
		isUploading = YES;
		[self startUpload];
	}
}

- (void)addUploadTaskArray:(NSArray*)draftArray {
	@synchronized(self){
		[taskList addObjectsFromArray:draftArray];
	}
	if (!isUploading) {
		isUploading = YES;
		[self startUpload];
	}
}

- (BOOL)stopUpload:(NSUInteger)draftId {
	@synchronized(self){
		if (currentDraft.draftId == draftId) {
			self.currentDraft = nil;
			if (uploadStatus != UQ_NONE) {
				if (currentUploadRequest && ![currentUploadRequest isFinished]) {
					[currentUploadRequest clearDelegatesAndCancel];
				}
			}
			return YES;
		} else {
			for (MMDraftInfo* draftInfo in taskList) {
				if (draftInfo.draftId == draftId && currentDraft.draftId != draftId) {
					[taskList removeObject:draftInfo];
					return TRUE;
				}
			}
		}
	}
	return NO;
}

- (void)removeAllTask {
	@synchronized(self){
		self.currentDraft = nil;
		if (currentUploadRequest) {
			if (![currentUploadRequest isFinished]) {
				[currentUploadRequest clearDelegatesAndCancel];
			}
			self.currentUploadRequest = nil;
		}
		
		[taskList removeAllObjects];
        isUploading = NO;
	}
}

- (void)startUpload {
	if (taskList.count > 0) {
		MMDraftInfo* draftInfo = [taskList objectAtIndex:0];
		self.currentDraft = draftInfo;
		@synchronized(self) {
			[taskList removeObjectAtIndex:0];
		}
		
		currentDraft.uploadStatus = uploadUploading;
		[[MMDraftMgr shareInstance] changeDraftStatus:draftInfo];
		
		switch (currentDraft.draftType) {
			case draftMessage: {
                if (draftInfo.attachImagePaths && draftInfo.attachImagePaths.count > 0) {
                    [self uploadNextImage];
                } else {
                    [self startUploadMessage:currentDraft];
                }
                [self updateUploadProgress:NO isAllFinished:NO];
			}
				break;
			case draftComment:
				[self startUploadComment:currentDraft];
				break;
			case draftRetweet: {
                [self startUploadRetweet:currentDraft];
                [self updateUploadProgress:NO isAllFinished:NO];
                break;
			}
			default:
				break;
		}
	}
}

- (void)resetUploadStatus {
	[uploadedImageIds removeAllObjects];
	
	if (imgUploadId) {
		self.imgUploadId = nil;
	}

	currentUploadImageIndex = -1;
	uploadStatus = UQ_NONE;
	
	if (currentUploadRequest) {
		self.currentUploadRequest = nil;
	}
}

- (void)onTaskDone:(MMDraftInfo*)draftInfo {
    if (draftInfo) {
        [[MMDraftMgr shareInstance] changeDraftStatus:draftInfo];
    }
	
	@synchronized(self){
		[self resetUploadStatus];
		
		currentDraft.attachImages = nil;
		self.currentDraft = nil;
		uploadStatus = UQ_NONE;
	}
	
	if (taskList.count > 0) {
		[self startUpload];
	} else {
        isUploading = NO;
    }
}

- (void)startUploadMessage:(MMDraftInfo*)draftInfo {
	uploadStatus = UQ_MESSAGE;
	draftInfo.uploadStatus = uploadUploading;
	[[MMDraftMgr shareInstance] changeDraftStatus:draftInfo];
	
	NSMutableDictionary* postObject = [NSMutableDictionary dictionary];
	[postObject setObject:[draftInfo textToUpload] forKey:@"text"];
	[postObject setObject:[NSNumber numberWithBool:draftInfo.syncToWeibo] forKey:@"sync"];
	
	NSMutableDictionary* accesseryObject = [NSMutableDictionary dictionary];
	NSMutableArray* tmpImageIds = [NSMutableArray arrayWithCapacity:uploadedImageIds.count];
	for (NSNumber* imageId in uploadedImageIds) {
		NSDictionary* srcDict = [NSDictionary dictionaryWithObject:imageId forKey:@"id"];
		[tmpImageIds addObject:srcDict];
	}
	
	[accesseryObject setObject:tmpImageIds forKey:@"image"];
	[postObject setObject:accesseryObject forKey:@"accessery"];
    
    if (draftInfo.extendInfo) {
        //包含地理信息
        if ([draftInfo.extendInfo objectForKey:@"longitude"] 
            && [draftInfo.extendInfo objectForKey:@"latitude"] 
            && [draftInfo.extendInfo objectForKey:@"isCorrect"])
            {
            NSMutableDictionary* locationDict = [NSMutableDictionary dictionary];
            [locationDict setObject:[draftInfo.extendInfo objectForKey:@"longitude"] forKey:@"longitude"];
            [locationDict setObject:[draftInfo.extendInfo objectForKey:@"latitude"] forKey:@"latitude"];
            [locationDict setObject:[draftInfo.extendInfo objectForKey:@"address"] forKey:@"address"];
            [locationDict setObject:[draftInfo.extendInfo objectForKey:@"isCorrect"] forKey:@"isCorrect"];
            [postObject setObject:locationDict forKey:@"location"];
            }
    }
	
	if (draftInfo.groupId > 0) {
        [postObject setObject:[NSNumber numberWithInt:1] forKey:@"group_type"];
        [postObject setObject:[NSNumber numberWithInt:draftInfo.groupId] forKey:@"group_id"];
	}
	
	if (draftInfo.ownerId != [[MMLoginService shareInstance] getLoginUserId]) {
		return [self onUploadMessageFailed:nil];
	}
	
	NSString* strSource = @"record/create.json";
	self.currentUploadRequest = [MMUapRequest postAsync:strSource withObject:postObject withDelegate:self];
	if (!currentUploadRequest) {
		return [self onUploadMessageFailed:nil];
	}
	
	[currentUploadRequest startAsynchronous];
}

- (void)startUploadRetweet:(MMDraftInfo*)draftInfo {
	uploadStatus = UQ_RETWEET;
	draftInfo.uploadStatus = uploadUploading;
	[[MMDraftMgr shareInstance] changeDraftStatus:draftInfo];
	
	NSMutableDictionary* postObject = [NSMutableDictionary dictionary];
	[postObject setObject:[draftInfo textToUpload] forKey:@"text"];
	[postObject setObject:[NSNumber numberWithBool:draftInfo.syncToWeibo] forKey:@"sync"];
	
	[postObject setObject:draftInfo.retweetStatusId forKey:@"retweet_id"];
	
	if (draftInfo.groupId > 0) {
        [postObject setObject:[NSNumber numberWithInt:1] forKey:@"group_type"];
        [postObject setObject:[NSNumber numberWithInt:draftInfo.groupId] forKey:@"group_id"];
	}
    
    if (draftInfo.extendInfo) {
        //包含地理信息
        if ([draftInfo.extendInfo objectForKey:@"longitude"] && [draftInfo.extendInfo objectForKey:@"latitude"]) {
            NSMutableDictionary* locationDict = [NSMutableDictionary dictionary];
            [locationDict setObject:[draftInfo.extendInfo objectForKey:@"longitude"] forKey:@"longitude"];
            [locationDict setObject:[draftInfo.extendInfo objectForKey:@"latitude"] forKey:@"latitude"];
            [postObject setObject:locationDict forKey:@"location"];
        }
    }
	
	if (draftInfo.ownerId != [[MMLoginService shareInstance] getLoginUserId]) {
		return [self onUploadRetweetFailed:nil];
	}
	
	NSString* strSource = @"record/create.json";
	self.currentUploadRequest = [MMUapRequest postAsync:strSource withObject:postObject withDelegate:self];
	if (!currentUploadRequest) {
		return [self onUploadRetweetFailed:nil];
	}
	[currentUploadRequest startAsynchronous];
}

- (void)startUploadComment:(MMDraftInfo*)draftInfo {
	uploadStatus = UQ_COMMENT;
	draftInfo.uploadStatus = uploadUploading;
	[[MMDraftMgr shareInstance] changeDraftStatus:draftInfo];
	
	NSMutableDictionary* postObject = [NSMutableDictionary dictionary];
	[postObject setObject:draftInfo.replyStatusId forKey:@"statuses_id"];
	[postObject setObject:PARSE_NULL_STR(draftInfo.replyCommentId) forKey:@"comment_id"];
	[postObject setObject:[draftInfo textToUpload] forKey:@"text"];
	
	if (draftInfo.ownerId != [[MMLoginService shareInstance] getLoginUserId]) {
		return [self onUploadCommentFailed:nil];;
	}
	
	NSString* strSource = @"comment/create.json";
	self.currentUploadRequest = [MMUapRequest postAsync:strSource withObject:postObject withDelegate:self];
	if (!currentUploadRequest) {
		return [self onUploadCommentFailed:nil];
	}
	[currentUploadRequest startAsynchronous];
}

- (void)requestFinished:(ASIHTTPRequest*)request {
	NSInteger statusCode = [request responseStatusCode];
    
	NSDictionary* retObject = [request responseObject];
	NSString *msg = [retObject valueForKey:@"error"];	
	int code = [[retObject valueForKey:@"code"] intValue];
	DLOG(@"status code = %d, error = %@", code, msg);
    
	if (statusCode != 200) {
		return [self requestFailed:request];
	}
	
	switch (uploadStatus) {
		case UQ_MESSAGE:
		{
        [self updateUploadProgress:YES isAllFinished:YES];
        [self onUploadMessageSuccess:request];
		}
			break;
		case UQ_RETWEET:
		{
        [self updateUploadProgress:YES isAllFinished:YES];
        [self onUploadRetweetSuccess:request];
		}
			break;
		case UQ_COMMENT:
		{
        [self onUploadCommentSuccess:request];
		}
			break;
		case UQ_MESSAGE_IMAGE_STEP1:
		{
        [self onUploadImageStep1Success:request];
		}
			break;
		case UQ_MESSAGE_IMAGE_STEP2:
		{
        [self onUploadImageStep2Success:request];
		}
			break;
		default:
			break;
	}
}

- (void)requestFailed:(ASIHTTPRequest*)request {
	switch (uploadStatus) {
		case UQ_MESSAGE: {
            [self onUploadMessageFailed:request];
		}
			break;
		case UQ_RETWEET: {
            [self onUploadRetweetFailed:request];
		}
			break;
		case UQ_COMMENT: {
            [self onUploadCommentFailed:request];
		}
			break;
		case UQ_MESSAGE_IMAGE_STEP1: {
            [self onUploadImageStep1Failed:request];
		}
			break;
		case UQ_MESSAGE_IMAGE_STEP2: {
            [self onUploadImageStep2Failed:request];
		}
			break;
		default:
			break;
	}
}

- (void)onUploadMessageSuccess:(ASIHTTPRequest*)request {
	currentDraft.uploadStatus = uploadSuccess;
	
	if (currentDraft.attachImagePaths) {
		for (NSString* imagePath in currentDraft.attachImagePaths) {
			[[NSFileManager defaultManager] removeItemAtPath:imagePath error:nil];
		}
	}
	[[MMDraft instance] deleteDraft:currentDraft.draftId];
	
    [self onTaskDone:currentDraft];
}

- (void)onUploadMessageFailed:(ASIHTTPRequest*)request {
	currentDraft.uploadStatus = uploadFailed;
	if (currentDraft) {
        NSDictionary* retObject = [request responseObject];
        NSString *msg = [retObject valueForKey:@"error"];	
        if (msg.length > 0) {
            currentDraft.uploadErrorString = msg;
        } else{
            currentDraft.uploadErrorString = nil;
        }
	}
    [self onTaskDone:currentDraft];
}

- (void)onUploadRetweetSuccess:(ASIHTTPRequest*)request {
	currentDraft.uploadStatus = uploadSuccess;
    [self onTaskDone:currentDraft];
	[[MMDraft instance] deleteDraft:currentDraft.draftId];
}

- (void)onUploadRetweetFailed:(ASIHTTPRequest*)request {
	currentDraft.uploadStatus = uploadFailed;
	if (currentDraft) {
        NSDictionary* retObject = [request responseObject];
        NSString *msg = [retObject valueForKey:@"error"];	
        if (msg.length > 0) {
            currentDraft.uploadErrorString = msg;
        } else{
            currentDraft.uploadErrorString = nil;
        }
	}
    [self onTaskDone:currentDraft];
}

- (void)onUploadCommentSuccess:(ASIHTTPRequest*)request {
	currentDraft.uploadStatus = uploadSuccess;
    [self onTaskDone:currentDraft];
	[[MMDraft instance] deleteDraft:currentDraft.draftId];
}

- (void)onUploadCommentFailed:(ASIHTTPRequest*)request {
	currentDraft.uploadStatus = uploadFailed;
	if (currentDraft) {
        NSDictionary* retObject = [request responseObject];
        NSString *msg = [retObject valueForKey:@"error"];	
        if (msg.length > 0) {
            currentDraft.uploadErrorString = msg;
        } else{
            currentDraft.uploadErrorString = nil;
        }
	}
    [self onTaskDone:currentDraft];
}

- (void)uploadNextImage {
	if (currentDraft.attachImagePaths.count == (NSUInteger)(currentUploadImageIndex + 1)) {
		self.currentUploadImageData = nil;
		return [self startUploadMessage:currentDraft];
	}
    
    if (currentDraft.attachImagePaths.count < (NSUInteger)(currentUploadImageIndex + 1)) {
        currentDraft.uploadStatus = uploadFailed;
        [self onTaskDone:currentDraft];
        return;
    }
	
	currentUploadImageIndex++;
	if (!currentDraft) {
		return;
	}
	
	NSString* imagePath = [currentDraft.attachImagePaths objectAtIndex:currentUploadImageIndex];
	if ([[NSFileManager defaultManager] fileExistsAtPath:imagePath]) {
		self.currentUploadImageData = [NSData dataWithContentsOfFile:imagePath];
	}
	
	if (!currentUploadImageData) {
		[self onUploadMessageFailed:nil];
		return;
	}
	
	uploadStatus = UQ_MESSAGE_IMAGE_STEP1;
	self.currentUploadRequest = [MMUapRequest uploadPhotoStep1Async:currentUploadImageData 
                                                       withDelegate:self]; 
	if (!currentUploadRequest) {
		return [self onUploadMessageFailed:nil];
	}
	[currentUploadRequest startAsynchronous];
}

- (void)onUploadImageStep1Success:(ASIHTTPRequest*)request {
	int statusCode = [request responseStatusCode];
    NSDictionary* retDict = [request responseObject];
	if (statusCode != 200) {	//relogin
		if (retDict && ![retDict isKindOfClass:[NSDictionary class]]) {
			NSString* errorStr = [retDict objectForKey:@"error"];
			DLOG(@"%@", errorStr);
		}
		
		[self onUploadImageStep1Failed:request];
		return;
	}
    
	NSNumber* imageId = [retDict objectForKey:@"id"];
	if (imageId) {	
		//image already exist
		[uploadedImageIds addObject:imageId];
		[self updateUploadProgress:YES isAllFinished:NO];
		
		[self uploadNextImage];
		return;
	}
	
	uploadStatus = UQ_MESSAGE_IMAGE_STEP2;
	self.imgUploadId = [retDict objectForKey:@"upload_id"];
	self.currentUploadRequest = [MMUapRequest uploadPhotoStep2Async:currentUploadImageData uploadId:imgUploadId 
                                                       withDelegate:self]; 
	self.currentUploadImageData = nil;
	if (!currentUploadRequest) {
		return [self onUploadImageStep1Failed:nil];
	}
	[currentUploadRequest startAsynchronous];
}

- (void)onUploadImageStep1Failed:(ASIHTTPRequest*)request {
	currentDraft.uploadStatus = uploadFailed;
	[self onTaskDone:currentDraft];
}

- (void)onUploadImageStep2Success:(ASIHTTPRequest*)request {
	int statusCode = [request responseStatusCode];
	NSDictionary* retDict = [request responseObject];
	
	if (!retDict || ![retDict isKindOfClass:[NSDictionary class]]) {
		[self onUploadImageStep2Failed:request];
		return;
	}
	
	if (statusCode != 200) {	//relogin
		NSString* errorStr = [retDict objectForKey:@"error"];
		DLOG(@"%@", errorStr);
		[self onUploadImageStep2Failed:request];
		return;
	}
	
	NSNumber* imageId = [retDict objectForKey:@"id"];
	if (!imageId || ![imageId isKindOfClass:[NSNumber class]]) {
		if (retDict && [retDict isKindOfClass:[NSDictionary class]]) {
			NSString* errorStr = [retDict objectForKey:@"error"];
			DLOG(@"%@", errorStr);
		}
		
		[self onUploadImageStep2Failed:request];
		return;
	}
	
	[uploadedImageIds addObject:imageId];
	[self updateUploadProgress:YES isAllFinished:NO];
	
	[self uploadNextImage];
}

- (void)onUploadImageStep2Failed:(ASIHTTPRequest*)request {
	currentDraft.uploadStatus = uploadFailed;
	[self onTaskDone:currentDraft];
}

- (void)updateUploadProgress:(BOOL)isCurrentRequestFinished isAllFinished:(BOOL)isAllFinished {
	NSUInteger totalCount = 1; 
	if (currentDraft.attachImagePaths.count > 0) {
		totalCount += currentDraft.attachImagePaths.count;
	}
	
	if (isAllFinished) {
		self.currentUploadProgress = [NSString stringWithFormat:@"%d/%d", totalCount, totalCount];
		return;
	} else {
		NSUInteger currentFinished = 0;
		if (currentUploadImageIndex >= 0) {
			currentFinished = currentUploadImageIndex;
			if (isCurrentRequestFinished) {
				currentFinished++;
			}
		} else {
			currentFinished = currentDraft.attachImagePaths.count;
		}
		
		self.currentUploadProgress = [NSString stringWithFormat:@"%d/%d", currentFinished, totalCount];
	}
    
	DLOG(@"%@", currentUploadProgress);
}

@end
