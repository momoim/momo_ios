//
//  MMAsset.m
//  momo
//
//  Created by linsz on 12-3-23.
//  Copyright (c) 2012年 TQND. All rights reserved.
//

#import "MMAsset.h"
#import "MMAssetsViewController.h"
#import "MMThemeMgr.h"
//#import "TQLocalPhotoExtract.h"
//#import "TQSuggestionController.h"
//#import "BaseAlterView.h"

@implementation MMAsset
@synthesize asset;
@synthesize parent;
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

-(id)initWithAsset:(ALAsset*)_asset {
	
	if (self = [super initWithFrame:CGRectMake(0, 0, 0, 0)]) {
		self.asset = _asset;
		CGRect viewFrames = CGRectMake(0, 0, 75, 75);
		
		assetImageView = [[[UIImageView alloc] initWithFrame:viewFrames] autorelease];
		[assetImageView setContentMode:UIViewContentModeScaleToFill];
		[self addSubview:assetImageView];

        UIImageView* chooseView = [[[UIImageView alloc] initWithFrame:CGRectMake(50,50,25,25)] autorelease];
        [chooseView setImage:[MMThemeMgr imageNamed:@"picture_choose.png"]];
        overlayView = [[UIView alloc] initWithFrame:CGRectMake(0,0,75,75)];
        overlayView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.3];
        [overlayView addSubview:chooseView];
		[overlayView setHidden:YES];
		[self addSubview:overlayView];
    }
    
	return self;	
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
    if (newSuperview) {
        if (!assetImageView.image) {
            [assetImageView setImage:[UIImage imageWithCGImage:[self.asset thumbnail]]];
        }
    } else {
        assetImageView.image = nil;
    }
}

-(void)toggleSelection {
    if (overlayView.hidden == YES) {
        //选中添加
        MMAssetsViewController* ctrl = (MMAssetsViewController*)self.parent;
        UIImage* image = [UIImage imageWithCGImage:[asset thumbnail]];
        
        //设置正确的方向
        UIImageOrientation orientation = UIImageOrientationUp;
        NSNumber* orientationValue = [asset valueForProperty:@"ALAssetPropertyOrientation"];
        if (orientationValue != nil) {
            orientation = [orientationValue intValue];
        }
        UIImage* originalImage = [UIImage imageWithCGImage:[[asset defaultRepresentation] fullScreenImage]
                                                     scale:1.0f 
                                               orientation:orientation];
        
        NSLog(@"%d", originalImage.imageOrientation);
        //      UIImage* originalImage = [UIImage imageWithCGImage:[[asset defaultRepresentation] fullScreenImage]];
        NSString* url = [[[asset defaultRepresentation] url] absoluteString];        
        [ctrl addSelectImage:image withOriginalImage:originalImage orientation:orientation withURL:url];
        
    } else {
        //删除
        MMAssetsViewController* ctrl = (MMAssetsViewController*)self.parent;
        NSString* url = [[[asset defaultRepresentation] url] absoluteString];   
        [ctrl deleteImage:url];
    }
}

-(BOOL)selected {
	return !overlayView.hidden;
}

-(void)setSelected:(BOOL)_selected {
	[overlayView setHidden:!_selected];
}

-(BOOL)isUrlEqual:(NSString*)_url
{
    NSString* url = [[[asset defaultRepresentation] url] absoluteString];   
    return [url isEqualToString:_url];
}

- (void)dealloc 
{    
    self.asset = nil;
	[overlayView release];
    [super dealloc];
}

@end
