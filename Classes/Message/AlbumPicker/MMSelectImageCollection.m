//
//  MMSelectImageCollection.m
//  momo
//
//  Created by linsz on 12-3-23.
//  Copyright (c) 2012年 TQND. All rights reserved.
//

#import "MMSelectImageCollection.h"
#import "MMCommonAPI.h"
#import "MMGlobalData.h"
#import "UIImage+Resize.h"

@implementation MMSelectImageInfo
@synthesize tmpSelectImagePath, draftImagePath, url, thumbImage, imageSize, originImage;

- (void)dealloc {
	self.tmpSelectImagePath = nil;
	self.draftImagePath = nil;
	self.thumbImage = nil;
    self.originImage = nil;
    self.url = nil;
	imageSize = 0;
	[super dealloc];
}
@end

////////////////////////////////////////////////////////////////////////////////
//
@implementation MMSelectImageCollection
@synthesize originSelectAsset;
@synthesize selectAsset;

MMSelectImageCollection* g_imageCollection;

+(MMSelectImageCollection*)shareInstance
{
    if (g_imageCollection == nil) {
        g_imageCollection = [[MMSelectImageCollection alloc] init];
    }
    return g_imageCollection;
}

-(id)init   
{
    self = [super init];
    if (self) {
        selectAsset = [[NSMutableArray alloc] initWithCapacity:5];
        [self removeAll];
    }
    return  self;
}

-(NSInteger)count
{
    return [selectAsset count];
}

-(void)removeAll
{
    self.originSelectAsset = nil;
    [selectAsset removeAllObjects];
}

- (void)addSelectImageInfo:(MMSelectImageInfo*)selectImageInfo {
    [selectAsset addObject:selectImageInfo];
}

-(void)addImage:(UIImage *)_image withOriginalImage:(UIImage*)_originalImage withURL:(NSString *)_url
{
    MMSelectImageInfo* imageAsset = [[[MMSelectImageInfo alloc] init] autorelease];
    imageAsset.originImage= _originalImage;
	imageAsset.thumbImage = _image;
    imageAsset.url        = _url;
    
    [selectAsset addObject:imageAsset];
}

//用户完成图片选择
- (void)applyImageSelection {
    
}

-(BOOL)isHasImage:(NSString*)imgURL
{
    for (MMSelectImageInfo* indexObj in selectAsset) {
        if ([indexObj.url isEqualToString:imgURL]) {
            return YES;
        }
    } 
    
    return NO;
}

-(void)deleteImage:(NSString*)_url
{
    if ([self count] == 0 ) {
        return;
    }
    
    for (MMSelectImageInfo* indexObj in selectAsset) {
        if ([indexObj.url isEqualToString:_url]) {
            if (![originSelectAsset containsObject:indexObj]) {
                [[NSFileManager defaultManager] removeItemAtPath:indexObj.tmpSelectImagePath error:nil];
            }
            
            [selectAsset removeObject:indexObj];
            return;
        }
    }
    
    return;
}

-(NSString*)indexOfURL:(NSInteger)index
{
    MMSelectImageInfo* imageInfo = [selectAsset objectAtIndex:index];
    return imageInfo.url;
}

-(UIImage*)indexOfImage:(NSInteger)index
{
    MMSelectImageInfo* imageInfo = [selectAsset objectAtIndex:index];
    return imageInfo.thumbImage;
}

-(NSMutableArray*)imageSelectArray{
    return selectAsset;
}

@end
