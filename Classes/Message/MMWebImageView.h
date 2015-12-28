//
//  MMWebImageView.h
//  momo
//
//  Created by jackie on 11-5-9.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MMHttpDownloadMgr.h"
#import "ASIHTTPRequest.h"

@protocol MMWebImageViewDelegate;
@interface MMWebImageView : UIImageView <MMHttpDownloadDelegate>{
	NSString* imageURL;
	UIImage* placeholderImage;
	UIActivityIndicatorView* indicatorView;
	
	id<MMWebImageViewDelegate> delegate;
	
	//setting
	BOOL	ignoreGPRS;					//default NO;
	ASICachePolicy cachePolicy;			//default ASIOnlyLoadIfNotCachedCachePolicy
	ASICacheStoragePolicy storagePolicy; //defualt ASICachePermanentlyCacheStoragePolicy
	BOOL	stopDownloadImageAfterViewReleased;	//default YES;
	
	BOOL	successLoadImage;
}
@property (nonatomic, copy) NSString* imageURL;
@property (nonatomic, retain) UIImage* placeholderImage;
@property(nonatomic, assign) id<MMWebImageViewDelegate> delegate;
@property (nonatomic, retain) UIActivityIndicatorView* indicatorView;

@property (nonatomic) BOOL	ignoreGPRS;	
@property (nonatomic) ASICachePolicy cachePolicy;
@property (nonatomic) ASICacheStoragePolicy storagePolicy;
@property (nonatomic) BOOL	stopDownloadImageAfterViewReleased;

- (id)initWithDefaultPlaceholderImage;
- (id)initWithAvatarPlaceholderImage;

- (id)initWithPlaceholderImage:(UIImage*)anImage;
- (id)initWithPlaceholderImage:(UIImage*)anImage delegate:(id<MMWebImageViewDelegate>)aDelegate;

- (void)startLoading;
- (void)cancelImageLoad;
- (void)resetImageURL:(NSString*)url;
- (void)refreshImage;

@end

@protocol MMWebImageViewDelegate <NSObject>
@optional
- (void)imageViewLoadedImage:(MMWebImageView*)imageView;
- (void)imageViewFailedToLoadImage:(MMWebImageView*)imageView;
@end

@interface UIImage(UIImageScale)
-(UIImage*)getSubImage:(CGRect)rect;
-(UIImage*)scaleToSize:(CGSize)size;
@end