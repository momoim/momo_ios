//
//  MMRelativeLayout.h
//  momo
//
//  Created by houxh on 11-5-23.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "MMLayoutParams.h"

/**
 * Rule that aligns a child's right edge with another child's left edge.
 */
#define LEFT_OF                    0
/**
 * Rule that aligns a child's left edge with another child's right edge.
 */
#define RIGHT_OF                   1
/**
 * Rule that aligns a child's bottom edge with another child's top edge.
 */
#define ABOVE                      2
/**
 * Rule that aligns a child's top edge with another child's bottom edge.
 */
#define BELOW                      3

/**
 * Rule that aligns a child's baseline with another child's baseline.
 */
#define ALIGN_BASELINE             4
/**
 * Rule that aligns a child's left edge with another child's left edge.
 */
#define ALIGN_LEFT                 5
/**
 * Rule that aligns a child's top edge with another child's top edge.
 */
#define ALIGN_TOP                  6
/**
 * Rule that aligns a child's right edge with another child's right edge.
 */
#define ALIGN_RIGHT                7
/**
 * Rule that aligns a child's bottom edge with another child's bottom edge.
 */
#define ALIGN_BOTTOM               8

/**
 * Rule that aligns the child's left edge with its RelativeLayout
 * parent's left edge.
 */
#define ALIGN_PARENT_LEFT          9
/**
 * Rule that aligns the child's top edge with its RelativeLayout
 * parent's top edge.
 */
#define ALIGN_PARENT_TOP           10
/**
 * Rule that aligns the child's right edge with its RelativeLayout
 * parent's right edge.
 */
#define ALIGN_PARENT_RIGHT         11
/**
 * Rule that aligns the child's bottom edge with its RelativeLayout
 * parent's bottom edge.
 */
#define ALIGN_PARENT_BOTTOM        12

/**
 * Rule that centers the child with respect to the bounds of its
 * RelativeLayout parent.
 */
#define CENTER_IN_PARENT           13
/**
 * Rule that centers the child horizontally with respect to the
 * bounds of its RelativeLayout parent.
 */
#define CENTER_HORIZONTAL          14
/**
 * Rule that centers the child vertically with respect to the
 * bounds of its RelativeLayout parent.
 */
#define CENTER_VERTICAL            15

#define VERB_COUNT 16

@interface MMRelativeLayoutParams : MMLayoutParams {
	int rules[VERB_COUNT];
}

@property(nonatomic, readonly) int* rules;
-(id)initWithDictionary:(NSDictionary*)attributeDict;
@end

@interface MMRelativeLayout : UIView
{

}

@end

//todo child relative other child
@interface MMRelativeLayoutManager : NSObject<MMLayoutManager> {
	
}
+(MMLayoutParams*)parseLayoutParams:(NSDictionary*)attributeDict;
@end
