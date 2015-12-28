//
//  MMAboutMeDragView.m
//  momo
//
//  Created by houxh on 11-9-25.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import "MMAboutMeDragView.h"
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

static const char* viewXml = 
"<root id=\"bg_view\" path=\"about_me_bg.png\" backgroundColor=\"@clear\" x=\"0\" y=\"25\" width=\"320\" height=\"300\"  >"
"<MMAbsoluteLayout id=\"drag_content\" backgroundColor=\"#f1f1f1\" x=\"5\" y=\"5\" width=\"310\" height=\"215\">"
"<MMAvatarImageView id=\"avatar\" layout_x=\"5\" layout_y=\"5\" layout_width=\"41\" layout_height=\"41\" cornerRadius=\"3.0\"/>"
"<UIButton id=\"go_message\" normalImage=\"about_me_ic_dynamic_detail.png\" layout_x=\"10\" layout_y=\"60\" layout_width=\"26\" layout_height=\"24\" />"
"<MMLinearLayout orientation=\"vertical\" layout_x=\"55\" layout_y=\"0\" layout_width=\"250\" layout_height=\"wrap_content\" layout_marginTop=\"5\" layout_marginRight=\"10\" >"
"<MMRelativeLayout layout_width=\"fill_parent\" layout_marginBottom=\"5\" >"
"<UILabel id=\"name\" layout_alignParentLeft=\"true\" backgroundColor=\"@clear\"/>"
"<MMLinearLayout orientation=\"horizontal\"  layout_alignParentRight=\"true\" layout_height=\"fill_parent\" >"
"<UIImageView id = \"source_name\" layout_marginRight= \"5\" layout_marginTop= \"2\"/>"
"<UILabel id = \"group\" textSize=\"12\" layout_maxWidth=\"100\" layout_marginRight= \"5\" />"
"<UILabel id=\"date\" layout_centerVertical=\"true\" textSize=\"12\" backgroundColor=\"@clear\" />"
"</MMLinearLayout>"
"</MMRelativeLayout>"
"<BCTextView id=\"content\" backgroundColor=\"@clear\" layout_width=\"fill_parent\" layout_marginRight=\"5\"  />"
"<BCTextView id=\"source_content\" backgroundColor=\"@clear\" layout_width=\"fill_parent\" textSize=\"14\" layout_marginTop=\"5\" />"
"</MMLinearLayout>"
"</MMAbsoluteLayout>"
"<UIImageView id=\"line\" path=\"individual_homepage_line.png\" backgroundColor=\"@clear\" x=\"5\" y=\"220\" width=\"310\" height=\"1\" />"
"<MMLinearLayout id=\"input_view\" orientation=\"horizontal\" backgroundColor=\"#cdcdcd\" x=\"10\" y=\"230\" width=\"300\" height=\"49\">"
"<MMRelativeLayout layout_width=\"fill_parent\" layout_height=\"fill_parent\" layout_marginLeft=\"0\" layout_marginRight=\"0\" >"
"<UIImageView id=\"bg_view_input\" path=\"about_me_at_bg.png\"  backgroundColor=\"@clear\" layout_width=\"fill_parent\" layout_height=\"fill_parent\"  />"
"<MMLinearLayout orientation=\"horizontal\" layout_width=\"fill_parent\" layout_height=\"fill_parent\" backgroundColor=\"@clear\" >"
"<UIButton id=\"@\"  normalImage=\"about_me_at.png\" pressedImage=\"about_me_at.png\" backgroundColor=\"@clear\" layout_marginLeft=\"5\" layout_marginTop=\"7\" layout_width=\"35\" layout_height=\"36\"/>"
"<MMHidePortionTextField id=\"input\" cornerRadius=\"3.0\" layout_width=\"215\" layout_height=\"fill_parent\" layout_marginTop=\"7\" layout_marginBottom=\"7\" layout_marginLeft=\"5\" layout_marginRight=\"8\" layout_centerVertical=\"true\" backgroundColor=\"#ffffff\"/>"
"<UIButton id=\"face\" normalImage=\"chat_ic_face.png\" backgroundColor=\"@clear\" layout_marginTop=\"10\"/>"
"</MMLinearLayout>"
"</MMRelativeLayout>"	
"</MMLinearLayout>"

"</root>";

void ReplyCornersBorder(UIView *view, CGRect rect){
	UIImage *image = [MMThemeMgr imageNamed:@"momo_dynamic_dialog_box.png"];
	[image drawInRect:view.bounds];
}

@implementation MMAboutMeDragView

- (MMHidePortionTextField*) inputTextField {
    return (MMHidePortionTextField*)[self viewWithId:@"input"];
}

- (UIButton *)faceButton {
	return (UIButton *)[self viewWithId:@"face"];
}

- (UIButton *)atButton {
	return (UIButton *)[self viewWithId:@"@"];
}

- (UIButton *)gotoMessage {
	return (UIButton *)[self viewWithId:@"go_message"];
}

- (void) setMessage:(MMAboutMeMessage*)message srcStatus:(MMMessageInfo*)messageInfo {
    UIView *view = [self viewWithId:@"drag_content"];
	
	MMAvatarImageView *avatarView = (MMAvatarImageView*)[view viewWithId:@"avatar"];
	avatarView.imageURL = [[MMMomoUserMgr shareInstance] avatarImageUrlByUserId:message.ownerId];
	
	UILabel *name = (UILabel*)[view viewWithId:@"name"];
	name.font = [UIFont fontWithName:@"Helvetica-Bold" size:16];	
	name.text = [[MMMomoUserMgr shareInstance] realNameByUserId:message.ownerId ];
	UILabel *date = (UILabel*)[view viewWithId:@"date"];
	date.textColor = RGBCOLOR(156,157,157);
	date.text = [MMCommonAPI getDateString:
				 [NSDate dateWithTimeIntervalSince1970:message.dateLine]];
    
	BCTextView *styledLabel = nil;
	NSString *comment = nil;
	switch (message.kind) {
		case MMAboutMeMessageKindComment:  //1表示评论
		{
			styledLabel = (BCTextView*)[view viewWithId:@"content"];
			comment = [NSString stringWithFormat:@"评论道:%@",message.comment ];
			styledLabel.textFrame = [MMFaceTextFrame textFromHTML:comment];
			
			styledLabel = (BCTextView*)[view viewWithId:@"source_content"];
			if (message.sourceComment != nil && [message.sourceComment length] != 0) {
				comment = [NSString stringWithFormat:@"我:%@", message.sourceComment];
			} else {
				comment = [NSString stringWithFormat:@"我:%@", messageInfo.text];
			}			
			styledLabel.textFrame = [MMFaceTextFrame textFromHTML:comment];			
			styledLabel.textFrame.singleLine = YES;
		}
			break;
		case MMAboutMeMessageKindLeaveMessage:   //2表示留言
		{
			styledLabel = (BCTextView*)[view viewWithId:@"content"];
			comment = [NSString stringWithFormat:@"%@",messageInfo.text];
			styledLabel.textFrame = [MMFaceTextFrame textFromHTML:comment];
			
			styledLabel = (BCTextView*)[view viewWithId:@"source_content"];
			comment = [NSString stringWithFormat:@"给我留言"];
			styledLabel.textFrame = [MMFaceTextFrame textFromHTML:comment];
			styledLabel.textFrame.singleLine = YES;
			
		}
			break;
		case MMAboutMeMessageKindAtComment:  //3表示评论中提到我
		{
            
			styledLabel = (BCTextView*)[view viewWithId:@"content"];
			comment = [NSString stringWithFormat:@"在评论中提到我:%@",message.comment];
			styledLabel.textFrame = [MMFaceTextFrame textFromHTML:comment];
			
			styledLabel = (BCTextView*)[view viewWithId:@"source_content"];
			if (message.sourceComment != nil && [message.sourceComment length] != 0) {
				comment = [NSString stringWithFormat:@"我:%@", message.sourceComment];
			} else {
				comment = [NSString stringWithFormat:@"%@", messageInfo.text];
			}
			styledLabel.textFrame = [MMFaceTextFrame textFromHTML:comment];
			styledLabel.textFrame.singleLine = YES;
			
		}
			break;
		case MMAboutMeMessageKindPraise:  //4表示赞
		{		
			styledLabel = (BCTextView*)[view viewWithId:@"content"];
			comment = [NSString stringWithFormat:@"认为这挺赞的"];
			styledLabel.textFrame = [MMFaceTextFrame textFromHTML:comment];
			
			styledLabel = (BCTextView*)[view viewWithId:@"source_content"];
			comment = [NSString stringWithFormat:@"我:%@",messageInfo.text];
			styledLabel.textFrame = [MMFaceTextFrame textFromHTML:comment];
			styledLabel.textFrame.singleLine = YES;
			styledLabel.hidden = NO;
		}
			break;
		case MMAboutMeMessageKindBroadcast:  //5广播中提到
		{		
			styledLabel = (BCTextView*)[view viewWithId:@"content"];
			comment = [NSString stringWithFormat:@"%@",messageInfo.text];
			styledLabel.textFrame = [MMFaceTextFrame textFromHTML:comment];
            
			styledLabel = (BCTextView*)[view viewWithId:@"source_content"];
			comment = [NSString stringWithFormat:@"提到我"];
			styledLabel.textFrame = [MMFaceTextFrame textFromHTML:comment];
			styledLabel.textFrame.singleLine = YES;
		}
			break;
		case MMAboutMeMessageKindReply:  //6表示回复
		{	
			styledLabel = (BCTextView*)[view viewWithId:@"content"];
			comment = [NSString stringWithFormat:@"回复:%@",message.comment];
			styledLabel.textFrame = [MMFaceTextFrame textFromHTML:comment];
            
			styledLabel = (BCTextView*)[view viewWithId:@"source_content"];
			if (message.sourceComment != nil && [message.sourceComment length] != 0) {
				comment = [NSString stringWithFormat:@"我:%@", message.sourceComment];
			} else {
				comment = [NSString stringWithFormat:@"我:%@", messageInfo.text];
			}
			styledLabel.textFrame = [MMFaceTextFrame textFromHTML:comment];
			styledLabel.textFrame.singleLine = YES;
            
		}
			break;
		default:
			break;
	}
    
	styledLabel = (BCTextView*)[view viewWithId:@"source_content"];
	styledLabel.textFrame.singleLine = YES;
    
	
	UILabel *group = (UILabel *)[view viewWithId:@"group"];
	group.textColor = [UIColor whiteColor];
	group.backgroundColor = RGBACOLOR(110, 162, 2, 255);
	group.layer.masksToBounds = YES;
	group.layer.cornerRadius = 3.0;
	
	if (messageInfo.groupName !=nil && [messageInfo.groupName length] > 0) {
		group.hidden = NO;
		group.text = [NSString stringWithFormat:@" %@ ",messageInfo.groupName];
	} else {
		group.hidden = YES;
	}
    
	
	UIImageView *sourceNameView = (UIImageView *)[view viewWithId:@"source_name"];
	if (messageInfo.sourceName != nil && [messageInfo.sourceName length] > 0) {
		sourceNameView.image = [MMThemeMgr imageNamed:@"momo_dynamic_ic_phone.png"];
	} else {
		sourceNameView.image = nil;
	}
	    
    MMHidePortionTextField* hidePortionTextField = (MMHidePortionTextField*)[self viewWithId:@"input"];
    MMHidePortionText* hidePortionText = [MMHidePortionText hidePortionTextWithUserName:message.ownerName
                                                                                    uid:message.ownerId];
    [hidePortionTextField clearTextAndHidePortion];
    [hidePortionTextField appendHidePortionText:hidePortionText];
    
	[view setNeedsLayoutRecursive];
}

-(id)init {
    self = [super init];
    if (self) {
		
        MMViewXmlParser *parser = [[[MMViewXmlParser alloc] init] autorelease];
        [parser parseXml:viewXml container:self];
        
        UIView *textView = [self viewWithId:@"text_content"];
        textView.clipsToBounds = YES;	
        
        BCTextView * srcLabel = (BCTextView*)[self viewWithId:@"source_content"];
        srcLabel.contentInset = UIEdgeInsetsMake(10, 5, 5, 5);
        [srcLabel setBackgroundImp:ReplyCornersBorder];
        
        UIView *view = [self viewWithId:@"drag_content"];
        view.clipsToBounds = YES;
        
        MMHidePortionTextField *hidePortionTextField = (MMHidePortionTextField*)[self viewWithId:@"input"];
        hidePortionTextField.textField.font = [UIFont systemFontOfSize:16.0f];
        hidePortionTextField.textField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        hidePortionTextField.textField.leftView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)] autorelease];
        hidePortionTextField.textField.leftViewMode = UITextFieldViewModeAlways;
        hidePortionTextField.textField.returnKeyType = UIReturnKeySend;
		
    }
    return self;
}

@end

