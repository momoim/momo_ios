//
//  MMRegisterProbationerViewController.m
//  momo
//
//  Created by  on 12-3-16.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "MMRegisterProbationerViewController.h"
#import "MMUapRequest.h"
#import "MMThemeMgr.h"
#import "MMGlobalData.h"
#import "MMCommonAPI.h"
#import "MMLoginViewController.h"
#import "MMGlobalDefine.h"
#import "MMLoginService.h"
#import "MBProgressHUD.h"
#import "MMGlobalCategory.h"

@implementation MMRegisterProbationerViewController
@synthesize telZoneCode = telZoneCode_;
@synthesize strCountryName = strCountryName_;

- (id)init {
    self = [super init];
    if (self) {
        self.telZoneCode = @"86";
        self.strCountryName = @"中国";
    }
    return self;
}

- (void)loadView {
    [super loadView];
	self.title = @"激活全部功能";
    self.navigationController.navigationBarHidden = NO;
	self.view.backgroundColor = TABLE_BACKGROUNDCOLOR;
    
	UIButton *itemButton = nil;
	UIImage *image = nil;
	image = [MMThemeMgr imageNamed:@"topbar_back.png"];
	itemButton = [[[UIButton alloc] initWithFrame:CGRectMake(0, 0, 34, 30)] autorelease];
	[itemButton setImage:image forState:UIControlStateNormal];	
	[itemButton setImage:image forState:UIControlStateHighlighted];
	[itemButton setBackgroundImage:[MMThemeMgr imageNamed:@"common_topbar_ic_press.png"] forState:UIControlStateHighlighted];
	[itemButton addTarget:self action:@selector(actionBack:) forControlEvents:UIControlEventTouchUpInside];	
	self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:itemButton] autorelease];
	
	btnCountry = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	btnCountry.frame = CGRectMake(40, 30, 240, 36);
	[btnCountry setTitle:@" 中国(+86)" forState:UIControlStateNormal];
	[btnCountry setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [btnCountry addTarget:self action:@selector(actionSelectCountry:) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview:btnCountry];
    
    //一个透明的button 点击收回键盘用 放在这。有个先后顺序，后面的控件就可以正常使用  
	removeKeyButton_ = [[[UIButton alloc] initWithFrame:CGRectMake(0, 0, 320, 400)] autorelease];
	removeKeyButton_.backgroundColor = [UIColor clearColor];
	removeKeyButton_.hidden = YES;
	[removeKeyButton_ addTarget:self action:@selector(actionInputShrink:) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview:removeKeyButton_];	
    
    //手机号
	UIImageView *imageView = [[[UIImageView alloc]initWithFrame:CGRectMake(40, 80, 240, 40)] autorelease];
	imageView.image =[MMThemeMgr imageNamed:@"inputbox.png"];
	[self.view addSubview:imageView];
	mobile_ = [[[UITextField alloc] initWithFrame: CGRectMake(49, 80, 222, 40)] autorelease];
	mobile_.placeholder = @"手机号码";
    mobile_.keyboardType = UIKeyboardTypeNumberPad;
    mobile_.clearButtonMode = UITextFieldViewModeNever;
    mobile_.clearsOnBeginEditing = NO;
    mobile_.autocorrectionType = UITextAutocorrectionTypeNo;
    mobile_.delegate = self;
    mobile_.backgroundColor = [UIColor clearColor];
    mobile_.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    mobile_.textColor = NOMAL_COLOR;
    mobile_.font = [UIFont systemFontOfSize:16];
    mobile_.returnKeyType = UIReturnKeyDone;
    [self.view addSubview:mobile_];
    
    //立即注册按钮
	UIButton* button = [[UIButton alloc]initWithFrame:CGRectMake(40, 136, 240, 40)];
	button.backgroundColor = [UIColor clearColor];    
    [button setBackgroundImage:[MMThemeMgr imageNamed:@"login_btn.png"] forState:UIControlStateNormal];
	[button setBackgroundImage:[MMThemeMgr imageNamed:@"login_btn_press.png"] forState:UIControlStateHighlighted];
    [button setTitle:@"立即激活" forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:16];
	[button setTitleColor: [UIColor colorWithRed:(CGFloat)0x00/0xFF green:(CGFloat)0x56/0xFF blue:(CGFloat)0x70/0xFF alpha:1.0] forState:UIControlStateNormal];
	[button setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    [button addTarget:self action:@selector(actionRegister:) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview:button];
	[button release];
	
	button = [[UIButton alloc]initWithFrame:CGRectMake(40, 190, 240, 40)];
	button.backgroundColor = [UIColor clearColor];    
    [button setBackgroundImage:[MMThemeMgr imageNamed:@"login_btn.png"] forState:UIControlStateNormal];
	[button setBackgroundImage:[MMThemeMgr imageNamed:@"login_btn_press.png"] forState:UIControlStateHighlighted];
    [button setTitle:@"手工激活" forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:16];
	[button setTitleColor: [UIColor colorWithRed:(CGFloat)0x00/0xFF green:(CGFloat)0x56/0xFF blue:(CGFloat)0x70/0xFF alpha:1.0] forState:UIControlStateNormal];
	[button setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    [button addTarget:self action:@selector(actionLogin:) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview:button];
	[button release];
	
	
	UITextView *textView = [[UITextView alloc] initWithFrame:CGRectMake(60, 249, 240, 130)];
	textView.backgroundColor = [UIColor clearColor];
	textView.editable = NO;
	textView.scrollEnabled = NO;
    textView.font = [UIFont systemFontOfSize:14];
    textView.text = @"现在就激活全部功能:\n1. 获取更多免费短信\n2. 获得发送全球短信的权限\n3. 登录momo.im群发短信\n4. 使用云通讯簿，联系人永不丢失\n5. 更多强大功能，等你尝试";
	textView.textAlignment = UITextAlignmentLeft;
    [self.view addSubview:textView];
    [textView release];
}

- (void)actionLogin:(id)sender{
	MMLoginViewController *controller = [[MMLoginViewController alloc] init];
	[self.navigationController pushViewController:controller animated:YES];
	[controller release];
}

-(void)actionInputShrink:(id)sender {
	removeKeyButton_.hidden = YES;
	if ([mobile_ isFirstResponder]) {
		[mobile_ resignFirstResponder];
    }
}
- (void)didRegisterWithResult:(NSInteger)result {
    [progressHUD hide:YES];
	[progressHUD removeFromSuperview];
    
    if (result) {
        switch (result) {
            case 400115:
                [MMCommonAPI alert:@"手机号码为空"];
                break;
            case 400116:
                [MMCommonAPI alert:@"手机号码格式不对"];
                break;
            case 400117:
                [MMCommonAPI alert:@"手机号码已注册"];
                break;
            case 400118:
                [MMCommonAPI alert:@"服务端发送短信异常"];
                break;
            case 400119:
                [MMCommonAPI alert:@"一天内号码发送不能超过3次"];
                break;
            default:
                [MMCommonAPI alert:@"注册失败"];
                break;
        } 
        return;
    }
    
	MMLoginViewController *controller = [[MMLoginViewController alloc] initWithMobile:mobile_.text zonecode:telZoneCode_ country:strCountryName_];
	[self.navigationController pushViewController:controller animated:YES];
	[controller release];
}

- (void)actionRegister:(id)sender {	
    if (![MMCommonAPI isValidTelNumber:mobile_.text]) {
        [MMCommonAPI alert:@"请输入手机号"];
        return;
    }
    
    NSString *number        = [[mobile_.text copy] autorelease];
    NSString *zonecode      = [[telZoneCode_ copy] autorelease];
    
    progressHUD = [[[MBProgressHUD alloc] initWithWindow:self.view.window] autorelease];
	[self.view.window addSubview:progressHUD];
	[progressHUD show:YES];
    
	__block int result = -1;
    
    [[MMLoginService shareInstance] increaseActiveCount];
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        
        result = [[MMLoginService shareInstance] getProbationerVerifyCode:number zonecode:zonecode];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self didRegisterWithResult:result];
		});
        [[MMLoginService shareInstance] decreaseActiveCount];
	});
    
}

- (void)viewDidUnload {
	removeKeyButton_     = nil;
	mobile_              = nil;
    btnCountry           = nil;
	[super viewDidUnload];
}


- (void)dealloc {
    self.telZoneCode = nil;
    [super dealloc];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
	removeKeyButton_.hidden = NO;
}

- (void)actionBack:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
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
        
        self.telZoneCode   = countryInfo.telCode;
        self.strCountryName = countryInfo.cnCountryName;
    }
    [self dismissModalViewControllerAnimated:YES];
}

@end

