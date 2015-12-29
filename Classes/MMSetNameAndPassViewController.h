//
//  MMSetNameAndPassViewController.h
//  momo
//
//  Created by linsz on 11-12-29.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MMSelectCountryViewController.h"
#import "MBProgressHUD.h"

@class MMSetNameAndPassViewController;

@interface MMSetNameAndPassViewController : UIViewController <UITextFieldDelegate> {
    UITextField *tfName_;
    UITextField *tfPassword_;
    UITextField *tfPassword2_;
	UIButton *btnOK;
   	UIButton *removeKeyButton_;
    NSString *strName_;
    NSString *strPassWord_;
    
    MBProgressHUD* progressHud_;
}
@property (nonatomic, copy) NSString *strName;
@property (nonatomic, copy) NSString *strPassWord;
@end
