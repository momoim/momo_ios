//
//  MMWebImageButton.h
//  momo
//
//  Created by jackie on 11-5-9.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MMHttpDownloadMgr.h"
#import "ASIHTTPRequest.h"

@protocol MMWebImageButtonDelegate;
@interface MMWebImageButton : UIButton<MMHttpDownloadDelegate>{
	NSString* imageURL;
	UIImage* placeholderImage;
	UIActivityIndicatorView* indicatorView;
	
	id<MMWebImageButtonDelegate> delegate;
	
	//setting
	BOOL	ignoreGPRS;					//default NO;
	ASICachePolicy cachePolicy;			//default ASIOnlyLoadIfNotCachedCachePolicy
	ASICacheStoragePolicy storagePolicy; //defualt ASICachePermanentlyCacheStoragePolicy
	BOOL	stopDownloadImageAfterViewReleased;	//default YES;
	
	//status
	BOOL	successLoadImage;
	BOOL	requestToDownload;
	
	//action wrap
	id		actionTarget;
	SEL		actionSelector;
}
@property (nonatomic, copy) NSString* imageURL;
@property (nonatomic, retain) UIImage* placeholderImage;
@property (nonatomic, retain) UIActivityIndicatorView* indicatorView;
@property(nonatomic, assign) id<MMWebImageButtonDelegate> delegate;

@property (nonatomic) BOOL	ignoreGPRS;	
@property (nonatomic) ASICachePolicy cachePolicy;
@property (nonatomic) ASICacheStoragePolicy storagePolicy;
@property (nonatomic) BOOL	stopDownloadImageAfterViewReleased;

@property (nonatomic, assign) id		actionTarget;
@property (nonatomic) SEL		actionSelector;

- (id)initWithDefaultPlaceholderImage;
- (id)initWithAvatarPlaceholderImage;
- (id)initWithPlaceholderImage:(UIImage*)anImage;
- (id)initWithPlaceholderImage:(UIImage*)anImage frame:(CGRect)frame;
- (id)initWithPlaceholderImage:(UIImage*)anImage frame:(CGRect)frame delegate:(id<MMWebImageButtonDelegate>)aDelegate;

- (void)cancelImageLoad;

- (void)startLoading;

- (void)setPlaceholderImageByPhotoId:(uint64_t)photoId;
- (void)resetImageURL:(NSString*)url;
- (void)refreshImage;

- (void)removeAllActions;
- (void)setTargetAndActionByImageURL:(id)target action:(SEL)aSelector withPhotoId:(uint64_t)photoId;
- (void)setTargetAndActionForImageLoaded:(id)target action:(SEL)aSelector;
- (void)actionWrap;

@end

@protocol MMWebImageButtonDelegate <NSObject>
@optional
- (void)imageButtonLoadedImage:(MMWebImageButton*)imageButton;
- (void)imageButtonFailedToLoadImage:(MMWebImageButton*)imageButton;
@end