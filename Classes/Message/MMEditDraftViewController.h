//
//  MMEditDraftViewController.h
//  momo
//
//  Created by jackie on 11-3-8.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MMNewMessageViewController.h"

@interface MMEditDraftViewController : MMNewMessageViewController {
	MMDraftInfo* messageDraft;
	
	BOOL	attachImagesChanged;
	NSMutableArray* selectImageBackup;
}
@property (nonatomic, retain) NSMutableArray* selectImageBackup;
@property (nonatomic, retain) MMDraftInfo* messageDraft;

- (id)initWithDraft:(MMDraftInfo *)draftInfo;

@end
