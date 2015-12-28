//
//  MMRegisterProbationerViewController.h
//  momo
//
//  Created by  on 12-3-16.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MMSelectCountryViewController.h"
#import "MBProgressHUD.h"

@interface MMRegisterProbationerViewController : UIViewController < UITextFieldDelegate, MMSelectCountryDelegate> {
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