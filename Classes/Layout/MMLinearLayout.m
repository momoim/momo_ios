//
//  MMLinearLayout.m
//  momo
//
//  Created by houxh on 11-5-6.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MMLinearLayout.h"
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

@implementation MMLinearLayoutParams
@synthesize weight, gravity;

-(id)init {
	self = [super init];
	if (self != nil) {
		weight = 0.0;
		gravity = GRAVITY_TOP | GRAVITY_LEFT;
	}
	return self;
}

-(id)initWithDictionary:(NSDictionary*)attributeDict {
	self = [super initWithDictionary:attributeDict];
	if (self != nil) {
		weight = 0.0;
		NSString *value = [attributeDict objectForKey:@"layout_weight"];
		if (value) {
			weight = [value floatValue];
		}
		value = [attributeDict objectForKey:@"layout_gravity"];
		if (value) {
			if ([value isEqualToString:@"center_horizontal"]) {
				gravity = GRAVITY_CENTER_HORIZONTAL;
			} else if ([value isEqualToString:@"center_vertical"]) {
				gravity = GRAVITY_CENTER_VERTICAL;
			} else if ([value isEqualToString:@"center"]) {
				gravity = GRAVITY_CENTER;
			}
		}
	}
	return self;
}

@end

@implementation MMLinearLayout

-(id)init {
	self = [super init];
	if (self != nil) {
		MMLinearLayoutManager *layout = [[[MMLinearLayoutManager alloc] init] autorelease];
		setViewLayoutManager(self, layout);
	}
	return self;
}

-(void)parseViewParams:(NSDictionary*)attributeDict {
	NSString *value = [attributeDict objectForKey:@"orientation"];
	if (value) {
		if ([value isEqualToString:@"vertical"]) {
			MMLinearLayoutManager *layout = getViewLayoutManager(self);
			layout.orientation = VERTICAL;
		} else if ([value isEqualToString:@"horizontal"]) {
			MMLinearLayoutManager *layout = getViewLayoutManager(self);
			layout.orientation = HORIZONTAL;
		}
	}
	[super parseViewParams:attributeDict];
}
@end

@implementation MMLinearLayoutManager

@synthesize orientation=orientation_;

- (id)init {
    self = [super init];

	if (nil != self) {
		orientation_ = HORIZONTAL;
	}
	return self;
}

- (id) initWithOrientation:(int)orientation {
	self = [self init];
	if(nil != self) {
		orientation_ = orientation;
	}
	return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code.
}
*/

- (void)dealloc {
    [super dealloc];
}

+(MMLinearLayoutParams*)parseLayoutParams:(NSDictionary*)attributeDict {
	return [[[MMLinearLayoutParams alloc] initWithDictionary:attributeDict] autorelease];
}

- (void) layoutVertical:(UIView*)container {
	float totalWeight = 0.0;
	int totalLength = 0;
	for(UIView *subview in [container subviews]) {
		MMLinearLayoutParams* params = (MMLinearLayoutParams*)getViewLayoutParams(subview);//[MMLinearLayout getViewLayoutParams:subview];
		if (subview.hidden || nil == params) {
			continue;
		}			
		totalWeight += params.weight;
		int w = 0;
		if(WRAP_CONTENT == params.width) {
			w = MIN([subview sizeThatFits:CGSizeZero].width, params.maxWidth);
		} else if(FILL_PARANT == params.width) {
			w = MIN(container.bounds.size.width - params.leftMargin - params.rightMargin, params.maxWidth);
		} else {
			w = params.width;
		}
		
		if(params.weight > 0.0) {
			totalLength += params.topMargin + params.bottomMargin;
		} else {
			totalLength += params.topMargin + params.bottomMargin;
			if(WRAP_CONTENT == params.height) {
				totalLength += MIN([subview sizeThatFits:CGSizeMake(w, 0)].height, params.maxHeight);
			} else if(FILL_PARANT == params.height) {
				totalLength += MIN(container.bounds.size.height, params.maxHeight);
			} else {
				totalLength += params.height;
			}
		}
		
	}
	
	int y = 0;
	float delta = container.bounds.size.height - totalLength;
	for(UIView *subview in [container subviews]){
		MMLinearLayoutParams* params = (MMLinearLayoutParams*)getViewLayoutParams(subview);
		if (subview.hidden || nil == params) {
			continue;
		}
		int x = params.leftMargin;
		y += params.topMargin;
		CGSize size;	
		if(WRAP_CONTENT == params.width) {
			size.width = MIN([subview sizeThatFits:CGSizeZero].width, params.maxWidth);
		} else if(FILL_PARANT == params.width) {
			size.width = MIN(container.bounds.size.width - params.leftMargin - params.rightMargin, params.maxWidth);
		} else {
			size.width = params.width;
		}
		
		if(params.weight > 0.0) {
			size.height = MIN(delta * params.weight / totalWeight, params.maxHeight);
		} else {
			if(WRAP_CONTENT == params.height) {
				size.height = MIN([subview sizeThatFits:CGSizeMake(size.width, 0)].height, params.maxHeight);
			} else if(FILL_PARANT == params.height) {
				size.height = MIN(container.bounds.size.height -  params.bottomMargin - y, params.maxHeight);
				assert(size.height > 0);
			} else {
				size.height = params.height;
			}
		}
	
		switch(params.gravity & GRAVITY_HORIZONTAL_GRAVITY_MASK) {
			case GRAVITY_CENTER_HORIZONTAL:
				x = (container.bounds.size.width - size.width)/2;
				break;
			default:
				break;
		}
		subview.frame = CGRectMake(x, y, size.width, size.height);
		y += size.height + params.bottomMargin;
	}
	
}

- (void) layoutHorizontal:(UIView*)container {
	float totalWeight = 0.0;
	int totalLength = 0;
	for(UIView *subview in [container subviews]) {
		MMLinearLayoutParams* params = (MMLinearLayoutParams*)getViewLayoutParams(subview);
		if (subview.hidden || nil == params) {
			continue;
		}
	
		totalWeight += params.weight;
		
		int h = 0;
		if(WRAP_CONTENT == params.height) {
			h = MIN([subview sizeThatFits:CGSizeZero].height, params.maxHeight);
		} else if(FILL_PARANT == params.height) {
			h = MIN(container.bounds.size.height - params.topMargin - params.bottomMargin, params.maxHeight);
		} else {
			h = params.height;
		}
		
		if(params.weight > 0.0) {
			totalLength += params.leftMargin + params.rightMargin;
		} else {
			totalLength += params.leftMargin + params.rightMargin;
			if(WRAP_CONTENT == params.width) {
				totalLength += MIN([subview sizeThatFits:CGSizeMake(0, h)].width, params.maxWidth);
			} else if(FILL_PARANT == params.width) {
				totalLength += MIN(container.bounds.size.width, params.maxWidth);
			} else {
				totalLength += params.width;
			}
		}
		
	}
	
	int x = 0;
	float delta = container.bounds.size.width - totalLength;
	for(UIView *subview in [container subviews]){
		MMLinearLayoutParams* params = (MMLinearLayoutParams*)getViewLayoutParams(subview);
		if (subview.hidden || nil == params) {
			continue;
		}
		
		x += params.leftMargin;
		int y = params.topMargin;
		CGSize size;	
		
		if(WRAP_CONTENT == params.height) {
			size.height = MIN([subview sizeThatFits:CGSizeZero].height, params.maxHeight);
		} else if(FILL_PARANT == params.height) {
			size.height = MIN(container.bounds.size.height - params.topMargin - params.bottomMargin, params.maxHeight);
		} else {
			size.height = params.height;
		}
		
		if(params.weight > 0.0) {
			size.width = MIN(delta * params.weight / totalWeight, params.maxWidth);
		} else {
			if(WRAP_CONTENT == params.width) {
				size.width = MIN([subview sizeThatFits:CGSizeMake(size.height, 0)].width, params.maxWidth);
			} else if(FILL_PARANT == params.width) {
				size.width = MIN(container.bounds.size.width - params.rightMargin - x, params.maxWidth);
				assert(size.width > 0);
			} else {
				size.width = params.width;
			}
		}
		switch(params.gravity & GRAVITY_VERTICAL_GRAVITY_MASK) {
			case GRAVITY_CENTER_VERTICAL:
				y = (container.bounds.size.height - size.height)/2;
				break;
			default:
				break;
		}
		subview.frame = CGRectMake(x, y, size.width, size.height);
		x += size.width + params.rightMargin;
	}
	
}

- (void)layoutSubviews:(UIView*)container {
	if(orientation_ == HORIZONTAL) {
		[self layoutHorizontal:container];
	} else if(orientation_ == VERTICAL) {
		[self layoutVertical:container];
	}
}

- (CGSize) sizeThatFitsVertical:(CGSize)size container:(UIView*)container{
	int prefWidth = size.width;
	int totalLength = 0;
	for(UIView *subview in [container subviews]) {
		MMLinearLayoutParams* params = (MMLinearLayoutParams*)getViewLayoutParams(subview);
		if (subview.hidden || nil == params) {
			continue;
		}

		int w;
		if (WRAP_CONTENT == params.width) {
			w = MIN([subview sizeThatFits:CGSizeZero].width, params.maxWidth);
		} else if(FILL_PARANT == params.width) {
			w = MIN(size.width, params.maxWidth);
		} else {
			w = params.width;
		}
		prefWidth = MAX(prefWidth, w);
		totalLength += params.topMargin + params.bottomMargin;
		if(WRAP_CONTENT == params.height) {
			totalLength += MIN([subview sizeThatFits:CGSizeMake(w, 0)].height, params.maxHeight);
		} else {
			totalLength += params.height;
		}
	}
	return CGSizeMake(prefWidth, totalLength);
}

- (CGSize) sizeThatFitsHorizontal:(CGSize)size container:(UIView*)container{
	int totalLength = 0;
	int height = 0;
	for(UIView *subview in [container subviews]) {
		MMLinearLayoutParams* params = (MMLinearLayoutParams*)getViewLayoutParams(subview);
		if (subview.hidden || nil == params) {
			continue;
		}
		int h = params.topMargin + params.bottomMargin;
		totalLength += params.leftMargin + params.rightMargin;
		if(WRAP_CONTENT == params.height) {
			h += MIN([subview sizeThatFits:CGSizeMake(0, 0)].height, params.maxHeight);
		} else if (FILL_PARANT == params.height) {
			h += MIN(size.height, params.maxHeight);
		} else {
			h += params.height;
		}
		
		height = MAX(height, h);

		if(WRAP_CONTENT == params.width || FILL_PARANT == params.width) {
			totalLength += MIN([subview sizeThatFits:CGSizeMake(0, size.height)].width, params.maxWidth);
		}  else {
			totalLength += params.width;
		}
	}
	return CGSizeMake(totalLength, height);
}

- (CGSize)sizeThatFits:(CGSize)size container:(UIView*)container{
	if(orientation_ == VERTICAL) {
		return [self sizeThatFitsVertical:size container:container];
	} else {
		return [self sizeThatFitsHorizontal:size container:container];
	}
}

@end
