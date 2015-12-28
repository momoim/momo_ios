//
//  MMAboutMeRootCell.m
//  momo
//
//  Created by houxh on 11-9-25.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import "MMAboutMeRootCell.h"
#import <QuartzCore/QuartzCore.h>
#import "MMAboutMeChatViewController.h"
#import "MMThemeMgr.h"
#import "MMViewXmlParser.h"
#import "MMLayoutParams.h"
#import "MMCommonAPI.h"
#import "MMGlobalData.h"
#import "MMGlobalPara.h"
#import "MMGlobalStyle.h"
#import "MMDraftMgr.h"
#import "MMBrowseMessageViewController.h"
#import "MMSelectFriendViewController.h"
#import "MMLoginService.h"
#import "MMUIMessage.h"
#import "MMMessageSyncer.h"
#import "MMUapRequest.h"
#import "MMAboutMeManager.h"
#import "MMWebViewController.h"
#import "MMMomoUserMgr.h"
#import "MMUIDefines.h"
#import "MMFaceTextFrame.h"

@implementation MMAboutMeRecord

@synthesize messageText, aboutMeText, messageInfo, message;

-(int64_t)lastCommentDate {
	return message.dateLine;
}
-(NSString*)statusId {
	return message.statusId;
}

- (void)dealloc {
    [messageText release];
    [aboutMeText release];
	[message release];
	[messageInfo release];
    [super dealloc];
}

- (void)setMessage:(MMAboutMeMessage *)msg {
	[message release];
	message = [msg retain];
	
	self.aboutMeText = nil;
}

@end


static const char* foldViewXml = 
"<root layout=\"MMAbsoluteLayoutManager\" >"
"<UIView layout=\"MMAbsoluteLayoutManager\" layout_width=\"320\" layout_height=\"fill_parent\">"
"<MMAvatarImageButton id=\"avatar\" layout_x=\"10\" layout_y=\"8\" layout_width=\"41\" layout_height=\"41\" cornerRadius=\"3.0\"/>"

"<MMLinearLayout orientation=\"vertical\" layout_x=\"60\" layout_y=\"8\" layout_width=\"fill_parent\" layout_height=\"fill_parent\" layout_marginRight=\"10\" >"



"<BCTextView id=\"comment_content\" layout_width=\"fill_parent\" layout_height=\"wrap_content\" layout_marginTop=\"3\" />"

"<MMLinearLayout orientation=\"horizontal\" layout_width=\"fill_parent\" layout_marginTop=\"5\">"
"<UILabel id=\"date\" layout_centerVertical=\"true\" textSize=\"12\" />"
"<UILabel id=\"groupTip\" layout_centerVertical=\"true\" backgroundColor=\"@clear\" textSize=\"12\" layout_marginLeft=\"20\" />"
"<UIButton id=\"group\" layout_maxWidth=\"120\" textSize=\"13\" layout_centerVertical=\"true\" layout_marginRight=\"5\" layout_marginLeft=\"5\" />"
"</MMLinearLayout>"

"<BCTextView id=\"statuses_content\" layout_marginTop=\"5\" layout_width=\"fill_parent\" layout_marginBottom=\"8\"  />"

"</MMLinearLayout>"
"</UIView>"
"</root>";


@implementation MMAboutMeRootCell
@synthesize delegate = delegate_;
@synthesize aboutMeRecord = aboutMeRecord_;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        MMAboutMeRootCell *cell = self;
        cell.selectedBackgroundView = [[[UIView alloc] initWithFrame:cell.frame] autorelease];
		cell.selectedBackgroundView.backgroundColor = RGBCOLOR(178, 230, 244);		
		
        MMViewXmlParser *parser = [[[MMViewXmlParser alloc] init] autorelease];
        [parser parseXml:foldViewXml container:cell.contentView];
        
        MMAvatarImageButton *avatar = (MMAvatarImageButton*)[cell.contentView viewWithId:@"avatar"];
        [avatar addTarget:self action:@selector(actionClickAvatar:) forControlEvents:UIControlEventTouchUpInside];
        
        BCTextView *styledLabel = (BCTextView*)[cell.contentView viewWithId:@"statuses_content"];
        [styledLabel setBackgroundImp:(BACKGROUD_IMP)ReplyCornersBorder];
		styledLabel.contentInset = UIEdgeInsetsMake(10, 5, 5, 5);
        
        UILabel *date = (UILabel*)[cell viewWithId:@"date"];
        date.backgroundColor = [UIColor clearColor];
        
        UIButton* groupButton = (UIButton*)[cell viewWithId:@"group"];
        [groupButton addTarget:self action:@selector(actionShowGroup) forControlEvents:UIControlEventTouchUpInside];

        cell.clipsToBounds = YES;
        
        UISwipeGestureRecognizer* swipeLeftGesture = [[[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeLeft:)] autorelease];
        swipeLeftGesture.direction = UISwipeGestureRecognizerDirectionLeft;
        [self addGestureRecognizer:swipeLeftGesture];
        
        UILongPressGestureRecognizer* longPressGesture = [[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)] autorelease];
        [self addGestureRecognizer:longPressGesture];
        
    }
    return self;
}

- (void)dealloc {
    self.aboutMeRecord = nil;
    [super dealloc];
}

-(void)setRecord:(MMAboutMeRecord*)record {
    self.aboutMeRecord = record;
    
    MMAboutMeRootCell *cell = self;
    assert(record.messageInfo);
    
    if (record.message.isRead) {
        self.contentView.backgroundColor = [UIColor whiteColor];
    } else {
        self.contentView.backgroundColor = [UIColor colorWithRed:1.0 green:239.0/255.0 blue:215.0/255.0 alpha:1.0];
    }
    
    UIImageView *sourceNameView = (UIImageView *)[cell viewWithId:@"source_name"];
    
    if (record.messageInfo.sourceName != nil && [record.messageInfo.sourceName length] > 0) {
        sourceNameView.image = [MMThemeMgr imageNamed:@"momo_dynamic_ic_phone.png"];
    } else {
        sourceNameView.image = nil;
    }
    
    
    MMAvatarImageButton *avatar = (MMAvatarImageButton*)[cell viewWithId:@"avatar"];
    avatar.imageURL = [[MMMomoUserMgr shareInstance] avatarImageUrlByUserId:record.message.ownerId];
    
    UILabel *name = (UILabel*)[cell viewWithId:@"name"];
	name.font = [UIFont fontWithName:@"Helvetica-Bold" size:16];	
    name.text = [[MMMomoUserMgr shareInstance] realNameByUserId:record.message.ownerId];
    
    UILabel *date = (UILabel*)[cell viewWithId:@"date"];
	date.textColor = RGBCOLOR(156,157,157);
    date.text = [MMCommonAPI getDateString:
                 [NSDate dateWithTimeIntervalSince1970:record.message.dateLine]];
    
    UILabel* groupTipLabel = (UILabel*)[cell viewWithId:@"groupTip"];
    groupTipLabel.text = @"来自";
    
    UIButton *group = (UIButton *)[cell viewWithId:@"group"];
    [group setTitleColor:RGBCOLOR(51, 204, 255) forState:UIControlStateNormal];
    group.titleLabel.font = [UIFont systemFontOfSize:13];
    
    if (record.messageInfo.groupName !=nil && [record.messageInfo.groupName length] > 0) {
        groupTipLabel.hidden = NO;
        group.hidden = NO; 
        [group setTitle:record.messageInfo.groupName forState:UIControlStateNormal];
    } else {
        groupTipLabel.hidden = YES;
        group.hidden = YES;
    }
    
    BCTextView *styledLabel = nil;
    NSString *comment = [NSString stringWithFormat:@"<A href=\"momo://user=%d\">@%@</A>", record.message.ownerId,
                         [[MMMomoUserMgr shareInstance] realNameByUserId:record.message.ownerId]];
	
    styledLabel = (BCTextView*)[cell viewWithId:@"comment_content"];
    NSString* tmpComment = [MMCommonAPI addHTMLLinkTag:record.message.comment];
    comment = [NSString stringWithFormat:@"%@ %@", comment, tmpComment];

    if (nil == record.aboutMeText) {
        record.aboutMeText = [MMFaceTextFrame textFromHTML:comment];
    }
    styledLabel.textFrame = record.aboutMeText;
	styledLabel.textFrame.fontSize = 14.0f;
	
    //原动态
    styledLabel = (BCTextView*)[cell viewWithId:@"statuses_content"];
    if (nil == record.messageText) {
        record.messageText = [MMFaceTextFrame textFromHTML:record.messageInfo.text];
    }
    styledLabel.textFrame.fontSize = 13.0f;
    styledLabel.textFrame = record.messageText;
    
	[cell.contentView setNeedsLayoutRecursive];
}

- (void)actionClickAvatar:(id)sender {
    if (delegate_ && [delegate_ respondsToSelector:@selector(didClickAtAvatar:)]) {
        [delegate_ didClickAtAvatar:self];
    }
}

- (void)actionShowGroup {

}

#pragma mark Handle Gesture
- (void)swipeLeft:(id)sender {
    if (delegate_ && [delegate_ respondsToSelector:@selector(didSwipeToLeft:)]) {
        [delegate_ didSwipeToLeft:self];
    }
}

- (void)actionViewMessage {
    if (delegate_ && [delegate_ respondsToSelector:@selector(didSwipeToLeft:)]) {
        [delegate_ didSwipeToLeft:self];
    }
}

- (void)longPress:(id)sender {
    [self becomeFirstResponder];
    
    UIMenuController* menu = [UIMenuController sharedMenuController];
    UIMenuItem* item = [[[UIMenuItem alloc] initWithTitle:@"查看原动态" action:@selector(actionViewMessage)] autorelease];
    [menu setMenuItems:[NSArray arrayWithObject:item]];
    [menu setTargetRect:self.frame inView:self.superview];
    [menu setMenuVisible:YES animated:YES];
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    return (action == @selector(actionViewMessage));
}

@end
