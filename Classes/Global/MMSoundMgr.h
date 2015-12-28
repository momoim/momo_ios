//
//  MMSoundMgr.h
//  momo
//
//  Created by jackie on 11-8-16.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface MMSoundMgr : NSObject {
	NSMutableDictionary* soundNameAndIds;	
    BOOL isPlaying_;
}
@property (nonatomic) BOOL isPlaying;

+ (MMSoundMgr*)shareInstance;

- (void)playSound:(NSString*)fileName;

- (void)playNewMessageSound;
- (void)playVibrate;

@end
