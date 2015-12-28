//
//  ViewXmlParser.m
//  Message
//
//  Created by houxh on 11-6-14.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MMViewXmlParser.h"
#import "MMLayoutParams.h"

@implementation MMViewXmlParser

-(id)init {
	self = [super init];
	if (self != nil) {
		root_ = nil;
		viewStack_ = [[NSMutableArray alloc] init];
	}
	return self;
}

-(void)dealloc {
	[viewStack_ release];
	[super dealloc];
}
-(void)pushView:(UIView*)view {
	[viewStack_ addObject:view];
}
-(void)popView {
	[viewStack_ removeLastObject];
}
-(UIView*)topView {
	return [viewStack_ lastObject];
}


-(BOOL)parseXml:(const char*)xml container:(UIView*)container {
	root_ = container;
	UIView *view = [self parseXml:xml];
	return (view != nil);
}

-(UIView*)parseXml:(const char*)xml {
	NSData *data = [NSData dataWithBytesNoCopy:(void*)xml length:strlen(xml) freeWhenDone:NO];
	NSXMLParser *xmlParser = [[[NSXMLParser alloc] initWithData:data] autorelease] ;
	
	[xmlParser setDelegate:self];
	[xmlParser setShouldProcessNamespaces:NO];
	[xmlParser setShouldReportNamespacePrefixes:NO];
	[xmlParser setShouldResolveExternalEntities:NO];
	[xmlParser parse];
	assert([viewStack_ count] == 0);
	return root_;
}

-(void)parserDidStartDocument:(NSXMLParser *)parser {
}
-(void)parserDidEndDocument:(NSXMLParser *)parser {
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
	NSLog(@"xml parser error");
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName 
  namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {

	UIView *parentView = [self topView];
	UIView *view = nil;
	if ([elementName isEqualToString:@"root"]) {
		view = root_;
	} else {
		Class class = NSClassFromString(elementName);
		assert(class);

		id obj = [[[class alloc] init] autorelease];
		assert([obj isKindOfClass:[UIView class]]);
		view = obj;
	}
	[view parseViewParams:attributeDict];
	Class layoutMgrClass = NSClassFromString([attributeDict objectForKey:@"layout"]);
	if (layoutMgrClass) {
		id obj = [[[layoutMgrClass alloc] init] autorelease];
		assert([obj conformsToProtocol:@protocol(MMLayoutManager)]);
		setViewLayoutManager(view, obj);
	}
	if (parentView) {
		id<MMLayoutManager> layoutManager = getViewLayoutManager(parentView);
		MMLayoutParams *layoutParams = [[layoutManager class] parseLayoutParams:attributeDict];
		setViewLayoutParams(view, layoutParams);
		[parentView addSubview:view];
	}
	[self pushView:view];
	if (nil == root_) root_ = view;
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName 
  namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
	[self popView];
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
}

@end
