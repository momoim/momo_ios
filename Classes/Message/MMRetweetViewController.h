//
//  MMRetweetViewController.h
//  momo
//
//  Created by wangsc on 11-2-25.
//  Copyright 2011 ND. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MMNewMessageViewController.h"

@interface MMRetweetViewController : MMNewMessageViewController {
	MMMessageInfo* retweetMessage;
}
@property (nonatomic, retain) MMMessageInfo* retweetMessage;

- (id)initWithRetweetMessage:(MMMessageInfo*)messageInfo;

@end
