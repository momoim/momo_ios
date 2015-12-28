//
//  MWPhotoBrowser.m
//  MWPhotoBrowser
//
//  Created by Michael Waterfall on 14/10/2010.
//  Copyright 2010 d3i. All rights reserved.
//

#import "MWPhotoBrowser.h"
#import "ZoomingScrollView.h"
#import "MMThemeMgr.h"
#import "MMCommonAPI.h"
#import "UIActionSheet+MKBlockAdditions.h"

#define PADDING 10

// Handle depreciations and supress hide warnings
@interface UIApplication (DepreciationWarningSuppresion)
- (void)setStatusBarHidden:(BOOL)hidden animated:(BOOL)animated;
@end

@interface UINavigationBar (DepreciationWarningSuppresion)
- (void)setBackgroundImage:(UIImage *)image forBarMetrics:(NSInteger)metrics;

@end


// MWPhotoBrowser
@implementation MWPhotoBrowser
@synthesize oldFrame;
- (id)initWithPhotos:(NSArray *)photosArray {
	if ((self = [super init])) {
		
		// Store photos
		photos = [photosArray retain];
		
        // Defaults
		self.wantsFullScreenLayout = YES;
        self.hidesBottomBarWhenPushed = YES;
		currentPageIndex = 0;
		performingLayout = NO;
		rotating = NO;
	}
	return self;
}

#pragma mark -
#pragma mark Memory

- (void)didReceiveMemoryWarning {
	
	// Release any cached data, images, etc that aren't in use.
	
	// Release images
	[photos makeObjectsPerformSelector:@selector(releasePhoto)];
	[recycledPages removeAllObjects];
	NSLog(@"didReceiveMemoryWarning");
	
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
}

// Release any retained subviews of the main view.
- (void)viewDidUnload {
	currentPageIndex = 0;
    [pagingScrollView release], pagingScrollView = nil;
    [visiblePages release], visiblePages = nil;
    [recycledPages release], recycledPages = nil;
    [toolbar release], toolbar = nil;
    [previousButton release], previousButton = nil;
    [nextButton release], nextButton = nil;
}

- (void)dealloc {
	currentPageIndex = 0;
    [pagingScrollView release], pagingScrollView = nil;
    [visiblePages release], visiblePages = nil;
    [recycledPages release], recycledPages = nil;
    [toolbar release], toolbar = nil;
    [previousButton release], previousButton = nil;
    [nextButton release], nextButton = nil;
	
	[photos release];
	[pagingScrollView release];
	[visiblePages release];
	[recycledPages release];
	[toolbar release];
	[previousButton release];
	[nextButton release];
    [super dealloc];
}

#pragma mark -
#pragma mark View

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
	
	// View
	self.view.backgroundColor = [UIColor blackColor];
	
	// Setup paging scrolling view
	CGRect pagingScrollViewFrame = [self frameForPagingScrollView];
	pagingScrollView = [[UIScrollView alloc] initWithFrame:pagingScrollViewFrame];
	pagingScrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	pagingScrollView.pagingEnabled = YES;
	pagingScrollView.delegate = self;
	pagingScrollView.showsHorizontalScrollIndicator = NO;
	pagingScrollView.showsVerticalScrollIndicator = NO;
	pagingScrollView.backgroundColor = [UIColor blackColor];
    pagingScrollView.contentSize = [self contentSizeForPagingScrollView];
	pagingScrollView.contentOffset = [self contentOffsetForPageAtIndex:currentPageIndex];
	[self.view addSubview:pagingScrollView];
	
	// Setup pages
	visiblePages = [[NSMutableSet alloc] init];
	recycledPages = [[NSMutableSet alloc] init];
	[self tilePages];
    
    // Navigation bar
	tintColorBackup = self.navigationController.navigationBar.tintColor;
	[tintColorBackup retain];
	barStyleBackup = self.navigationController.navigationBar.barStyle;
    
    self.navigationController.navigationBar.tintColor = nil;
    self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
    
    if ([self.navigationController.navigationBar respondsToSelector:@selector(setBackgroundImage:forBarMetrics:)]){
        [self.navigationController.navigationBar setBackgroundImage:nil forBarMetrics:0];
    }
	
	// Status bar
	statusBarStyleBackup = [[UIApplication sharedApplication] statusBarStyle];
    
    saveItem = [[[UIBarButtonItem alloc] initWithTitle:@"保存" style:UIBarButtonItemStyleBordered target:self action:@selector(saveToAlbum)] autorelease];
    saveItem.enabled = NO;
    self.navigationItem.rightBarButtonItem = saveItem;
	     
    // Only show toolbar if there's more that 1 photo
    if (photos.count > 1) {
        backPageView = [[UIView alloc] initWithFrame:CGRectMake(0, iPhone5?478+88:478, 320, 2)];
        backPageView.backgroundColor = [UIColor colorWithRed:54.0/255.0 green:54.0/255.0 blue:54.0/255.0 alpha:1.0];
        [self.view addSubview:backPageView];
        [backPageView release];
        
        curPageView  = [[UIView alloc] initWithFrame:CGRectMake(0, iPhone5?478+88:478, 320/photos.count, 2)];
        curPageView.backgroundColor = [UIColor colorWithRed:41.0/255.0 green:179.0/255.0 blue:216.0/255.0 alpha:1.0];
        [self.view addSubview:curPageView]; 
        [curPageView release];
        
        //        // Toolbar
        //        toolbar = [[UIToolbar alloc] initWithFrame:[self frameForToolbarAtOrientation:self.interfaceOrientation]];
        //        toolbar.tintColor = nil;
        //        toolbar.barStyle = UIBarStyleBlackTranslucent;
        //        toolbar.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
        //        [self.view addSubview:toolbar];
        //        
        //        // Toolbar Items
        //        previousButton = [[UIBarButtonItem alloc] initWithImage:[MMThemeMgr imageNamed:@"browse_image_left_arrow.png"]
        //														  style:UIBarButtonItemStylePlain 
        //														 target:self 
        //														 action:@selector(gotoPreviousPage)];
        //        nextButton = [[UIBarButtonItem alloc] initWithImage:[MMThemeMgr imageNamed:@"browse_image_right_arrow.png"]
        //													  style:UIBarButtonItemStylePlain 
        //													 target:self 
        //													 action:@selector(gotoNextPage)];
        //        UIBarButtonItem *space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
        //        NSMutableArray *items = [[NSMutableArray alloc] init];
        //        [items addObject:space];
        //        if (photos.count > 1) [items addObject:previousButton];
        //        [items addObject:space];
        //        if (photos.count > 1) [items addObject:nextButton];
        //        [items addObject:space];
        //        [toolbar setItems:items];
        //        [items release];
        //        [space release];
        
    }
    
	// Super
    [super viewDidLoad];
	
}

- (void)viewWillAppear:(BOOL)animated {
    
	// Super
	[super viewWillAppear:animated];
	
	// Layout
	[self performLayout];
    
    // Set status bar style to black translucent
	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:YES];
    
	// Navigation
	[self updateNavigation];
	[self hideControlsAfterDelay];
	[self didStartViewingPageAtIndex:currentPageIndex]; // initial
	
}

- (void)viewWillDisappear:(BOOL)animated {
	
	// Super
	[super viewWillDisappear:animated];
    
	// Cancel any hiding timers
	[self cancelControlHiding];
	
	self.navigationController.navigationBar.tintColor = tintColorBackup;
	[tintColorBackup release];
    self.navigationController.navigationBar.barStyle = barStyleBackup;
    
    if ([self.navigationController.navigationBar respondsToSelector:@selector(setBackgroundImage:forBarMetrics:)]){
        [self.navigationController.navigationBar setBackgroundImage:[MMThemeMgr imageNamed:@"group_topbar.png"] forBarMetrics:0];
    }
	
	// restore status bar style
	[[UIApplication sharedApplication] setStatusBarStyle:statusBarStyleBackup animated:YES];
	
	for (MWPhoto* photo in photos) {
		[[MMHttpDownloadMgr shareInstance] stopDownloadByDelegate:photo];
	}
}

#pragma mark -
#pragma mark Layout

// Layout subviews
- (void)performLayout {
	
	// Flag
	performingLayout = YES;
	
	// Toolbar
	toolbar.frame = [self frameForToolbarAtOrientation:self.interfaceOrientation];
	
	// Remember index
	NSUInteger indexPriorToLayout = currentPageIndex;
	
	// Get paging scroll view frame to determine if anything needs changing
	CGRect pagingScrollViewFrame = [self frameForPagingScrollView];
    
	// Frame needs changing
	pagingScrollView.frame = pagingScrollViewFrame;
	
	// Recalculate contentSize based on current orientation
	pagingScrollView.contentSize = [self contentSizeForPagingScrollView];
	
	// Adjust frames and configuration of each visible page
	for (ZoomingScrollView *page in visiblePages) {
		page.frame = [self frameForPageAtIndex:page.index];
		[page setMaxMinZoomScalesForCurrentBounds];
	}
	
	// Adjust contentOffset to preserve page location based on values collected prior to location
	pagingScrollView.contentOffset = [self contentOffsetForPageAtIndex:indexPriorToLayout];
	
	// Reset
	currentPageIndex = indexPriorToLayout;
	performingLayout = NO;
    
}

#pragma mark -
#pragma mark Photos

// Get image if it has been loaded, otherwise nil
- (NSObject *)imageObjectAtIndex:(NSUInteger)index {
	if (photos && index < photos.count) {
        
		// Get image or obtain in background
		MWPhoto *photo = [photos objectAtIndex:index];
		if ([photo isImageAvailable]) {
			return [photo imageObject];
		} else {
			[photo obtainImageInBackgroundAndNotify:self];
		}
		
	}
	return nil;
}

#pragma mark -
#pragma mark MWPhotoDelegate

- (void)photoDidFinishLoading:(MWPhoto *)photo {
	NSUInteger index = [photos indexOfObject:photo];
	if (index != NSNotFound) {
		if ([self isDisplayingPageForIndex:index]) {
			
			// Tell page to display image again
			ZoomingScrollView *page = [self pageDisplayedAtIndex:index];
			if (page) [page displayImage];
			
		}
	}
    
    [self refreshSaveItem];
}

- (void)photoDidFailToLoad:(MWPhoto *)photo {
	NSUInteger index = [photos indexOfObject:photo];
	if (index != NSNotFound) {
		if ([self isDisplayingPageForIndex:index]) {
			
			// Tell page it failed
			ZoomingScrollView *page = [self pageDisplayedAtIndex:index];
			if (page) [page displayImageFailure];
			
		}
	}
    
    [self refreshSaveItem];
}

#pragma mark -
#pragma mark Paging

- (void)tilePages {
	
	// Calculate which pages should be visible
	// Ignore padding as paging bounces encroach on that
	// and lead to false page loads
	CGRect visibleBounds = pagingScrollView.bounds;
	int iFirstIndex = (int)floorf((CGRectGetMinX(visibleBounds)+PADDING*2) / CGRectGetWidth(visibleBounds));
	int iLastIndex  = (int)floorf((CGRectGetMaxX(visibleBounds)-PADDING*2-1) / CGRectGetWidth(visibleBounds));
    if (iFirstIndex < 0) iFirstIndex = 0;
    if (iFirstIndex > photos.count - 1) iFirstIndex = photos.count - 1;
    if (iLastIndex < 0) iLastIndex = 0;
    if (iLastIndex > photos.count - 1) iLastIndex = photos.count - 1;
	
	// Recycle no longer needed pages
	for (ZoomingScrollView *page in visiblePages) {
		if (page.index < (NSUInteger)iFirstIndex || page.index > (NSUInteger)iLastIndex) {
			[recycledPages addObject:page];
			/*NSLog(@"Removed page at index %i", page.index);*/
			page.index = NSNotFound; // empty
			[page removeFromSuperview];
		}
	}
	[visiblePages minusSet:recycledPages];
	
	// Add missing pages
	for (NSUInteger index = (NSUInteger)iFirstIndex; index <= (NSUInteger)iLastIndex; index++) {
		if (![self isDisplayingPageForIndex:index]) {
			ZoomingScrollView *page = [self dequeueRecycledPage];
			if (!page) {
				page = [[[ZoomingScrollView alloc] init] autorelease];
				page.photoBrowser = self;
			}
			[self configurePage:page forIndex:index];
			[visiblePages addObject:page];
			[pagingScrollView addSubview:page];
			/*NSLog(@"Added page at index %i", page.index);*/
		}
	}
	
}

- (BOOL)isDisplayingPageForIndex:(NSUInteger)index {
	for (ZoomingScrollView *page in visiblePages)
		if (page.index == index) return YES;
	return NO;
}

- (ZoomingScrollView *)pageDisplayedAtIndex:(NSUInteger)index {
	ZoomingScrollView *thePage = nil;
	for (ZoomingScrollView *page in visiblePages) {
		if (page.index == index) {
			thePage = page; break;
		}
	}
	return thePage;
}

- (void)configurePage:(ZoomingScrollView *)page forIndex:(NSUInteger)index {
	page.frame = [self frameForPageAtIndex:index];
	page.index = index;
}

- (ZoomingScrollView *)dequeueRecycledPage {
	ZoomingScrollView *page = [recycledPages anyObject];
	if (page) {
		[[page retain] autorelease];
		[recycledPages removeObject:page];
	}
	return page;
}

// Handle page changes
- (void)didStartViewingPageAtIndex:(NSUInteger)index {
    NSUInteger i;
    if (index > 0) {
        
        // Release anything < index - 1
        for (i = 0; i < index-1; i++) { [(MWPhoto *)[photos objectAtIndex:i] releasePhoto]; /*NSLog(@"Release image at index %i", i);*/ }
        
        // Preload index - 1
        i = index - 1; 
        if (i < photos.count) { [(MWPhoto *)[photos objectAtIndex:i] obtainImageInBackgroundAndNotify:self]; /*NSLog(@"Pre-loading image at index %i", i);*/ }
        
    }
    if (index < photos.count - 1) {
        
        // Release anything > index + 1
        for (i = index + 2; i < photos.count; i++) { [(MWPhoto *)[photos objectAtIndex:i] releasePhoto]; /*NSLog(@"Release image at index %i", i);*/ }
        
        // Preload index + 1
        i = index + 1; 
        if (i < photos.count) { [(MWPhoto *)[photos objectAtIndex:i] obtainImageInBackgroundAndNotify:self]; /*NSLog(@"Pre-loading image at index %i", i);*/ }
        
    }
}

#pragma mark -
#pragma mark Frame Calculations

- (CGRect)frameForPagingScrollView {
    CGRect frame = self.view.bounds;// [[UIScreen mainScreen] bounds];
    frame.origin.x -= PADDING;
    frame.size.width += (2 * PADDING);
    return frame;
}

- (CGRect)frameForPageAtIndex:(NSUInteger)index {
    // We have to use our paging scroll view's bounds, not frame, to calculate the page placement. When the device is in
    // landscape orientation, the frame will still be in portrait because the pagingScrollView is the root view controller's
    // view, so its frame is in window coordinate space, which is never rotated. Its bounds, however, will be in landscape
    // because it has a rotation transform applied.
    CGRect bounds = pagingScrollView.bounds;
    CGRect pageFrame = bounds;
    pageFrame.size.width -= (2 * PADDING);
    pageFrame.origin.x = (bounds.size.width * index) + PADDING;
    return pageFrame;
}

- (CGSize)contentSizeForPagingScrollView {
    // We have to use the paging scroll view's bounds to calculate the contentSize, for the same reason outlined above.
    CGRect bounds = pagingScrollView.bounds;
    return CGSizeMake(bounds.size.width * photos.count, bounds.size.height);
}

- (CGPoint)contentOffsetForPageAtIndex:(NSUInteger)index {
	CGFloat pageWidth = pagingScrollView.bounds.size.width;
	CGFloat newOffset = index * pageWidth;
	return CGPointMake(newOffset, 0);
}

- (CGRect)frameForNavigationBarAtOrientation:(UIInterfaceOrientation)orientation {
	CGFloat height = UIInterfaceOrientationIsPortrait(orientation) ? 44 : 32;
	return CGRectMake(0, 20, self.view.bounds.size.width, height);
}

- (CGRect)frameForToolbarAtOrientation:(UIInterfaceOrientation)orientation {
	CGFloat height = UIInterfaceOrientationIsPortrait(orientation) ? 44 : 32;
	return CGRectMake(0, self.view.bounds.size.height - height, self.view.bounds.size.width, height);
}

#pragma mark -
#pragma mark UIScrollView Delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	
	if (performingLayout || rotating) return;
	
	// Tile pages
	[self tilePages];
	
	// Calculate current page
	CGRect visibleBounds = pagingScrollView.bounds;
	NSUInteger index = (NSUInteger)(floorf(CGRectGetMidX(visibleBounds) / CGRectGetWidth(visibleBounds)));
	if (index > photos.count - 1) index = photos.count - 1;
	NSUInteger previousCurrentPage = currentPageIndex;
	currentPageIndex = index;
	if (currentPageIndex != previousCurrentPage) {
        [self didStartViewingPageAtIndex:index];
    }
	[self refreshSaveItem];
}

//- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
//	// Hide controls when dragging begins
//	[self setControlsHidden:YES];
//}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
	// Update nav when page changes
	[self updateNavigation];
}

#pragma mark -
#pragma mark Navigation

- (void)updateNavigation {
	// Title
	if (photos.count > 1) {
		self.title = [NSString stringWithFormat:@"%i of %i", currentPageIndex+1, photos.count];		
	} else {
		self.title = nil;
	}
	
	// Buttons
	//previousButton.enabled = (currentPageIndex > 0);
	//nextButton.enabled = (currentPageIndex < photos.count-1);
	
    //backPageView
    if (photos.count > 1) {
        curPageView.frame = CGRectMake(currentPageIndex * 320/photos.count, iPhone5?478+88:478, 320/photos.count, 2);
    }
}

- (void)jumpToPageAtIndex:(NSUInteger)index {
	
	// Change page
	if (index < photos.count) {
		CGRect pageFrame = [self frameForPageAtIndex:index];
		pagingScrollView.contentOffset = CGPointMake(pageFrame.origin.x - PADDING, 0);
		[self updateNavigation];
	}
	
	// Update timer to give more time
	[self hideControlsAfterDelay];
	
}

- (void)gotoPreviousPage { [self jumpToPageAtIndex:currentPageIndex-1]; }
- (void)gotoNextPage { [self jumpToPageAtIndex:currentPageIndex+1]; }

#pragma mark -
#pragma mark Control Hiding / Showing

- (void)setControlsHidden:(BOOL)hidden {
	
	// Get status bar height if visible
	CGFloat statusBarHeight = 0;
	if (![UIApplication sharedApplication].statusBarHidden) {
		CGRect statusBarFrame = [[UIApplication sharedApplication] statusBarFrame];
		statusBarHeight = MIN(statusBarFrame.size.height, statusBarFrame.size.width);
	}
	
	// Status Bar
	if ([UIApplication instancesRespondToSelector:@selector(setStatusBarHidden:withAnimation:)]) {
		[[UIApplication sharedApplication] setStatusBarHidden:hidden withAnimation:UIStatusBarAnimationFade];
	} else {
		[[UIApplication sharedApplication] setStatusBarHidden:hidden animated:YES];
	}
	
	// Get status bar height if visible
	if (![UIApplication sharedApplication].statusBarHidden) {
		CGRect statusBarFrame = [[UIApplication sharedApplication] statusBarFrame];
		statusBarHeight = MIN(statusBarFrame.size.height, statusBarFrame.size.width);
	}
	
	// Set navigation bar frame
	CGRect navBarFrame = self.navigationController.navigationBar.frame;
	navBarFrame.origin.y = statusBarHeight;
	self.navigationController.navigationBar.frame = navBarFrame;
	
	// Bars
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:0.35];
	[self.navigationController.navigationBar setAlpha:hidden ? 0 : 1];
	[toolbar setAlpha:hidden ? 0 : 1];
	[UIView commitAnimations];
	
	// Control hiding timer
	// Will cancel existing timer but only begin hiding if
	// they are visible
	[self hideControlsAfterDelay];
	
}

- (void)cancelControlHiding {
	// If a timer exists then cancel and release
	if (controlVisibilityTimer) {
		[controlVisibilityTimer invalidate];
		[controlVisibilityTimer release];
		controlVisibilityTimer = nil;
	}
}

// Enable/disable control visiblity timer
- (void)hideControlsAfterDelay {
	[self cancelControlHiding];
	if (![UIApplication sharedApplication].isStatusBarHidden) {
		controlVisibilityTimer = [[NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(hideControls) userInfo:nil repeats:NO] retain];
	}
}

- (void)hideControls { [self setControlsHidden:YES]; }
- (void)toggleControls { [self setControlsHidden:![UIApplication sharedApplication].isStatusBarHidden]; }

- (void)refreshSaveItem {
    MWPhoto* photo = [photos objectAtIndex:currentPageIndex];
    NSObject* imageObject = photo.imageObject;
    if (imageObject && [imageObject isKindOfClass:[UIImage class]]) {
        saveItem.enabled = YES;
    } else {
        saveItem.enabled = NO;
    }
}

#pragma mark -
#pragma mark Rotation

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    switch (toInterfaceOrientation) {
        case UIInterfaceOrientationPortrait:
        case UIInterfaceOrientationLandscapeLeft:
        case UIInterfaceOrientationLandscapeRight:
            return YES;
        default:
            return NO;
    }
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    
	// Remember page index before rotation
	pageIndexBeforeRotation = currentPageIndex;
	rotating = YES;
	
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
	
	// Perform layout
	currentPageIndex = pageIndexBeforeRotation;
	[self performLayout];
	
	// Delay control holding
	[self hideControlsAfterDelay];
	
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	rotating = NO;
}

#pragma mark -
#pragma mark Properties

- (void)setInitialPageIndex:(NSUInteger)index {
	if (![self isViewLoaded]) {
		if (index >= photos.count) {
			currentPageIndex = 0;
		} else {
			currentPageIndex = index;
		}
	}
}

#pragma mark Actions
- (void)saveToAlbum {
    MWPhoto* photo = [photos objectAtIndex:currentPageIndex];
    UIImage* image = (UIImage*)[photo obtainImageObject];
    if (![image isKindOfClass:[UIImage class]]) {
        [MMCommonAPI alert:@"不支持保存gif图片到相册"];
        return;
    }
    
    UIImageWriteToSavedPhotosAlbum(image, self, @selector(imageSavedToPhotosAlbum:didFinishSavingWithError:contextInfo:), nil);
}

- (void)imageSavedToPhotosAlbum:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
	NSString *message;
	NSString *title;
	if (!error) {
		title = @"储存成功";
		message = @"图片已保存到相册";
	} else {
		title = @"储存失败";
		message = [error description];
	}
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
													message:message
												   delegate:nil
										  cancelButtonTitle:@"确定"
										  otherButtonTitles:nil];
	[alert show];
	[alert release];
}

@end


@implementation MMPhotoBrowser


- (void)imageSavedToPhotosAlbum:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
	NSString *message;
	NSString *title;
	if (!error) {
		title = @"储存成功";
		message = @"图片已保存到相册";
	} else {
		title = @"储存失败";
		message = [error description];
	}
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
													message:message
												   delegate:nil
										  cancelButtonTitle:@"确定"
										  otherButtonTitles:nil];
	[alert show];
	[alert release];
}


- (CGRect)frameForSaveBtnAtOrientation:(UIInterfaceOrientation)orientation {
	CGFloat height = UIInterfaceOrientationIsPortrait(orientation) ? 440 : 280;
	
	//24为image.size.height/width
	return CGRectMake(20, height, 24, 24);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[UIApplication sharedApplication] setStatusBarHidden:YES animated:NO];
    self.navigationController.navigationBar.hidden = YES;
    UILongPressGestureRecognizer* longPressGesture = [[[UILongPressGestureRecognizer alloc] initWithTarget:self 
                                                                                                    action:@selector(handleLongPress:)] autorelease];
    [self.view addGestureRecognizer:longPressGesture];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:NO animated:NO];
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        [UIActionSheet actionSheetWithTitle:nil
                                    message:nil 
                                    buttons:[NSArray arrayWithObject:@"保存照片"] 
                                 showInView:self.view
                                  onDismiss:^(int buttonIndex){
                                      [self saveToAlbum];
                                  } onCancel:nil];
    }
}
#pragma mark Actions
- (void)actionBack {
	
	[self setControlsHidden:NO];
    self.navigationController.navigationBar.hidden = NO;
    self.navigationController.navigationBar.tintColor = tintColorBackup;
    self.navigationController.navigationBar.barStyle = barStyleBackup;
    [self.navigationController.navigationBar setAlpha:1];
    if ([self.navigationController.navigationBar respondsToSelector:@selector(setBackgroundImage:forBarMetrics:)]){
        [self.navigationController.navigationBar setBackgroundImage:[MMThemeMgr imageNamed:@"group_topbar.png"] forBarMetrics:0];
    }
    
    [self.navigationController popViewControllerAnimated:NO];
}

- (void)toggleControls {
    
	[self actionBack];
}

@end
