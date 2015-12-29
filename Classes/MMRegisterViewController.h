//
//  MMRegisterViewController.h
//  momo
//
//  Created by jackie on 10-8-11.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MMSelectCountryViewController.h"
#import "MBProgressHUD.h"

@interface MMRegisterViewController : UIViewController < UITextFieldDelegate, MMSelectCountryDelegate> {
    UITextField *mobile_;
	UIButton *removeKeyButton_; 
    UIButton *btnCountry;
    
    NSString *telZoneCode_;
    NSString *strConutryName_;
   
    MBProgressHUD *progressHUD;
}
@property (nonatomic, copy) NSString* telZoneCode;
@property (nonatomic, copy) NSString* strCountryName;

- (void)actionBack:(id)sender;

- (void)actionRegister:(id)sender;

-(void)actionInputShrink:(id)sender;

- (void)actionSelectCountry:(id)sender;

@end
