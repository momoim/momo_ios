
#import <UIKit/UIKit.h>

@interface MMAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow                                *window;
    
    @private
    UITabBarController                      *tabBarController_;
	NSArray									*tabItems;
	
    NSObject<UITabBarControllerDelegate>    *tabBarDelegate_;
	
	UIViewController *preselectedView_;
	
	UINavigationController *preferenceViewNavigationController_;	
	
	NSMutableArray *arrayViewNames_;
    UIViewController *messageViewController_;
    NSTimeInterval enterForegroundTime_;
    
    NSTimer* resignActiveTimer_; //锁屏一段时间后关闭MQ和其它定时器, 节省耗电
	BOOL allowAddressBook_;
	UIImageView* allowBackView_;
}

@property (nonatomic, retain) UIWindow *window;
@property (nonatomic, retain) UITabBarController *tabBarController_;
@property (nonatomic, retain) NSArray	*tabItems;
@property (nonatomic, retain) NSMutableArray *arrayViewNames_;
@property (nonatomic, retain) UIViewController *messageViewController;

@property (nonatomic, retain) NSTimer* resignActiveTimer;

- (void)addViewController:(UIViewController*)controller 
			  andViewName:(NSString*)viewName atIndex:(NSUInteger)index;

- (void)switchToStartViewController;

@end

