#import "BCTextView.h"
#import "BCTextFrame.h"
#import "MMCommonAPI.h"

@interface BCTextView ()
@property (nonatomic, retain) NSArray *linkHighlights;

- (void)removeAllHighlightsLinks;

@end


@implementation BCTextView
@synthesize textFrame, linkHighlights, delegate, contentInset, textToSelect, shouldSelectText;

-(void)setTextFrame:(BCTextFrame *)newTextFrame {
    [textFrame release];
    textFrame = [newTextFrame retain];
    textFrame.delegate = self;
    
    [self removeAllHighlightsLinks];
}

-(id)init {
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)removeAllHighlightsLinks {
    for (UIView *v in self.linkHighlights) {
		[v removeFromSuperview];
	}
    self.linkHighlights = nil;
}

- (void)setShouldSelectText:(BOOL)selectText {
    shouldSelectText = selectText;
    
    NSArray* gestures = [self gestureRecognizers];
    for (UIGestureRecognizer* gesture in gestures) {
        if ([gesture isKindOfClass:[UILongPressGestureRecognizer class]]) {
            [gesture removeTarget:self action:@selector(handleLongPress:)];
        }
    }
    if (selectText) {
        UILongPressGestureRecognizer* longPressGesture = [[[UILongPressGestureRecognizer alloc] initWithTarget:self 
                                                                                                        action:@selector(handleLongPress:)] autorelease];
        [self addGestureRecognizer:longPressGesture];
    }
}

- (id)initWithHTML:(NSString *)html {
	if ((self = [self init])) {
		self.textFrame = [[[BCTextFrame alloc] initWithHTML:html] autorelease];
	}
	return self;
}

- (CGSize)sizeThatFits:(CGSize)size {
    if (self.textFrame.width != (size.width - contentInset.left - contentInset.right)) {
        self.textFrame.width = size.width - contentInset.left - contentInset.right;
    }

    return CGSizeMake(self.textFrame.width + contentInset.left + contentInset.right, 
                      self.textFrame.height + contentInset.top + contentInset.bottom);
}

- (void)drawRect:(CGRect)rect {
	[super drawRect:rect];
//	[[UIColor blackColor] set]; 
    CGRect bounds = self.bounds;
    CGRect rc = UIEdgeInsetsInsetRect(bounds, contentInset);
	[self.textFrame drawInRect:rc];
}

- (void)setFrameWithoutLayout:(CGRect)newFrame {
    [self setFrame:newFrame];
}

- (void)setFrame:(CGRect)aFrame {
	[super setFrame:aFrame];
    
    [self removeAllHighlightsLinks];
    
    if (self.textFrame.width != (aFrame.size.width - contentInset.left - contentInset.right)) {
        self.textFrame.width = aFrame.size.width - contentInset.left - contentInset.right;
    }
	[self setNeedsDisplay];
}

- (void)setFontSize:(CGFloat)aFontSize {
	self.textFrame.fontSize = aFontSize;
}

- (CGFloat)fontSize {
	return self.textFrame.fontSize;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	CGPoint point = [[touches anyObject] locationInView:self];
    point.x -= contentInset.left;
    point.y -= contentInset.top;
	BOOL touchOnLink = [self.textFrame touchBeganAtPoint:point];
	[self setNeedsDisplay];
    
    if (!touchOnLink) {
        [self removeAllHighlightsLinks];
        [super touchesBegan:touches withEvent:event];
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	CGPoint point = [[touches anyObject] locationInView:self];
    point.x -= contentInset.left;
    point.y -= contentInset.top;
	BOOL touchOnLink = [self.textFrame touchEndedAtPoint:point];
	[self setNeedsDisplay];
    
    if (!touchOnLink) {
        [self removeAllHighlightsLinks];
        [super touchesEnded:touches withEvent:event];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    CGPoint point = [[touches anyObject] locationInView:self];
    point.x -= contentInset.left;
    point.y -= contentInset.top;
	[self.textFrame touchMovedAtPoint:point];
	[self setNeedsDisplay];
	[super touchesMoved:touches withEvent:event];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    for (UIView *v in self.linkHighlights) {
		[v removeFromSuperview];
	}
	[self.textFrame touchCancelled];
	[self setNeedsDisplay];
	[super touchesCancelled:touches withEvent:event];
}

- (void)link:(NSValue *)link touchedInRects:(NSArray *)rects {
	for (UIView *v in self.linkHighlights) {
		[v removeFromSuperview];
	}
	
	NSMutableArray *views = [NSMutableArray arrayWithCapacity:rects.count];
	for (NSValue *v in rects) {
		CGRect r = [v CGRectValue];
        r.origin.x += contentInset.left;
        r.origin.y += contentInset.top;
		UIView *view = [[[UIView alloc] initWithFrame:r] autorelease];
		view.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.28];
		[self addSubview:view];
		[views addObject:view];
	}
	self.linkHighlights = views;
}

- (void)link:(NSValue *)link touchedUpInRects:(NSArray *)rects {
	for (UIView *v in self.linkHighlights) {
		[v removeFromSuperview];
	}
    
    xmlNode* linkNode = [link pointerValue];
    if (linkNode) {
        char *url = (char *)xmlGetProp(linkNode, (xmlChar *)"href");
        if (url) {
            NSString* urlString = [NSString stringWithUTF8String:url];
            free(url);
            
            [MMCommonAPI openUrl:urlString];
        }
    }
}

- (void)dealloc {
	self.textFrame = nil;
	self.linkHighlights = nil;
    self.textToSelect = nil;
	[super dealloc];
}

//LONG press copy
- (void)handleLongPress:(id)sender {
    if (textToSelect.length == 0) {
        return;
    }
    
    [self removeAllHighlightsLinks];
    
    [self becomeFirstResponder];
    UIMenuController* menu = [UIMenuController sharedMenuController];
    [menu setTargetRect:self.frame inView:self.superview];
    [menu setMenuVisible:YES animated:YES];
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (void)copy:(id)sender {
    UIPasteboard* pboard = [UIPasteboard generalPasteboard];
    pboard.string = textToSelect;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    return (action == @selector(copy:));
}

@end
