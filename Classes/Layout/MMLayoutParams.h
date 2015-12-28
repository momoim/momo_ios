//
//  MMLayoutParams.h
//  momo
//
//  Created by houxh on 11-5-23.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//
#import <Foundation/Foundation.h>

#define WRAP_CONTENT -1
#define FILL_PARANT -2
typedef void(*BACKGROUD_IMP)(UIView*, CGRect);
@interface UIView(MMLayout)
-(void)parseViewParams:(NSDictionary*)attributeDict;
-(void)setId:(NSString*)id;
-(NSString*)id;
-(void)setBackgroundImp:(BACKGROUD_IMP)imp;
-(BACKGROUD_IMP)backgroundImp;
-(UIView*)viewWithId:(NSString*)id;
- (void)setNeedsLayoutRecursive;
@end

@interface MMLayoutParams : NSObject {
	int width;
	int maxWidth;
	int height;
	int maxHeight;
	int leftMargin;
	int rightMargin;
	int topMargin;
	int bottomMargin;
}

@property(nonatomic) int width;
@property(nonatomic) int maxWidth;
@property(nonatomic) int height;
@property(nonatomic) int maxHeight;
@property(nonatomic) int leftMargin;
@property(nonatomic) int rightMargin;
@property(nonatomic) int topMargin;
@property(nonatomic) int bottomMargin;

-(id)initWithDictionary:(NSDictionary*)attributeDict;

@end

@protocol MMLayoutManager<NSObject>
- (void)layoutSubviews:(UIView*)container;

+(MMLayoutParams*)parseLayoutParams:(NSDictionary*)attributeDict;
@optional
- (CGSize)sizeThatFits:(CGSize)size container:(UIView*)container;
@end



@class UIView;

void setViewLayoutParams(UIView *view, MMLayoutParams *params);
MMLayoutParams* getViewLayoutParams(UIView *view);

void setViewLayoutManager(UIView* view,id<MMLayoutManager> manager);
id<MMLayoutManager> getViewLayoutManager(UIView *view);

