#import "BCTextLine.h"
#import "BCTextNode.h"
#import <libxml/HTMLparser.h>

@interface BCTextLine ()
@property (nonatomic, retain) NSMutableArray *stack;
@end

@implementation BCTextLine
@synthesize stack, width, height, indented, y;

- (id)initWithWidth:(CGFloat)aWidth {
	if ((self = [super init])) {
		self.stack = [NSMutableArray arrayWithCapacity:25];
		width = aWidth;
		pos = 0;
	}
	return self;
}

- (void)dealloc {
	self.stack = nil;
	[super dealloc];
}

- (CGFloat)widthRemaining {
	return self.width - pos;
}


- (void)drawAtPoint:(CGPoint)point textColor:(UIColor *)textColor linkColor:(UIColor *)linkColor {
	int drawPos = 0;
	if (self.indented) {
		point.x += kIndentWidth;
	}
	for (BCTextNode *node in self.stack) {
		if ([node isKindOfClass:[BCTextNode class]]) {
			if (node.link) {
				[linkColor set];
			} else {
				[textColor set];
			}
		}
 
		[node drawAtPoint:CGPointMake(point.x + drawPos, point.y + ((self.height / 2) - (node.height / 2)))];
		drawPos += node.width;
	}
}

- (void)addNode:(BCTextNode *)node height:(CGFloat)aHeight {
	[self.stack addObject:node];
	pos += node.width;
	
	if (aHeight > height) {
		height = aHeight;
	}
}

- (void)setHeight:(CGFloat)aHeight { // override automaticaly discovered height
	height = aHeight;
}

- (CGFloat)width {
	if (self.indented) {
		return width - (kIndentWidth * 2);
	} else {
		return width;
	}
}

@end
