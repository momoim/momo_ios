//
//  MMAlbumPickerController.h
//  momo
//
//  Created by linsz on 12-3-23.
//  Copyright (c) 2012年 TQND. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>

@protocol MMAlbumPickerControllerDelegate <NSObject>
@optional
- (void)didFinishPickingAlbum: (NSMutableArray*) selectAsset; 
- (void)didCancelPickingAlbum;
@end


@class MMAssetsViewController;
@interface MMAlbumPickerController : UITableViewController
{
    NSMutableArray *assetGroups;
    ALAssetsLibrary *assetLibrary;
    NSIndexPath* currentSelectIndex;
    MMAssetsViewController* selectGroupViewControl;

    id<MMAlbumPickerControllerDelegate> albumdelegate;
}

@property (nonatomic, retain) NSMutableArray *assetGroups;
@property (nonatomic, retain) ALAssetsLibrary *assetLibrary;
@property (nonatomic, assign) id<MMAlbumPickerControllerDelegate> albumdelegate;
@property (nonatomic, assign) MMAssetsViewController* selectGroupViewControl;
@property (nonatomic, retain)  NSIndexPath* currentSelectIndex;

-(void)doCancel:(id)sender;
+(void)removeAllImage;

@end
