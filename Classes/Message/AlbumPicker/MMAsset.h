//
//  TQAsset.h
//  momo
//
//  Created by linsz on 12-3-23.
//  Copyright (c) 2012年 TQND. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>

@interface MMAsset : UIView
{
    ALAsset *asset;
	UIView *overlayView;
	BOOL selected;
    id   parent;
    
    UIImageView *assetImageView;
}

@property (nonatomic, retain) ALAsset *asset;
@property (nonatomic, assign) id parent;
-(id)initWithAsset:(ALAsset*)_asset;
-(BOOL)selected;
-(void)setSelected:(BOOL)_selected;
-(BOOL)isUrlEqual:(NSString*)_url;
@end
