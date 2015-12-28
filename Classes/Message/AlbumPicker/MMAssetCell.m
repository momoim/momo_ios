//
//  MMAssetCell.m
//  momo
//
//  Created by linsz on 12-3-23.
//  Copyright (c) 2012年 TQND. All rights reserved.
//

#import "MMAssetCell.h"
#import "MMAsset.h"

@implementation MMAssetCell
@synthesize rowAssets;

-(id)initWithAssets:(NSArray*)_assets reuseIdentifier:(NSString*)_identifier {
    
	if(self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:_identifier]) {
        
		self.rowAssets = _assets;
	}
	
	return self;
}

-(void)setAssets:(NSArray*)_assets {
	
	for(UIView *view in [self subviews]) 
    {		
		[view removeFromSuperview];
	}
	
	self.rowAssets = _assets;
}

-(void)layoutSubviews {
    
	CGRect frame = CGRectMake(4, 2, 75, 75);
	
	for(MMAsset *elcAsset in self.rowAssets) {
		
		[elcAsset setFrame:frame];
		[elcAsset addGestureRecognizer:[[[UITapGestureRecognizer alloc] initWithTarget:elcAsset action:@selector(toggleSelection)] autorelease]];
		[self addSubview:elcAsset];
		
		frame.origin.x = frame.origin.x + frame.size.width + 4;
	}
}

-(void)dealloc 
{
	[rowAssets release];
    
	[super dealloc];
}


@end
