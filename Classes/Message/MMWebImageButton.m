//
//  MMWebImageButton.m
//  momo
//
//  Created by jackie on 11-5-9.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MMWebImageButton.h"
#import "MMThemeMgr.h"
#import "MMCommonAPI.h"
#import "MMLogger.h"

@implementation MMWebImageButton
@synthesize placeholderImage, imageURL, delegate, indicatorView;
@synthesize cachePolicy, storagePolicy, ignoreGPRS, stopDownloadImageAfterViewReleased;
@synthesize actionTarget, actionSelector;

- (id)initWithDefaultPlaceholderImage {
	return [self initWithPlaceholderImage:[MMThemeMgr imageNamed:@"momo_dynamic_picture_dolphin.png"]];
}

- (id)initWithAvatarPlaceholderImage {
	return [self initWithPlaceholderImage:[MMThemeMgr imageNamed:@"momo_dynamic_head_portrait.png"]];
}

- (id)initWithPlaceholderImage:(UIImage*)anImage {
	CGRect frame = CGRectMake(0, 0, anImage.size.width, anImage.size.height);
	return [self initWithPlaceholderImage:anImage frame:frame delegate:nil];
}

- (id)initWithPlaceholderImage:(UIImage*)anImage frame:(CGRect)frame {
	return [self initWithPlaceholderImage:anImage frame:frame delegate:nil];	
}

- (id)initWithPlaceholderImage:(UIImage*)anImage frame:(CGRect)frame delegate:(id<MMWebImageButtonDelegate>)aDelegate {
	if((self = [super initWithFrame:frame])) {
		self.placeholderImage = anImage;
		self.delegate = aDelegate;
		[self.imageView setContentMode:UIViewContentModeScaleAspectFill];
		[self setImage:self.placeholderImage forState:UIControlStateNormal];
		[self setImage:self.placeholderImage forState:UIControlStateHighlighted];
		
		cachePolicy = ASIOnlyLoadIfNotCachedCachePolicy;
		storagePolicy = ASICachePermanentlyCacheStoragePolicy;
		ignoreGPRS = NO;
		stopDownloadImageAfterViewReleased = YES;
		
		successLoadImage = NO;
		requestToDownload = NO;
		
		indicatorView = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite] autorelease];
		indicatorView.center = CGPointMake(self.frame.size.width / 2, self.frame.size.height / 2);
		[self addSubview:indicatorView];
	}
	
	return self;
}

- (void)setPlaceholderImageByPhotoId:(uint64_t)photoId {
	if (photoId > 0) {
		self.placeholderImage = [MMThemeMgr imageNamed:@"momo_dynamic_picture_dolphin.png"];
	} else {
		self.placeholderImage = [MMThemeMgr imageNamed:@"momo_dynamic_picture_lock.png"];
	}
}

- (void)removeAllActions {
	NSSet* allTargets = [self allTargets];
	for (NSObject* target in allTargets) {
		if (![target isKindOfClass:[NSNull class]]) {
			NSArray* allActions = [self actionsForTarget:target forControlEvent:UIControlEventTouchUpInside];
			if (!allActions || allActions.count == 0) {
				continue;
			}
			
			for (NSString* actionString in allActions) {
				[self removeTarget:target action:NSSelectorFromString(actionString) forControlEvents:UIControlEventTouchUpInside];
			}
		}
	}
}

- (void)resetImageURL:(NSString*)url {
	[self cancelImageLoad];
	[indicatorView stopAnimating];
	
	successLoadImage = NO;
	requestToDownload = NO;
	[self setImage:self.placeholderImage forState:UIControlStateNormal];
	[self setImage:self.placeholderImage forState:UIControlStateHighlighted];
	
	self.imageURL = url;
}

- (void)refreshImage {
	successLoadImage = NO;
	requestToDownload = NO;
	
	[self startLoading];
}

- (void)startLoading {
	if (!imageURL || imageURL.length == 0) {
		return;
	}
	
	if (successLoadImage) {
		return;
	}
	
	requestToDownload = YES;
	indicatorView.center = CGPointMake(self.frame.size.width / 2, self.frame.size.height / 2);
	[self.indicatorView startAnimating];
	
	[[MMHttpDownloadMgr shareInstance] downloadWithCachePolicy:imageURL 
													  delegate:self 
												   cachePolicy:cachePolicy 
											cacheStoragePolicy:storagePolicy];
}

- (void)removeFromSuperview {
	[self cancelImageLoad];
	
	[super removeFromSuperview];
}

- (void)cancelImageLoad {
	@synchronized (self) {
		if (!successLoadImage) {
			if (stopDownloadImageAfterViewReleased) {
				[[MMHttpDownloadMgr shareInstance] stopDownloadByDelegate:self];
			} else {
				[[MMHttpDownloadMgr shareInstance] removeDelegateAndNotStopDownload:self];
			}
		}
		
		[indicatorView stopAnimating];
	}
}

- (void)dealloc {
	if (placeholderImage) {
		[placeholderImage release];
	}
	[imageURL release];
	[super dealloc];
}

- (void)setTargetAndActionByImageURL:(id)target action:(SEL)aSelector withPhotoId:(uint64_t)photoId {
	if (photoId > 0) {
		[self setTargetAndActionForImageLoaded:target action:aSelector];
	} else {
		//外链图片点击不载入缩略图
		[self addTarget:target action:aSelector forControlEvents:UIControlEventTouchUpInside];
	}
}

- (void)setTargetAndActionForImageLoaded:(id)target action:(SEL)aSelector {
	self.actionTarget = target;
	self.actionSelector = aSelector;
	
	[self addTarget:self action:@selector(actionWrap) forControlEvents:UIControlEventTouchUpInside];
}

- (void)actionWrap {
	if (!requestToDownload && actionTarget) {
		requestToDownload = YES;
		[self startLoading];
		return;
	}
	
	@synchronized(self) {
		if (!successLoadImage && actionTarget) {
			return;
		}
		if (actionTarget && [(NSObject*)actionTarget respondsToSelector:actionSelector]) {
			[actionTarget performSelector:actionSelector withObject:self];
		}
	}
}

#pragma mark MMHttpDownloadDelegate
- (void)downloadDidSuccess:(NSString *)url {
	[self.indicatorView stopAnimating];
	
	NSData* imageData = [[MMHttpDownloadMgr shareInstance] dataFromCache:url];
	if (!imageData) {
		return;
	}
	
	UIImage* image = [UIImage imageWithData:imageData];
	if (!image) {
		[[MMHttpDownloadMgr shareInstance] removeCacheForUrl:url];
		return;
	}
	
	@synchronized (self) {
		[self setImage:image forState:UIControlStateNormal];
		[self setImage:image forState:UIControlStateHighlighted];
		[self setNeedsDisplay];
		
		if(delegate && [self.delegate respondsToSelector:@selector(imageButtonLoadedImage:)]) {
			[self.delegate imageButtonLoadedImage:self];
		}	
		
		successLoadImage = YES;
	}
}

- (void)downloadDidFailed:(NSString *)url {
	[self.indicatorView stopAnimating];
	
	DLOG(@"%@ download failed", url);
	
	@synchronized (self) {
		[[MMHttpDownloadMgr shareInstance] removeCacheForUrl:url];
		if(delegate && [self.delegate respondsToSelector:@selector(imageButtonFailedToLoadImage:)]) {
			[self.delegate imageButtonFailedToLoadImage:self];
		}
		
		successLoadImage = NO;
		requestToDownload = NO;
	}
}

@end