//
//  MMGlobalCategory.m
//  momo
//
//  Created by jackie on 11-6-9.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MMGlobalCategory.h"
#import "MMThemeMgr.h"
#import <QuartzCore/QuartzCore.h>
#import "MMGlobalData.h"
#include <sys/sysctl.h>
#import "MMGlobalPara.h"
#import <CommonCrypto/CommonDigest.h>

#define CUSTOM_BG_IMAGE_VIEW_TAG 5555

@implementation UINavigationBar (CustomBackground)

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx {
	//只替换默认类型的navigationbar
	if (![self isMemberOfClass:[UINavigationBar class]] ||
		self.barStyle != UIBarStyleDefault) {
		return [super drawLayer:layer inContext:ctx];
	}
	
	UIImage* image = [MMThemeMgr imageNamed:@"group_topbar.png"];
//	CGContextClip(ctx);
	CGContextTranslateCTM(ctx, 0, self.frame.size.height);
	CGContextScaleCTM(ctx, 1.0, -1.0);
	CGContextDrawImage(ctx, CGRectMake(0, 0, self.frame.size.width, self.frame.size.height), image.CGImage);
}

@end

@implementation MMNavigationController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationBar.tintColor = NAVIGATION_TINT_COLOR;
    if ([self.navigationBar respondsToSelector:@selector(setBackgroundImage:forBarMetrics:)]){
        [self.navigationBar setBackgroundImage:[MMThemeMgr imageNamed:@"group_topbar.png"] forBarMetrics:0];
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    UITabBarController* tabController = [MMGlobalPara getTabBarController];
    if ([tabController.selectedViewController respondsToSelector:@selector(topViewController)]) {
        UINavigationController *nc = (UINavigationController*)tabController.selectedViewController;     
        return [nc.topViewController shouldAutorotateToInterfaceOrientation:interfaceOrientation];
    }
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end

@implementation MMToolbar

- (void)drawRect:(CGRect)rect {
	UIImage* image = [MMThemeMgr imageNamed:@"dynamic_bottombar.png"];
	[image drawInRect:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (UIBarButtonItem*)itemWithTag:(NSInteger)tag {
    for (UIBarButtonItem* button in self.items) {
        if (button.tag == tag) {
            return button;
        }
    }
    return nil;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)replaceItemWithTag:(NSInteger)tag withItem:(UIBarButtonItem*)item {
    NSInteger buttonIndex = 0;
    for (UIBarButtonItem* button in self.items) {
        if (button.tag == tag) {
            NSMutableArray* newItems = [NSMutableArray arrayWithArray:self.items];
            [newItems replaceObjectAtIndex:buttonIndex withObject:item];
            self.items = newItems;
            break;
        }
        ++buttonIndex;
    }
}

@end

@implementation UITableView (Custom)

- (void)removeAllCell:(UITableViewRowAnimation)animation {
	int sectionCount = [self numberOfSections];
	NSMutableArray* rowArray = [NSMutableArray array];
	for (int i = 0; i < sectionCount; i++) {
		int rowCount = [self numberOfRowsInSection:i];
		for (int j = 0; j < rowCount; j++) {
			NSIndexPath* indexPath = [NSIndexPath indexPathForRow:j inSection:i];
			[rowArray addObject:indexPath];
		}
	}
	
	[self deleteRowsAtIndexPaths:rowArray withRowAnimation:animation];
}

@end

@implementation UIView (MMCatagory)

///////////////////////////////////////////////////////////////////////////////////////////////////
- (CGFloat)left {
    return self.frame.origin.x;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setLeft:(CGFloat)x {
    CGRect frame = self.frame;
    frame.origin.x = x;
    self.frame = frame;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (CGFloat)top {
    return self.frame.origin.y;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setTop:(CGFloat)y {
    CGRect frame = self.frame;
    frame.origin.y = y;
    self.frame = frame;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (CGFloat)right {
    return self.frame.origin.x + self.frame.size.width;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setRight:(CGFloat)right {
    CGRect frame = self.frame;
    frame.origin.x = right - frame.size.width;
    self.frame = frame;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (CGFloat)bottom {
    return self.frame.origin.y + self.frame.size.height;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setBottom:(CGFloat)bottom {
    CGRect frame = self.frame;
    frame.origin.y = bottom - frame.size.height;
    self.frame = frame;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (CGFloat)centerX {
    return self.center.x;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setCenterX:(CGFloat)centerX {
    self.center = CGPointMake(centerX, self.center.y);
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (CGFloat)centerY {
    return self.center.y;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setCenterY:(CGFloat)centerY {
    self.center = CGPointMake(self.center.x, centerY);
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (CGFloat)width {
    return self.frame.size.width;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setWidth:(CGFloat)width {
    CGRect frame = self.frame;
    frame.size.width = width;
    self.frame = frame;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (CGFloat)height {
    return self.frame.size.height;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setHeight:(CGFloat)height {
    CGRect frame = self.frame;
    frame.size.height = height;
    self.frame = frame;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (CGFloat)ttScreenX {
    CGFloat x = 0;
    for (UIView* view = self; view; view = view.superview) {
        x += view.left;
    }
    return x;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (CGFloat)ttScreenY {
    CGFloat y = 0;
    for (UIView* view = self; view; view = view.superview) {
        y += view.top;
    }
    return y;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (CGFloat)screenViewX {
    CGFloat x = 0;
    for (UIView* view = self; view; view = view.superview) {
        x += view.left;
        
        if ([view isKindOfClass:[UIScrollView class]]) {
            UIScrollView* scrollView = (UIScrollView*)view;
            x -= scrollView.contentOffset.x;
        }
    }
    
    return x;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (CGFloat)screenViewY {
    CGFloat y = 0;
    for (UIView* view = self; view; view = view.superview) {
        y += view.top;
        
        if ([view isKindOfClass:[UIScrollView class]]) {
            UIScrollView* scrollView = (UIScrollView*)view;
            y -= scrollView.contentOffset.y;
        }
    }
    return y;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (CGRect)screenFrame {
    return CGRectMake(self.screenViewX, self.screenViewY, self.width, self.height);
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (CGPoint)origin {
    return self.frame.origin;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setOrigin:(CGPoint)origin {
    CGRect frame = self.frame;
    frame.origin = origin;
    self.frame = frame;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (CGSize)size {
    return self.frame.size;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setSize:(CGSize)size {
    CGRect frame = self.frame;
    frame.size = size;
    self.frame = frame;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (CGFloat)orientationWidth {
    return UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)
    ? self.height : self.width;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (CGFloat)orientationHeight {
    return UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)
    ? self.width : self.height;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (UIView*)descendantOrSelfWithClass:(Class)cls {
    if ([self isKindOfClass:cls])
        return self;
    
    for (UIView* child in self.subviews) {
        UIView* it = [child descendantOrSelfWithClass:cls];
        if (it)
            return it;
    }
    
    return nil;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (UIView*)ancestorOrSelfWithClass:(Class)cls {
    if ([self isKindOfClass:cls]) {
        return self;
        
    } else if (self.superview) {
        return [self.superview ancestorOrSelfWithClass:cls];
        
    } else {
        return nil;
    }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)removeAllSubviews {
    while (self.subviews.count) {
        UIView* child = self.subviews.lastObject;
        [child removeFromSuperview];
    }
}


@end


@implementation UIDevice (HardwareModel)

-(NSString*)hardwareModel
{
    size_t size;
    char *model;
    
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    model = malloc(size);
    sysctlbyname("hw.machine", model, &size, NULL, 0);
    
    NSString *hwString = [NSString stringWithCString: model encoding: NSUTF8StringEncoding];
    free(model);
    
    //iPhone
    if([hwString isEqualToString: @"iPhone1,1"]) return @"iPhone 1G";
    if([hwString isEqualToString: @"iPhone1,2"]) return @"iPhone 3G";
    if([hwString isEqualToString: @"iPhone2,1"]) return @"iPhone 3GS";
    if([hwString hasPrefix: @"iPhone3"]) return @"iPhone 4";
    if([hwString hasPrefix: @"iPhone4"]) return @"iPhone 4S";
    
    //iTouch
    if([hwString hasPrefix: @"iPod1"]) return @"iPod Touch 1G";
    if([hwString hasPrefix: @"iPod2"]) return @"iPod Touch 2G";
    if([hwString hasPrefix: @"iPod3"]) return @"iPod Touch 3G";;
    if([hwString hasPrefix: @"iPod4"]) return @"iPod Touch 4G";;
    
    //iPad
    if([hwString hasPrefix: @"iPad1"]) return @"iPad1";
    if([hwString hasPrefix: @"iPad2"]) return @"iPad2";
    
    //Simulator
    if ([hwString hasSuffix:@"86"] || [hwString isEqual:@"x86_64"] || [hwString isEqualToString: @"i386"])
    {
        return @"Simulator";
    }
    
    //Unknown
    return hwString;
}

@end


@implementation MMHttpRequest
@synthesize tag = tag_;
@synthesize tagObject = tagObject_;

- (void)dealloc {
    self.tagObject = tagObject_;
    [super dealloc];
}

- (void)startAsynchronousOnRequestFinished:(RequestFinishedBlock)finishedBlock 
                           onRequestFailed:(RequestFailedBlock)failedBlock {
    self.delegate = self;
    
    finishBlock_ = finishedBlock;
    failedBlock_ = failedBlock;
    
    [self startAsynchronous];
}

#pragma mark ASIHttpRequestDelegate
- (void)requestFinished:(ASIHTTPRequest *)request {
    if (finishBlock_) {
        finishBlock_(self);
    }
}

- (void)requestFailed:(ASIHTTPRequest *)request {
    if (failedBlock_) {
        failedBlock_(self);
    }
}

@end

@implementation NSData (MD5)

- (NSString*)md5Hash {
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5([self bytes], [self length], result);
    
    return [NSString stringWithFormat:
            @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            result[0], result[1], result[2], result[3], result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11], result[12], result[13], result[14], result[15]
            ];
}

@end

@implementation NSString (MD5)

- (NSString*)md5Hash {
    return [[self dataUsingEncoding:NSUTF8StringEncoding] md5Hash];
}

+ (NSString*)stringWithData:(NSData*)data encoding:(NSStringEncoding)encoding {
    return [[[NSString alloc] initWithData:data encoding:encoding] autorelease];
}

@end

@implementation UIImage (ImageFromColor)

+ (UIImage *)imageFromColor:(UIColor *)color {
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}


@end

