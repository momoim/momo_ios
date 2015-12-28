#import "MMAppDelegate.h"
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


#define kMMTabBarImageView 99




@implementation MMAppDelegate

@synthesize window;
@synthesize tabBarController_;
@synthesize arrayViewNames_;
@synthesize tabItems;
@synthesize messageViewController = messageViewController_;
@synthesize resignActiveTimer = resignActiveTimer_;

-(void) onUserLogin:(NSNotification*)notification {
   	[[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound)];
}

-(void) onUserLogout:(NSNotification*)notification {
    [[UIApplication sharedApplication] unregisterForRemoteNotifications];
}

-(id)init {
    self = [super init];
    if (self) {
		allowAddressBook_ = NO;
    }
    return self;
}

- (void)dealloc {
	[preferenceViewNavigationController_ release];
    [tabBarDelegate_ release];
    [tabBarController_ release];
    [window release];	
    [MMThemeMgr destroyInstance];
	[arrayViewNames_ release];
    [super dealloc];
}



- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    if (![[MMLoginService shareInstance] isLogin]) {
        return;
    }
    [[MMLoginService shareInstance] increaseActiveCount];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        NSString *str = @"";
        unsigned char *data = (unsigned char*)[deviceToken bytes];
        for (int i = 0; i < [deviceToken length]; i++) {
            str = [str stringByAppendingFormat:@"%02x", data[i]];
        }
        assert([str length] == 64);
        
        [[MMLoginService shareInstance] registerPushNotification:str];
        [[MMLoginService shareInstance] decreaseActiveCount];
    });
} 

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {

} 

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {

}

- (void) initApplication {
	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
    window.backgroundColor = [UIColor whiteColor];
	
	// tabbar
    self.tabBarController_ = [[[UITabBarController alloc] init] autorelease];
	[MMGlobalPara setTabBarController:tabBarController_];
	
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
    

	
    self.tabBarController_.viewControllers = localViewControllers;
    
    window.rootViewController = self.tabBarController_;
    
//    [window addSubview:tabBarController_.view];
    [window makeKeyAndVisible];
    
    

	if (![[MMLoginService shareInstance] isLogin]) {
		self.tabBarController_.selectedIndex = 3;
//		MMFirstInterfaceViewController *controller = [[MMFirstInterfaceViewController alloc] init];
//		controller.hidesBottomBarWhenPushed = YES;
//		[prefViewController.navigationController pushViewController:controller animated:NO];
//		[controller release];
		
	} else {

//		[self switchToStartViewController];
        
        
        
        
//        if ([launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey]) {
//            [self switchToStartViewController:(NSString*)kMMIMRootViewController];
//        } else {
//            [self switchToStartViewController];
//        }
	}
	
    NSNotificationCenter * center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(onUserLogin:) name:kMMUserLogin object:nil];
    [center addObserver:self selector:@selector(onUserLogout:) name:kMMUserLogout object:nil];
	
}

#pragma mark App Life Cycle
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    application.applicationIconBadgeNumber = 0;
	// window
    UIWindow *localWindow;
    localWindow = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window = localWindow;
    [localWindow release];
	[MMThemeMgr getInstance];	//初始化MMThemeMgr
	[MMCommonAPI checkDirectoryExist];	//保证数据文件所在文件夹创建
	
	self.window.backgroundColor = TABLE_BACKGROUNDCOLOR;
    [self initApplication];

    return YES;
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    enterForegroundTime_ = 0;
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    enterForegroundTime_ = [[NSDate date] timeIntervalSince1970];

}

- (void)applicationWillResignActive:(UIApplication *)application {
    application.applicationIconBadgeNumber = 0;
}
  
- (void)applicationDidBecomeActive:(UIApplication *)application {
    application.applicationIconBadgeNumber = 0;
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    MLOG(@"applicationDidReceiveMemoryWarning");
    [[MMAvatarMgr shareInstance] clearCache];
    [MMThemeMgr removeUnusedImages];
}

- (void)addViewController:(UIViewController*)controller 
			  andViewName:(NSString*)viewName atIndex:(NSUInteger)index {
	UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
    navigationController.navigationBarHidden = YES;
	
	NSMutableArray *array = [[NSMutableArray alloc]initWithArray:self.tabBarController_.viewControllers];
	NSUInteger i = (index > [array count]) ? [array count]: index;
    [array insertObject:navigationController atIndex:i];
    [navigationController release];
	
	[arrayViewNames_ insertObject:viewName atIndex:i];
	[self.tabBarController_ setViewControllers:array animated:YES];
	[array release];
}

@end
