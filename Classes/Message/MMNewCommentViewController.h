//
//  MMNewCommentViewController.h
//  momo
//
//  Created by wangsc on 11-1-30.
//  Copyright 2011 ND. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DbStruct.h"
#import "MMNewMessageViewController.h"

@interface MMNewCommentViewController : MMNewMessageViewController {
	MMMessageInfo*	replyMessageInfo;
	MMCommentInfo*  replyCommentInfo;
	NSString*		startString;
}
@property (nonatomic, retain) MMMessageInfo*	replyMessageInfo;
@property (nonatomic, retain) MMCommentInfo*  replyCommentInfo;
@property (nonatomic, copy) NSString*		startString;

- (id)initWithMessageInfo:(MMMessageInfo*)messageInfo replyComment:(MMCommentInfo*)commentInfo;

@end
