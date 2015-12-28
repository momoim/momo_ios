//
//  IrregularShapedButton.m
//  momo
//
//  Created by wangsc on 11-2-28.
//  Copyright 2011 ND. All rights reserved.
//

#import "IrregularShapedButton.h"
#import "UIImageAlpha.h"

#define kAlphaVisibleThreshold (0.1f);

@implementation IrregularShapedButton

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    
    // Return NO if even super returns NO (i.e., if point lies outside our bounds)
    BOOL superResult = [super pointInside:point withEvent:event];
    if (!superResult) {
        return superResult;
    }
    
    // We can't test the image's alpha channel if the button has no image. Fall back to super.
    UIImage *buttonImage = [self imageForState:UIControlStateNormal];
    if (buttonImage == nil) {
        return YES;
    }
    
    CGColorRef pixelColor = [[buttonImage colorAtPixel:point] CGColor];
    CGFloat alpha = CGColorGetAlpha(pixelColor);
    return alpha >= kAlphaVisibleThreshold;
}

@end
