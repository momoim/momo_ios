//
//  MMHidePortionTextField.m
//  HidePortion
//
//  Created by  on 11-9-1.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import "MMHidePortionTextField.h"

@implementation MMHidePortionTextField
@synthesize textField = textField_;
@synthesize hidePortionTextFieldDelegate = hidePotionTextFieldDelegate_;

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        portionArray_ = [[NSMutableArray alloc] init];
        
        CGRect newFrame = CGRectMake(0, 0, frame.size.width, frame.size.height);
        textField_ = [[[UITextField alloc] initWithFrame:newFrame] autorelease];
        textField_.delegate = self;
        textField_.backgroundColor = [UIColor clearColor];
        textField_.autocorrectionType = UITextAutocorrectionTypeNo;
        [self addSubview:textField_];
    }
    return self;
}

- (void)dealloc {
    [portionArray_ release];
    [super dealloc];
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    
    CGRect newFrame = CGRectMake(0, 0, frame.size.width, frame.size.height);
    textField_.frame = newFrame;
}

- (BOOL)becomeFirstResponder {
    return [textField_ becomeFirstResponder];
}

- (BOOL)resignFirstResponder {
    return [textField_ resignFirstResponder];
}

- (BOOL)isFirstResponder {
    return [textField_ isFirstResponder];
}

//删除字符串
- (void)onRangeRemoved:(NSRange)rangedRemoved {
	NSUInteger i, count = [portionArray_ count];
	for (i = 0; i < count; i++) {
		MMHidePortionText * portionText = [portionArray_ objectAtIndex:i];
		NSInteger left = portionText.visibleRange.location;
		NSInteger right = portionText.visibleRange.location + portionText.visibleRange.length - 1;
		//在左边的没影响
		if (right < rangedRemoved.location) {
			continue;
		}
		
		//右边的下标左移
		if (left > (rangedRemoved.location + rangedRemoved.length - 1)) {
            NSRange tmpRange = portionText.visibleRange;
			tmpRange.location = portionText.visibleRange.location - rangedRemoved.length;
            portionText.visibleRange = tmpRange;
			continue;
		}
		
		//中间交叉的先直接抛弃掉
		[portionArray_ removeObjectAtIndex:i];
		--count;
		--i;
	}
}

//插入字符串
- (void)onRangeInserted:(NSRange)rangedInserted {
	NSUInteger i, count = [portionArray_ count];
	for (i = 0; i < count; i++) {
		MMHidePortionText * portionText = [portionArray_ objectAtIndex:i];
		NSInteger left = portionText.visibleRange.location;
		NSInteger right = portionText.visibleRange.location + portionText.visibleRange.length - 1;
        
		//在左边的没影响
		if (right < rangedInserted.location) {
			continue;
		}
		
		//右边的下标左移
		if (left >= rangedInserted.location) {
            NSRange tmpRange = portionText.visibleRange;
			tmpRange.location = portionText.visibleRange.location + rangedInserted.length;
            portionText.visibleRange = tmpRange;
			continue;
		}
		
		//中间交叉的先直接抛弃掉
		[portionArray_ removeObjectAtIndex:i];
		--count;
		--i;
	}
}

- (void)appendText:(NSString*)text {
    NSString* tmpText = textField_.text;
    if (!tmpText) {
        textField_.text = text;
    } else {
        textField_.text = [tmpText stringByAppendingString:text];
    }
}

- (void)sortPortionArray {
    [portionArray_ sortUsingComparator:(NSComparator)^(id obj1, id obj2){
        MMHidePortionText* portion1 = (MMHidePortionText*)obj1;
        MMHidePortionText* portion2 = (MMHidePortionText*)obj2;
        
        if (portion1.visibleRange.location < portion2.visibleRange.location) {
            return NSOrderedAscending;
        } else if (portion1.visibleRange.location > portion2.visibleRange.location) {
            return NSOrderedDescending;
        } else {
            return NSOrderedSame;
        }
    }];
}

- (void)appendHidePortionText:(MMHidePortionText*)hidePortionText {
    if (hidePortionText.visibleString.length == 0) {
        return;
    }
    
    NSRange visibleRange;
    visibleRange.length = hidePortionText.visibleString.length;
    visibleRange.location = textField_.text.length;
    hidePortionText.visibleRange = visibleRange;
    [portionArray_ addObject:hidePortionText];
    
    NSString* tmpText = textField_.text;
    if (!tmpText) {
        textField_.text = [NSString stringWithFormat:@"%@%@", hidePortionText.visibleString, hidePortionText.extraText];
    } else {
        textField_.text = [tmpText stringByAppendingFormat:@"%@%@", hidePortionText.visibleString, hidePortionText.extraText];
    }
}


- (void)validatePortions {
    for (int i = 0; i < portionArray_.count; i++) {
        MMHidePortionText* hidePortionText = [portionArray_ objectAtIndex:i];
        if (hidePortionText.visibleRange.location + hidePortionText.visibleRange.length > textField_.text.length) {
            NSLog(@"range overflow, location=%d, length=%d, realLength=%d", 
                  hidePortionText.visibleRange.location, 
                  hidePortionText.visibleRange.length, 
                  textField_.text.length);
            
            [portionArray_ removeObjectAtIndex:i];
            i--;
            continue;
        }
        
        NSString* portionText = [textField_.text substringWithRange:hidePortionText.visibleRange];
        if (![portionText isEqualToString:hidePortionText.visibleString]) {
            NSLog(@"Portion not equal, visibleString=%@, realstring=%@", hidePortionText.visibleString, portionText);
            
            [portionArray_ removeObjectAtIndex:i];
            i--;
            continue;
        }
    }
}

- (void)setText:(NSString*)text {
    textField_.text = text;
    [portionArray_ removeAllObjects];
}

- (NSString*)text {
    return textField_.text;
}

- (NSString*)textWithHiddenPortion {
    if (portionArray_.count == 0) {
        return textField_.text;
    }
    
    [self validatePortions];
    
    NSMutableString* result = [NSMutableString string];
    NSRange preRange = NSMakeRange(0, 0);
    NSRange nextRange;
    
    for (MMHidePortionText* hidePortionText in portionArray_) {
        nextRange = hidePortionText.visibleRange;
        
        if (preRange.location + preRange.length < nextRange.location) {
            NSRange appendRange = NSMakeRange(preRange.location + preRange.length, nextRange.location - preRange.location - preRange.length);
            [result appendString:[textField_.text substringWithRange:appendRange]];
        }
        
        [result appendString:hidePortionText.fullString];
        preRange = hidePortionText.visibleRange;
    }
    
    if (preRange.location + preRange.length < textField_.text.length) {
        [result appendString:[textField_.text substringFromIndex:preRange.location + preRange.length]];
    }
    
	return result;
}

- (void)clearTextAndHidePortion {
    [self setText:@""];
}

#pragma mark --
#pragma mark UITextFieldDelegate
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if ([string isEqualToString:@". "] && range.length != 2) {
        range.length = 2;
    }
    
    if (hidePotionTextFieldDelegate_ && [hidePotionTextFieldDelegate_ respondsToSelector:@selector(textField:shouldChangeCharactersInRange:replacementString:)]) {
        if (![hidePotionTextFieldDelegate_ textField:textField shouldChangeCharactersInRange:range replacementString:string]) {
            return NO;
        }
    }
    
    if (range.length > 0) {
        [self onRangeRemoved:range];
    }
    
    if (string.length > 0) {
        NSRange replaceRange = NSMakeRange(range.location, string.length);
        [self onRangeInserted:replaceRange];
    }
    
	return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField 
{
    if (hidePotionTextFieldDelegate_ && [hidePotionTextFieldDelegate_ respondsToSelector:@selector(textFieldDidBeginEditing:)]) {
        [hidePotionTextFieldDelegate_ textFieldDidBeginEditing:textField];
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if (hidePotionTextFieldDelegate_ && [hidePotionTextFieldDelegate_ respondsToSelector:@selector(textFieldDidEndEditing:)]) {
        [hidePotionTextFieldDelegate_ textFieldDidEndEditing:textField];
    }
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    if (hidePotionTextFieldDelegate_ && [hidePotionTextFieldDelegate_ respondsToSelector:@selector(textFieldShouldBeginEditing:)]) {
        return [hidePotionTextFieldDelegate_ textFieldShouldBeginEditing:textField];
    }
    return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField {
    if (hidePotionTextFieldDelegate_ && [hidePotionTextFieldDelegate_ respondsToSelector:@selector(textFieldShouldClear:)]) {
        return [hidePotionTextFieldDelegate_ textFieldShouldClear:textField];
    }
    return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    if (hidePotionTextFieldDelegate_ && [hidePotionTextFieldDelegate_ respondsToSelector:@selector(textFieldShouldEndEditing:)]) {
        return [hidePotionTextFieldDelegate_ textFieldShouldEndEditing:textField];
    }
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (hidePotionTextFieldDelegate_ && [hidePotionTextFieldDelegate_ respondsToSelector:@selector(textFieldShouldReturn:)]) {
        return [hidePotionTextFieldDelegate_ textFieldShouldReturn:textField];
    }
    return YES;
}

@end
