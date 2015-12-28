//
//  MWPhoto.m
//  MWPhotoBrowser
//
//  Created by Michael Waterfall on 17/10/2010.
//  Copyright 2010 d3i. All rights reserved.
//

#import "MWPhoto.h"
#import "UIImage+Decompress.h"
#import "MMGIFImageView.h"

// Private
@interface MWPhoto ()

// Properties
//@property (retain) UIImage *photoImage;
@property (retain) NSObject *photoImageObject;
@property () BOOL workingInBackground;

// Private Methods
- (void)doBackgroundWork:(id <MWPhotoDelegate>)delegate;

@end


// MWPhoto
@implementation MWPhoto

// Properties
@synthesize photoImageObject, workingInBackground, mwPhotoDelegate;

#pragma mark Class Methods

+ (MWPhoto *)photoWithImage:(UIImage *)image {
	return [[[MWPhoto alloc] initWithImage:image] autorelease];
}

+ (MWPhoto *)photoWithFilePath:(NSString *)path {
	return [[[MWPhoto alloc] initWithFilePath:path] autorelease];
}

+ (MWPhoto *)photoWithURL:(NSURL *)url {
	return [[[MWPhoto alloc] initWithURL:url] autorelease];
}

#pragma mark NSObject

- (id)initWithImage:(UIImage *)image {
	if ((self = [super init])) {
//		self.photoImage = image;
		self.photoImageObject = image;
	}
	return self;
}

- (id)initWithFilePath:(NSString *)path {
	if ((self = [super init])) {
		photoPath = [path copy];
	}
	return self;
}

- (id)initWithURL:(NSURL *)url {
	if ((self = [super init])) {
		photoURL = [url copy];
	}
	return self;
}

- (void)dealloc {
	[[MMHttpDownloadMgr shareInstance] stopDownloadByDelegate:self];
	[photoPath release];
	[photoURL release];
//	[photoImage release];
	[photoImageObject release];
	[super dealloc];
}

#pragma mark Photo

// Return whether the image available
// It is available if the UIImage has been loaded and
// loading from file or URL is not required
- (BOOL)isImageAvailable {
	return (self.photoImageObject != nil);
}

// Return image
- (NSObject *)imageObject {
	return self.photoImageObject;
}

// Get and return the image from existing image, file path or url
- (NSObject *)obtainImageObject {
	if (!self.photoImageObject) {
		
		// Load
		NSData* imageData = nil;
//		UIImage *img = nil;
		if (photoPath) { 
			
			// Read image from file
			NSError *error = nil;
			imageData = [NSData dataWithContentsOfFile:photoPath options:NSDataReadingUncached error:&error];
			if (error) {
				NSLog(@"Photo from file error: %@", error);
			}
			
		} else if (photoURL) { 
			//reading from cache
			imageData = [[MMHttpDownloadMgr shareInstance] dataFromCache:[photoURL absoluteString]];
		}	
		
		if (imageData) {
			if (![MMGIFDecoder isGifImage:imageData]) {
				self.photoImageObject = [UIImage imageWithData:imageData];
			} else {
				NSArray* frameArray = [MMGIFImageView getGifFrames:imageData];
				if (frameArray && frameArray.count > 0) {
                    NSLog(@"%d", frameArray.retainCount);
					self.photoImageObject = frameArray;
				} else {
					self.photoImageObject = [UIImage imageWithData:imageData];
				}
			}
		}
	}
	return self.photoImageObject;
}

// Release if we can get it again from path or url
- (void)releasePhoto {
	if (self.photoImageObject && (photoPath || photoURL)) {
		self.photoImageObject = nil;
	}
}

// Obtain image in background and notify the browser when it has loaded
- (void)obtainImageInBackgroundAndNotify:(id <MWPhotoDelegate>)delegate {
	if (self.workingInBackground == YES) return; // Already fetching
	self.workingInBackground = YES;
	self.mwPhotoDelegate = delegate;
	[self performSelectorInBackground:@selector(doBackgroundWork:) withObject:delegate];
}

// Run on background thread
// Download image and notify delegate
- (void)doBackgroundWork:(id <MWPhotoDelegate>)delegate {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	// Load image from local path
	NSObject *imgObject = [self obtainImageObject];
	
	// Notify delegate of success or fail
	if (imgObject) {
		[(NSObject *)delegate performSelectorOnMainThread:@selector(photoDidFinishLoading:) withObject:self waitUntilDone:NO];
		self.workingInBackground = NO;
	}

	//download
	if (!imgObject && photoURL) {
		[[MMHttpDownloadMgr shareInstance] downloadFirstUsingCache:[photoURL absoluteString] delegate:self];
	}

	[pool release];
}

#pragma mark MMHttpDownloadDelegate
- (void)downloadDidSuccess:(NSString*)url {
	NSData* imageData = [[MMHttpDownloadMgr shareInstance] dataFromCache:url];
	if (!imageData) {
		[self downloadDidFailed:url];
		return;
	}
	
	if (![MMGIFDecoder isGifImage:imageData]) {
		self.photoImageObject = [UIImage imageWithData:imageData];
	} else {
		NSArray* frameArray = [MMGIFImageView getGifFrames:imageData];
		if (frameArray && frameArray.count > 0) {
			self.photoImageObject = frameArray;
		} else {
			self.photoImageObject = [UIImage imageWithData:imageData];
		}
	}
	self.workingInBackground = NO;
	
	if (mwPhotoDelegate && [mwPhotoDelegate respondsToSelector:@selector(photoDidFinishLoading:)]) {
		[(NSObject *)mwPhotoDelegate performSelectorOnMainThread:@selector(photoDidFinishLoading:) withObject:self waitUntilDone:NO];	
	}
	
}

- (void)downloadDidFailed:(NSString*)url {
	if (mwPhotoDelegate && [mwPhotoDelegate respondsToSelector:@selector(photoDidFailToLoad:)]) {
		[(NSObject *)mwPhotoDelegate performSelectorOnMainThread:@selector(photoDidFailToLoad:) withObject:self waitUntilDone:NO];	
	}
	self.workingInBackground = NO;
}

@end
