#import "BCTextFrame.h"
#import "BCTextLine.h"
#import "BCTextNode.h"
#import "BCImageNode.h"
#import "BCBlockBorder.h"
#import "MMThemeMgr.h"
#import <CoreText/CoreText.h>
#import "MMGlobalStyle.h"

typedef enum {
	BCTextNodePlain = 0,
	BCTextNodeBold = 1,
	BCTextNodeItalic = 1 << 1,
	BCTextNodeLink = 1 << 2,
} BCTextNodeAttributes;

@interface BCTextFrame ()
- (UIFont *)fontWithAttributes:(BCTextNodeAttributes)attr;

@property (nonatomic, retain) NSMutableArray *lines;
@property (nonatomic, retain) BCTextLine *currentLine;
@end

@implementation BCTextFrame
@synthesize fontSize, height, width, lines, textColor, linkColor, delegate, indented, links, singleLine, linksInCurrentLine;

- (id)init {
	if ((self = [super init])) {
		self.textColor = [UIColor blackColor];
		self.linkColor = RGBCOLOR(0, 112, 191);
	}
	
	return self;
}

+ (BCTextFrame*)textFromHTML:(NSString*)source {
    return [[[[self class] alloc] initWithHTML:source] autorelease];
}

- (id)initWithHTML:(NSString *)html {
    if (!html) {
        html = @"";
    }
    
	if ((self = [self init])) {
        //bug ios7 enc == null
//		CFStringEncoding cfenc = CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding);
//		CFStringRef cfencstr = CFStringConvertEncodingToIANACharSetName(cfenc);
//		const char *enc = CFStringGetCStringPtr(cfencstr, 0);

        const char *enc = "utf-8";
        
		// let's set our xml doc to doc because we don't want to free node
		// (which we didn't alloc) but we want to free a doc we alloced
		doc = node = (xmlNode *)htmlReadDoc((xmlChar *)[html UTF8String],
									   "",
									   enc,
									   XML_PARSE_NOERROR | XML_PARSE_NOWARNING);
	}
	
	return self;
}

- (id)initWithXmlNode:(xmlNode *)aNode {
	if ((self = [self init])) {
		node = aNode;
	}
	
	return self;
}

- (BOOL)touchBeganAtPoint:(CGPoint)point {
	for (NSValue *link in self.links) {
		NSArray *rects = [self.links objectForKey:link];
		for (NSValue *v in rects) {
			if (CGRectContainsPoint([v CGRectValue], point)) {
				touchingLink = link;
				if ([(NSObject *)self.delegate respondsToSelector:@selector(link: touchedInRects:)])
					[self.delegate link:link touchedInRects:rects];
				return YES;
			}
		}
	}
    return NO;
}

- (BOOL)touchEndedAtPoint:(CGPoint)point {
	if (touchingLink) {
		NSArray *rects = [self.links objectForKey:touchingLink];
		for (NSValue *v in rects) {
			if (CGRectContainsPoint([v CGRectValue], point)) {
				if ([(NSObject *)self.delegate respondsToSelector:@selector(link: touchedUpInRects:)])
					[self.delegate link:touchingLink touchedUpInRects:rects];
				
				touchingLink = nil;
                return YES;
			}
		}
	}
	touchingLink = nil;
    return NO;
}

- (BOOL)touchMovedAtPoint:(CGPoint)point {
    if (touchingLink) {
        NSArray *rects = [self.links objectForKey:touchingLink];
        BOOL containPoint = NO;
        for (NSValue *v in rects) {
			if (CGRectContainsPoint([v CGRectValue], point)) {
				containPoint = YES;
                break;
			}
		}
        
        if (!containPoint) {
            if ([(NSObject *)self.delegate respondsToSelector:@selector(link: touchedUpInRects:)])
                [self.delegate link:touchingLink touchedUpInRects:rects];
            
            touchingLink = nil;
            return YES;
        }
    }
    return NO;
}

- (void)touchCancelled {
	touchingLink = nil;
}

- (void)layoutLinksInCurrentLine {
    if (linksInCurrentLine == 0) {
        return;
    }
    
    for (NSValue* link in linksInCurrentLine) {
        BCTextLine* currentLine = self.currentLine;
        NSMutableArray *linkRectValues = [self.links objectForKey:link];
        for (int i = 0; i < linkRectValues.count; i++) {
            NSValue* linkRectValue = [linkRectValues objectAtIndex:i];
            CGRect linkRect = [linkRectValue CGRectValue];
            
            //当前行的link
            if ((NSInteger)linkRect.origin.y == (NSInteger)currentLine.y && currentLine.height > linkRect.size.height) {
                linkRect.origin.y += currentLine.height / 2 - linkRect.size.height / 2;
                [linkRectValues replaceObjectAtIndex:i withObject:[NSValue valueWithCGRect:linkRect]];
            }
        }
    }
    [linksInCurrentLine removeAllObjects];
}

- (void)pushNewline:(BCTextLine *)line {
	line.indented = self.indented;
	if (self.currentLine.height == 0) {
		self.currentLine.height = self.fontSize;
	}
	self.currentLine = line;
}

- (void)pushNewline {
    //插入新行时,对上一行的链接位置进行调整
    [self layoutLinksInCurrentLine];
    
	[self pushNewline:[[[BCTextLine alloc] initWithWidth:self.width] autorelease]];
}

- (void)addLink:(NSValue *)link forRect:(CGRect)rect {
	NSMutableArray *a = [self.links objectForKey:link];
	if (!a) {
		a = [NSMutableArray array];
		[self.links setObject:a forKey:link];
	}
	
	[a addObject:[NSValue valueWithCGRect:rect]];
    
    //保存当前行的link
    [linksInCurrentLine addObject:link];
}

- (void)pushText:(NSString *)text withFont:(UIFont *)font link:(NSValue *)link {
	CGSize size = [text sizeWithFont:font];

	if (size.width > self.currentLine.widthRemaining) {
		NSRange spaceRange = [text rangeOfCharacterFromSet:[NSCharacterSet newlineCharacterSet]];
		
		// a word that needs to wrap
		if (spaceRange.location == NSNotFound || spaceRange.location == text.length - 1) {
            if (self.currentLine.widthRemaining < fontSize) {
                [self pushNewline];
            }
			
			if (size.width > self.currentLine.widthRemaining) { // word is too long even for its own line
                NSMutableAttributedString* attributedString = [[NSMutableAttributedString alloc] initWithString:text];
                
                CTFontRef aFont = CTFontCreateWithName((CFStringRef)font.familyName, fontSize, NULL);
                [attributedString addAttribute:(NSString*)kCTFontAttributeName value:(id)aFont range:NSMakeRange(0, text.length)];
                
                CTTypesetterRef typesetter = CTTypesetterCreateWithAttributedString((CFAttributedStringRef)attributedString);
                NSInteger length = CTTypesetterSuggestLineBreak(typesetter, 0, self.currentLine.widthRemaining);
                [attributedString release];
                CFRelease(aFont);
                CFRelease(typesetter);
                
                NSString *firstPart = [text substringToIndex:length];
                
                //sizeWithFont算出的宽度会更大, 可能会导致死循环, 这里直接addNote
//				[self pushText:lastPart withFont:font link:link];
                size = [firstPart sizeWithFont:font];
                BCTextNode *n = [[[BCTextNode alloc] initWithText:firstPart font:font width:size.width height:size.height link:link != nil] autorelease];
                if (link) {
                    [self addLink:link forRect:CGRectMake((self.currentLine.width - self.currentLine.widthRemaining) - 2, 
                                                          self.currentLine.y, 
                                                          n.width + 4, n.height)];
                }
                [self.currentLine addNode:n height:size.height];
                
                if (length < text.length) {
                    [self pushNewline]; //断句后插入新行, 防止单词被截断
                    [self pushText:[text substringFromIndex:length] withFont:font link:link];
                }
			} else {
				[self pushText:text withFont:font link:link];
			}
		} else {
			[self pushText:[text substringWithRange:NSMakeRange(0, spaceRange.location + 1)] withFont:font
					  link:link];
			[self pushText:[text substringWithRange:NSMakeRange(spaceRange.location + 1, text.length - (spaceRange.location + 1))]
				  withFont:font
					  link:link];
		}
	} else {
		BCTextNode *n = [[[BCTextNode alloc] initWithText:text font:font width:size.width height:size.height link:link != nil] autorelease];
		
		if (link) {
			[self addLink:link forRect:CGRectMake((self.currentLine.width - self.currentLine.widthRemaining) - 2, 
												  self.currentLine.y, 
												  n.width + 4, n.height)];
		}
																				  
		[self.currentLine addNode:n height:size.height];
	}
}

- (void)pushImage:(NSString *)src linkTarget:(NSValue *)link {
	UIImage *img = nil;
	BCImageNode *n;
	if ([(NSObject *)self.delegate respondsToSelector:@selector(imageForURL:)]) {
		img = [self.delegate imageForURL:src];
		n = [[[BCImageNode alloc] initWithImage:img link:YES] autorelease];
		if (img.size.width > self.currentLine.widthRemaining) {
			[self pushNewline];
		}
	} 
	
	if (!img) {
		img = [UIImage imageNamed:@"view-image.png"];
		n = [[[BCImageNode alloc] initWithImage:img link:NO] autorelease];
		if (img.size.width > self.currentLine.widthRemaining) {
			[self pushNewline];
		}
		[self addLink:(NSValue *)src forRect:CGRectMake((self.currentLine.width - self.currentLine.widthRemaining) - 2, 
											  self.currentLine.y, 
											  img.size.width + 4, img.size.height)];
	}
	
	
	[self.currentLine addNode:(BCTextNode *)n height:img.size.height];
	
	whitespaceNeeded = YES;
	
}

- (void)pushImage:(xmlNode*)curNode link:(NSValue *)link {
    UIImage *img = nil;
	BCImageNode *n;
    
    char *url = (char *)xmlGetProp(curNode, (xmlChar *)"src");
    NSString *src = [NSString stringWithUTF8String:url];
    free(url);
    
    img = [self imageForURL:src];
    if (!img) {
        NSLog(@"%@ 图片不存在", src);
        return;
    }
    
    n = [[[BCImageNode alloc] initWithImage:img link:YES] autorelease];
    
    //获取HTML中指定高宽
    char* sWidth = (char *)xmlGetProp(curNode, (xmlChar *)"width");
    if (sWidth) {
        n.imageWidth = [[NSString stringWithUTF8String:sWidth] intValue];
        xmlFree(sWidth);
    }
    char* sHeight = (char *)xmlGetProp(curNode, (xmlChar *)"height");
    if (sHeight) {
        n.imageHeight = [[NSString stringWithUTF8String:sHeight] intValue];
        xmlFree(sHeight);
    }
    
    //图片宽度大于行宽, 缩放
    if (n.imageWidth > self.currentLine.width) {
        NSInteger tmpWidth = n.imageWidth;
        n.imageWidth = self.currentLine.width - 10;
        n.imageHeight = (NSInteger)((float)n.imageHeight * (float)n.imageWidth / (float)tmpWidth);
    }
    
    if (n.imageWidth > self.currentLine.widthRemaining) {
        [self pushNewline];
    }
    
    [self.currentLine addNode:(BCTextNode *)n height:n.imageHeight];
	
	whitespaceNeeded = YES;
}

- (void)pushBlockBorder {
	[self pushNewline:[[[BCBlockBorder alloc] initWithWidth:self.width] autorelease]];
}


- (NSString *)stripWhitespace:(char *)str {
	char *stripped = malloc(strlen(str) + 1);
	int i = 0;
	for (; *str != '\0'; str++) {
		if (*str == ' ' || *str == '\t' || *str == '\n' || *str == '\r') {
			if (whitespaceNeeded) {
				stripped[i++] = ' ';
				whitespaceNeeded = NO;
			}
		} else {
			whitespaceNeeded = YES;
			stripped[i++] = *str;
		}
	}
	stripped[i] = '\0';
	NSString *strippedString = [NSString stringWithUTF8String:stripped];
	free(stripped);
	return strippedString;
}


- (void)layoutNode:(xmlNode *)n attributes:(BCTextNodeAttributes)attr linkTarget:(NSValue *)link {
	if (!n) return;
	
	for (xmlNode *curNode = n; curNode; curNode = curNode->next) {
		if (curNode->type == XML_TEXT_NODE) {
			UIFont *textFont = [self fontWithAttributes:attr];
			
			NSString *text = [self stripWhitespace:(char *)curNode->content];
			
			[self pushText:text withFont:textFont link:link];
		} else {
			BCTextNodeAttributes childrenAttr = attr;
			
			if (curNode->name) {
				if (!strcmp((char *)curNode->name, "b")) {
					childrenAttr |= BCTextNodeBold;
				} else if (!strcmp((char *)curNode->name, "i")) {
					childrenAttr |= BCTextNodeItalic; 
				} else if (!strcmp((char *)curNode->name, "a")) {
					childrenAttr |= BCTextNodeLink;
					[self layoutNode:curNode->children attributes:childrenAttr linkTarget:[NSValue valueWithPointer:curNode]];
					continue;
				} else if (!strcmp((char *)curNode->name, "br")) {
					[self pushNewline];
					whitespaceNeeded = NO;
				} else if (!strcmp((char *)curNode->name, "h4")) {
					childrenAttr |= (BCTextNodeBold | BCTextNodeItalic);
					[self layoutNode:curNode->children attributes:childrenAttr linkTarget:link];
					[self pushNewline];
					whitespaceNeeded = NO;
					continue;
				} else if (!strcmp((char *)curNode->name, "p")) {
					char *class = (char *)xmlGetProp(curNode, (xmlChar *)"class");
					if (class) {
//						if (!strcmp(class, "editedby") && curNode->children && 
//							!strcmp((char *)curNode->children->name, "span")) {
//							[self pushNewline];
//							[self pushNewline];
//							[self pushImage:@"http://i.somethingawful.com/bullet_wrench.png" linkTarget:link];
//							whitespaceNeeded = NO;
//							childrenAttr |= (BCTextNodeItalic);
//							[self layoutNode:curNode->children attributes:childrenAttr linkTarget:link];
//							free(class);
//							continue;
//						}
						free(class);
					}
				} else if (!strcmp((char *)curNode->name, "div")) {
					char *class =(char *)xmlGetProp(curNode, (xmlChar *)"class");
					if (class) {
						if (!strcmp(class, "bbc-block")) {
							[self pushBlockBorder];
							self.indented = YES;
							[self pushNewline];
							[self layoutNode:curNode->children attributes:childrenAttr linkTarget:link];
							self.indented = NO;
							[self.lines removeLastObject];
							[self pushBlockBorder];
							[self pushNewline];
							whitespaceNeeded = NO;
							free(class);
							continue;
						} else {
							free(class);
						}
					} 
				} else if (!strcmp((char *)curNode->name, "img")) {
                    [self pushImage:curNode link:link];
//					char *url = (char *)xmlGetProp(curNode, (xmlChar *)"src");
//					NSString *src = [NSString stringWithUTF8String:url];
//					free(url);
//					[self pushImage:src linkTarget:link];
				}
			}

			[self layoutNode:curNode->children attributes:childrenAttr linkTarget:link];
		}
	}
}

- (void)drawInRect:(CGRect)rect {
	for (BCTextLine *line in self.lines) {
		if (line.y > rect.size.height) {
			return;
		}
		
		[line drawAtPoint:CGPointMake(rect.origin.x, rect.origin.y + line.y) textColor:self.textColor linkColor:self.linkColor];
        if (singleLine) {
            break;
        }
	}
}

- (BCTextLine *)currentLine {
	return [self.lines lastObject];
}

- (void)setCurrentLine:(BCTextLine *)aLine {
	aLine.y = self.currentLine.y + self.currentLine.height;
	[self.lines addObject:aLine];
}

- (void)setWidth:(CGFloat)aWidth {
	self.links = [NSMutableDictionary dictionary];
	width = aWidth;
	self.lines = [NSMutableArray array];
    self.linksInCurrentLine = [NSMutableArray array];
	self.currentLine = [[[BCTextLine alloc] initWithWidth:width] autorelease];
	[self layoutNode:node attributes:BCTextNodePlain linkTarget:nil];
	height = self.currentLine.y + self.currentLine.height;
    
    //调整最后一行
    [self layoutLinksInCurrentLine];
}

- (void)dealloc {
	if (doc) 
		xmlFreeDoc((xmlDoc *)doc);
	
	node = NULL;
	self.links = nil;
	self.textColor = nil;
	self.linkColor = nil;
	self.lines = nil;
	self.currentLine = nil;
    self.linksInCurrentLine = nil;
	[super dealloc];
}

- (CGFloat)fontSize {
	if (!fontSize) {
		fontSize = 12;
	}
	return fontSize;
}

- (UIFont *)regularFont {
	return [UIFont fontWithName:@"Helvetica" size:self.fontSize];
}

- (UIFont *)boldFont {
	return [UIFont fontWithName:@"Helvetica-Bold" size:self.fontSize];
}

- (UIFont *)italicFont {
	return [UIFont fontWithName:@"Helvetica-Oblique" size:self.fontSize];
}

- (UIFont *)boldItalicFont {
	return [UIFont fontWithName:@"Helvetica-BoldOblique" size:self.fontSize];
}

- (UIFont *)fontWithAttributes:(BCTextNodeAttributes)attr {
	if (attr & BCTextNodeItalic && attr & BCTextNodeBold) {
		return [self boldItalicFont];
	} else if (attr & BCTextNodeItalic) {
		return [self italicFont];
	} else if (attr & BCTextNodeBold) {
		return [self boldFont];
	} else {
		return [self regularFont];
	}
}

- (CGFloat)properWidth {
    if (self.lines.count != 1) {
        return self.width;
    }
    return self.currentLine.width - self.currentLine.widthRemaining;
}

- (UIImage *)imageForURL:(NSString *)url {
    if ([url hasPrefix:@"file://"]) {
        NSString* imageName = [[url pathComponents] lastObject];
        return [MMThemeMgr imageNamed:imageName];
    }
	return nil;
}

- (CGFloat)height {
    if (!singleLine) {
        return height;
    } else {
        if (lines.count == 0) {
            return 0;
        }
        return [[lines objectAtIndex:0] height];
    }
}

@end
