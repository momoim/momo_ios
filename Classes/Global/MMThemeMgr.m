//
//  MMThemeMgr.m
//  momo
//
//  Created by mfm on 6/24/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MMThemeMgr.h"
#import "UIImageCrossDevice.h"


MMThemeMgr *g_MMThemeMgr;
NSMutableDictionary* imageResourceCacheDict = nil; //内存警告时可以释放
NSMutableDictionary* scaleResourceCacheDict = nil;
NSMutableDictionary* gifImageViewCacheDict = nil;

@implementation MMThemeMgr


+(MMThemeMgr*)getInstance
{
	if (nil == g_MMThemeMgr)
	{
		imageResourceCacheDict = [[NSMutableDictionary alloc] init];
        scaleResourceCacheDict = [[NSMutableDictionary alloc] init];
        gifImageViewCacheDict = [[NSMutableDictionary alloc] init]; 
		g_MMThemeMgr = [[MMThemeMgr alloc] init];
        [g_MMThemeMgr initPara:@"Default"];
	}
	return g_MMThemeMgr;
}

- (id)init {
    self = [super init];
    if (self != nil) {
    }
    
    return self;
}

- (void)dealloc {
    [imageResourceCacheDict release];    
    [scaleResourceCacheDict release];
    [gifImageViewCacheDict release];
	[super dealloc];
}

+ (void)destroyInstance {
    if (g_MMThemeMgr != nil) {
        [g_MMThemeMgr release];
    }
}

+ (void)changeToTheme:(NSString *)themeName {
    MMThemeMgr *instance = [MMThemeMgr getInstance];
    [instance initPara:themeName];
}

//以下函数供内部使用
- (void)initPara:(NSString *)themeName
{
	//新资源中需要伸缩的图片在初始化加载并指定伸缩区域	
	UIImage *image = nil;
		
    image = [MMThemeMgr imageWithContentOfFile:@"share_pop_btn.png"];
	image = [image stretchableImageWithLeftCapWidth:6 topCapHeight:15];
	[scaleResourceCacheDict setObject:image forKey:@"share_pop_btn.png"];
    
    image = [MMThemeMgr imageWithContentOfFile:@"share_bg.png"];
	image = [image stretchableImageWithLeftCapWidth:5 topCapHeight:24];
	[scaleResourceCacheDict setObject:image forKey:@"share_bg.png"];
    
	image = [MMThemeMgr imageWithContentOfFile:@"momo_dynamic_dialog_box.png"];
	image = [image stretchableImageWithLeftCapWidth:24 topCapHeight:15];
	[scaleResourceCacheDict setObject:image forKey:@"momo_dynamic_dialog_box.png"];
    
    image = [MMThemeMgr imageWithContentOfFile:@"share_photo_bg.png"];
	image = [image stretchableImageWithLeftCapWidth:5 topCapHeight:5];
	[scaleResourceCacheDict setObject:image forKey:@"share_photo_bg.png"];
    
    image = [MMThemeMgr imageWithContentOfFile:@"share_photo_single.png"];
	image = [image stretchableImageWithLeftCapWidth:5 topCapHeight:5];
	[scaleResourceCacheDict setObject:image forKey:@"share_photo_single.png"];
	
	image = [MMThemeMgr imageWithContentOfFile:@"momo_dynamic_head_portrait_rightcolor.png"];
	image = [image stretchableImageWithLeftCapWidth:5 topCapHeight:0];
	[scaleResourceCacheDict setObject:image forKey:@"momo_dynamic_head_portrait_rightcolor.png"];
	
	image = [MMThemeMgr imageWithContentOfFile:@"publish_dynamic_picture_number.png"];
	image = [image stretchableImageWithLeftCapWidth:25 topCapHeight:0];
	[scaleResourceCacheDict setObject:image forKey:@"publish_dynamic_picture_number.png"];
	
	image = [MMThemeMgr imageWithContentOfFile:@"chat_basebar_bg.png"];
	image = [image stretchableImageWithLeftCapWidth:2 topCapHeight:4];
	[scaleResourceCacheDict setObject:image forKey:@"chat_basebar_bg.png"];
	
	image = [MMThemeMgr imageWithContentOfFile:@"chat_basebar_inputbox_bg.png"];
	image = [image stretchableImageWithLeftCapWidth:2 topCapHeight:6];
	[scaleResourceCacheDict setObject:image forKey:@"chat_basebar_inputbox_bg.png"];
	
	image = [MMThemeMgr imageWithContentOfFile:@"inputbox.png"];
	image = [image stretchableImageWithLeftCapWidth:9 topCapHeight:14];
	[scaleResourceCacheDict setObject:image forKey:@"inputbox.png"];

	image = [MMThemeMgr imageWithContentOfFile:@"login_btn.png"];
	image = [image stretchableImageWithLeftCapWidth:14 topCapHeight:20];
	[scaleResourceCacheDict setObject:image forKey:@"login_btn.png"];
    
    image = [MMThemeMgr imageWithContentOfFile:@"btn_delete.png"];
	image = [image stretchableImageWithLeftCapWidth:14 topCapHeight:20];
	[scaleResourceCacheDict setObject:image forKey:@"btn_delete.png"];
	
	image = [MMThemeMgr imageWithContentOfFile:@"login_btn_press.png"];
	image = [image stretchableImageWithLeftCapWidth:14 topCapHeight:20];
	[scaleResourceCacheDict setObject:image forKey:@"login_btn_press.png"];
	
	image = [MMThemeMgr imageWithContentOfFile:@"login_btn_green.png"];
	image = [image stretchableImageWithLeftCapWidth:12 topCapHeight:20];
	[scaleResourceCacheDict setObject:image forKey:@"login_btn_green.png"];
	
	image = [MMThemeMgr imageWithContentOfFile:@"login_btn_green_press.png"];
	image = [image stretchableImageWithLeftCapWidth:12 topCapHeight:20];
	[scaleResourceCacheDict setObject:image forKey:@"login_btn_green_press.png"];
	
	image = [MMThemeMgr imageWithContentOfFile:@"about_me_bg_white.png"];
	image = [image stretchableImageWithLeftCapWidth:7 topCapHeight:11];
	[scaleResourceCacheDict setObject:image forKey:@"about_me_bg_white.png"];

	image = [MMThemeMgr imageWithContentOfFile:@"about_me_bg_yellow.png"];
	image = [image stretchableImageWithLeftCapWidth:4 topCapHeight:20];
	[scaleResourceCacheDict setObject:image forKey:@"about_me_bg_yellow.png"];
	
	image = [MMThemeMgr imageWithContentOfFile:@"about_me_at_bg.png"];
	image = [image stretchableImageWithLeftCapWidth:8 topCapHeight:15];
	[scaleResourceCacheDict setObject:image forKey:@"about_me_at_bg.png"];
	
	image = [MMThemeMgr imageWithContentOfFile:@"about_me_bg.png"];
	image = [image stretchableImageWithLeftCapWidth:8 topCapHeight:50];
	[scaleResourceCacheDict setObject:image forKey:@"about_me_bg.png"];
	
	image = [MMThemeMgr imageWithContentOfFile:@"chat_dialogbox_bg_right.png"];
	image = [image stretchableImageWithLeftCapWidth:14 topCapHeight:30];
	[scaleResourceCacheDict setObject:image forKey:@"chat_dialogbox_bg_right.png"];
    
    image = [MMThemeMgr imageWithContentOfFile:@"chat_dialogbox_bg_left.png"];
	image = [image stretchableImageWithLeftCapWidth:14 topCapHeight:30];
	[scaleResourceCacheDict setObject:image forKey:@"chat_dialogbox_bg_left.png"];
	
	image = [MMThemeMgr imageWithContentOfFile:@"chat_bg_right.png"];
	image = [image stretchableImageWithLeftCapWidth:30 topCapHeight:30];
	[scaleResourceCacheDict setObject:image forKey:@"chat_bg_right.png"];
	
	image = [MMThemeMgr imageWithContentOfFile:@"chat_bg_right_press.png"];
	image = [image stretchableImageWithLeftCapWidth:30 topCapHeight:30];
	[scaleResourceCacheDict setObject:image forKey:@"chat_bg_right_press.png"];
	
	image = [MMThemeMgr imageWithContentOfFile:@"chat_bg_left.png"];
	image = [image stretchableImageWithLeftCapWidth:30 topCapHeight:30];
	[scaleResourceCacheDict setObject:image forKey:@"chat_bg_left.png"];
	
	image = [MMThemeMgr imageWithContentOfFile:@"chat_bg_left_press.png"];
	image = [image stretchableImageWithLeftCapWidth:30 topCapHeight:30];
	[scaleResourceCacheDict setObject:image forKey:@"chat_bg_left_press.png"];
	
	image = [MMThemeMgr imageWithContentOfFile:@"chat_ic_press_bg.png"];
	image = [image stretchableImageWithLeftCapWidth:4 topCapHeight:0];
	[scaleResourceCacheDict setObject:image forKey:@"chat_ic_press_bg.png"];

	image = [MMThemeMgr imageWithContentOfFile:@"change_call.png"];
	image = [image stretchableImageWithLeftCapWidth:10 topCapHeight:0];
	[scaleResourceCacheDict setObject:image forKey:@"change_call.png"];
	
	image = [MMThemeMgr imageWithContentOfFile:@"change_call_press.png"];
	image = [image stretchableImageWithLeftCapWidth:10 topCapHeight:0];
	[scaleResourceCacheDict setObject:image forKey:@"change_call_press.png"];
	
	image = [MMThemeMgr imageWithContentOfFile:@"card_remind_yellow.png"];
	image = [image stretchableImageWithLeftCapWidth:2 topCapHeight:0];
	[scaleResourceCacheDict setObject:image forKey:@"card_remind_yellow.png"];
	
	image = [MMThemeMgr imageWithContentOfFile:@"mo_ic_msg.png"];
	image = [image stretchableImageWithLeftCapWidth:80 topCapHeight:0];
	[scaleResourceCacheDict setObject:image forKey:@"mo_ic_msg.png"];
	
	image = [MMThemeMgr imageWithContentOfFile:@"mo_ic_share.png"];
	image = [image stretchableImageWithLeftCapWidth:80 topCapHeight:0];
	[scaleResourceCacheDict setObject:image forKey:@"mo_ic_share.png"];
    
    image = [MMThemeMgr imageWithContentOfFile:@"group_topbar.png"];
	image = [image stretchableImageWithLeftCapWidth:2 topCapHeight:0];
	[scaleResourceCacheDict setObject:image forKey:@"group_topbar.png"];
    
    image = [MMThemeMgr imageWithContentOfFile:@"pop_bg.png"];
	image = [image stretchableImageWithLeftCapWidth:6 topCapHeight:10];
	[scaleResourceCacheDict setObject:image forKey:@"pop_bg.png"];
	
	image = [MMThemeMgr imageWithContentOfFile:@"chat_popup_bg.png"];
	image = [image stretchableImageWithLeftCapWidth:5 topCapHeight:10];
	[scaleResourceCacheDict setObject:image forKey:@"chat_popup_bg.png"];
	
	image = [MMThemeMgr imageWithContentOfFile:@"chat_popup_ic_bg.png"];
	image = [image stretchableImageWithLeftCapWidth:2 topCapHeight:10];
	[scaleResourceCacheDict setObject:image forKey:@"chat_popup_ic_bg.png"];
    
    image = [MMThemeMgr imageWithContentOfFile:@"number_bg.png"];
	image = [image stretchableImageWithLeftCapWidth:10 topCapHeight:10];
	[scaleResourceCacheDict setObject:image forKey:@"number_bg.png"];
    
    image = [MMThemeMgr imageWithContentOfFile:@"chat_history_btn.png"];
	image = [image stretchableImageWithLeftCapWidth:10 topCapHeight:0];
	[scaleResourceCacheDict setObject:image forKey:@"chat_history_btn.png"];
    
    image = [MMThemeMgr imageWithContentOfFile:@"chat_history_btn_press.png"];
	image = [image stretchableImageWithLeftCapWidth:10 topCapHeight:0];
	[scaleResourceCacheDict setObject:image forKey:@"chat_history_btn_press.png"];
    
    image = [MMThemeMgr imageWithContentOfFile:@"chat_card_bg_blue.png"];
	image = [image stretchableImageWithLeftCapWidth:10 topCapHeight:5];
	[scaleResourceCacheDict setObject:image forKey:@"chat_card_bg_blue.png"];
    
    image = [MMThemeMgr imageWithContentOfFile:@"chat_card_bg_gray.png"];
	image = [image stretchableImageWithLeftCapWidth:10 topCapHeight:5];
	[scaleResourceCacheDict setObject:image forKey:@"chat_card_bg_gray.png"];

    image = [MMThemeMgr imageWithContentOfFile:@"momo_dynamic_topbar_button.png"];
	image = [image stretchableImageWithLeftCapWidth:7 topCapHeight:0];
	[scaleResourceCacheDict setObject:image forKey:@"momo_dynamic_topbar_button.png"];
    
    image = [MMThemeMgr imageWithContentOfFile:@"momo_dynamic_topbar_button_press.png"];
	image = [image stretchableImageWithLeftCapWidth:7 topCapHeight:0];
	[scaleResourceCacheDict setObject:image forKey:@"momo_dynamic_topbar_button_press.png"];
    
    image = [MMThemeMgr imageWithContentOfFile:@"change_status_image_button.png"];
	image = [image stretchableImageWithLeftCapWidth:7 topCapHeight:0];
	[scaleResourceCacheDict setObject:image forKey:@"change_status_image_button.png"];
    
    image = [MMThemeMgr imageWithContentOfFile:@"change_status_image_button_selected.png"];
	image = [image stretchableImageWithLeftCapWidth:7 topCapHeight:0];
	[scaleResourceCacheDict setObject:image forKey:@"change_status_image_button_selected.png"];
}

- (void)initTheme:(NSString *)themeName {
    NSString *path = [NSString stringWithFormat:@"Image/Theme/%@", themeName];
    NSDictionary *themePlist = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"theme.plist" ofType:nil inDirectory:path]];

    NSString *value = [themePlist objectForKey:@"addressbookBackgroundImage"];
    if (value != nil) {
        
    }
}

+ (void)removeUnusedImages {
    [imageResourceCacheDict removeAllObjects];
}

+ (UIImage*)imageNamed:(NSString*)imageName {
    UIImage* retImage = [scaleResourceCacheDict objectForKey:imageName];
    if (retImage) {
		return retImage;
	}
    
	retImage = [imageResourceCacheDict objectForKey:imageName];
	if (retImage) {
		return retImage;
	}
	
	NSString* path = @"Image/Default";
	NSString* imagePath = [[NSBundle mainBundle] pathForResource:imageName ofType:nil inDirectory:path];
	retImage = [[[UIImageCrossDevice alloc] initWithContentsOfFile:imagePath] autorelease];
	if (retImage) {
		[imageResourceCacheDict setObject:retImage forKey:imageName];
	}
	return retImage;
}

+ (UIImage*)imageWithContentOfFile:(NSString*)imageName {
    UIImage* retImage = [scaleResourceCacheDict objectForKey:imageName];
    if (retImage) {
		return retImage;
	}
    
	retImage = [imageResourceCacheDict objectForKey:imageName];
	if (retImage) {
		return retImage;
	}
	
	NSString* path = @"Image/Default";
	NSString* imagePath = [[NSBundle mainBundle] pathForResource:imageName ofType:nil inDirectory:path];
	return [[[UIImageCrossDevice alloc] initWithContentsOfFile:imagePath] autorelease];
}

+ (NSArray*)fileListInSubdir:(NSString*)subdir {
    NSString *path = [NSString stringWithFormat:@"Image/Default/%@", subdir];
    NSString *dir = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:path];
    NSArray *fileList = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:dir error:nil];
    NSMutableArray *sfileList = [NSMutableArray array];
    for (NSString *file in fileList) {
        if (![file hasSuffix:@"@2x.png"]){
            [sfileList addObject:file];
        }
    }
    fileList = sfileList;
    fileList = [fileList sortedArrayUsingComparator:^(id obj1, id obj2) {
        NSString *str1 = obj1;
        NSString *str2 = obj2;
        NSInteger i1 = [[str1 stringByDeletingPathExtension] intValue];
        NSInteger i2 = [[str2 stringByDeletingPathExtension] intValue];
        if (i1 < i2) {
            return NSOrderedAscending;            
        } else if (i1 == i2) {
            return NSOrderedSame;
        } else {
            return NSOrderedDescending;
        }
    }];
    return fileList;
}

+ (NSArray*)animationImagesWithSubdir:(NSString*)subdir {
    NSMutableArray *overlayArray = [NSMutableArray array];
    NSString *path = [NSString stringWithFormat:@"Image/Default/%@", subdir];
    NSArray* fileList = [MMThemeMgr fileListInSubdir:subdir];
    
    for (NSString *imageName in fileList) {
        NSString* imagePath = [[NSBundle mainBundle] pathForResource:imageName ofType:nil inDirectory:path];
        UIImage *retImage = [[[UIImageCrossDevice alloc] initWithContentsOfFile:imagePath] autorelease];
        
        [overlayArray addObject:retImage];
    }
    return overlayArray;
}

+ (NSArray*)cacheAnimationImagesWithSubdir:(NSString*)subdir {
    NSMutableArray *overlayArray = [NSMutableArray array];
    NSString *path = [NSString stringWithFormat:@"Image/Default/%@", subdir];
    NSArray* fileList = [MMThemeMgr fileListInSubdir:subdir];
    
    for (NSString *imageName in fileList) {
        NSString* imagePath = [[NSBundle mainBundle] pathForResource:imageName ofType:nil inDirectory:path];
        
        UIImage *retImage = [imageResourceCacheDict objectForKey:imagePath];
        if (!retImage) {
            retImage = [[[UIImageCrossDevice alloc] initWithContentsOfFile:imagePath] autorelease];
            if (retImage) {
                [imageResourceCacheDict setObject:retImage forKey:imagePath];
            }
        }
        
        [overlayArray addObject:retImage];
    }
    return overlayArray;
}

@end
