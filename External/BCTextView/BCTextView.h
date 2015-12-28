#import "BCTextFrame.h"

@protocol BCTextViewDelegate;
@interface BCTextView : UIView <BCTextFrameDelegate>{
	BCTextFrame *textFrame;
	NSArray *linkHighlights;
    
    id<BCTextViewDelegate> delegate;
    
    UIEdgeInsets contentInset;
    
    NSString* textToSelect;
    BOOL shouldSelectText;
}

- (id)initWithHTML:(NSString *)html;

- (void)setFrameWithoutLayout:(CGRect)newFrame;

- (void)handleLongPress:(id)sender;

@property (nonatomic) CGFloat fontSize;
@property (nonatomic, retain) BCTextFrame *textFrame;
@property (nonatomic,assign) id<BCTextViewDelegate> delegate;
@property (nonatomic) UIEdgeInsets contentInset;
@property (nonatomic, copy) NSString* textToSelect;
@property (nonatomic) BOOL shouldSelectText;
@end

@protocol BCTextViewDelegate <NSObject>

@optional
- (void)didClickAtLink:(NSString*)url;

@end

