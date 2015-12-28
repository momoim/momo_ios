//
//  MMScrollPageViewController.h
//  momo
//
//  Created by  on 11-10-8.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//



@interface MMScrollPageViewController : UIViewController
{
    UIViewController* pageContainerViewController_;
}
@property (nonatomic, assign) UIViewController* pageContainerViewController;

//代替self.navigationController
- (UINavigationController*)properNavigationController;

//需要presentModalViewController时代替self
- (UIViewController*)properViewController;

//页面需要滚动
- (void)pageWillScroll;

//页面切换时调用
- (void)didSwitchToPage:(UIViewController*)viewController;

//当前显示的page
- (UIViewController*)currentPageViewController;

- (void)actionLeft:(id)sender;

- (void)setScrollToTop:(BOOL)scrollToTop;

@end
