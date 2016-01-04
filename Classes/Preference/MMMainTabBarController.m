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
#import "MMPreferenceViewController.h"
#import "MMFriendViewController.h"
#import "MMDraftMgr.h"
#import "Token.h"
#import "MMLoginService.h"

@interface MMMainTabBarController ()
@property(nonatomic)dispatch_source_t refreshTimer;
@property(nonatomic)int refreshFailCount;
@end

@implementation MMMainTabBarController
@synthesize tabItems;


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [[MMDraftMgr shareInstance] reloadDraftList];
    NSMutableArray* localViewControllers = [[NSMutableArray alloc] initWithCapacity:5] ;
    
    UIViewController   *viewController;
    UINavigationController  *navigationController;
    
    arrayViewNames_ = [[NSMutableArray alloc] init];
    
    
    // MO分享
    viewController = [[MMMessageViewController alloc] init];
    navigationController = [[MMNavigationController alloc] initWithRootViewController:viewController];
    navigationController.navigationBarHidden = NO;
    [navigationController navigationBar].tintColor = NAVIGATION_TINT_COLOR;
    [localViewControllers addObject:navigationController];
    [arrayViewNames_ addObject:kMMMessageViewController];
    UITabBarItem *tabBarItem = [[UITabBarItem alloc] initWithTitle:@"MO分享"
                                                             image:[MMThemeMgr imageNamed:@"momo_dynamic_bottombar_dynamic.png"]
                                                               tag:11];
    viewController.tabBarItem = tabBarItem;
    
    //好友请求
    viewController = [[MMFriendViewController alloc] init];
    navigationController = [[MMNavigationController alloc] initWithRootViewController:viewController];
    navigationController.navigationBarHidden = NO;
    [navigationController navigationBar].tintColor = NAVIGATION_TINT_COLOR;
    [localViewControllers addObject:navigationController];
    [arrayViewNames_ addObject:kMMAddressBookViewController];
    tabBarItem = [[UITabBarItem alloc] initWithTitle:@"好友"
                                               image:[MMThemeMgr imageNamed:@"momo_dynamic_bottombar_contacts.png"]
                                                 tag:11];
    viewController.tabBarItem = tabBarItem;
    
    
    // preference
    viewController = [[MMPreferenceViewController alloc] init];
    navigationController = [[MMNavigationController alloc] initWithRootViewController:viewController];
    navigationController.navigationBarHidden = NO;
    viewController.view.backgroundColor = DEFAULT_VIEW_BACKGROUND_COLOR;
    [localViewControllers addObject:navigationController];
    viewController.tabBarItem = [tabItems objectAtIndex:4];
    [arrayViewNames_ addObject:kMMPreferenceViewController];
    tabBarItem = [[UITabBarItem alloc] initWithTitle:@"更多"
                                               image:[MMThemeMgr imageNamed:@"momo_dynamic_bottombar_setting.png"]
                                                 tag:11];
    viewController.tabBarItem = tabBarItem;

    
    self.viewControllers = localViewControllers;
    
    
    dispatch_queue_t queue = dispatch_get_main_queue();
    self.refreshTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0,queue);
    dispatch_source_set_event_handler(self.refreshTimer, ^{
        [self refreshAccessToken];
    });
    
    [self startRefreshTimer];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)refreshAccessToken {
    Token *token = [Token instance];

    NSString *refreshToken = token.refreshToken;
    
    [[MMLoginService shareInstance] increaseActiveCount];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSInteger statusCode = 0;
        NSDictionary *resp = [[MMLoginService shareInstance] refreshAccessToken:refreshToken statusCode:&statusCode];
        dispatch_async(dispatch_get_main_queue(), ^{
            [[MMLoginService shareInstance] decreaseActiveCount];
            
            if (statusCode != 200) {
                NSLog(@"refresh token fail");
                self.refreshFailCount = self.refreshFailCount + 1;
                int64_t timeout;
                if (self.refreshFailCount > 60) {
                    timeout = 60*NSEC_PER_SEC;
                } else {
                    timeout = (int64_t)self.refreshFailCount*NSEC_PER_SEC;
                }
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, timeout), dispatch_get_main_queue(), ^{
                    [self prepareTimer];
                });
            } else {
                token.accessToken = [resp objectForKey:@"access_token"];
                token.refreshToken = [resp objectForKey:@"refresh_token"];
                token.expireTimestamp = (int)time(NULL) + [[resp objectForKey:@"expires_in"] intValue];
                [token save];
                [self prepareTimer];
                NSLog(@"refresh token success:%@", token.accessToken);
            }
        });
    });
    
}

-(void)prepareTimer {
    Token *token = [Token instance];
    int now = time(NULL);
    if (now >= token.expireTimestamp - 1) {
        dispatch_time_t w = dispatch_walltime(NULL, 0);
        dispatch_source_set_timer(self.refreshTimer, w, DISPATCH_TIME_FOREVER, 0);
    } else {
        dispatch_time_t w = dispatch_walltime(NULL, (token.expireTimestamp - now - 1)*NSEC_PER_SEC);
        dispatch_source_set_timer(self.refreshTimer, w, DISPATCH_TIME_FOREVER, 0);
    }
}

-(void)startRefreshTimer {
    [self prepareTimer];
    dispatch_resume(self.refreshTimer);
}

-(void)stopRefreshTimer {
    dispatch_suspend(self.refreshTimer);
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
