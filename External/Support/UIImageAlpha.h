//
//  UIImage-Alpha.h
//  momo
//
//  Created by wangsc on 11-2-28.
//  Copyright 2011 ND. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreGraphics/CoreGraphics.h>

@interface UIImage (ColorAtPixel)

- (UIColor *)colorAtPixel:(CGPoint)point;

@end