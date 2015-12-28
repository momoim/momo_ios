//
//  AssetsTableViewController.m
//  momo
//
//  Created by linsz on 12-3-23.
//  Copyright (c) 2012年 TQND. All rights reserved.
//

#import "MMAssetsViewController.h"
#import "MMAsset.h"
#import "MMAssetCell.h"
#import "MMSelectImage.h"
#import "MMThemeMgr.h"
#import "MMCommonAPI.h"
#import "UIImage+Resize.h"

@implementation MMAssetsViewController
@synthesize assetGroup, elcAssets, groupControl;
@synthesize albumdelegate;

BOOL isAnimating = FALSE;
- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)dealloc {
    self.elcAssets = nil;
    self.assetGroup= nil;
    [super dealloc];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"确定" 
						 													  style:UIBarButtonItemStyleBordered 
																			 target:self 
																			 action:@selector(actionRight:)] autorelease];
    
    tableView_ = [[UITableView alloc] initWithFrame:CGRectMake(0, 44, 320, 318)];
    [tableView_ setDelegate:self];
    [tableView_ setDataSource:self];
    [tableView_ setSeparatorColor:[UIColor clearColor]];
    [tableView_ setAllowsSelection:NO];
    
    //选中张数
    totalPhotosNumber = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 320, 50)];
    totalPhotosNumber.font = [UIFont boldSystemFontOfSize:18];
    totalPhotosNumber.backgroundColor = [UIColor clearColor];
    [totalPhotosNumber setTextAlignment:UITextAlignmentCenter];

    UIView *tableBackgroundView = [[[UIView alloc] initWithFrame: CGRectMake(0, 0, 320, 318)] autorelease];
	tableBackgroundView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"photos_background.jpg"]];
	tableView_.backgroundView = tableBackgroundView;
    [self.view addSubview:tableView_];
    
    //选中张数
    selectNumber = [[UILabel alloc] initWithFrame:CGRectMake(0, 359, 320, 27)];
   
    selectNumber.font = [UIFont boldSystemFontOfSize:13];
    selectNumber.backgroundColor = [UIColor colorWithRed:224.0/255.0 green:232.0/255.0 blue:236.0/255.0 alpha:1.0];
    NSString* strMsg = [NSString stringWithFormat:@"   请选择需要上传的图片! (已选0张)"];
    [selectNumber setTextAlignment:UITextAlignmentLeft];
    [selectNumber setText:strMsg];
    totalPhotosNumber.hidden = YES;
    [self.view addSubview:selectNumber];
    
    //提取图片
    self.elcAssets = [NSMutableArray array];
    selectImagePanel = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 384, 320, 90)];
    selectImagePanel.backgroundColor = [UIColor colorWithRed:224.0/255.0 green:232.0/255.0 blue:236.0/255.0 alpha:1.0];

    selectImagePanel.contentSize = CGSizeMake(320, 90);
    [self.view addSubview:selectImagePanel];	
    
    [self preparePhotos];
}

- (void)preparePhotos {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableArray* assetArray = [NSMutableArray array];
        [self.assetGroup enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {         
            if(result == nil) {
                return;
            }
            
            [assetArray addObject:result];
            
        }];   
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.elcAssets removeAllObjects];
            [self layoutSelectImages];
            
            for (ALAsset* asset in assetArray) {
                MMAsset *elcAsset = [[[MMAsset alloc] initWithAsset:asset] autorelease];
                [elcAsset setParent:self];
                NSString* imgURL  = [[[elcAsset.asset defaultRepresentation] url] absoluteString]; 
                BOOL isSelect     = [[MMSelectImageCollection shareInstance] isHasImage:imgURL];
                elcAsset.selected = isSelect;
                
                [self.elcAssets addObject:elcAsset]; 
            }
            
            [self.navigationItem setTitle:[assetGroup valueForProperty:ALAssetsGroupPropertyName]];
            if ([self.elcAssets count] > 16) {
                tableView_.tableFooterView = totalPhotosNumber;
                totalPhotosNumber.hidden = NO;
                [totalPhotosNumber setText: [NSString stringWithFormat:@"%d 张照片",[self.elcAssets count]]];
                if ([self.elcAssets count] > 16)  {
                    NSInteger row = 0;
                    if ([self.elcAssets count]%4) {
                        row = [self.elcAssets count]/4 + 1;
                    }else{
                        row = [self.elcAssets count]/4;
                    } 
                    
                    CGPoint offset = CGPointMake(0, 79*(row-4));
                    [tableView_ setContentOffset:offset animated:NO];
                } 
            }
            
            [tableView_ reloadData];
        });
    });
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.groupControl.currentSelectIndex = nil;
    self.groupControl.selectGroupViewControl = nil;
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return ceil([self.assetGroup numberOfAssets] / 4.0);
}

- (NSArray*)assetsForIndexPath:(NSIndexPath*)_indexPath {
    
	int index = (_indexPath.row*4);
	int maxIndex = (_indexPath.row*4+3);
    
	// NSLog(@"Getting assets for %d to %d with array count %d", index, maxIndex, [assets count]);
    
	if(maxIndex < [self.elcAssets count]) {
        
		return [NSArray arrayWithObjects:[self.elcAssets objectAtIndex:index],
				[self.elcAssets objectAtIndex:index+1],
				[self.elcAssets objectAtIndex:index+2],
				[self.elcAssets objectAtIndex:index+3],
				nil];
	}
    
	else if(maxIndex-1 < [self.elcAssets count]) {
        
		return [NSArray arrayWithObjects:[self.elcAssets objectAtIndex:index],
				[self.elcAssets objectAtIndex:index+1],
				[self.elcAssets objectAtIndex:index+2],
				nil];
	}
    
	else if(maxIndex-2 < [self.elcAssets count]) {
        
		return [NSArray arrayWithObjects:[self.elcAssets objectAtIndex:index],
				[self.elcAssets objectAtIndex:index+1],
				nil];
	}
    
	else if(maxIndex-3 < [self.elcAssets count]) {
        
		return [NSArray arrayWithObject:[self.elcAssets objectAtIndex:index]];
	}
    
	return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    MMAssetCell *cell = (MMAssetCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) 
    {		        
        cell = [[[MMAssetCell alloc] initWithAssets:[self assetsForIndexPath:indexPath] reuseIdentifier:CellIdentifier] autorelease];
    }	
	else 
    {		
		[cell setAssets:[self assetsForIndexPath:indexPath]];
	}
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 79;
}

- (NSString*)saveImageToLocalPath:(UIImage*)originImage orientation:(UIImageOrientation)orientation {
    UIImage* image = [originImage resizedImage:1024.0f];
//    UIImage* image = [MMCommonAPI scaleAndRotateImage:originImage scaleSize:CONSTRAINT_UPLOAD_IMAGE_SIZE];
    NSString* strImageDirectory = [NSHomeDirectory() stringByAppendingString:@"/tmp/tmp_selected_images/"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:strImageDirectory]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:strImageDirectory withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    NSString* imageSavePath = [strImageDirectory stringByAppendingFormat:@"%@.jpg", [MMCommonAPI createGUIDStr]];
    NSData* imageData = UIImageJPEGRepresentation(image, 0.8f);
    if (![imageData writeToFile:imageSavePath atomically:YES]) {
        return nil;
    }
    return imageSavePath;
}

#pragma mark add select image
- (void)addSelectImage:(UIImage*)image 
     withOriginalImage:(UIImage*) originalImage 
           orientation:(UIImageOrientation)orientation
               withURL:(NSString*)url
{
    if ([[MMSelectImageCollection shareInstance] isHasImage:url])
        return;
    
    int iTotalCount = [[MMSelectImageCollection shareInstance] count];
    MMSelectImage* view = [[[MMSelectImage alloc]initWithFrame:CGRectMake((iTotalCount)*(56+20) + 18, 0, 64, 64) 
                                                             andImage:image] autorelease];
    view.imageURL = url;
    view.parent   = self;
    view.tag      = iTotalCount + 1000;
    [view setBackgroundColor:[UIColor clearColor]];
    [selectImagePanel addSubview:view];
    
    [self addSelectedToken:url];
    
    MMSelectImageInfo* selectImageInfo = [[[MMSelectImageInfo alloc] init] autorelease];
    selectImageInfo.thumbImage = image;
    selectImageInfo.url = url;
    selectImageInfo.tmpSelectImagePath = [self saveImageToLocalPath:originalImage orientation:orientation];
    [[MMSelectImageCollection shareInstance] addSelectImageInfo:selectImageInfo];
    
//    [[MMSelectImageCollection shareInstance] addImage:image withOriginalImage:originalImage withURL:url];
    
    //文字说明修改
    NSString* strMsg = [NSString stringWithFormat:@"   请选择需要上传的图片! (已选 %d 张)",
                        [[MMSelectImageCollection shareInstance] count]];
    [selectNumber setTextAlignment:UITextAlignmentLeft];
    [selectNumber setText:strMsg];
    selectImagePanel.contentSize = CGSizeMake((iTotalCount+1)*(56+20) + 18, 90);
}

-(void)deleteImage:(NSString*)url
{
    int iTotalCount = [[MMSelectImageCollection shareInstance] count];
    int selIndex = -1;
    for (int index = 0; index < iTotalCount; index++) {
        NSString* urlImCollectionath = [[MMSelectImageCollection shareInstance] indexOfURL:index];
        if ([urlImCollectionath isEqualToString:url]) {
            selIndex = index;
            break;
        }
    }
    if (selIndex < 0)
        return;
    MMSelectImage* selView = (MMSelectImage*) [selectImagePanel viewWithTag:(selIndex+1000)];
    for (int index = selIndex+1; index < iTotalCount; index++) {
        MMSelectImage* view = (MMSelectImage*) [selectImagePanel viewWithTag:(index+1000)];
        view.frame = CGRectMake((index-1)*(56+20) + 18, 0, 64, 64);
        view.tag   = (index-1+1000);
    }
    [selView removeFromSuperview];
    [self removeSelectedToken:url];
    
    [[MMSelectImageCollection shareInstance] deleteImage:url];
    //文字说明修改
    NSString* strMsg = [NSString stringWithFormat:@"   请选择需要上传的图片! (已选 %d 张)",
                        [[MMSelectImageCollection shareInstance] count]];
    [selectNumber setTextAlignment:UITextAlignmentLeft];
    [selectNumber setText:strMsg];
    
    iTotalCount = [[MMSelectImageCollection shareInstance] count];
    selectImagePanel.contentSize = CGSizeMake((iTotalCount)*(56+20) + 18, 90);
}

-(void)addSelectedToken:(NSString*)url{
    for (MMAsset* asset in elcAssets) {
        if ([asset isUrlEqual:url] == YES) {
            [asset setSelected:YES];
            return;
        }
    }
    return;
}
-(void)removeSelectedToken:(NSString*)url
{
    for (MMAsset* asset in elcAssets) {
        if ([asset isUrlEqual:url] == YES) {
            [asset setSelected:NO];
            return;
        }
    }
    return;
}
	
-(void)layoutSelectImages
{
    for (UIView *subView in selectImagePanel.subviews)
    {
        [subView removeFromSuperview];
    }
    
    int iTotalCount = [[MMSelectImageCollection shareInstance] count];
    for (int index = 0; index < iTotalCount; index++) {
        NSString* url   = [[MMSelectImageCollection shareInstance] indexOfURL:index];
        UIImage*  image = [[MMSelectImageCollection shareInstance] indexOfImage:index]; 
        
        MMSelectImage* view = [[[MMSelectImage alloc] initWithFrame:CGRectMake(index*(56+20) + 18, 0, 64, 64) andImage:image] autorelease];
        view.imageURL = url;
        view.parent   = self;
        view.tag      = index + 1000;
            
        [view setBackgroundColor:[UIColor clearColor]];
        [selectImagePanel addSubview:view];
    }
    
    //文字说明修改
    NSString* strMsg = [NSString stringWithFormat:@"   请选择需要上传的图片! (已选 %d 张)",iTotalCount];
    [selectNumber setTextAlignment:UITextAlignmentLeft];
    [selectNumber setText:strMsg];    
    
    selectImagePanel.contentSize = CGSizeMake(iTotalCount * (56+20) + 18, 90);
}

- (void)actionRight:(id)sender {
    [[MMSelectImageCollection shareInstance] applyImageSelection];
    
    if (albumdelegate && [albumdelegate respondsToSelector:@selector(didFinishPickingAlbum:)] ) {
        [albumdelegate didFinishPickingAlbum: [[MMSelectImageCollection shareInstance] imageSelectArray]];
    }
    
    [[MMSelectImageCollection shareInstance] removeAll];
}

@end
