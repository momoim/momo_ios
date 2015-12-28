//
//  MWPhoto.h
//  MWPhotoBrowser
//
//  Created by Michael Waterfall on 17/10/2010.
//  Copyright 2010 d3i. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MMHttpDownloadMgr.h"

// Class
@class MWPhoto;

// Delegate
@protocol MWPhotoDelegate <NSObject>
- (void)photoDidFinishLoading:(MWPhoto *)photo;
- (void)photoDidFailToLoad:(MWPhoto *)photo;
@end

// MWPhoto
@interface MWPhoto : NSObject <MMHttpDownloadDelegate> {
	
	// Image
	NSString *photoPath;
	NSURL *photoURL;
//	UIImage *photoImage;
	NSObject *photoImageObject;	//UIImage 或 NSMutableArray, NSMutableArray用于GIF
	
	// Flags
	BOOL workingInBackground;
	
	id<MWPhotoDelegate> mwPhotoDelegate;
}
@property (nonatomic, assign) id<MWPhotoDelegate> mwPhotoDelegate;

// Class
+ (MWPhoto *)photoWithImage:(UIImage *)image;
+ (MWPhoto *)photoWithFilePath:(NSString *)path;
+ (MWPhoto *)photoWithURL:(NSURL *)url;

// Init
- (id)initWithImage:(UIImage *)image;
- (id)initWithFilePath:(NSString *)path;
- (id)initWithURL:(NSURL *)url;

// Public methods
- (BOOL)isImageAvailable;
- (NSObject *)imageObject;
- (NSObject *)obtainImageObject;
- (void)obtainImageInBackgroundAndNotify:(id <MWPhotoDelegate>)notifyDelegate;
- (void)releasePhoto;

@end
