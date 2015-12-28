//
//  MMAvatarImageView.h
//  momo
//
//  Created by jackie on 11-7-25.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MMAvatarMgr.h"
#import "MMMomoUserMgr.h"

@interface MMAvatarImageView : UIImageView<MMAvatarMgrDelegate, MMMomoUserDelegate> {
	NSString* imageURL;
	UIImage* placeholderImage;
    
    NSInteger uid_;
}
@property (nonatomic, copy) NSString* imageURL;
@property (nonatomic, retain) UIImage* placeholderImage;
@property (nonatomic) NSInteger uid;

- (id)initWithAvatarImageURL:(NSString*)avatarImageURL;

@end
