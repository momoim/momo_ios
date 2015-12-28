#import <UIKit/UIKit.h>
#import "MMLayoutParams.h"
#import "MMLoginService.h"
#import "MMUapRequest.h"
#import "MMPreference.h"
#import "MMAboutMeManager.h"
#import "MMHttpDownloadMgr.h"

int main(int argc, char *argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
#ifdef NDEBUG
    [MMCrashHandle shareInstance];
#endif
	
	//保证多线程模式
	NSObject* tmpObject = [[NSObject alloc] init];
	[tmpObject performSelectorInBackground:@selector(release) withObject:nil];
	/////////////////

    if (sqlite3_config(SQLITE_CONFIG_MULTITHREAD) != SQLITE_OK) {
		NSLog(@"sqlite3_config failed");
	}
	//创建各个单件
    [MMPreference shareInstance];
	[MMLoginService shareInstance];
	[MMUapRequest shareInstance];
    [MMAboutMeManager shareInstance];
    [MMHttpDownloadMgr shareInstance];

	int retVal = UIApplicationMain(argc, argv, nil, @"MMAppDelegate");
    
    [pool release];
    return retVal;
}
