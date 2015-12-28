//
//  MMLayoutParams.m
//  momo
//
//  Created by houxh on 11-5-23.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MMLayoutParams.h"
#import "MMThemeMgr.h"
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <QuartzCore/QuartzCore.h>

static char paramsKey;
static char managerKey;

static char idKey;
static char bkImpKey;
static char drawRectMethodImpKey;


#define GetAlpha(color) (((color) >> 24) & 0xff)
#define GetRed(color)   (((color) >> 16) & 0xff)
#define GetGreen(color) (((color) >> 8) & 0xff)
#define GetBlue(color)  (((color) >> 0) & 0xff)
static inline unsigned int SetAlpha(unsigned int c, unsigned int a) {
	return (c & 0x00ffffff) | (a << 24);
}

@implementation UIView(MMLayout)

+(UIColor*)parseColorParams:(NSString*)textColor {
	UIColor *color = nil;
	if (textColor) {
		if ([textColor hasPrefix:@"@"]) {
			if ([textColor isEqualToString:@"@clear"]) {
				color = [UIColor clearColor];
			} else if ([textColor isEqualToString:@"@gray"]) {
				color = [UIColor grayColor];
			} else if ([textColor isEqualToString:@"@blue"]) {
				color = [UIColor blueColor];
			} else if ([textColor isEqualToString:@"@red"]) {
				color = [UIColor redColor];
			} 
		}
		if ([textColor hasPrefix:@"#"]) {
			const char *c = [textColor UTF8String];
			unsigned int cc = 0;
			sscanf(c + 1, "%x", &cc);
			if (GetAlpha(cc) == 0) {
				cc = SetAlpha(cc, 0xff);
			}
			color = [UIColor colorWithRed:(float)GetRed(cc)/255.0 green:(float)GetGreen(cc)/255.0 
									 blue:(float)GetBlue(cc)/255.0 alpha:(float)GetAlpha(cc)/255.0];
		}
	}
	return color;
}


-(void)setId:(NSString*)id {
	objc_setAssociatedObject (self,
							  &idKey,
							  id,
							  OBJC_ASSOCIATION_RETAIN
							  );
}

-(NSString*)id {
	return (NSString*)objc_getAssociatedObject(self, &idKey);
}


static void draw_rect(id self, SEL sel, CGRect rect) {
	BACKGROUD_IMP imp = (BACKGROUD_IMP)[self backgroundImp];
	if (imp) {
		(*imp)(self, rect);
	}
	IMP prev_imp = (IMP)objc_getAssociatedObject([self class], &drawRectMethodImpKey);
	assert(prev_imp);
	(*prev_imp)(self, sel, rect);
}
-(void)setBackgroundImp:(BACKGROUD_IMP)imp {
	objc_setAssociatedObject (self,
							  &bkImpKey,
							  (id)imp,
							  OBJC_ASSOCIATION_ASSIGN
							  );
	Method method =  class_getInstanceMethod([self class], @selector(drawRect:));
	if (method) {
		IMP imp = method_getImplementation(method);
		if (imp != (IMP)draw_rect) {
			IMP prev_imp = method_setImplementation(method, (IMP)draw_rect);
			objc_setAssociatedObject([self class], &drawRectMethodImpKey, (id)prev_imp, OBJC_ASSOCIATION_ASSIGN);
		}
	}
}

-(BACKGROUD_IMP)backgroundImp {
	return (BACKGROUD_IMP)objc_getAssociatedObject(self, &bkImpKey);
}

-(UIView*)viewWithId:(NSString*)id {
	if ([[self id] isEqualToString:id]) {
		return self;
	}
	for (UIView *subview in self.subviews) {
		UIView *v = [subview viewWithId:id];
		if (v)
			return v;
	}
	return nil;
}

-(void)parseViewParams:(NSDictionary*)attributeDict {
	if ([attributeDict objectForKey:@"x"] && [attributeDict objectForKey:@"y"] &&
		[attributeDict objectForKey:@"width"] && [attributeDict objectForKey:@"height"]) {
		int x = [[attributeDict objectForKey:@"x"] intValue];
		int y = [[attributeDict objectForKey:@"y"] intValue];
		int width = [[attributeDict objectForKey:@"width"] intValue];
		int height = [[attributeDict objectForKey:@"height"] intValue];
		self.frame = CGRectMake(x, y, width, height);
	}
	NSString *id = [attributeDict objectForKey:@"id"];
	if ([attributeDict objectForKey:@"backgroundColor"]) {
		self.backgroundColor = [[self class] parseColorParams:[attributeDict objectForKey:@"backgroundColor"]];
	}
	if ([attributeDict objectForKey:@"borderWidth"]) {
		self.layer.borderWidth = [[attributeDict objectForKey:@"borderWidth"] intValue];
	}
	if ([attributeDict objectForKey:@"borderColor"]) {
		self.layer.borderColor = [[[self class] parseColorParams:[attributeDict objectForKey:@"borderColor"]] CGColor];
	}
	if ([attributeDict objectForKey:@"cornerRadius"]) {
		self.layer.cornerRadius = [[attributeDict objectForKey:@"cornerRadius"] intValue];
		self.layer.masksToBounds =YES;
	}
	if ([attributeDict objectForKey:@"hidden"]) {
		self.hidden = [[attributeDict objectForKey:@"hidden"] isEqualToString:@"true"];
	}
	if ([attributeDict objectForKey:@"backgroundImage"]) {
		self.backgroundColor = [UIColor colorWithPatternImage:[MMThemeMgr imageNamed:[attributeDict objectForKey:@"backgroundImage"]]];
	}
	[self setId:id];
}

- (void)layoutSubviews {
	id<MMLayoutManager> manager = getViewLayoutManager(self);
	if (manager) {
		[manager layoutSubviews:self];
	}
}

- (CGSize)sizeThatFits:(CGSize)size {
	id<MMLayoutManager> manager = getViewLayoutManager(self);
	if (manager) {
		if([manager respondsToSelector:@selector(sizeThatFits:container:)]){
			return [manager sizeThatFits:size container:self];
		}
	}
	return self.bounds.size;
}

- (void)setNeedsLayoutRecursive {
	[self setNeedsLayout];
	for (UIView *subview in self.subviews) {
		if(getViewLayoutManager(subview)){
			[subview setNeedsLayoutRecursive];			
		}
	}
}

@end

@implementation UILabel(MMLayout)


-(void)parseViewParams:(NSDictionary*)attributeDict {
	NSString *alignment = [attributeDict objectForKey:@"textAlignment"];
	if (alignment) {
		if ([alignment isEqualToString:@"left"]) {
			self.textAlignment = UITextAlignmentLeft;
		} else if ([alignment isEqualToString:@"center"]) {
			self.textAlignment = UITextAlignmentCenter;
		} else if ([alignment isEqualToString:@"right"]) {
			self.textAlignment = UITextAlignmentRight;
		} else {
			assert(NO);
		}

	}
	if ([attributeDict objectForKey:@"numberOfLines"]) {
		self.numberOfLines = [[attributeDict objectForKey:@"numberOfLines"] intValue];
	}
	NSString *lineBreakMode = [attributeDict objectForKey:@"lineBreakMode"];

	if (lineBreakMode) {
		if ([lineBreakMode isEqualToString:@"wordWrap"]) {
			self.lineBreakMode = UILineBreakModeWordWrap;
		} else if ([lineBreakMode isEqualToString:@"characterWrap"]) {
			self.lineBreakMode = UILineBreakModeCharacterWrap;
		} else if ([lineBreakMode isEqualToString:@"clip"]){
			self.lineBreakMode = UILineBreakModeClip;
		} else if([lineBreakMode isEqualToString:@"headTruncation"]) {
			self.lineBreakMode = UILineBreakModeHeadTruncation;
		} else if([lineBreakMode isEqualToString:@"tailTruncation"]) {
			self.lineBreakMode = UILineBreakModeTailTruncation;
		} else if([lineBreakMode isEqualToString:@"middleTruncation"]) {
			self.lineBreakMode = UILineBreakModeMiddleTruncation;
		} else {
			assert(NO);
		}
	}
	NSString *textColor = [attributeDict objectForKey:@"textColor"];
	if (textColor) {
		self.textColor = [[self class] parseColorParams:textColor];
	}
	
	NSString *textSize = [attributeDict objectForKey:@"textSize"];
	if (textSize) {
		self.font = [UIFont systemFontOfSize:[textSize floatValue]];
	}
	NSString *text = [attributeDict objectForKey:@"text"];
	if (text) {
		self.text = text;
	}
	[super parseViewParams:attributeDict];
}
@end
@implementation UITextView(MMLayout)

-(void)parseViewParams:(NSDictionary*)attributeDict {
    NSString *dataDetectorTypes = [attributeDict objectForKey:@"dataDetectorTypes"];
    if ([dataDetectorTypes isEqualToString:@"UIDataDetectorTypeLink"]) {
        self.dataDetectorTypes = UIDataDetectorTypeLink;
    }
    NSString *editable = [attributeDict objectForKey:@"editable"];
    if (editable) {
        self.editable = [[attributeDict objectForKey:@"editable"] isEqualToString:@"true"];
    }
    
	NSString *textSize = [attributeDict objectForKey:@"textSize"];
	if (textSize) {
		self.font = [UIFont systemFontOfSize:[textSize floatValue]];
	}
	NSString *text = [attributeDict objectForKey:@"text"];
	if (text) {
		self.text = text;
	}
	[super parseViewParams:attributeDict];
}
@end

@implementation UIScrollView(MMLayout)

-(void)parseViewParams:(NSDictionary*)attributeDict {

    NSString *editable = [attributeDict objectForKey:@"scrollEnabled"];
    if (editable) {
        self.scrollEnabled = [[attributeDict objectForKey:@"scrollEnabled"] isEqualToString:@"true"];
    }
    
	
	[super parseViewParams:attributeDict];
}
@end

@implementation UIImageView(MMLayout)					
-(void)parseViewParams:(NSDictionary*)attributeDict {
	NSString *path = [attributeDict objectForKey:@"path"];
	if (path) {
		UIImage *image = [MMThemeMgr imageNamed:path];
		self.image = image;
	}
	[super parseViewParams:attributeDict];
}
@end				

@implementation UIButton(MMLayout)
-(void)parseViewParams:(NSDictionary*)attributeDict {
	NSString *title = [attributeDict objectForKey:@"normalTitle"];
	if (title) {
		[self setTitle:title forState:UIControlStateNormal];
	}
	NSString *imagePath = [attributeDict objectForKey:@"normalImage"];
	if (imagePath) {
		[self setBackgroundImage:[MMThemeMgr imageNamed:imagePath] forState:UIControlStateNormal];
	}
	imagePath = [attributeDict objectForKey:@"pressedImage"];
	if (imagePath) {
		[self setBackgroundImage:[MMThemeMgr imageNamed:imagePath] forState:UIControlStateHighlighted];
	}
	[super parseViewParams:attributeDict];
}
@end

@implementation MMLayoutParams
@synthesize  width, height, leftMargin, rightMargin, topMargin,bottomMargin;
@synthesize maxWidth, maxHeight;
- (id)init {
    self = [super init];
	
	if (nil != self) {
		width = WRAP_CONTENT;
		height = WRAP_CONTENT;
		leftMargin = rightMargin = topMargin = bottomMargin = 0;
		maxWidth = INT_MAX;
		maxHeight = INT_MAX;
	}
	return self;
}
-(id)initWithDictionary:(NSDictionary*)attributeDict {
	self = [self init];

	if (nil != self) {
		NSString *value = [attributeDict objectForKey:@"layout_width"];
		if (value) {
			if ([value isEqualToString:@"fill_parent"]) {
				width = FILL_PARANT;
			} else if ([value isEqualToString:@"wrap_content"]) {
				width = WRAP_CONTENT;
			} else {
				width = [value intValue];
			}
		}
		
		value = [attributeDict objectForKey:@"layout_height"];
		if (value) {
			if ([value isEqualToString:@"fill_parent"]) {
				height = FILL_PARANT;
			} else if ([value isEqualToString:@"wrap_content"]) {
				height = WRAP_CONTENT;
			} else {
				height = [value intValue];
			}
		}
		
		value = [attributeDict objectForKey:@"layout_marginLeft"];
		if (value) {
			leftMargin = [value intValue];
		}
		value = [attributeDict objectForKey:@"layout_marginRight"];
		if (value) {
			rightMargin = [value intValue];
		}
		value = [attributeDict objectForKey:@"layout_marginTop"];
		if (value) {
			topMargin = [value intValue];
		}
		value = [attributeDict objectForKey:@"layout_marginBottom"];
		if (value) {
			bottomMargin = [value intValue];
		}
		value = [attributeDict objectForKey:@"layout_maxWidth"];
		if (value) {
			maxWidth = [value intValue];
		}
		value = [attributeDict objectForKey:@"layout_maxHeight"];
		if (value) {
			maxHeight = [value intValue];
		}

	}
	return self;
}
@end

void setViewLayoutParams(UIView *view, MMLayoutParams *params) {
    objc_setAssociatedObject (view,
							  &paramsKey,
							  params,
							  OBJC_ASSOCIATION_RETAIN
							  );
}

MMLayoutParams* getViewLayoutParams(UIView *view) {
	return (MMLayoutParams *) objc_getAssociatedObject(view, &paramsKey);
}

void setViewLayoutManager(UIView* view, id<MMLayoutManager> manager) {
	objc_setAssociatedObject (view,
							  &managerKey,
							  manager,
							  OBJC_ASSOCIATION_RETAIN
							  );
}

id<MMLayoutManager> getViewLayoutManager(UIView *view) {
	return (id<MMLayoutManager>) objc_getAssociatedObject(view, &managerKey);
}

