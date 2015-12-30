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
#import "MMPreferenceViewController.h"
#import "MMLoginViewController.h"
#import "MMMainTabBarController.h"
#import "Token.h"

#define kMMTabBarImageView 99


@implementation MMAppDelegate

@synthesize window;
@synthesize tabBarController_;

-(id)init {
    self = [super init];
    if (self) {

    }
    return self;
}

- (void)dealloc {
    [tabBarController_ release];
    [window release];	
    [MMThemeMgr destroyInstance];
    [super dealloc];
}



- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSString *str = @"";
    unsigned char *data = (unsigned char*)[deviceToken bytes];
    for (int i = 0; i < [deviceToken length]; i++) {
        str = [str stringByAppendingFormat:@"%02x", data[i]];
    }
    assert([str length] == 64);
    
    NSLog(@"device token:%@", str);
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {

} 

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {

}

- (void) initApplication {
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
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
    window.backgroundColor = [UIColor whiteColor];
    
    if ([Token instance].uid == 0 ) {
        MMLoginViewController *controller = [[[MMLoginViewController alloc] init] autorelease];
        controller.hidesBottomBarWhenPushed = YES;
        
        MMNavigationController *root = [[[MMNavigationController alloc] initWithRootViewController:controller] autorelease];
        
        window.rootViewController = root;
        [window makeKeyAndVisible];
        
    } else {
        NSLog(@"login user id:%zd", [Token instance].uid);
        self.tabBarController_ = [[[MMMainTabBarController alloc] init] autorelease];
        
        [MMGlobalPara setTabBarController:tabBarController_];
        window.rootViewController = self.tabBarController_;
        [window makeKeyAndVisible];
    }

    return YES;
}

- (void)applicationDidEnterBackground:(UIApplication *)application {

}

- (void)applicationWillEnterForeground:(UIApplication *)application {
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


@end
