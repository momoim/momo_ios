//
//  MMSelectImage.h
//  momo
//
//  Created by linsz on 12-3-23.
//  Copyright (c) 2012年 TQND. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MMSelectImage : UIView
{
    UIImageView*  imageView;
    UIButton*     btnDeleteImage;
    NSString*     imageURL;
    id            parent;
}

@property(nonatomic,retain) NSString* imageURL;
@property(nonatomic,assign) id        parent;

- (id)initWithFrame:(CGRect)frame andImage:(UIImage*)image;
-(void)deleteSelf;
@end
