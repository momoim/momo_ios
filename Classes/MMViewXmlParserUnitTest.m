//
//  ViewXmlParserUnitTest.m
//  momo
//
//  Created by houxh on 11-6-14.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//
#import "GHTestCase.h"
#import "MMViewXmlParser.h"

@interface ViewXmlParserUnitTest : GHTestCase {
	
}

@end

@implementation ViewXmlParserUnitTest

-(void)testParser {
	const char* xml = "<UIView layout=\"MMLinearLayoutManager\">"
	"<UIView layout_width=\"fill_parent\"/>"
	"<UIView layout_width=\"1\"/>"
	"<MMLinearLayout orientation=\"vertical\" />"
						  "</UIView>";
	MMViewXmlParser *parser = [[[MMViewXmlParser alloc] init] autorelease];
	[parser parseXml:xml];
}
@end
