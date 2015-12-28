//
//  MMAssetCell.h
//  momo
//
//  Created by linsz on 12-3-23.
//  Copyright (c) 2012年 TQND. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MMAssetCell : UITableViewCell
{
}
-(id)initWithAssets:(NSArray*)_assets reuseIdentifier:(NSString*)_identifier;
-(void)setAssets:(NSArray*)_assets;

@property (nonatomic,retain) NSArray *rowAssets;

@end
