//
//  MMUploadQueue.h
//  momo
//
//  Created by wangsc on 11-2-12.
//  Copyright 2011 ND. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DbStruct.h"
#import "MMMessageDelegate.h"
#import "ASIHTTPRequest.h"

typedef enum {
	UQ_NONE,
	UQ_MESSAGE,
	UQ_MESSAGE_IMAGE_STEP1,
	UQ_MESSAGE_IMAGE_STEP2,
	UQ_MESSAGE_IMAGE_STEP3,
	UQ_COMMENT,
	UQ_RETWEET,
} UploadQueueStatus;

@interface MMUploadQueue : NSObject <UIAlertViewDelegate, ASIHTTPRequestDelegate>{
	NSMutableArray*	taskList;
	MMDraftInfo*	currentDraft;
	BOOL isUploading;
	
	//uploading infomation
	UploadQueueStatus uploadStatus;
	ASIHTTPRequest* currentUploadRequest;
	
	NSInteger currentUploadImageIndex;
	NSMutableArray* uploadedImageIds;
	NSString*	imgUploadId;
	NSData*	currentUploadImageData;
	NSString* currentUploadProgress;
}
@property (nonatomic, retain) NSMutableArray* taskList;
@property (nonatomic) BOOL isUploading;
@property (nonatomic, retain) MMDraftInfo* currentDraft;
@property (nonatomic, retain) ASIHTTPRequest* currentUploadRequest;
@property (nonatomic, copy) NSString* imgUploadId;
@property (nonatomic, retain) NSData*	currentUploadImageData;
@property (nonatomic, copy) NSString* currentUploadProgress;

+ (MMUploadQueue*)shareInstance;

- (void)addUploadTask:(MMDraftInfo*)draftInfo;

- (void)addUploadTaskArray:(NSArray*)draftArray;

- (void)removeAllTask;

- (void)startUpload;
- (BOOL)stopUpload:(NSUInteger)draftId;
- (void)resetUploadStatus;

- (void)updateUploadProgress:(BOOL)isCurrentRequestFinished isAllFinished:(BOOL)isAllFinished;

- (void)uploadNextImage;
- (void)startUploadMessage:(MMDraftInfo*)draftInfo;
- (void)startUploadRetweet:(MMDraftInfo*)draftInfo;
- (void)startUploadComment:(MMDraftInfo*)draftInfo;

- (void)onUploadMessageSuccess:(ASIHTTPRequest*)request;
- (void)onUploadMessageFailed:(ASIHTTPRequest*)request;

- (void)onUploadImageStep1Success:(ASIHTTPRequest*)request;
- (void)onUploadImageStep1Failed:(ASIHTTPRequest*)request;
- (void)onUploadImageStep2Success:(ASIHTTPRequest*)request;
- (void)onUploadImageStep2Failed:(ASIHTTPRequest*)request;

- (void)onUploadRetweetSuccess:(ASIHTTPRequest*)request;
- (void)onUploadRetweetFailed:(ASIHTTPRequest*)request;

- (void)onUploadCommentSuccess:(ASIHTTPRequest*)request;
- (void)onUploadCommentFailed:(ASIHTTPRequest*)request;

@end
