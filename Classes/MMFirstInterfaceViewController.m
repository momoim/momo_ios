    //
//  MMFirstInterfaceViewController.m
//  momo
//
//  Created by chenjd on 11-10-10.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MMFirstInterfaceViewController.h"
#import "MMGlobalDefine.h"
#import "MMThemeMgr.h"
#import "MMLoginViewController.h"
#import "MMRegisterViewController.h"
#import "MMLoginService.h"
#import "MMCommonAPI.h"
#import "MMGlobalData.h"
#import "MMPreference.h"
#import "MMAppDelegate.h"
#import "MMGlobalPara.h"

@implementation MMFirstInterfaceViewController

- (void)loadView {
    [super loadView];

	UIImageView *imageView = [[[UIImageView alloc]initWithFrame:self.view.bounds] autorelease];
	imageView.backgroundColor = [UIColor clearColor];
    imageView.image = [MMThemeMgr imageNamed:@"login.jpg"];
	[self.view addSubview:imageView];
	
    // register button
	UIButton* button = [[UIButton alloc]initWithFrame:CGRectMake(40, 220, 240, 40)];
    button.backgroundColor = [UIColor clearColor];
    [button setBackgroundImage:[MMThemeMgr imageNamed:@"login_btn.png"] forState:UIControlStateNormal];
	[button setBackgroundImage:[MMThemeMgr imageNamed:@"login_btn_press.png"] forState:UIControlStateHighlighted];
	[button setTitle:@"登录" forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:16];
	[button setTitleColor: [UIColor colorWithRed:(CGFloat)0x00/0xFF green:(CGFloat)0x56/0xFF blue:(CGFloat)0x70/0xFF alpha:1.0] forState:UIControlStateNormal];
	[button setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    [button addTarget:self action:@selector(actionLogin:) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview:button];
	[button release];
    
    button = [[UIButton alloc]initWithFrame:CGRectMake(40, 290, 240, 40)];
    button.backgroundColor = [UIColor clearColor];
    [button setBackgroundImage:[MMThemeMgr imageNamed:@"login_btn_green.png"] forState:UIControlStateNormal];
	[button setBackgroundImage:[MMThemeMgr imageNamed:@"login_btn_green_press.png"] forState:UIControlStateHighlighted];
	[button setTitle:@"注册" forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:16];
	[button setTitleColor: [UIColor colorWithRed:(CGFloat)0x00/0xFF green:(CGFloat)0x56/0xFF blue:(CGFloat)0x70/0xFF alpha:1.0] forState:UIControlStateNormal];
	[button setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    [button addTarget:self action:@selector(actionRegister:) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview:button];
	[button release];
}

- (void)actionLogin:(id)sender{
	MMLoginViewController *controller = [[MMLoginViewController alloc] init];
	[self.navigationController pushViewController:controller animated:YES];
	[controller release];
}

//注册
- (void)actionRegister:(id)sender {
	MMRegisterViewController *controller = [[MMRegisterViewController alloc] init];
	[self.navigationController pushViewController:controller animated:YES];
	[controller release];
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

- (void)viewWillAppear:(BOOL)animated {
	self.navigationController.navigationBarHidden = YES;
}

- (void)viewDidUnload {
    [maskView_ release];
    maskView_ = nil;
    [super viewDidUnload];
}


- (void)dealloc {
	[maskView_ release];
    [super dealloc];
}


@end
