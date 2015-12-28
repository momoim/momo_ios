//
//  MMSelectImageCollection.h
//  momo
//
//  Created by linsz on 12-3-23.
//  Copyright (c) 2012年 TQND. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MMSelectImageInfo : NSObject
{
    NSString* url;
	NSString* tmpSelectImagePath;
	NSString* draftImagePath;
	UIImage * thumbImage;
    UIImage * originImage;
	NSInteger imageSize;
}
@property(nonatomic,copy) NSString* url;
@property (nonatomic, copy) NSString* tmpSelectImagePath;
@property (nonatomic, copy) NSString* draftImagePath;
@property (nonatomic, retain) UIImage* thumbImage;
@property (nonatomic, retain) UIImage* originImage;
@property (nonatomic) NSInteger imageSize;

@end

@interface MMSelectImageCollection : NSObject
{
    NSArray* originSelectAsset;
    NSMutableArray* selectAsset;
}
@property (nonatomic, retain) NSArray*  originSelectAsset;
@property (nonatomic, retain) NSMutableArray* selectAsset;

/**
 *  单例
 */
+(MMSelectImageCollection*)shareInstance;

/**
 *  个数
 */
-(NSInteger)count;

/**
 *  清除所有
 */
-(void)removeAll;

/**
 *  添加图片
 */
- (void)addSelectImageInfo:(MMSelectImageInfo*)selectImageInfo;

//- (void)saveAllImageToPath;

- (void)applyImageSelection;

/**
 *  是否包含
 */
-(BOOL)isHasImage:(NSString*)imgURL;

/**
 *  删除图片
 */
-(void)deleteImage:(NSString*)_url;

/**
 *  索引URL
 */
-(NSString*)indexOfURL:(NSInteger)index;

/**
 *  索引图片
 */
-(UIImage*)indexOfImage:(NSInteger)index;

-(NSMutableArray*)imageSelectArray;

@end
