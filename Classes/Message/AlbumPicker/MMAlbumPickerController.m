//
//  AlbumPickerController.m
//  momo
//
//  Created by linsz on 12-3-23.
//  Copyright (c) 2012年 TQND. All rights reserved.
//

#import "MMAlbumPickerController.h"
#import "MMAssetsViewController.h"

@implementation MMAlbumPickerController
@synthesize assetGroups, assetLibrary, albumdelegate, currentSelectIndex, selectGroupViewControl;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(id)init
{
    self = [super init];
    if (self) {
        self.assetLibrary = [[[ALAssetsLibrary alloc] init] autorelease];
	[self.assetLibrary writeImageToSavedPhotosAlbum:nil metadata:nil completionBlock:^(NSURL *assetURL, NSError *error){}];

	 self.assetGroups  = [[[NSMutableArray alloc] init] autorelease];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(assetsLibraryDidChange:) name:ALAssetsLibraryChangedNotification object:nil];  
    }
    
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

-(void)dealloc
{
    //[[NSNotificationCenter defaultCenter] removeObserver:self name:ALAssetsLibraryChangedNotification object:nil];
    [assetGroups release];
    [assetLibrary release];
    
    [super dealloc];
}

#pragma mark - View lifecycle

-(void)updateAssetsLibrary{
    if( self.assetGroups != nil )
    {
        [self.assetGroups removeAllObjects];
    }
    else
    {
        self.assetGroups = [[[NSMutableArray alloc] init] autorelease];
    }
    
	if (self.assetLibrary == nil) {
		self.assetLibrary = [[[ALAssetsLibrary alloc] init] autorelease];
	} 
    
    // Load Albums into assetGroups
    dispatch_async(dispatch_get_main_queue(), ^
                   {
                       NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
                       
                       // Group enumerator Block
                       void (^assetGroupEnumerator)(ALAssetsGroup *, BOOL *) = ^(ALAssetsGroup *group, BOOL *stop) 
                       {
                           if (group == nil) 
                           {
                               [self performSelectorOnMainThread:@selector(reloadTableView) withObject:nil waitUntilDone:YES];
                               return;
                           }
                           
                           [self.assetGroups addObject:group];
                       };
                       
                       // Group Enumerator Failure Block
                       void (^assetGroupEnumberatorFailure)(NSError *) = ^(NSError *error) {
                           
                           UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"Album Error: %@ - %@", [error localizedDescription], [error localizedRecoverySuggestion]] delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
                           [alert show];
                           [alert release];
                           
                           NSLog(@"A problem occured %@", [error description]);	                                 
                       };	
                       
                       // Enumerate Albums
                       [self.assetLibrary enumerateGroupsWithTypes:ALAssetsGroupAll
                                              usingBlock:assetGroupEnumerator 
                                            failureBlock:assetGroupEnumberatorFailure];
                       
                       [pool release];
                   });  
}

+(void)removeAllImage {
    [[MMSelectImageCollection shareInstance] removeAll];
}

-(void)reloadTableView {
	[self.tableView reloadData];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(assetsLibraryDidChange:) name:ALAssetsLibraryChangedNotification object:nil];
    
    if (currentSelectIndex != nil) {
        [MMAlbumPickerController removeAllImage];
        NSInteger index = currentSelectIndex.row;
        selectGroupViewControl.assetGroup = [assetGroups objectAtIndex:index];
        [selectGroupViewControl.assetGroup setAssetsFilter:[ALAssetsFilter allPhotos]];
        [selectGroupViewControl preparePhotos];
    }
}

- (void)assetsLibraryDidChange:(NSNotification*)changeNotification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ALAssetsLibraryChangedNotification object:nil];
    [self updateAssetsLibrary];
}

// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
    [super loadView];
    
    self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
    
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"取消" 
                                                                              style:UIBarButtonItemStyleBordered 
                                                                             target:self 
                                                                              action:@selector(doCancel:)] autorelease]; 
    
    self.navigationItem.title = @"相簿";  
    [self updateAssetsLibrary];
}

- (void)doCancel:(id)sender{
    [MMAlbumPickerController removeAllImage];
    if (albumdelegate && [albumdelegate respondsToSelector:@selector(didCancelPickingAlbum)] ) {
        [albumdelegate didCancelPickingAlbum];
    }
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return [assetGroups count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    // Get count
    ALAssetsGroup *g = (ALAssetsGroup*)[assetGroups objectAtIndex:indexPath.row];
    [g setAssetsFilter:[ALAssetsFilter allPhotos]];
    NSInteger gCount = [g numberOfAssets];
    
    cell.textLabel.text = [NSString stringWithFormat:@"%@ (%d)",[g valueForProperty:ALAssetsGroupPropertyName], gCount];
    [cell.imageView setImage:[UIImage imageWithCGImage:[(ALAssetsGroup*)[assetGroups objectAtIndex:indexPath.row] posterImage]]];
	[cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
	
    return cell;
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	MMAssetsViewController *picker = [[MMAssetsViewController alloc] init];
	picker.albumdelegate   = self.albumdelegate;
    
    //保存选中的相册集
    picker.groupControl    = self;
    currentSelectIndex     = [indexPath retain];
    selectGroupViewControl = picker;
    // Move me    
    picker.assetGroup = [assetGroups objectAtIndex:indexPath.row];
    [picker.assetGroup setAssetsFilter:[ALAssetsFilter allPhotos]];
    
	[self.navigationController pushViewController:picker animated:YES];
	[picker release];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	return 57;
}

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
}
*/

- (void)viewDidUnload
{
    [super viewDidUnload];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ALAssetsLibraryChangedNotification object:nil];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


@end
