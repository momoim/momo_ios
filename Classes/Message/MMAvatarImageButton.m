//
//  MMAvatarImageButton.m
//  momo
//
//  Created by jackie on 11-7-25.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MMAvatarImageButton.h"
#import "MMThemeMgr.h"

@implementation MMAvatarImageButton
@synthesize imageURL, placeholderImage;

@synthesize isSetImage;

- (id)initWithAvatarImageURL:(NSString*)avatarImageURL {
	CGRect newFrame = CGRectMake(0, 0, 0, 0);
	return [self initWithAvatarImageURL:avatarImageURL frame:newFrame];
}

- (id)initWithFrame:(CGRect)frame {
	return [self initWithAvatarImageURL:nil frame:frame];
}

- (id)initWithAvatarImageURL:(NSString*)avatarImageURL frame:(CGRect)newFrame {
	if (self = [super initWithFrame:newFrame]) {
		self.placeholderImage = [MMThemeMgr imageNamed:@"momo_dynamic_head_portrait.png"];
		self.imageURL = avatarImageURL;
		[self setBackgroundImage:placeholderImage forState:UIControlStateNormal];
		[self setBackgroundImage:placeholderImage forState:UIControlStateHighlighted];
        
        self.imageView.contentMode = UIViewContentModeScaleAspectFill;
	}
	return self;
}

- (void)dealloc {
	if (imageURL) {
		[imageURL release];
		imageURL = nil;
	}

	self.placeholderImage = nil;
	[super dealloc];
}

- (void)removeFromSuperview {
	[[MMAvatarMgr shareInstance] removeDelegate:self avatarImageURL:imageURL];
	[super removeFromSuperview];
}

- (void)resetImageButton {
	if (imageURL) {
		[[MMAvatarMgr shareInstance] removeDelegate:self avatarImageURL:imageURL];
		
		[imageURL release];
		imageURL = nil;
	}
	[self setBackgroundImage:placeholderImage forState:UIControlStateNormal];
	[self setBackgroundImage:placeholderImage forState:UIControlStateHighlighted];
}

- (void)setImageURL:(NSString *)newImageURL {
	if (newImageURL && 
		[newImageURL isKindOfClass:[NSString class]] && 
		newImageURL.length > 0) {
		[newImageURL retain];
	}
	
	[self resetImageButton];
	
	if (newImageURL && 
		[newImageURL isKindOfClass:[NSString class]] && 
		newImageURL.length > 0) {
		imageURL = [newImageURL copy];
		[newImageURL release];
		
		//载入新头像
		UIImage* avatarImage = [[MMAvatarMgr shareInstance] imageFromURL:imageURL];
		if (!avatarImage) {
			[[MMAvatarMgr shareInstance] downImageByURLAsync:imageURL delegate:self];
		} else {
			if (isSetImage) {
                [self setImage:avatarImage forState:UIControlStateNormal];
                [self setImage:avatarImage forState:UIControlStateHighlighted];
            } else {
                [self setBackgroundImage:avatarImage forState:UIControlStateNormal];
                [self setBackgroundImage:avatarImage forState:UIControlStateHighlighted];
            }
		}
	}
}

#pragma mark --
#pragma mark MMAvatarMgrDelegate
- (void)downloadAvatarDidSuccess:(NSString*)url image:(UIImage*)newImage {
	if (![imageURL isEqualToString:url]) {
		return;
	}
	
    if (isSetImage) {
        [self setImage:newImage forState:UIControlStateNormal];
        [self setImage:newImage forState:UIControlStateHighlighted];
    } else {
        [self setBackgroundImage:newImage forState:UIControlStateNormal];
        [self setBackgroundImage:newImage forState:UIControlStateHighlighted];
    }
    
}

@end
