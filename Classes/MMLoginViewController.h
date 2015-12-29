//
//  MMLoginViewController.h
//  momo
//
//  Created by jackie on 10-8-7.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MMSelectCountryViewController.h"
#import "MBProgressHUD.h"

@class MMPreferenceViewController;

@interface MMLoginViewController : UIViewController <UITextFieldDelegate, UIActionSheetDelegate, MMSelectCountryDelegate> {
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

- (void)afterLogin:(NSString*)result; 

- (void)actionSelectCountry:(id)sender;

@end
