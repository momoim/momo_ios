
#import <UIKit/UIKit.h>

@interface MMAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow                                *window;
    
    @private
    UITabBarController                      *tabBarController_;
}

@property (nonatomic, retain) UIWindow *window;
@property (nonatomic, retain) UITabBarController *tabBarController_;

@end

