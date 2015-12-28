//
//  MMGIFImageView.h
//  TestGIF
//
//  Created by jackie on 11-7-12.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AnimatedGifFrame : NSObject
{
	NSData *data;
	NSData *header;
	double delay;
	int disposalMethod;
	CGRect area;
}

@property (nonatomic, copy) NSData *header;
@property (nonatomic, copy) NSData *data;
@property (nonatomic) double delay;
@property (nonatomic) int disposalMethod;
@property (nonatomic) CGRect area;

@end

@class MMGIFImage;
@interface MMGIFDecoder : NSObject {
    NSData *GIF_pointer;
	NSData *GIF_buffer;
	NSMutableData *GIF_screen;
	NSMutableData *GIF_global;
	NSMutableArray *GIF_frames;
	
	int GIF_sorted;
	int GIF_colorS;
	int GIF_colorC;
	int GIF_colorF;
	int animatedGifDelay;
	
	int dataPointer;

}
+ (BOOL)isGifImage:(NSData*)imageData;
-(MMGIFImage*)decode:(NSData *)GIFData;
@end

@interface MMGIFImage : NSObject {
	NSMutableArray *GIF_frames;
}
@property (nonatomic, retain) NSMutableArray *GIF_frames;
- (UIImage*) getFrameAsImageAtIndex:(int)index;
@end

@interface UIImageView(MMExtention) 
- (void)loadImageData:(MMGIFImage*)gif;
- (id)initWithDirectory:(NSString*)subdir;
- (id)initWithAnimationImages:(NSArray*)animationImages;
@end

@interface MMGIFImageView : UIImageView {

}

- (id)initWithGIFFile:(NSString*)gifFilePath;
- (id)initWithGIFData:(NSData*)gifImageData;
- (void)setGIF_frames:(NSMutableArray *)gifFrames;
+ (NSMutableArray*)getGifFrames:(NSData*)gifImageData;

@end

@interface MMImageViewAnimator : UIImageView {
@private
	NSTimer *				animtimer;
	NSInteger				index;
    NSInteger animationRepeatIndex;
    
	id						context;
	id						delegate;
	SEL						frameChangeSelector;
	SEL						startSelector;
	SEL						stopSelector;
}
@property (nonatomic,retain)	id				delegate;
@property (nonatomic)			SEL				startSelector;
@property (nonatomic)			SEL				stopSelector;
@property (nonatomic)			SEL				frameChangeSelector;

- (id)initWithGIFFile:(NSString*)gifFilePath;


- (void) startImageAnimating;
- (void) startAnimatingWithContext:(id)_context;
- (void) stopImageAnimating;
- (BOOL) isImageAnimating;
@end

