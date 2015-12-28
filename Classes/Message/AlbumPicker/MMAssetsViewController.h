//
//  AssetsTableViewController.h
//  momo
//
//  Created by linsz on 12-3-23.
//  Copyright (c) 2012年 TQND. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "MMSelectImageCollection.h"
#import "MMAlbumPickerController.h"

@interface MMAssetsViewController : UIViewController<UITableViewDataSource,UITableViewDelegate>
{
    ALAssetsGroup *assetGroup;
    NSMutableArray *elcAssets;
    UITableView* tableView_;
    UILabel*  selectNumber;  //选中图片个数说明
    UILabel*  totalPhotosNumber;
    UIButton *buttonLeft_;   //取消按钮
    UIScrollView* selectImagePanel;
    MMSelectImageCollection* seledImageCollection; //选中的图片集合
    
    id<MMAlbumPickerControllerDelegate> albumdelegate;
    MMAlbumPickerController* groupControl;
}

@property (nonatomic, assign) ALAssetsGroup *assetGroup;
@property (nonatomic, assign) MMAlbumPickerController* groupControl;
@property (nonatomic, retain) NSMutableArray *elcAssets;
@property (nonatomic, assign) id<MMAlbumPickerControllerDelegate> albumdelegate;

-(void)preparePhotos;

/**
 *  添加选中的图片
 */
-(void)addSelectImage:(UIImage*)image 
    withOriginalImage:(UIImage*) originalImage 
          orientation:(UIImageOrientation)orientation
              withURL:(NSString*)url;

/**
 *  删除图片
 */
-(void)deleteImage:(NSString*)url;
-(void)addSelectedToken:(NSString*)url;
-(void)removeSelectedToken:(NSString*)url;

/**
 *  重新布局选中的图片
 */
-(void)layoutSelectImages;

- (void)actionRight:(id)sender;
@end
