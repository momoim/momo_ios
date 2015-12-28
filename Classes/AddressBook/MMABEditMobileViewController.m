//
//  MMABEditMobileViewController.m
//  momo
//
//  Created by mfm on 8/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MMABEditMobileViewController.h"
#import "MMThemeMgr.h"
#import "MMGlobalDefine.h"

@implementation MMABEditMobileViewController

@synthesize momoDelegate;
@synthesize originalMobile_;

#pragma mark -
#pragma mark Initialization
- (id)initWithMobile:(NSString *)mobile {
	
	if (self = [super init]) {
		self.originalMobile_ = mobile;
	}
	return self;
}

-(void)dealloc {  
	self.originalMobile_ = nil;
	
	[newMobile_ release];
	[password_ release];
	[super dealloc];
}

- (void)loadView { 
    [super loadView];
	
	self.view.backgroundColor = TABLE_BACKGROUNDCOLOR;
//navigation	
	UIButton *itemButton = nil;
	UIImage *image = nil;
	image = [MMThemeMgr imageNamed:@"topbar_back.png"];
	itemButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 34, 30)];
	[itemButton setImage:image forState:UIControlStateNormal];	
	[itemButton setImage:image forState:UIControlStateHighlighted];
	[itemButton setBackgroundImage:[MMThemeMgr imageNamed:@"common_topbar_ic_press.png"] forState:UIControlStateHighlighted];
	[itemButton addTarget:self action:@selector(actionLeft:) forControlEvents:UIControlEventTouchUpInside];	
	self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:itemButton] autorelease];
	[itemButton release];
	
	image = [MMThemeMgr imageNamed:@"edit_contact_topbar_save.png"];  
	itemButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 34, 30)];
	[itemButton setImage:image forState:UIControlStateNormal];	
	[itemButton setImage:image forState:UIControlStateHighlighted];
	[itemButton setBackgroundImage:[MMThemeMgr imageNamed:@"common_topbar_ic_press.png"] forState:UIControlStateHighlighted];
	[itemButton addTarget:self action:@selector(actionRight:) forControlEvents:UIControlEventTouchUpInside];
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:itemButton] autorelease];
	[itemButton release];

	self.navigationItem.title = @"编辑姓名";	
	
	//LastName
	image = [MMThemeMgr imageNamed:@"inputbox.png"];  	
	newMobile_ = [[UITextField alloc]initWithFrame:CGRectMake(10, 10, 300, 40)];
	newMobile_.backgroundColor	= [UIColor clearColor];
	newMobile_.textColor		= NOMAL_COLOR;	
	newMobile_.returnKeyType	= UIReturnKeyDone;
	newMobile_.background		= image;
	newMobile_.clearButtonMode	= UITextFieldViewModeWhileEditing;
	newMobile_.font				= [UIFont systemFontOfSize:16];
	newMobile_.placeholder		= @"新手机号码";
	newMobile_.keyboardType		= UIKeyboardTypeDefault;
	newMobile_.clipsToBounds	= YES;	
	newMobile_.leftView			= [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)] autorelease];
	newMobile_.leftViewMode		= UITextFieldViewModeAlways;
	newMobile_.delegate			= self;
	newMobile_.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
	[self.view addSubview:newMobile_];
	
	//FirstName		
	password_ = [[UITextField alloc]initWithFrame:CGRectMake(10, 10 + image.size.height + NOMAL_SPACING, image.size.width, image.size.height)];  
	password_.backgroundColor	= [UIColor clearColor];
	password_.textColor			= NOMAL_COLOR;	
	password_.returnKeyType		= UIReturnKeyDone;
	password_.background		= image;
	password_.clearButtonMode	= UITextFieldViewModeWhileEditing;
	password_.font				= [UIFont systemFontOfSize:16.0];
	password_.placeholder		= @"MOMO密码";
	password_.keyboardType		= UIKeyboardTypeDefault;   
	password_.clipsToBounds		= YES;	
	password_.leftView			= [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)] autorelease];  //生成左偏移
	password_.leftViewMode		= UITextFieldViewModeAlways;
	password_.delegate			= self;    
	password_.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
	[self.view addSubview:password_];

}

- (void)viewDidLoad {
	[newMobile_ becomeFirstResponder];	
}

- (void)viewDidUnload {
	[newMobile_ release];
    newMobile_ = nil;
	
	[password_ release];
	password_ = nil;
	
	[super viewDidUnload];
}

#pragma mark -
#pragma mark action events and other
- (void)actionLeft:(id)sender {
	[self.navigationController popViewControllerAnimated:YES];	
}

- (void)actionRight:(id)sender {
	
	if (![originalMobile_ isEqualToString:newMobile_.text]) {
		if ([(NSObject*)momoDelegate respondsToSelector:@selector(mobileDidChange:withPassword:)]) {
			[momoDelegate mobileDidChange:newMobile_.text withPassword:password_.text];
		}
	}
	
	[self.navigationController popViewControllerAnimated:YES];	
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField  {
	
	[self actionRight:nil];	
	return YES;
}

@end
