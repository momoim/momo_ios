//
//  MMWebImageView.m
//  momo
//
//  Created by jackie on 11-5-9.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MMWebImageView.h"
#import "MMThemeMgr.h"
#import "MMLogger.h"



@implementation UIImage(UIImageScale)

    //截取部分图像
-(UIImage*)getSubImage:(CGRect)rect
{
    CGImageRef subImageRef = CGImageCreateWithImageInRect(self.CGImage, rect);
	CGRect smallBounds = CGRectMake(0, 0, CGImageGetWidth(subImageRef), CGImageGetHeight(subImageRef));
	
    UIGraphicsBeginImageContext(smallBounds.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextDrawImage(context, smallBounds, subImageRef);
    UIImage* smallImage = [UIImage imageWithCGImage:subImageRef];
    UIGraphicsEndImageContext();
    
    CGImageRelease(subImageRef);
	
    return smallImage;
}

    //等比例缩放
-(UIImage*)scaleToSize:(CGSize)size 
{
	CGFloat width = CGImageGetWidth(self.CGImage);
    CGFloat height = CGImageGetHeight(self.CGImage);
    
	float verticalRadio = size.height*1.0/height; 
	float horizontalRadio = size.width*1.0/width;
	
	float radio = 1;
	if(verticalRadio>1 && horizontalRadio>1)
	{
        radio = 1;
	}
	else
	{
        radio = verticalRadio < horizontalRadio ? horizontalRadio : verticalRadio;	
	}
	
	width = width*radio;
	height = height*radio;
    
	int xPos = (size.width - width)/2;
	int yPos = (size.height-height)/2;
	
        // 创建一个bitmap的context  
        // 并把它设置成为当前正在使用的context  
    UIGraphicsBeginImageContext(size);  
	
        // 绘制改变大小的图片  
	if(verticalRadio>1 && horizontalRadio>1)
	{
            //        居中显示图片
        [self drawInRect:CGRectMake(xPos, yPos, width, height)];
	}
	else
	{
            //        左上角显示图片（从上从左开始显示）
        [self drawInRect:CGRectMake(0, 0, width, height)];
	}
    
	
        // 从当前context中创建一个改变大小后的图片  
    UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();  
	
        // 使当前的context出堆栈  
    UIGraphicsEndImageContext();  
	
        // 返回新的改变大小后的图片  
    return scaledImage;
}
@end

@implementation MMWebImageView
@synthesize placeholderImage, imageURL, delegate, indicatorView;
@synthesize cachePolicy, storagePolicy, ignoreGPRS, stopDownloadImageAfterViewReleased;

- (id)initWithDefaultPlaceholderImage {
	return [self initWithPlaceholderImage:[MMThemeMgr imageNamed:@"momo_dynamic_picture_dolphin.png"]];
}

- (id)initWithAvatarPlaceholderImage {
	return [self initWithPlaceholderImage:[MMThemeMgr imageNamed:@"momo_dynamic_head_portrait.png"]];
}

- (id)initWithPlaceholderImage:(UIImage*)anImage {
	return [self initWithPlaceholderImage:anImage delegate:nil];	
}

- (id)initWithPlaceholderImage:(UIImage*)anImage delegate:(id<MMWebImageViewDelegate>)aDelegate {
	if((self = [super initWithImage:anImage])) {
		self.placeholderImage = anImage;
		self.delegate = aDelegate;

		
		cachePolicy = ASIOnlyLoadIfNotCachedCachePolicy;
		storagePolicy = ASICachePermanentlyCacheStoragePolicy;
		ignoreGPRS = NO;
		stopDownloadImageAfterViewReleased = YES;
		successLoadImage = NO;
		
		indicatorView = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite] autorelease];
		[self addSubview:indicatorView];
	}
	
	return self;
}


- (void)layoutSubviews {
    indicatorView.center = CGPointMake(self.frame.size.width / 2, self.frame.size.height / 2);
    [super layoutSubviews];
}

- (void)resetImageURL:(NSString*)url {
	[self cancelImageLoad];
	
	successLoadImage = NO;
	self.imageURL = url;
	[self setImage:self.placeholderImage];
}

- (void)refreshImage {
	successLoadImage = NO;
	
	[self startLoading];
}

- (void)startLoading {
	if (!imageURL || imageURL.length == 0) {
		return;
	}
	
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
    [indicatorView stopAnimating];
    
	if (!successLoadImage) {
		if (stopDownloadImageAfterViewReleased) {
			[[MMHttpDownloadMgr shareInstance] stopDownloadByDelegate:self];
		} else {
			[[MMHttpDownloadMgr shareInstance] removeDelegateAndNotStopDownload:self];
		}
	}
}

- (void)dealloc {
	if (placeholderImage) {
		[placeholderImage release];
	}
	[imageURL release];
	[super dealloc];
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
	
	successLoadImage = YES;
	self.image = image;
	[self setNeedsDisplay];
	
	if([self.delegate respondsToSelector:@selector(imageViewLoadedImage:)]) {
		[self.delegate imageViewLoadedImage:self];
	}	
}

- (void)downloadDidFailed:(NSString *)url {
	[self.indicatorView stopAnimating];
	
	DLOG(@"%@ download failed", url);
	[[MMHttpDownloadMgr shareInstance] removeCacheForUrl:url];
	if([self.delegate respondsToSelector:@selector(imageViewFailedToLoadImage:)]) {
		[self.delegate imageViewFailedToLoadImage:self];
	}
}

@end
