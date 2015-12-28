#import <libxml/HTMLparser.h>

@class BCTextLine;
@protocol BCTextFrameDelegate;


@interface BCTextFrame : NSObject {
	xmlNode *node;
	xmlNode *doc;
	CGFloat fontSize;
	NSMutableArray *lines;
	CGFloat height;
	CGFloat width;
	UIColor *textColor;
	UIColor *linkColor;
	BOOL whitespaceNeeded;
	BOOL indented;
	id <BCTextFrameDelegate> delegate;
	NSMutableDictionary *links;
	NSValue *touchingLink;
    BOOL singleLine;
    
    NSMutableArray*     linksInCurrentLine;
}
+ (BCTextFrame*)textFromHTML:(NSString*)source;
- (id)initWithHTML:(NSString *)html;
- (id)initWithXmlNode:(xmlNode *)aNode;
- (void)drawInRect:(CGRect)rect;
- (BOOL)touchBeganAtPoint:(CGPoint)point;
- (BOOL)touchEndedAtPoint:(CGPoint)point;
- (BOOL)touchMovedAtPoint:(CGPoint)point;
- (void)touchCancelled;

- (CGFloat)properWidth;
- (UIImage *)imageForURL:(NSString *)url;

@property (nonatomic) CGFloat fontSize;
@property (nonatomic) CGFloat height;
@property (nonatomic) CGFloat width;
@property (nonatomic) BOOL indented;

@property (nonatomic, retain) NSMutableDictionary *links;
@property (nonatomic, retain) UIColor *textColor;
@property (nonatomic, retain) UIColor *linkColor;
@property (nonatomic, assign) id <BCTextFrameDelegate> delegate;
@property (nonatomic) BOOL singleLine;
@property (nonatomic, retain) NSMutableArray*     linksInCurrentLine;
@end

@protocol BCTextFrameDelegate
- (void)link:(NSValue *)link touchedInRects:(NSArray *)rects;
- (void)link:(NSValue *)link touchedUpInRects:(NSArray *)rects;

@optional
- (UIImage *)imageForURL:(NSString *)url;

@end

