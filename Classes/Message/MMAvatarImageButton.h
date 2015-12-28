//
//  MMAvatarImageButton.h
//  momo
//
//  Created by jackie on 11-7-25.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MMAvatarMgr.h"

@interface MMAvatarImageButton : UIButton {
	NSString* imageURL;
	UIImage* placeholderImage;
}
@property (nonatomic, copy) NSString* imageURL;
@property (nonatomic, retain) UIImage* placeholderImage;

@property (nonatomic) BOOL isSetImage;

- (id)initWithAvatarImageURL:(NSString*)avatarImageURL;
- (id)initWithAvatarImageURL:(NSString*)avatarImageURL frame:(CGRect)newFrame;

@end
