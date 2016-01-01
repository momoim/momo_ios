//
//  MMRegisterLoginViewController.m
//  momo
//
//  Created by  on 12-3-19.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "MMRegisterLoginViewController.h"
#import "MMGlobalDefine.h"
#import "MMGlobalData.h"
#import "MMThemeMgr.h"
#import "MMCommonAPI.h"
#import "MMLoginService.h"
#import "MMDraftMgr.h"
#import "MMUapRequest.h"
#import "MMAppDelegate.h"
#import "MMGlobalPara.h"
#import "MMPreference.h"
#import "MMGlobalCategory.h"
#import "MMWebViewController.h"
#import "MMSetNameAndPassViewController.h"
#import "Token.h"

@implementation MMRegisterLoginViewController
@synthesize telNumber   = telNumber_;
@synthesize telZoneCode = telZoneCode_;
@synthesize strCountry  = strCountry_;

#pragma mark -
#pragma mark Initialization

- (id)initWithMobile:(NSString*)mobile 
            zonecode:zonecode 
             country:(NSString*)strCountry{
    self = [super init];
    if (self) {
        self.telNumber = mobile;
        self.telZoneCode = zonecode;
        self.strCountry = strCountry;
        needLogout_ = NO;
    }
    return self;
}

- (id)init {
    if ((self = [super init])) {
        self.telZoneCode = @"86";
        self.strCountry = @"中国";
        needLogout_ = NO;
    }
    return self;
}

- (void)loadView {
    [super loadView];
	self.title = @"用户注册";
    self.view.backgroundColor = TABLE_BACKGROUNDCOLOR;
	UIImage* image = [MMThemeMgr imageNamed:@"topbar_back.png"];
	UIButton *itemButton = [[[UIButton alloc] initWithFrame:CGRectMake(0, 0, 34,30)] autorelease];
	[itemButton setImage:image forState:UIControlStateNormal];
	[itemButton setImage:image forState:UIControlStateHighlighted];
	[itemButton setBackgroundImage:[MMThemeMgr imageNamed:@"common_topbar_ic_press.png"] forState:UIControlStateHighlighted];
	[itemButton addTarget:self action:@selector(actionLeft:) forControlEvents:UIControlEventTouchUpInside];	
	self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:itemButton] autorelease];
    
	//一个透明的button 点击收回键盘用 放在这。有个先后顺序，后面的控件就可以正常使用  
	removeKeyButton_ = [[[UIButton alloc] initWithFrame:CGRectMake(0, 0, 320, 400)] autorelease];
	removeKeyButton_.backgroundColor = [UIColor clearColor];
	removeKeyButton_.hidden = YES;
	[removeKeyButton_ addTarget:self action:@selector(actionInputShrink:) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview:removeKeyButton_];
	
    btnCountry = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	btnCountry.frame = CGRectMake(40, 12, 240, 36);
    NSString* title = [NSString stringWithFormat:@"%@(+%@)", self.strCountry, self.telZoneCode];
	[btnCountry setTitle:title forState:UIControlStateNormal];
	[btnCountry setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [btnCountry addTarget:self action:@selector(actionSelectCountry:) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview:btnCountry];
	
    //手机号
	UIImageView* imageView = [[[UIImageView alloc]initWithFrame:CGRectMake(40, 58, 240, 40)] autorelease];
	imageView.image =[MMThemeMgr imageNamed:@"inputbox.png"];
	[self.view addSubview:imageView];
    mobile_ = [[[UITextField alloc] initWithFrame: CGRectMake(49, 58, 222, 40)] autorelease];
    mobile_.placeholder = @"手机号码";
    mobile_.delegate = self;
    mobile_.keyboardType = UIKeyboardTypePhonePad;
    mobile_.clearButtonMode = UITextFieldViewModeNever;
    mobile_.clearsOnBeginEditing = NO;
    mobile_.autocorrectionType = UITextAutocorrectionTypeNo;
    if (telNumber_) {
        mobile_.text = telNumber_;
    }
    
    mobile_.borderStyle = UITextBorderStyleNone;
    mobile_.backgroundColor = [UIColor clearColor];
    mobile_.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
	mobile_.textColor = [UIColor colorWithRed:(CGFloat)0x5D/0xFF green:(CGFloat)0x5E/0xFF blue:(CGFloat)0x5E/0xFF alpha:1.0];
    mobile_.font = [UIFont systemFontOfSize:16];
    mobile_.returnKeyType = UIReturnKeyDone;
    [self.view addSubview:mobile_];
    
    imageView = [[[UIImageView alloc]initWithFrame:CGRectMake(40, 108, 240, 40)] autorelease];
	imageView.image =[MMThemeMgr imageNamed:@"inputbox.png"];
	[self.view addSubview:imageView];
    password_ = [[[UITextField alloc] initWithFrame: CGRectMake(49, 108, 222, 40)] autorelease];
    password_.placeholder = @"验证码";
    
    password_.delegate = self;
    password_.secureTextEntry = YES;
	password_.keyboardType = UIKeyboardTypeDefault;
    // TODO: also test
    password_.clearButtonMode = UITextFieldViewModeWhileEditing;
    password_.clearsOnBeginEditing = NO;
    password_.autocorrectionType = UITextAutocorrectionTypeNo;
    password_.borderStyle = UITextBorderStyleNone;
    password_.backgroundColor = [UIColor clearColor];
    password_.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    password_.textColor = [UIColor colorWithRed:(CGFloat)0x5D/0xFF green:(CGFloat)0x5E/0xFF blue:(CGFloat)0x5E/0xFF alpha:1.0];;
	password_.font = [UIFont systemFontOfSize:16];
    password_.returnKeyType = UIReturnKeyDone;
    [self.view addSubview:password_];
    
	UIButton* button = [[[UIButton alloc]initWithFrame:CGRectMake(40, 164, 240, 40)] autorelease];
	button.backgroundColor = [UIColor clearColor];    
    [button setBackgroundImage:[MMThemeMgr imageNamed:@"login_btn.png"] forState:UIControlStateNormal];
	[button setBackgroundImage:[MMThemeMgr imageNamed:@"login_btn_press.png"] forState:UIControlStateHighlighted];
    [button setTitle:@"下一步" forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:16];
	[button setTitleColor: [UIColor colorWithRed:(CGFloat)0x00/0xFF green:(CGFloat)0x56/0xFF blue:(CGFloat)0x70/0xFF alpha:1.0] forState:UIControlStateNormal];
	[button setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    [button addTarget:self action:@selector(actionLogin:) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview:button];
    
    if ([telNumber_ length] > 0) {
        button = [[[UIButton alloc]initWithFrame:CGRectMake(40, 220, 240, 40)] autorelease];
        button.backgroundColor = [UIColor clearColor];
        [button setBackgroundImage:[MMThemeMgr imageNamed:@"login_btn.png"] forState:UIControlStateNormal];
        [button setBackgroundImage:[MMThemeMgr imageNamed:@"login_btn_press.png"] forState:UIControlStateHighlighted];
        [button setTitle:@"重获验证码" forState:UIControlStateNormal];
        button.titleLabel.font = [UIFont systemFontOfSize:16];
        [button setTitleColor: [UIColor colorWithRed:(CGFloat)0x00/0xFF green:(CGFloat)0x56/0xFF blue:(CGFloat)0x70/0xFF alpha:1.0] forState:UIControlStateNormal];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
        [button addTarget:self action:@selector(actionRegister:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:button];
    } else {
        button.frame = CGRectMake(40, 158, 240, 40);
    }
}

-(void)actionInputShrink:(id)sender {
	removeKeyButton_.hidden = YES;	
	if ([mobile_ isFirstResponder]) {
		[mobile_ resignFirstResponder];
	} else if ([password_ isFirstResponder]) {
		[password_ resignFirstResponder];
	}
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
	
	removeKeyButton_.hidden = NO;
}

- (void)viewWillAppear:(BOOL)animated {
    //	[mobile_ becomeFirstResponder];
	self.navigationController.navigationBarHidden = NO;
}


-(void)afterRegiter:(NSString*)result {
    [maskView_ removeFromSuperview];

    if (result.length > 0) {
        [MMCommonAPI alert:result];
        return;
    }
    
    
    
    MMSetNameAndPassViewController *controller = [[MMSetNameAndPassViewController alloc] init];
    [self.navigationController pushViewController:controller animated:YES];
    [controller release];
}

- (NSString*)errorStringFromResponseError:(NSString*)error statusCode:(NSInteger)statusCode {
    if (statusCode == 0) {
        return @"网络连接失败";
    }
    
    NSArray* errorArray = [error componentsSeparatedByString:@":"];
    if (errorArray.count < 2) {
        return nil;
    }
    
    return [errorArray objectAtIndex:1];
}

- (void)actionLogin:(id)sender {
    if ([mobile_.text length] == 0) {
        [MMCommonAPI alert:@"请输入手机号"];
		return;
    }
    if ([password_.text length] == 0) {
		[MMCommonAPI alert:@"请输入密码"];
        return;
    }
    
    CHECK_NETWORK;
    
    [self showMask];
	
    //注册
    NSString* phone = [[mobile_.text copy] autorelease];
    NSString* password = [[password_.text copy] autorelease];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        NSInteger statusCode = 0;
        NSDictionary* response = [[MMLoginService shareInstance] verifyRegister:phone zonecode:telZoneCode_
                                                                     password:password statusCode:&statusCode];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [maskView_ removeFromSuperview];
            
            NSLog(@"verify register:%@", response);
            
            if (statusCode != 200) {
                NSString *error = [response objectForKey:@"error"];
                NSString* retString = [self errorStringFromResponseError:error statusCode:statusCode];
                if (!retString) {
                    retString = @"验证失败";
                }
                [MMCommonAPI alert:retString];
                return;
            }
            
            
            Token *token = [Token instance];
            token.accessToken = [response objectForKey:@"access_token"];
            token.refreshToken = [response objectForKey:@"refresh_token"];
            
            token.expireTimestamp = (int)time(NULL) + [[response objectForKey:@"expires_in"] intValue];
            token.uid = [[response objectForKey:@"id"] longLongValue];;
            token.phoneNumber = phone;
            [token save];

            //发送登陆通知
            NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:phone, @"user_mobile", @"YES", @"realLogin", nil];
            NSNotification *notification = [NSNotification notificationWithName:kMMUserLogin object:nil userInfo:userInfo];
            [[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:) withObject:notification waitUntilDone:NO];

            MMSetNameAndPassViewController *controller = [[MMSetNameAndPassViewController alloc] init];
            [self.navigationController pushViewController:controller animated:YES];
            [controller release];
        });
    });
}

- (void)didRegisterWithResult:(NSString*)result {
	[progressHUD hide:YES];
	[progressHUD removeFromSuperview];
    
    if (result.length > 0) {
        [MMCommonAPI alert:result];
        return;
    } else {
        [MMCommonAPI alert:@"请查收短信"];
    }
}

- (void)actionRegister:(id)sender {
    NSString *number = [[mobile_.text copy] autorelease];
    
    progressHUD = [[[MBProgressHUD alloc] initWithWindow:self.view.window] autorelease];
	[self.view.window addSubview:progressHUD];
	[progressHUD show:YES];
    
    [[MMLoginService shareInstance] increaseActiveCount];
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        
        NSString* result = [[MMLoginService shareInstance] reGetRegisterVerifyCode:number zonecode:telZoneCode_];
        dispatch_async(dispatch_get_main_queue(), ^{
			[self didRegisterWithResult:result];
		});
        [[MMLoginService shareInstance] decreaseActiveCount];
	});
}

- (void)viewDidUnload {
	mobile_          = nil;
	password_        = nil;
	maskView_        = nil;
    self.telNumber = nil;
    self.telZoneCode = nil;
	[super viewDidUnload];
}


- (void)dealloc {
    self.telNumber = nil;
    self.telZoneCode = nil;
    [super dealloc];
}

- (void)actionLeft:(id)sender {
	[self.navigationController popViewControllerAnimated: YES];	
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    if ([mobile_.text length] == 0) {
		return NO;
    }
    if ([password_.text length] == 0) {
        return NO;
    }
    [self actionLogin:nil];
    return NO;
}

- (void)showMask {
    // show mask
    [maskView_ release];
    maskView_ = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    maskView_.backgroundColor = [UIColor blackColor];
    maskView_.alpha = 0.8f;
    
    UIActivityIndicatorView *activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    activity.frame = CGRectMake(142, 200, 36, 36);
    [activity startAnimating];
    [maskView_ addSubview:activity];
    [activity release];
    [[[UIApplication sharedApplication] keyWindow] addSubview:maskView_];
}

- (void)actionSelectCountry:(id)sender {
    MMSelectCountryViewController *viewController = [[[MMSelectCountryViewController alloc] init] autorelease];
    viewController.delegate = self;
    
    UINavigationController *navigationController = [[[MMNavigationController alloc]
                                                     initWithRootViewController:viewController] autorelease];
    [self presentModalViewController:navigationController animated:YES];
}

#pragma mark MMSelectCountryDelegate
- (void)didSelectCountry:(MMCountryInfo*)countryInfo {
    if (countryInfo) {
        NSString* title = [NSString stringWithFormat:@"%@(+%@)", countryInfo.cnCountryName, countryInfo.telCode];
        [btnCountry setTitle:title forState:UIControlStateNormal];
        [btnCountry setTitle:title forState:UIControlStateHighlighted];
        
        self.telZoneCode = countryInfo.telCode;
    }
    [self dismissModalViewControllerAnimated:YES];
}

@end
