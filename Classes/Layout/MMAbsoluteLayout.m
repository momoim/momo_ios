//
//  MMAbsoluteLayout.m
//  momo
//
//  Created by houxh on 11-6-16.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MMAbsoluteLayout.h"

@implementation MMAbsoluteLayoutParams
@synthesize x, y;
-(id)initWithDictionary:(NSDictionary*)attributeDict {
	self = [super initWithDictionary:attributeDict];
	if (self) {
		x = [[attributeDict objectForKey:@"layout_x"] intValue];
		y = [[attributeDict objectForKey:@"layout_y"] intValue];
	}
	return self;
}
@end

@implementation MMAbsoluteLayout
-(id)init {
	self = [super init];
	if (self != nil) {
		MMAbsoluteLayoutManager *layout = [[[MMAbsoluteLayoutManager alloc] init] autorelease];
		setViewLayoutManager(self, layout);
	}
	return self;
}

@end

@implementation MMAbsoluteLayoutManager
+(MMLayoutParams*)parseLayoutParams:(NSDictionary*)attributeDict {
	return [[[MMAbsoluteLayoutParams alloc] initWithDictionary:attributeDict] autorelease];
}
- (void)layoutSubviews:(UIView*)container {
	for (UIView *subview in [container subviews]) {
		MMAbsoluteLayoutParams *params = (MMAbsoluteLayoutParams*)getViewLayoutParams(subview);
		if (nil == params) {
			continue;
		}
		int x = params.x + params.leftMargin;
		int y = params.y + params.topMargin;
		CGSize size;	
		if(WRAP_CONTENT == params.width) {
			size.width = MIN([subview sizeThatFits:CGSizeZero].width, params.maxWidth);
		} else if(FILL_PARANT == params.width) {
			size.width = MIN(container.bounds.size.width - params.rightMargin - x, params.maxWidth);
		} else {
			size.width = params.width;
		}

		if(WRAP_CONTENT == params.height) {
			size.height = MIN([subview sizeThatFits:CGSizeMake(size.width, 0)].height, params.maxHeight);
		} else if(FILL_PARANT == params.height) {
			size.height = MIN(container.bounds.size.height - params.bottomMargin - y, params.maxHeight);
			assert(size.height > 0);
		} else {
			size.height = params.height;
		}
		
		subview.frame = CGRectMake(x, y, size.width, size.height);
	}
}
- (CGSize)sizeThatFits:(CGSize)size container:(UIView*)container{
	CGSize prefSize = size;
	for (UIView *subview in [container subviews]) {
		MMAbsoluteLayoutParams *params = (MMAbsoluteLayoutParams*)getViewLayoutParams(subview);
		if (nil == params) {
			continue;
		}
		int x = params.x + params.leftMargin;
		int y = params.y + params.topMargin;
        int w, h;
		if(WRAP_CONTENT == params.width) {
			w = MIN([subview sizeThatFits:CGSizeZero].width, params.maxWidth);
		} else if (FILL_PARANT == params.width) {
            w = size.width - x - params.rightMargin;
		} else {
			w = params.width;
		}
		
		if(WRAP_CONTENT == params.height || FILL_PARANT == params.height) {
			h = MIN([subview sizeThatFits:CGSizeMake(w, 0)].height, params.maxHeight);
		} else {
			h = params.height;
		}
		prefSize.width = MAX(x + w, prefSize.width);
		prefSize.height = MAX(y + h, prefSize.height);
	}
	return prefSize;
}
@end
