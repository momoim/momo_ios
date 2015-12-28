//
//  MMHidePortionTextView.h
//  HidePortion
//
//  Created by jackie on 11-7-22.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SSTextView.h"

@protocol MMHidePortionTextViewDelegate<UITextViewDelegate>


@end

@interface MMHidePortionText : NSObject
{
	NSRange visibleRange_;
	NSString* visibleString_;
	NSString* hideString_;
    
    NSString* extraText_;  //多余的文本, 不算入visibleRange
}
@property (nonatomic) NSRange visibleRange;
@property (nonatomic, copy) NSString* visibleString;
@property (nonatomic, copy) NSString* hideString;
@property (nonatomic, copy) NSString* extraText;
@property (nonatomic, readonly) NSString* fullString;

- (id)initWithString:(NSString*)visibleString hideString:(NSString*)hideString;
+ (id)hidePortionTextWithString:(NSString*)visibleString hideString:(NSString*)hideString;
+ (id)hidePortionTextWithUserName:(NSString*)userName uid:(NSUInteger)uid;

@end


@interface MMHidePortionTextView : UIView <UITextViewDelegate> {
    SSTextView* textView_;
    
	NSRange selectedRangeBackup_;
	NSMutableArray* portionArray_;
	id<MMHidePortionTextViewDelegate> hidePotionTextViewDelegate_;
}
@property (nonatomic, readonly) UITextView* textView;   //尽量不直接获取textView
@property (nonatomic) NSRange selectedRangeBackup;
@property (nonatomic, assign) id<MMHidePortionTextViewDelegate> hidePotionTextViewDelegate;
@property (nonatomic, retain) NSString* placeholder;
@property (nonatomic, retain) UIColor* placeholderColor;

- (void)backupSelectedRange;

- (void)restoreSelectedRange;

- (void)appendText:(NSString*)text;
- (void)appendHidePortionText:(MMHidePortionText*)hidePortionText;
- (void)insertHidePortionText:(MMHidePortionText*)hidePortionText;

- (void)setText:(NSString*)text;
- (NSString*)text;
- (NSString*)textWithHiddenPortion;

- (void)clearTextAndHidePortion;

@end

