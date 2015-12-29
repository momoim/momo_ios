//
//  MainTabBarController.h
//  momo
//
//  Created by houxh on 15/12/29.
//
//

#import <UIKit/UIKit.h>

@interface MMMainTabBarController : UITabBarController {
    UIViewController *preselectedView_;
    
    UINavigationController *preferenceViewNavigationController_;
    
    NSMutableArray *arrayViewNames_;
}

@property (nonatomic, retain) NSArray	*tabItems;
@end
