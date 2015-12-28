//
//  MMScrollPageViewController.m
//  momo
//
//  Created by  on 11-10-8.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import "MMScrollPageViewController.h"

@implementation MMScrollPageViewController
@synthesize pageContainerViewController = pageContainerViewController_;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (UINavigationController*)properNavigationController {
    if (pageContainerViewController_) {
        return pageContainerViewController_.navigationController;
    }
    return self.navigationController;
}

- (UIViewController*)properViewController {
    if (pageContainerViewController_) {
        return pageContainerViewController_;
    }
    return self;
}

- (void)pageWillScroll {
    
}

- (void)didSwitchToPage:(UIViewController*)viewController {
    
}

- (UIViewController*)currentPageViewController {
    return nil;
//    MMUserMainPageViewController* viewController = (MMUserMainPageViewController*)pageContainerViewController_;
//    return [viewController currentPageViewController];
}

- (void)actionLeft:(id)sender {
}

- (void)setScrollToTop:(BOOL)scrollToTop {
    
}

@end
