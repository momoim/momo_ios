//
//  MMLinearLayout.h
//  momo
//
//  Created by houxh on 11-5-6.
//  Copyright 2011 __MyCompanyName__. Al
#import <UIKit/UIKit.h>
#import "MMLayoutParams.h"

/** Raw bit indicating the gravity for an axis has been specified. */
#define AXIS_SPECIFIED   0x0001

/** Raw bit controlling how the left/top edge is placed. */
#define AXIS_PULL_BEFORE   0x0002
/** Raw bit controlling how the right/bottom edge is placed. */
#define AXIS_PULL_AFTER   0x0004
/** Raw bit controlling whether the right/bottom edge is clipped to its
 * container, based on the gravity direction being applied. */
#define AXIS_CLIP  0x0008

/** Bits defining the horizontal axis. */
#define AXIS_X_SHIFT  0
/** Bits defining the vertical axis. */
#define AXIS_Y_SHIFT 4

/** Push object to the top of its container, not changing its size. */
#define GRAVITY_TOP   AXIS_PULL_BEFORE
/** Push object to the bottom of its container, not changing its size. */
#define GRAVITY_BOTTOM   (AXIS_PULL_AFTER|AXIS_SPECIFIED)<<AXIS_Y_SHIFT
/** Push object to the left of its container, not changing its size. */
#define GRAVITY_LEFT   (AXIS_PULL_BEFORE|AXIS_SPECIFIED)<<AXIS_X_SHIFT
/** Push object to the right of its container, not changing its size. */
#define GRAVITY_RIGHT   (AXIS_PULL_AFTER|AXIS_SPECIFIED)<<AXIS_X_SHIFT

/** Place object in the vertical center of its container, not changing its
 *  size. */
#define GRAVITY_CENTER_VERTICAL   AXIS_SPECIFIED<<AXIS_Y_SHIFT
/** Grow the vertical size of the object if needed so it completely fills
 *  its container. */
#define FILL_VERTICAL   TOP|BOTTOM

/** Place object in the horizontal center of its container, not changing its
 *  size. */
#define GRAVITY_CENTER_HORIZONTAL   AXIS_SPECIFIED<<AXIS_X_SHIFT
/** Grow the horizontal size of the object if needed so it completely fills
 *  its container. */
#define GRAVITY_FILL_HORIZONTAL   LEFT|RIGHT

/** Place the object in the center of its container in both the vertical
 *  and horizontal axis, not changing its size. */
#define GRAVITY_CENTER   GRAVITY_CENTER_VERTICAL|GRAVITY_CENTER_HORIZONTAL

/** Grow the horizontal and vertical size of the object if needed so it
 *  completely fills its container. */
#define GRAVITY_FILL   FILL_VERTICAL|FILL_HORIZONTAL

/** Flag to clip the edges of the object to its container along the
 *  vertical axis. */
#define GRAVITY_CLIP_VERTICAL   AXIS_CLIP<<AXIS_Y_SHIFT

/** Flag to clip the edges of the object to its container along the
 *  horizontal axis. */
#define GRAVITY_CLIP_HORIZONTAL   AXIS_CLIP<<AXIS_X_SHIFT

/**
 * Binary mask to get the horizontal gravity of a gravity.
 */
#define GRAVITY_HORIZONTAL_GRAVITY_MASK   (AXIS_SPECIFIED | AXIS_PULL_BEFORE | AXIS_PULL_AFTER) << AXIS_X_SHIFT
/**
 * Binary mask to get the vertical gravity of a gravity.
 */
#define GRAVITY_VERTICAL_GRAVITY_MASK   (AXIS_SPECIFIED | AXIS_PULL_BEFORE | AXIS_PULL_AFTER) << AXIS_Y_SHIFT

/** Special constant to enable clipping to an overall display along the
 *  vertical dimension.  This is not applied by default by
 *  {@link #apply(int, int, int, Rect, int, int, Rect)}; you must do so
 *  yourself by calling {@link #applyDisplay}.
 */
#define GRAVITY_DISPLAY_CLIP_VERTICAL   0x10000000

/** Special constant to enable clipping to an overall display along the
 *  horizontal dimension.  This is not applied by default by
 *  {@link #apply(int, int, int, Rect, int, int, Rect)}; you must do so
 *  yourself by calling {@link #applyDisplay}.
 */
#define GRAVITY_DISPLAY_CLIP_HORIZONTAL   0x01000000



@interface MMLinearLayoutParams : MMLayoutParams{
	float weight;
	int gravity;
}

@property(nonatomic) float weight;
@property(nonatomic) int gravity;
-(id)initWithDictionary:(NSDictionary*)attributeDict;

@end

#define HORIZONTAL 0
#define VERTICAL 1

@interface MMLinearLayout : UIView 
{
	
}

@end


@interface MMLinearLayoutManager : NSObject<MMLayoutManager>  {
	int orientation_;
}
@property(nonatomic)int orientation;

- (id) initWithOrientation:(int)orientation;
- (void) layoutVertical:(UIView*)container;
- (void) layoutHorizontal:(UIView*)container;
- (CGSize) sizeThatFitsVertical:(CGSize)size container:(UIView*)container;
- (CGSize) sizeThatFitsHorizontal:(CGSize)size container:(UIView*)container;

+(MMLinearLayoutParams*)parseLayoutParams:(NSDictionary*)attributeDict;
@end
