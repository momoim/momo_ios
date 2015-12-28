//
//  MMHidePortionTextView.m
//  HidePortion
//
//  Created by jackie on 11-7-22.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MMHidePortionTextView.h"

@implementation MMHidePortionText
@synthesize visibleString = visibleString_;
@synthesize hideString = hideString_;
@synthesize visibleRange = visibleRange_;
@synthesize extraText = extraText_;
@synthesize fullString;

- (id)init {
	if (self = [super init]) {
		visibleRange_ = NSMakeRange(0, 0);
        self.extraText = @" ";//默认多插入个空格
	}
	return self;
}

- (id)initWithString:(NSString*)visibleString hideString:(NSString*)hideString {
    self = [super init];
    if (self) {
        visibleRange_ = NSMakeRange(0, 0);
        self.extraText = @" ";//默认多插入个空格
        self.visibleString = visibleString;
        self.hideString = hideString;
    }
    return self;
}

+ (id)hidePortionTextWithString:(NSString*)visibleString hideString:(NSString*)hideString {
    MMHidePortionText* hidePortionText = [[MMHidePortionText alloc] initWithString:visibleString
                                                                        hideString:hideString];
    return [hidePortionText autorelease];
}

+ (id)hidePortionTextWithUserName:(NSString*)userName uid:(NSUInteger)uid {
    NSString* visibleString = [NSString stringWithFormat:@"@%@", userName];
    NSString* hideString = [NSString stringWithFormat:@"հ%dհ", uid];
    MMHidePortionText* hidePortionText = [MMHidePortionText hidePortionTextWithString:visibleString 
                                                                           hideString:hideString];
    return hidePortionText;
}

- (NSString*)fullString {
    return [visibleString_ stringByAppendingString:hideString_];
}

- (void)dealloc {
	self.visibleString = nil;
	self.hideString = nil;
	[super dealloc];
}

@end


@implementation MMHidePortionTextView
@synthesize textView = textView_;
@synthesize selectedRangeBackup = selectedRangeBackup_;
@synthesize hidePotionTextViewDelegate = hidePotionTextViewDelegate_;
@synthesize placeholder;
@synthesize placeholderColor;

- (id)initWithFrame:(CGRect)frame {
	if (self = [super initWithFrame:frame]) {
		portionArray_ = [[NSMutableArray alloc] init];
        
        CGRect newFrame = CGRectMake(0, 0, frame.size.width, frame.size.height);
        textView_ = [[[SSTextView alloc] initWithFrame:newFrame] autorelease];
        textView_.delegate = self;
        textView_.backgroundColor = [UIColor clearColor];
        textView_.autocorrectionType = UITextAutocorrectionTypeNo;
        [self addSubview:textView_];
	}
	return self;
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    
    CGRect newFrame = CGRectMake(0, 0, frame.size.width, frame.size.height);
    textView_.frame = newFrame;
}

- (void)dealloc {
	[portionArray_ release];
	[super dealloc];
}

- (BOOL)becomeFirstResponder {
    return [textView_ becomeFirstResponder];
}

- (BOOL)resignFirstResponder {
    return [textView_ resignFirstResponder];
}

- (BOOL)isFirstResponder {
    return [textView_ isFirstResponder];
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
    NSString* tmpText = textView_.text;
    if (!tmpText) {
        textView_.text = text;
    } else {
        textView_.text = [tmpText stringByAppendingString:text];
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
    visibleRange.location = textView_.text.length;
    hidePortionText.visibleRange = visibleRange;
    [portionArray_ addObject:hidePortionText];
    
    NSString* tmpText = textView_.text;
    if (!tmpText) {
        textView_.text = [NSString stringWithFormat:@"%@%@", hidePortionText.visibleString, hidePortionText.extraText];
    } else {
        textView_.text = [tmpText stringByAppendingFormat:@"%@%@", hidePortionText.visibleString, hidePortionText.extraText];
    }
}

- (void)insertHidePortionText:(MMHidePortionText*)hidePortionText; {
    if (hidePortionText.visibleString.length == 0) {
        return;
    }
    
    NSRange visibleRange = textView_.selectedRange;
    if (textView_.text.length == 0) {
        visibleRange.location = 0;
    }
    
    if (textView_.selectedRange.length > 0) {
        [self onRangeRemoved:textView_.selectedRange];
        
        NSMutableString* newString = [NSMutableString stringWithString:textView_.text];
        [newString deleteCharactersInRange:textView_.selectedRange];
        textView_.text = newString;
    }
    
    visibleRange.length = hidePortionText.visibleString.length;
    hidePortionText.visibleRange = visibleRange;
    visibleRange.length += hidePortionText.extraText.length;;
    [self onRangeInserted:visibleRange];
    [portionArray_ addObject:hidePortionText];
    
    [self sortPortionArray];
    
    NSMutableString* newText = [NSMutableString stringWithString:textView_.text];
    NSString* appendString = [NSString stringWithFormat:@"%@%@", hidePortionText.visibleString, hidePortionText.extraText];
    [newText insertString:appendString atIndex:visibleRange.location];
    textView_.text = newText;
    textView_.selectedRange = NSMakeRange(visibleRange.location + visibleRange.length, 0);
}

- (void)validatePortions {
    for (int i = 0; i < portionArray_.count; i++) {
        MMHidePortionText* hidePortionText = [portionArray_ objectAtIndex:i];
        if (hidePortionText.visibleRange.location + hidePortionText.visibleRange.length > textView_.text.length) {
            NSLog(@"range overflow, location=%d, length=%d, realLength=%d", 
                  hidePortionText.visibleRange.location, 
                  hidePortionText.visibleRange.length, 
                  textView_.text.length);
            
            [portionArray_ removeObjectAtIndex:i];
            i--;
            continue;
        }
        
        NSString* portionText = [textView_.text substringWithRange:hidePortionText.visibleRange];
        if (![portionText isEqualToString:hidePortionText.visibleString]) {
            NSLog(@"Portion not equal, visibleString=%@, realstring=%@", hidePortionText.visibleString, portionText);
            
            [portionArray_ removeObjectAtIndex:i];
            i--;
            continue;
        }
    }
}

- (void)setText:(NSString*)text {
    textView_.text = text;
    [portionArray_ removeAllObjects];
}

- (NSString*)text {
    return textView_.text;
}

- (NSString*)textWithHiddenPortion {
    if (portionArray_.count == 0) {
        return textView_.text;
    }
    
    [self validatePortions];
    
    NSMutableString* result = [NSMutableString string];
    NSRange preRange = NSMakeRange(0, 0);
    NSRange nextRange;
    
    for (MMHidePortionText* hidePortionText in portionArray_) {
        nextRange = hidePortionText.visibleRange;
        
        if (preRange.location + preRange.length < nextRange.location) {
            NSRange appendRange = NSMakeRange(preRange.location + preRange.length, nextRange.location - preRange.location - preRange.length);
            [result appendString:[textView_.text substringWithRange:appendRange]];
        }
        
        [result appendString:hidePortionText.fullString];
        preRange = hidePortionText.visibleRange;
    }
    
    if (preRange.location + preRange.length < textView_.text.length) {
        [result appendString:[textView_.text substringFromIndex:preRange.location + preRange.length]];
    }
    
	return result;
} 

- (void)backupSelectedRange
{
    selectedRangeBackup_ = textView_.selectedRange;
}

- (void)restoreSelectedRange
{
    textView_.selectedRange = selectedRangeBackup_;
}

- (void)clearTextAndHidePortion {
    [self setText:@""];
}

#pragma mark --
#pragma mark UITextViewDelegate
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    //by wangsc:可能是apple的BUG, 先这样处理
    if ([text isEqualToString:@". "] && range.length != 2) {
        range.length = 2;
    }
    
    if (hidePotionTextViewDelegate_ && [hidePotionTextViewDelegate_ respondsToSelector:@selector(textView:shouldChangeTextInRange:replacementText:)]) {
        if (![hidePotionTextViewDelegate_ textView:textView shouldChangeTextInRange:range replacementText:text]) {
            return NO;
        }
    }
    
    if (range.length > 0) {
        [self onRangeRemoved:range];
    }
    
    if (text.length > 0) {
        NSRange replaceRange = NSMakeRange(range.location, text.length);
        [self onRangeInserted:replaceRange];
    }
    
	return YES;
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
    if (hidePotionTextViewDelegate_ && [hidePotionTextViewDelegate_ respondsToSelector:@selector(textViewDidBeginEditing:)]) {
        [hidePotionTextViewDelegate_ textViewDidBeginEditing:textView];
    }
}

- (void)textViewDidChange:(UITextView *)textView {
    if (hidePotionTextViewDelegate_ && [hidePotionTextViewDelegate_ respondsToSelector:@selector(textViewDidChange:)]) {
        [hidePotionTextViewDelegate_ textViewDidChange:textView];
    }
}

- (void)textViewDidChangeSelection:(UITextView *)textView {
    if (hidePotionTextViewDelegate_ && [hidePotionTextViewDelegate_ respondsToSelector:@selector(textViewDidChangeSelection:)]) {
        [hidePotionTextViewDelegate_ textViewDidChangeSelection:textView];
    }
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    if (hidePotionTextViewDelegate_ && [hidePotionTextViewDelegate_ respondsToSelector:@selector(textViewDidEndEditing:)]) {
        [hidePotionTextViewDelegate_ textViewDidEndEditing:textView];
    }
}

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    if (hidePotionTextViewDelegate_ && [hidePotionTextViewDelegate_ respondsToSelector:@selector(textViewShouldBeginEditing:)]) {
        return [hidePotionTextViewDelegate_ textViewShouldBeginEditing:textView];
    }
    return YES;
}

- (BOOL)textViewShouldEndEditing:(UITextView *)textView {
    if (hidePotionTextViewDelegate_ && [hidePotionTextViewDelegate_ respondsToSelector:@selector(textViewShouldEndEditing:)]) {
        return [hidePotionTextViewDelegate_ textViewShouldEndEditing:textView];
    }
    return YES;
}

#pragma mark Placeholder
- (void)setPlaceholder:(NSString *)newPlaceholder {
    [textView_ setPlaceholder:newPlaceholder];
}

- (NSString*)placeholder {
    return textView_.placeholder;
}

- (void)setPlaceholderColor:(UIColor *)newPlaceholderColor {
    [textView_ setPlaceholderColor:newPlaceholderColor];
}

- (UIColor*)placeholderColor {
    return textView_.placeholderColor;
}

@end
