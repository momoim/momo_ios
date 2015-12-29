//
//  MMGlobalDefine.h
//  momo
//
//  Created by liaoxh on 11-6-10.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

//#import <Foundation/Foundation.h>

//内外网设置
#define INNER_SERVER 1
#define OUTER_SERVER 2
#define SIMULATE_SERVER 3

#define SERVER OUTER_SERVER

#if (SERVER == OUTER_SERVER)
    //外网
    #define ALBUM_URL @"http://api.momo.im/"


    #define ALBUM_SSL_URL @"https://api.momo.im/"


    #define FEED_BACK_GROUP_ID 136
    #define FEED_BACK_ID 353    //小秘ID

#if 0

    #define MQ_PROXY_HOSTNAME "proxy.momo.im"   //MQ

    #define MQ_HOSTPORT 5672
    #define MQ_PROXY_PORT 9191

    #define REQUEST_DETAIL_URL @"http://v3.api.momo.im/transfer/apiserver.php"
    #define MQ_HOST "/"
    #define CHANGE_PASSWORD @"http://m.momo.im/t/user/password_change"
    #define RESET_PASSWORD @"http://m.momo.im/t/user/password_reset"
    #define CHAT_HISTORY @"http://m.momo.im/t/chats"

    #define YOU_DAO_ID 3388784	//有道翻译 
    #define WEARTHER_91 10643866   //91黄历天气
#endif
#else
    //外网仿真
    #define ALBUM_URL @"http://api.simulate.momo.im/"
    #define ALBUM_SSL_URL @"https://simulate-oauth.momo.im/"
    #define MQ_PROXY_HOSTNAME "proxy.simulate.momo.im"  // "121.207.242.210"   //MQ

    #define MQ_HOSTPORT 5672
    #define MQ_PROXY_PORT 9292
    #define FEED_BACK_GROUP_ID 136
    #define FEED_BACK_ID 353    //小秘ID
    #define REQUEST_DETAIL_URL @"http://api.simulate.momo.im/transfer/apiserver.php"
    #define MQ_HOST "/"
    #define CHANGE_PASSWORD @"http://m.simulate.momo.im/t/user/password_change"
    #define RESET_PASSWORD @"http://m.simulate.momo.im/t/user/password_reset" 
    #define CHAT_HISTORY @"http://m.simulate.momo.im/t/chats"

    #define YOU_DAO_ID 60566	//有道翻译 
    #define WEARTHER_91 71085   //91黄历天气

#endif

#define SCRIPT_HIDE_TOOLBAR @"document.getElementsByClassName(\"toolbar\")[0].style.display='none';"

//ProgressHud显示时间
#define HUB_AUTO_HIDE_DELAY_TIME 2.0f

#define STATUSBAR_OVERLAY_HIDE_DELAY_TIME 2.0f

////////////////////////////////////////////////////////////////////////////////

//UI相关设置
#define iPhone5 ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(640, 1136), [[UIScreen mainScreen] currentMode].size) : NO)
#define TABLE_WIDTH 320.0f    //table的宽度
#define TABLE_BACKGROUNDCOLOR [UIColor colorWithRed:224.0/255.0 green:232.0/255.0 blue:236.0/255.0 alpha:1.0]//table背景色

#define	TABLE_CELL_BG_HEIGHT 44.0f  //cell背景图的高度   //图是43像素高。
#define TABLE_CELL_BG_WIDTH 300.0f  //cell背景图的宽度

#define TABLE_CELL_X_OFFSET 10.0f      //cell背景图的左边（X）偏移量
#define Table_CELL_Y_OFFSET 0.0f	 //cell背景图的上边（Y）偏移量

#define CONTACT_TABLE_CELL_HEIGHT 57.0f  //联系人页面下的cell高度
#define CONTACT_TABLE_CELL_WIDTH 320.0f  //联系人页面下的cell宽度，其实就是table的宽度。
#define CONTACT_TABLE_HEADVIEW_HEIGHT 20.0f  //联系人页面下的headView高度。即section的间距

#define	TABLE_HEADVIEW_HEIGHT 12.0f  //headView高度。即section的间距
#define NOMAL_SPACING 12.0f  //两编辑条之间的间距。

//字体
#define Helvetica [UIFont fontWithName:@"Helvetica" size:18]

#define SELECT_THUMB_IMAGE_SIZE 62


/* ============== text color ================ */

/* 文本颜色 － 普通 */
#define NOMAL_COLOR [UIColor colorWithRed:(CGFloat)0x29/0xFF green:(CGFloat)0x1D/0xFF blue:(CGFloat)0x14/0xFF alpha:1.0]

/* 文本颜色 － 无效 */
#define	INVALID_COLOR [UIColor colorWithRed:(CGFloat)0x71/0xFF green:(CGFloat)0x51/0xFF blue:(CGFloat)0x2B/0xFF alpha:1.0]

/* 文本颜色 － 高亮 */
//名字加个1，是为了避免同名
#define HIGHLIGHT_COLOR [UIColor colorWithRed:(CGFloat)0x9D/0xFF green:(CGFloat)0x30/0xFF blue:(CGFloat)0x12/0xFF alpha:1.0]

/* 文本颜色 － 暗背景色下的文字 */
#define DARK_COLOR [UIColor colorWithRed:(CGFloat)0xBF/0xFF green:(CGFloat)0xAF/0xFF blue:(CGFloat)0x8E/0xFF alpha:1.0]

#define DEFAULT_VIEW_BACKGROUND_COLOR [UIColor colorWithRed:224.0/255.0 green:232.0/255.0 blue:236.0/255.0 alpha:1.0]
#define NAVIGATION_TINT_COLOR [UIColor colorWithRed:0.29 green:0.72 blue:0.87 alpha:1.0]

#define CHECK_NETWORK 	if ([MMCommonAPI getNetworkStatus] == kNotReachable) { \
[MMCommonAPI showAlertHud:@"网络连接失败!" detailText:nil]; \
return; \
}

//判断float是否相等
#define fequal(a,b) (fabs((a) - (b)) < FLT_EPSILON)
#define fequalzero(a) (fabs(a) < FLT_EPSILON)

#define MM_RELEASE_SAFELY(__POINTER) { [__POINTER release]; __POINTER = nil; }

#define BOOL_NUMBER(value) [NSNumber numberWithBool:value]
#define SUBTITLE_GRAY_COLOR RGBCOLOR(156, 157, 157)
#define SUBTITLE_BLUE_COLOR RGBCOLOR(6, 128, 160)
#define HUG_TAG 501

//version
#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)






