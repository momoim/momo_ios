//
//  MMLoginViewController.m
//  momo
//
//  Created by linsz on 10-8-7.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MMSetNameAndPassViewController.h"
#import "MMGlobalData.h"
#import "MMThemeMgr.h"
#import "MMCommonAPI.h"
#import "MMLoginService.h"
#import "MMDraftMgr.h"
#import "MBProgressHUD.h"
#import "MMUapRequest.h"
#import "MMAppDelegate.h"
#import "MMGlobalPara.h"
#import "MMPreference.h"
#import "MMLoginService.h"
#import "MMAppDelegate.h"
#import "MMMainTabBarController.h"
#import "MMGlobalPara.h"

@implementation MMSetNameAndPassViewController
@synthesize strPassWord = strPassWord_;
@synthesize strName = strName_;

#pragma mark -
#pragma mark Initialization


- (id)init {
    if ((self = [super init])) {
    }
    return self;
}

- (void)loadView {
    [super loadView];
	self.title = @"完善信息";
	self.navigationController.navigationBarHidden = NO;
	self.view.backgroundColor = TABLE_BACKGROUNDCOLOR;
	self.navigationItem.hidesBackButton = YES;
    
	//一个透明的button 点击收回键盘用 放在这。有个先后顺序，后面的控件就可以正常使用  
	removeKeyButton_ = [[[UIButton alloc] initWithFrame:CGRectMake(0, 0, 320, 400)] autorelease];
	removeKeyButton_.backgroundColor = [UIColor clearColor];
	removeKeyButton_.hidden = YES;
	[removeKeyButton_ addTarget:self action:@selector(actionInputShrink:) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview:removeKeyButton_];
    
    //名字
	UIImageView* imageView = [[[UIImageView alloc]initWithFrame:CGRectMake(40, 12, 240, 40)] autorelease];
	imageView.image =[MMThemeMgr imageNamed:@"inputbox.png"];
	[self.view addSubview:imageView];
    tfName_ = [[[UITextField alloc] initWithFrame: CGRectMake(49, 12, 222, 40)] autorelease];
    tfName_.placeholder = @"名字 (必填)";
    tfName_.delegate = self;
    tfName_.clearButtonMode = UITextFieldViewModeNever;
    tfName_.clearsOnBeginEditing = NO;
    tfName_.autocorrectionType = UITextAutocorrectionTypeNo;
    tfName_.borderStyle = UITextBorderStyleNone;
    tfName_.backgroundColor = [UIColor clearColor];
    tfName_.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
	tfName_.textColor = [UIColor colorWithRed:(CGFloat)0x5D/0xFF green:(CGFloat)0x5E/0xFF blue:(CGFloat)0x5E/0xFF alpha:1.0];
    tfName_.font = [UIFont systemFontOfSize:16];
    tfName_.returnKeyType = UIReturnKeyDone;
    [self.view addSubview:tfName_];
    
    imageView = [[[UIImageView alloc]initWithFrame:CGRectMake(40, 58, 240, 40)] autorelease];
	imageView.image =[MMThemeMgr imageNamed:@"inputbox.png"];
	[self.view addSubview:imageView];
    tfPassword_ = [[[UITextField alloc] initWithFrame: CGRectMake(49, 58, 222, 40)] autorelease];
    tfPassword_.placeholder = @"密码 (6-20)";
    tfPassword_.delegate = self;
    tfPassword_.secureTextEntry = YES;
	tfPassword_.keyboardType = UIKeyboardTypeDefault;
    tfPassword_.clearButtonMode = UITextFieldViewModeWhileEditing;
    tfPassword_.clearsOnBeginEditing = NO;
    tfPassword_.autocorrectionType = UITextAutocorrectionTypeNo;
    tfPassword_.borderStyle = UITextBorderStyleNone;
    tfPassword_.backgroundColor = [UIColor clearColor];
    tfPassword_.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    tfPassword_.textColor = [UIColor colorWithRed:(CGFloat)0x5D/0xFF green:(CGFloat)0x5E/0xFF blue:(CGFloat)0x5E/0xFF alpha:1.0];;
	tfPassword_.font = [UIFont systemFontOfSize:16];
    tfPassword_.returnKeyType = UIReturnKeyDone;
    [self.view addSubview:tfPassword_];
    
    imageView = [[[UIImageView alloc]initWithFrame:CGRectMake(40, 108, 240, 40)] autorelease];
	imageView.image =[MMThemeMgr imageNamed:@"inputbox.png"];
	[self.view addSubview:imageView];
    tfPassword2_ = [[[UITextField alloc] initWithFrame:CGRectMake(49,108,222,40)] autorelease];
    tfPassword2_.placeholder = @"密码校验(6-20)";
    tfPassword2_.delegate = self;
    tfPassword2_.secureTextEntry = YES;
	tfPassword2_.keyboardType = UIKeyboardTypeDefault;
    tfPassword2_.clearButtonMode = UITextFieldViewModeWhileEditing;
    tfPassword2_.clearsOnBeginEditing = NO;
    tfPassword2_.autocorrectionType = UITextAutocorrectionTypeNo;
    tfPassword2_.borderStyle = UITextBorderStyleNone;
    tfPassword2_.backgroundColor = [UIColor clearColor];
    tfPassword2_.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    tfPassword2_.textColor = [UIColor colorWithRed:(CGFloat)0x5D/0xFF green:(CGFloat)0x5E/0xFF blue:(CGFloat)0x5E/0xFF alpha:1.0];;
	tfPassword2_.font = [UIFont systemFontOfSize:16];
    [self.view addSubview:tfPassword2_];
    
	UIButton* button = [[[UIButton alloc]initWithFrame:CGRectMake(40, 158, 240, 40)] autorelease];
	button.backgroundColor = [UIColor clearColor];    
    [button setBackgroundImage:[MMThemeMgr imageNamed:@"login_btn.png"] forState:UIControlStateNormal];
	[button setBackgroundImage:[MMThemeMgr imageNamed:@"login_btn_press.png"] forState:UIControlStateHighlighted];
    [button setTitle:@"确定" forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:16];
	[button setTitleColor: [UIColor colorWithRed:(CGFloat)0x00/0xFF green:(CGFloat)0x56/0xFF blue:(CGFloat)0x70/0xFF alpha:1.0] forState:UIControlStateNormal];
	[button setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    [button addTarget:self action:@selector(actionSet:) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview:button];
}

-(void)actionInputShrink:(id)sender {
	removeKeyButton_.hidden = YES;	
	if ([tfName_ isFirstResponder]) {
		[tfName_ resignFirstResponder];
	} else if ([tfPassword_ isFirstResponder]) {
		[tfPassword_ resignFirstResponder];
	}
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
	
	removeKeyButton_.hidden = NO;
}

- (void)viewWillAppear:(BOOL)animated {
//	[mobile_ becomeFirstResponder];
	self.navigationController.navigationBarHidden = NO;
}

- (void)didSetNameAndPwdStatusCode:(NSInteger)statusCode withErrorString:(NSString *)errorString {
    [progressHud_ hide:YES];
    [progressHud_ removeFromSuperview];
    progressHud_ = nil;
    
    if (statusCode != 200) {
        
        UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:errorString message:@""
                                                            delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil] autorelease];
        [alertView show];
        return;
    }

    [[MMLoginService shareInstance] setUserName:tfName_.text];

 
    MMAppDelegate *app = [UIApplication sharedApplication].delegate;
    app.tabBarController_ = [[[MMMainTabBarController alloc] init] autorelease];
    
    [MMGlobalPara setTabBarController:app.tabBarController_];
    app.window.rootViewController = app.tabBarController_;
}


- (void)actionSet:(id)sender {
    if (tfName_.text.length == 0) {
        UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:@"姓名不能为空" message:@""
                                                            delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil] autorelease];
        [alertView show];
        return;
    }
    
    if ([tfPassword_.text length] == 0) {
        UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:@"密码为空" message:@""
                                                            delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil] autorelease];
        [alertView show];
        return;
    }
    
    if (![tfPassword_.text isEqualToString:tfPassword2_.text]) {
        UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:@"密码两次输入不相等" message:@""
                                                            delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil] autorelease];
        [alertView show];
        return;
    }
    
    NSString *name = [[tfName_.text copy] autorelease];
    NSString *password = [[tfPassword_.text copy] autorelease];
    
    
    progressHud_ = [[[MBProgressHUD alloc] initWithWindow:self.view.window] autorelease];
	[self.view.window addSubview:progressHud_];
	[progressHud_ show:YES];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:name, @"username", password, @"password", nil];
        ASIHTTPRequest *request = [ASIHTTPRequest requestWithPath:@"user/init" withObject:dic usingSSL:NO];
        [ASIHTTPRequest startSynchronous:request];
        NSInteger statusCode  = [request responseStatusCode];
        NSObject *responseObject = [request responseObject];
        
        NSString *errorString = nil;
        if (responseObject && [responseObject isKindOfClass:[NSDictionary class]]) {
            NSString* error = [(NSDictionary*)responseObject valueForKey:@"error"];
            errorString = [[MMLoginService shareInstance] errorStringFromResponseError:error statusCode:statusCode];
        }
        
        if (0 == statusCode) {
            errorString = @"网络连接失败";
        }
        
        if (errorString.length == 0) {
            errorString = @"输入不合法，请重新输入";
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self didSetNameAndPwdStatusCode:statusCode withErrorString:errorString];
        });
    });
}


- (void)viewDidUnload {
	tfName_          = nil;
	tfPassword_      = nil;
    self.strName     = nil;
    self.strPassWord = nil;
	[super viewDidUnload];
}


- (void)dealloc {
    self.strName     = nil;
    self.strPassWord = nil;
    [super dealloc];	
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    if ([tfName_.text length] == 0) {
		return NO;
    }
    if ([tfPassword_.text length] == 0) {
        return NO;
    }
    [self actionSet:nil];
    return NO;
}

@end

