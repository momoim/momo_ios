//
//  MMFaceView.h
//  momo
//
//  Created by m fm on 11-5-18.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MMFaceDelegate.h"


@interface MMFaceView : UIView  <MMFaceDelegate> 
{
	id<MMFaceDelegate> delegate_;
	
	NSArray *arrayKey_;	
	
	UIButton *button_[20];
	
	
	CGFloat faceWidth_;
	CGFloat faceHeight_;
	
}

@property(nonatomic, assign) id<MMFaceDelegate> delegate_;

@property(nonatomic) CGFloat faceWidth_;
@property(nonatomic) CGFloat faceHeight_;

- (void) initPara;
- (void)actionSelect:(id)sender;

@end
