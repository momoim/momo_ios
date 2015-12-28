//
//  MMAbsoluteLayout.h
//  momo
//
//  Created by houxh on 11-6-16.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MMLayoutParams.h"

@interface MMAbsoluteLayoutParams : MMLayoutParams
{
	int x;
	int y;
}

@property(nonatomic)int x;
@property(nonatomic)int y;
-(id)initWithDictionary:(NSDictionary*)attributeDict;
@end


@interface MMAbsoluteLayout : UIView
{

}

@end

@interface MMAbsoluteLayoutManager : NSObject<MMLayoutManager> {
	
}
- (void)layoutSubviews:(UIView*)container;

+(MMLayoutParams*)parseLayoutParams:(NSDictionary*)attributeDict;
@end
