//
//  MMThemeMgr.h
//  momo
//
//  Created by mfm on 6/24/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MMGlobalDefine.h"
#import "MMGIFImageView.h"

@interface MMThemeMgr : NSObject {

}

+ (MMThemeMgr*)getInstance;
+ (void)destroyInstance;

#ifndef MOMO_UNITTEST
#endif

+ (void)changeToTheme:(NSString *)themeName;

//以下函数供内部使用
- (void)initPara:(NSString *)themeName;

- (void)initTheme:(NSString *)themeName;

//移除未被使用的图片, 不包括可拉伸的图片
+ (void)removeUnusedImages;

+ (UIImage*)imageNamed:(NSString*)imageName;

+ (UIImage*)imageWithContentOfFile:(NSString*)imageName;

+ (NSArray*)animationImagesWithSubdir:(NSString*)subdir;
+ (NSArray*)cacheAnimationImagesWithSubdir:(NSString*)subdir;


@end
