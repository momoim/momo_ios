//
//  MMSelectImage.m
//  momo
//
//  Created by linsz on 12-3-23.
//  Copyright (c) 2012年 TQND. All rights reserved.
//

#import "MMSelectImage.h"
#import "MMAssetsViewController.h"
#import "MMThemeMgr.h"

@implementation MMSelectImage
@synthesize imageURL;
@synthesize parent;

- (id)initWithFrame:(CGRect)frame andImage:(UIImage*)image
{
    self = [super initWithFrame:frame];
    if (self) {
        UIImage* deleteImage = [MMThemeMgr imageNamed:@"picture_delete.png"];
        imageView = [[UIImageView alloc] initWithImage:image];
        
        btnDeleteImage = [UIButton buttonWithType:UIButtonTypeCustom];
        [btnDeleteImage setImage:deleteImage forState:UIControlStateNormal];
        [btnDeleteImage addTarget:self action:@selector(deleteSelf) forControlEvents:UIControlEventTouchUpInside];
    
        [self addSubview:imageView];
        [self addSubview:btnDeleteImage];
    }
    return self;
}



// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    imageView.frame = CGRectMake(0, 12, 56, 56);
    btnDeleteImage.frame = CGRectMake(56-12,0,25,25);
    
}

-(void)deleteSelf
{
    MMAssetsViewController* parentCtrl = (MMAssetsViewController*)self.parent;
    [parentCtrl deleteImage:self.imageURL];
}

@end
