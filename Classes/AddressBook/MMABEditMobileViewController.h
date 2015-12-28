//
//  MMABEditMobileViewController.h
//  momo
//
//  Created by mfm on 8/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MMMessageDelegate.h"
#import "DbStruct.h"


@interface MMABEditMobileViewController : UIViewController < UITextFieldDelegate>
{
	NSString *originalMobile_;
	
	UITextField *newMobile_;	
	UITextField *password_;

	id<MMMyMomoDelegate> momoDelegate;
}

@property (nonatomic, assign) id<MMMyMomoDelegate> momoDelegate;
@property (nonatomic, copy) NSString *originalMobile_;


- (id)initWithMobile:(NSString *)mobile;

- (void)actionLeft:(id)sender;
- (void)actionRight:(id)sender;

@end
