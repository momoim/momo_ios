//
//  MMRelativeLayout.m
//  momo
//
//  Created by houxh on 11-5-23.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MMRelativeLayout.h"
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

@implementation MMRelativeLayout

-(id)init {
	self = [super init];
	if (self != nil) {
		MMRelativeLayoutManager *layout = [[[MMRelativeLayoutManager alloc] init] autorelease];
		setViewLayoutManager(self, layout);
	}
	return self;
}

-(void)parseViewParams:(NSDictionary*)attributeDict {
	[super parseViewParams:attributeDict];
}

@end

@implementation MMRelativeLayoutParams

- (id)init {
    self = [super init];
	
	if (nil != self) {
		bzero(rules, sizeof(rules));
	}
	return self;
}
-(int*)rules{
	return rules;
}
#define GETRULEVALUE(name, key) \
if([[attributeDict objectForKey:name] isEqualToString:@"true"]) {\
	rules[key] = 1;\
}

-(id)initWithDictionary:(NSDictionary*)attributeDict {
	self = [super initWithDictionary:attributeDict];
	if (self != nil) {
		bzero(rules, sizeof(rules));
		GETRULEVALUE(@"layout_alignParentLeft", ALIGN_PARENT_LEFT);
		GETRULEVALUE(@"layout_alignParentRight", ALIGN_PARENT_RIGHT);
		GETRULEVALUE(@"layout_alignParentTop", ALIGN_PARENT_TOP);
		GETRULEVALUE(@"layout_alignParentBottom", ALIGN_PARENT_BOTTOM);
		GETRULEVALUE(@"layout_centerInParent", CENTER_IN_PARENT);
		GETRULEVALUE(@"layout_centerHorizontal", CENTER_HORIZONTAL);
		GETRULEVALUE(@"layout_centerVertical", CENTER_VERTICAL);
	}
	return self;
}

@end

@implementation MMRelativeLayoutManager
+(MMLayoutParams*)parseLayoutParams:(NSDictionary*)attributeDict {
	return [[[MMRelativeLayoutParams alloc] initWithDictionary:attributeDict] autorelease];
}
- (void)layoutSubviews:(UIView*)container {
	for (UIView *subview in [container subviews]) {
		MMRelativeLayoutParams *params = (MMRelativeLayoutParams*)getViewLayoutParams(subview);
		int w, h;
		if (nil == params) {
			continue;
		}
		if(FILL_PARANT == params.width) {
			w = container.bounds.size.width - params.leftMargin - params.rightMargin;
		} else if (WRAP_CONTENT == params.width) {
			w = [subview sizeThatFits:CGSizeZero].width;
		} else {
			w = params.width;
		}

		if (FILL_PARANT == params.height) {
			h = container.bounds.size.height - params.topMargin - params.bottomMargin;
		} else if (WRAP_CONTENT == params.height) {
			h = [subview sizeThatFits:CGSizeZero].height;
		} else {
			h = params.height;
		}
		w = MIN(w, params.maxWidth);
		h = MIN(h, params.maxHeight);
		int x = params.leftMargin;
		int y = params.topMargin;
		
		if (params.rules[ALIGN_PARENT_BOTTOM]) {
			y = container.bounds.size.height - h - params.bottomMargin;
		}
		if (params.rules[ALIGN_PARENT_TOP]) {
			y = params.topMargin;
		}
		if (params.rules[ALIGN_PARENT_LEFT]) {
			x = params.leftMargin;
		}
		if (params.rules[ALIGN_PARENT_RIGHT]) {
			x = container.bounds.size.width - w - params.rightMargin;
		}
		if (params.rules[CENTER_IN_PARENT]) {
			y = (container.bounds.size.height - h)/2;
			x = (container.bounds.size.width - w)/2;
		}
		if (params.rules[CENTER_VERTICAL]) {
			y = (container.bounds.size.height - h)/2;
		}
		if (params.rules[CENTER_HORIZONTAL]) {
			x = (container.bounds.size.width - w)/2;
		}

	    subview.frame = CGRectMake(x, y, w, h);
	}
}
- (CGSize)sizeThatFits:(CGSize)size container:(UIView*)container{
	CGSize prefSize = size;
	for (UIView *subview in [container subviews]) {
		MMRelativeLayoutParams *params = (MMRelativeLayoutParams*)getViewLayoutParams(subview);
		int w, h;
		if (nil == params) {
			continue;
		}
		if( WRAP_CONTENT == params.width) {
			w = [subview sizeThatFits:CGSizeZero].width;
		} else if (FILL_PARANT == params.width) {
			w = [subview sizeThatFits:CGSizeMake(size.width, 0)].width;
		} else{
			w = params.width;
		}
		
		if (FILL_PARANT == params.height || WRAP_CONTENT == params.height) {
			h = [subview sizeThatFits:CGSizeMake(w, 0)].height;
		} else {
			h = params.height;
		}
		w = MIN(w, params.maxWidth);
		h = MIN(h, params.maxHeight);
		int x = params.leftMargin;
		int y = params.topMargin;
		
		if (params.rules[ALIGN_PARENT_BOTTOM]) {
			y = container.bounds.size.height - h - params.bottomMargin;
		}
		if (params.rules[ALIGN_PARENT_TOP]) {
			y = params.topMargin;
		}
		if (params.rules[ALIGN_PARENT_LEFT]) {
			x = params.leftMargin;
		}
		if (params.rules[ALIGN_PARENT_RIGHT]) {
			x = container.bounds.size.width - w - params.rightMargin;
		}
		if (params.rules[CENTER_IN_PARENT]) {
			y = (container.bounds.size.height - h)/2;
			x = (container.bounds.size.width - w)/2;
		}
		if (params.rules[CENTER_VERTICAL]) {
			y = (container.bounds.size.height - h)/2;
		}
		if (params.rules[CENTER_HORIZONTAL]) {
			x = (container.bounds.size.width - w)/2;
		}
		
		prefSize.width = MAX(x + w, prefSize.width);
		prefSize.height = MAX(y + h, prefSize.height);
	}
	return prefSize;
}

@end
