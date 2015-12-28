//
//  MWPhotoBrowser.h
//  MWPhotoBrowser
//
//  Created by Michael Waterfall on 14/10/2010.
//  Copyright 2010 d3i. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MWPhoto.h"

@class ZoomingScrollView;

@interface MWPhotoBrowser : UIViewController <UIScrollViewDelegate, MWPhotoDelegate> {
	
	// Photos
	NSArray *photos;
	
	// Views
	UIScrollView *pagingScrollView;
	
	// Paging
	NSMutableSet *visiblePages, *recycledPages;
	NSUInteger currentPageIndex;
	NSUInteger pageIndexBeforeRotation;
	
	// Navigation & controls
	UIToolbar *toolbar;
	NSTimer *controlVisibilityTimer;
	UIBarButtonItem *previousButton, *nextButton;
    UIBarButtonItem *saveItem;
    
    // Misc
	BOOL performingLayout;
	BOOL rotating;
	
	// navigation backup
	UIColor* tintColorBackup;
	UIBarStyle barStyleBackup;
	
	// status bar backup
	UIStatusBarStyle statusBarStyleBackup;
    CGRect oldFrame;
    
    // 底部当前页提示
    UIView* backPageView;
    UIView* curPageView;
}
@property (nonatomic) CGRect oldFrame;
// Init
- (id)initWithPhotos:(NSArray *)photosArray;

// Photos
- (NSObject *)imageObjectAtIndex:(NSUInteger)index;

// Layout
- (void)performLayout;

// Paging
- (void)tilePages;
- (BOOL)isDisplayingPageForIndex:(NSUInteger)index;
- (ZoomingScrollView *)pageDisplayedAtIndex:(NSUInteger)index;
- (ZoomingScrollView *)dequeueRecycledPage;
- (void)configurePage:(ZoomingScrollView *)page forIndex:(NSUInteger)index;
- (void)didStartViewingPageAtIndex:(NSUInteger)index;

// Frames
- (CGRect)frameForPagingScrollView;
- (CGRect)frameForPageAtIndex:(NSUInteger)index;
- (CGSize)contentSizeForPagingScrollView;
- (CGPoint)contentOffsetForPageAtIndex:(NSUInteger)index;
- (CGRect)frameForNavigationBarAtOrientation:(UIInterfaceOrientation)orientation;
- (CGRect)frameForToolbarAtOrientation:(UIInterfaceOrientation)orientation;

// Navigation
- (void)updateNavigation;
- (void)jumpToPageAtIndex:(NSUInteger)index;
- (void)gotoPreviousPage;
- (void)gotoNextPage;

// Controls
- (void)cancelControlHiding;
- (void)hideControlsAfterDelay;
- (void)setControlsHidden:(BOOL)hidden;
- (void)toggleControls;

// Properties
- (void)setInitialPageIndex:(NSUInteger)index;

- (void)saveToAlbum;
- (void)refreshSaveItem;

@end


@interface MMPhotoBrowser : MWPhotoBrowser {
}

@end

