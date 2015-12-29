//
//  MainTabBarController.m
//  momo
//
//  Created by houxh on 15/12/29.
//
//

#import "MMMainTabBarController.h"
#import "MMMessageViewController.h"
#import "MMAboutMeViewController.h"
#import "MMLoginService.h"
#import "MMCommonAPI.h"
#import "MMUapRequest.h"
#import "MMAboutMeManager.h"
#import "MMThemeMgr.h"
#import "MMGlobalPara.h"
#import "MMGlobalData.h"
#import "MMDBUpdater.h"
#import "MMAvatarMgr.h"
#import "MMPreference.h"
#import "MMGlobalCategory.h"
#import "MMFirstInterfaceViewController.h"
#import "MMPreferenceViewController.h"
#import "MMDraftMgr.h"

@interface MMMainTabBarController ()

@end

@implementation MMMainTabBarController
@synthesize tabItems;

- (void)dealloc {
    [super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [[MMDraftMgr shareInstance] reloadDraftList];
    NSMutableArray* localViewControllers = [[[NSMutableArray alloc] initWithCapacity:5] autorelease];
    
    UIViewController   *viewController;
    UINavigationController  *navigationController;
    
    arrayViewNames_ = [[NSMutableArray alloc] init];
    
    
    // 3.MO分享
    viewController = [[MMMessageViewController alloc] init];
    navigationController = [[MMNavigationController alloc] initWithRootViewController:viewController];
    navigationController.navigationBarHidden = NO;
    [navigationController navigationBar].tintColor = NAVIGATION_TINT_COLOR;
    [localViewControllers addObject:navigationController];
    [navigationController release];
    [viewController release];
    preselectedView_ = navigationController;
    [arrayViewNames_ addObject:kMMMessageViewController];
    UITabBarItem *tabBarItem = [[UITabBarItem alloc] initWithTitle:@"MO分享"
                                                             image:[MMThemeMgr imageNamed:@"momo_dynamic_bottombar_dynamic.png"]
                                                               tag:11];
    viewController.tabBarItem = tabBarItem;
    [tabBarItem release];
    
    
    // 5. preference
    viewController = [[MMPreferenceViewController alloc] init];
    MMPreferenceViewController *prefViewController = (MMPreferenceViewController*)viewController;
    navigationController = [[MMNavigationController alloc] initWithRootViewController:viewController];
    navigationController.navigationBarHidden = NO;
    viewController.view.backgroundColor = DEFAULT_VIEW_BACKGROUND_COLOR;
    [localViewControllers addObject:navigationController];
    preferenceViewNavigationController_ = [navigationController retain];
    [viewController release];
    [navigationController release];
    viewController.tabBarItem = [tabItems objectAtIndex:4];
    [arrayViewNames_ addObject:kMMPreferenceViewController];
    tabBarItem = [[UITabBarItem alloc] initWithTitle:@"更多"
                                               image:[MMThemeMgr imageNamed:@"momo_dynamic_bottombar_setting.png"]
                                                 tag:11];
    viewController.tabBarItem = tabBarItem;
    [tabBarItem release];
    
    self.viewControllers = localViewControllers;
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
