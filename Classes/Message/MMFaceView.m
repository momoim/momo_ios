//
//  MMFaceView.m
//  momo
//
//  Created by m fm on 11-5-18.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MMFaceView.h"
#import "MMThemeMgr.h"
#import "MMGlobalData.h"
#import "MMGlobalStyle.h"
#import "MMFaceTextFrame.h"

@implementation MMFaceView

@synthesize delegate_;


@synthesize faceWidth_;
@synthesize faceHeight_;


- (id)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code.
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

- (void) initPara {	
	self.backgroundColor = RGBCOLOR(175,221,234); 
	self.userInteractionEnabled = YES;
	delegate_ = self;
	
    NSInteger w = 64;
    NSInteger h = 54;
    NSInteger rows = 3;
    NSInteger cols = 5;
    
	//横线
	for (int i = 0; i < rows ; ++i) {
		NSInteger col = i % rows;
		UIView *Horizontal = [[[UIView alloc] initWithFrame:CGRectMake(0, 54 + h*col, 320, 2)] autorelease];
		Horizontal.backgroundColor = RGBCOLOR(225,249,255);
		UIView *horLine = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 1)] autorelease];
		horLine.backgroundColor = RGBCOLOR(0,158,202);
		[Horizontal addSubview:horLine];
		[self addSubview:Horizontal];
	}
	
	//竖线
	for (int i = 0; i < cols - 1; ++i){
		NSInteger col = i % cols;
		UIView *Vertical = [[[UIView alloc] initWithFrame:CGRectMake(63 + w*col, 0, 1, 216)] autorelease];
		Vertical.backgroundColor = RGBCOLOR(0,158,202);
		[self addSubview:Vertical];
	}
	
	arrayKey_ = [[NSArray alloc] initWithArray:[[MMFace shareInstance] getArrayFace]];
	
	for (int i = 0; i < 20; ++i) {
		NSString *strFace = [arrayKey_ objectAtIndex:i];
		button_[i] = [UIButton buttonWithType:UIButtonTypeCustom];
		NSInteger row = i / cols;
		NSInteger col = i % cols;
		button_[i] = [[UIButton alloc] initWithFrame:CGRectMake(w*col, h*row, 320/cols, h)];
		button_[i].backgroundColor = [UIColor clearColor];
		button_[i].tag = i;	
       	[button_[i] setImage:[[MMFace shareInstance] getImageByFace:strFace] forState:UIControlStateNormal];
		[button_[i] addTarget:self action:@selector(actionSelect:) forControlEvents:UIControlEventTouchUpInside];
		[self addSubview:button_[i]];
	}
	
		
}

- (void)dealloc {
	[arrayKey_ release];
    [super dealloc];
}

- (void)actionSelect:(id)sender {
    UIButton* button = (UIButton*)sender;
	if ((unsigned int)button.tag >= [arrayKey_ count]) {
		return;
	}
	
	NSString *strFace = [arrayKey_ objectAtIndex:button.tag];
	
	if ([(NSObject*)delegate_ respondsToSelector:@selector(selectFace:)]) {
		[delegate_ selectFace:strFace];
	} else {
		[self selectFace:strFace];
	}	
}


#pragma mark MMFaceDelegate

-(void)selectFace:(NSString*)strFace {
	//do nothing
}



@end
