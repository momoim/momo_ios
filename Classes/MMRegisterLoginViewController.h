//
//  MMRegisterLoginViewController.h
//  momo
//
//  Created by  on 12-3-19.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MMSelectCountryViewController.h"
#import "MBProgressHUD.h"

@interface MMRegisterLoginViewController : UIViewController <UITextFieldDelegate, UIActionSheetDelegate, MMSelectCountryDelegate> {
    UITextField *mobile_;
    UITextField *password_;
    UIView      *maskView_;
    UIButton    *btnCountry;
	UIButton *removeKeyButton_;
    NSString *telNumber_;
    NSString *telZoneCode_;
    NSString *strCountry_;
    
    BOOL        needLogout_;
    
    MBProgressHUD *progressHUD;
}
@property (nonatomic, copy) NSString *telZoneCode;
@property (nonatomic, copy) NSString *telNumber;
@property (nonatomic, copy) NSString *strCountry;

- (id)initWithMobile:(NSString*)mobile 
            zonecode:(NSString*)zonecode
             country:(NSString*)strCountry;
- (void)showMask;

- (void)actionLogin:(id)sender;
- (void)actionRegister:(id)sender;

- (void)afterLogin:(NSNumber*)result; 

- (void)actionSelectCountry:(id)sender;

@end