//
//  MMAvatarImageView.m
//  momo
//
//  Created by jackie on 11-7-25.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MMAvatarImageView.h"
#import "MMThemeMgr.h"
#import "MMMomoUserMgr.h"

@implementation MMAvatarImageView
@synthesize imageURL, placeholderImage;
@synthesize uid = uid_;

- (id)initWithFrame:(CGRect)frame {
	if (self = [super initWithFrame:frame]) {
		self.placeholderImage = [MMThemeMgr imageNamed:@"momo_dynamic_head_portrait.png"];
		self.image = placeholderImage;
        self.contentMode = UIViewContentModeScaleAspectFill;
	}
	return self;
}

- (id)initWithAvatarImageURL:(NSString *)avatarImageURL {
	if (self = [super init]) {
		self.placeholderImage = [MMThemeMgr imageNamed:@"momo_dynamic_head_portrait.png"];
		self.imageURL = avatarImageURL;
		self.image = placeholderImage;
        self.contentMode = UIViewContentModeScaleAspectFill;
	}
	return self;
}

- (void)dealloc {
	self.imageURL = nil;
	self.placeholderImage = nil;
	[super dealloc];
}

- (void)removeFromSuperview {
	[[MMAvatarMgr shareInstance] removeDelegate:self avatarImageURL:imageURL];
    [[MMMomoUserMgr shareInstance] removeAvatarObserver:self];
	[super removeFromSuperview];
}

- (void)resetImageView {
	if (imageURL) {
		[[MMAvatarMgr shareInstance] removeDelegate:self avatarImageURL:imageURL];
		[[MMMomoUserMgr shareInstance] removeAvatarObserver:self];
        
		[imageURL release];
		imageURL = nil;
	}
	self.image = placeholderImage;
}

- (void)setUid:(NSInteger)uid {
    uid_ = uid;
    
    NSString* url = [[MMMomoUserMgr shareInstance] avatarImageUrlByUserId:uid_];
    self.imageURL = url;
    
    if (uid > 0) {
        [[MMMomoUserMgr shareInstance] addAvatarChangeObserverForUid:uid observer:self];
    }
}

- (void)setImageURL:(NSString *)newImageURL {
	if (newImageURL && 
		[newImageURL isKindOfClass:[NSString class]] && 
		newImageURL.length > 0) {
		[newImageURL retain];
	}
	
	[self resetImageView];
	
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
			self.image = avatarImage;
		}
	}
}

#pragma mark --
#pragma mark MMAvatarMgrDelegate
- (void)downloadAvatarDidSuccess:(NSString*)url image:(UIImage*)newImage {
	if (![imageURL isEqualToString:url]) {
		return;
	}
	
	self.image = newImage;
}

#pragma mark MMMomoUserDelegate
- (void)userAvatarDidChange:(NSString *)avatarURL {
    self.imageURL = avatarURL;
}

@end
