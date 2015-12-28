//
//  ViewXmlParser.h
//  Message
//
//  Created by houxh on 11-6-14.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface MMViewXmlParser : NSObject<NSXMLParserDelegate> {
	UIView *root_;
	NSMutableArray *viewStack_;
}
-(BOOL)parseXml:(const char*)xml container:(UIView*)container;
-(UIView*)parseXml:(const char*)xml;
-(void)pushView:(UIView*)view;
-(void)popView;
-(UIView*)topView;
@end
