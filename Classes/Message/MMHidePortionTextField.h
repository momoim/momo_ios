//
//  MMHidePortionTextField.h
//  HidePortion
//
//  Created by  on 11-9-1.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import "MMHidePortionTextView.h"

@protocol MMHidePortionTextFieldDelegate<UITextFieldDelegate>
@end

@interface MMHidePortionTextField : UITextField <UITextFieldDelegate>
{
    UITextField* textField_;
    
	NSMutableArray* portionArray_;
	id<MMHidePortionTextFieldDelegate> hidePotionTextFieldDelegate_;
}

@property (nonatomic, readonly) UITextField* textField;   //尽量不直接获取textView
@property (nonatomic, assign) id<MMHidePortionTextFieldDelegate> hidePortionTextFieldDelegate;

- (void)appendText:(NSString*)text;
- (void)appendHidePortionText:(MMHidePortionText*)hidePortionText;

- (void)setText:(NSString*)text;
- (NSString*)text;
- (NSString*)textWithHiddenPortion;

- (void)clearTextAndHidePortion;

@end
