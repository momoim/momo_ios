    //
//  MMAboutMeChatViewController.m
//  momo
//
//  Created by houxh on 11-5-4.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MMAboutMeChatViewController.h"
#import "MMLinearLayout.h"
#import "MMViewXmlParser.h"
#import "MMLayoutParams.h"
#import "MMThemeMgr.h"
#import "MMDraftMgr.h"
#import "MMCommonAPI.h"
#import "MMGlobalData.h"
#import "MMSelectFriendViewController.h"
#import "MMBrowseMessageViewController.h"
#import "RegexKitLite.h"
#import <QuartzCore/QuartzCore.h>
#import "MMUIMessage.h"
#import "MMMessageSyncer.h"
#import "MMUapRequest.h"
#import "MMAboutMeManager.h"
#import "MMMomoUserMgr.h"
#import "MMWebViewController.h"
#import "MMGlobalStyle.h"
#import "MMFaceTextFrame.h"
#import "MMLoginService.h"

@implementation MMAboutMeMessageWithStyleText
@synthesize styledComment=styledComment_;
@synthesize styledSrcComment=styledSrcComment_;

- (void)dealloc {
	self.styledComment = nil;
	self.styledSrcComment = nil;
	[super dealloc];
}
@end


@implementation MMAboutMeChatViewController
@synthesize isViewUnload = isViewUnload_;
@synthesize statusId = statusId_;

-(id)initWithStatusId:(NSString*)statusId {
	self = [super init];
	if (self) {
        statusId_ = [statusId copy];
        isViewUnload_ = NO;
		messageInfo_ = [[[MMUIMessage instance] getMessage:statusId ownerId:[[MMLoginService shareInstance] getLoginUserId]] retain];
		assert(messageInfo_ != nil);
		messages_ = [[NSMutableArray alloc] init];
		NSMutableArray *array = [NSMutableArray array];

		void(^mergePraise)(void) = ^(void) {
			if ([array count] > 0) {
				MMAboutMeMessageWithStyleText *lastMessage = [messages_ lastObject];
				NSAssert(lastMessage && MMAboutMeMessageKindPraise == lastMessage.kind && lastMessage.isRead, @"data error");
				NSMutableString *comment = [NSMutableString stringWithString:lastMessage.ownerName];
				MMAboutMeMessage *msg = [array objectAtIndex:0];
				[comment appendFormat:@",%@", msg.ownerName];
				if([array count] > 1) 
					[comment appendString:@"等"];
				//[comment appendString:@"觉得这挺赞的"];
				lastMessage.styledComment = [MMFaceTextFrame textFromHTML:comment];
				[array removeAllObjects];
			}
		};
		
		NSArray *aboutMeList = [[MMAboutMeManager shareInstance] getAboutMeListWithStatusId:statusId];
		for (MMAboutMeMessage *msg in aboutMeList) {
			MMAboutMeMessageWithStyleText *lastMessage = [messages_ lastObject];
			if (MMAboutMeMessageKindPraise == msg.kind && msg.isRead && 
				MMAboutMeMessageKindPraise == lastMessage.kind && lastMessage.isRead) {
				[array addObject:msg];
			} else {
				mergePraise();
				MMAboutMeMessageWithStyleText *message = [[[MMAboutMeMessageWithStyleText alloc] initWithMessage:msg]  autorelease];
				BCTextFrame *text = [MMFaceTextFrame textFromHTML:message.comment];
				message.styledComment = text;
				text = [MMFaceTextFrame textFromHTML:message.sourceComment];
				message.styledSrcComment = text;
				[messages_ addObject:message];
			}
		}
		mergePraise();
	}
	return self;
}

- (void)dealloc {
    [statusId_ release];
	[messages_ release];
	[messageInfo_ release];
	[tableView_ release];
	
	[linearLayout_ release];
	[faceBgView release];
	
    [super dealloc];
}

- (void)viewDidUnload {
	
	[tableView_ release];
	tableView_ = nil;
	
	[linearLayout_ release];
	linearLayout_ = nil;
	
	[faceBgView release];
	faceBgView = nil;
}

// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
	[super loadView];	
	
	UIButton *itemButton = nil;
	UIImage *image = nil;
	
	image = [MMThemeMgr imageNamed:@"topbar_back.png"];
	itemButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 34, 30)];
	[itemButton setImage:image forState:UIControlStateNormal];	
	[itemButton setImage:image forState:UIControlStateHighlighted];
	[itemButton setBackgroundImage:[MMThemeMgr imageNamed:@"common_topbar_ic_press.png"] forState:UIControlStateHighlighted];
	[itemButton addTarget:self action:@selector(actionLeft:) forControlEvents:UIControlEventTouchUpInside];	
	self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:itemButton] autorelease];
	[itemButton release];
	
	image = [MMThemeMgr imageNamed:@"chat_topbar_ic_next.png"]; 
	itemButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 34, 30)];
	[itemButton setImage:image forState:UIControlStateNormal];
	[itemButton setImage:image forState:UIControlStateHighlighted];
	[itemButton setBackgroundImage:[MMThemeMgr imageNamed:@"common_topbar_ic_press.png"] forState:UIControlStateHighlighted];
	[itemButton addTarget:self action:@selector(actionRight:) forControlEvents:UIControlEventTouchUpInside];
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:itemButton] autorelease];
	[itemButton release];

	
	UIButton *titleButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 250, 44)];	
	if (nil == messageInfo_) {
		[titleButton setTitle:@"读取中..." forState:UIControlStateNormal];
	} else {
		[titleButton setTitle:[messageInfo_.text stringByReplacingOccurrencesOfRegex:@"<[^>]*>" withString:@""] forState:UIControlStateNormal];
	}
	titleButton.titleLabel.lineBreakMode   = UILineBreakModeTailTruncation;
	titleButton.backgroundColor = [UIColor clearColor];
	titleButton.userInteractionEnabled = YES;
	[titleButton addTarget:self action:@selector(actionTitleBtn) forControlEvents:UIControlEventTouchUpInside];
	self.navigationItem.titleView = titleButton;
	[titleButton release];
	
	UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapFrom:)];
	[[self view] addGestureRecognizer:tapGestureRecognizer];
	tapGestureRecognizer.cancelsTouchesInView = NO;
	[tapGestureRecognizer release];
	
	CGFloat height = [[UIScreen mainScreen] applicationFrame].size.height-45;
	tableView_ = [[UITableView alloc] initWithFrame:CGRectMake(0.0, 0.0, 320.0, height) style:UITableViewStylePlain];
	tableView_.dataSource = self;
	tableView_.delegate = self;
	tableView_.backgroundColor = TABLE_BACKGROUNDCOLOR;
	tableView_.separatorStyle = UITableViewCellSeparatorStyleNone;
	tableView_.autoresizingMask = UIViewAutoresizingFlexibleHeight;
	tableView_.tableFooterView = [[[UIView alloc] init] autorelease];
	[[self view] addSubview:tableView_];
	
	
	static const char *viewXml = "<MMLinearLayout orientation=\"horizontal\" backgroundColor=\"#555555\" x=\"0\" y=\"371\" width=\"320\" height=\"45\">"
	//背景图
	"<MMRelativeLayout layout_width=\"fill_parent\" layout_height=\"fill_parent\" layout_marginLeft=\"0\" layout_marginRight=\"0\" >"
	"<UIImageView id=\"bg_view\" path=\"chat_basebar_bg.png\" backgroundColor=\"@clear\" layout_width=\"fill_parent\" layout_height=\"fill_parent\"  />"
	
	"<MMLinearLayout orientation=\"horizontal\" layout_width=\"fill_parent\" layout_height=\"fill_parent\" backgroundColor=\"@clear\" >"
	"<UIButton id=\"@\" backgroundColor=\"@clear\" layout_marginLeft=\"5\" layout_marginTop=\"10\" layout_width=\"26\" layout_height=\"26\"/>"
	
	"<MMHidePortionTextField id=\"input\" cornerRadius=\"3.0\" layout_width=\"240\" layout_height=\"32\" layout_marginTop=\"6\" layout_marginBottom=\"10\" layout_marginLeft=\"5\" layout_marginRight=\"8\" layout_centerVertical=\"true\" backgroundColor=\"#ffffff\"/>"
	
	"<UIButton id=\"face\" layout_width=\"fill_parent\" backgroundColor=\"@clear\" layout_marginTop=\"8\" layout_marginRight=\"5\"/>"
	
	"</MMLinearLayout>"
	
	"</MMRelativeLayout>"	
	"</MMLinearLayout>";
	
	
	
	MMViewXmlParser *parser = [[[MMViewXmlParser alloc] init] autorelease];
	UIView *bottomView = [parser parseXml:viewXml];

	UIButton *button = (UIButton*)[bottomView viewWithId:@"@"];
	[button setImage:[MMThemeMgr imageNamed:@"publish_dynamic_bottombar_at.png"] forState:UIControlStateNormal];
	[button setImage:[MMThemeMgr imageNamed:@"publish_dynamic_bottombar_at_press.png"] forState:UIControlStateHighlighted];
	[button addTarget:self action:@selector(actionForAt:) forControlEvents:UIControlEventTouchUpInside];	
	
	MMHidePortionTextField *hidePortionTextField = (MMHidePortionTextField*)[bottomView viewWithId:@"input"];
	hidePortionTextField.hidePortionTextFieldDelegate = self;
	hidePortionTextField.textField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
	hidePortionTextField.textField.leftView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)] autorelease];
	hidePortionTextField.textField.leftViewMode = UITextFieldViewModeAlways;
	hidePortionTextField.textField.returnKeyType = UIReturnKeySend;
	
	UIButton *faceBtn = (UIButton *)[bottomView viewWithId:@"face"];
	[faceBtn setImage:[MMThemeMgr imageNamed:@"chat_ic_face.png"] forState:UIControlStateNormal];
	
	[faceBtn addTarget:self action:@selector(actionForSelectFace) forControlEvents:UIControlEventTouchUpInside];
	
	[[self view] addSubview:bottomView];
	linearLayout_ = [bottomView retain];
	
	faceBgView = [[UIView alloc] initWithFrame:CGRectMake(0, 416, 320, 216)];
    faceBgView.backgroundColor = RGBCOLOR(175, 221, 234);
    [self.view addSubview:faceBgView];
    
    MMFaceView* faceView = [[[MMFaceView alloc] init] autorelease];
    [faceView initPara];
	faceView.frame = CGRectMake(0, 0, 320, 216);
	faceView.delegate_ = self;
	[faceBgView addSubview:faceView];
	
}

- (void)viewWillAppear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
}

#pragma mark -
#pragma mark UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	//[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	MMAboutMeMessage *msg = [messages_ objectAtIndex:indexPath.row];

	if (MMAboutMeMessageKindPraise == msg.kind) {
		return;
	}
	
	replyTarget_ = [messages_ objectAtIndex:indexPath.row];
    
    MMHidePortionText* hidePortionText = [MMHidePortionText hidePortionTextWithUserName:msg.ownerName
                                                                                    uid:msg.ownerId];
	MMHidePortionTextField* hidePortionTextField = (MMHidePortionTextField*)[linearLayout_ viewWithId:@"input"];
    [hidePortionTextField clearTextAndHidePortion];
    [hidePortionTextField appendHidePortionText:hidePortionText];
	
	if (![hidePortionTextField.textField isFirstResponder]) {
		MMAboutMeMessage *msg = [messages_ objectAtIndex:indexPath.row];
		if (MMAboutMeMessageKindPraise == msg.kind) {
			return;
		}
		[hidePortionTextField.textField becomeFirstResponder];
	} else {
		//
	}
	
	[tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [self tableView:tableView cellForRowAtIndexPath:indexPath];
	CGRect bounds = cell.bounds;
	CGSize ss = CGSizeMake(bounds.size.width, 0);
	CGSize size = [cell.contentView sizeThatFits:ss];
	return size.height;
}

#pragma mark -
#pragma mark UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	
	
	if ([MMCommonAPI getNetworkStatus] == kNotReachable) {
		[MMCommonAPI alert:@"网络连接失败!"];
		[textField resignFirstResponder];
		return YES;
	}

	MMHidePortionTextField* hidePortionTextField = (MMHidePortionTextField*)[linearLayout_ viewWithId:@"input"] ;
	if (replyTarget_) {

		MMDraftInfo* draftInfo = [[[MMDraftInfo alloc] init] autorelease];
		draftInfo.ownerId = [[MMLoginService shareInstance] getLoginUserId];
		draftInfo.text = [hidePortionTextField textWithHiddenPortion];
		draftInfo.draftType = draftComment;
		draftInfo.replyStatusId = replyTarget_.statusId;
		draftInfo.replyCommentId = replyTarget_.commentId; 
		
		[[MMDraftMgr shareInstance] insertAndUploadNewDraft:draftInfo];
		//当无未选中某条评论时的回复 当作回复该动态
	} else if ([messages_ count] > 0) {
		MMDraftInfo* draftInfo = [[[MMDraftInfo alloc] init] autorelease];
		draftInfo.ownerId = [[MMLoginService shareInstance] getLoginUserId];
		draftInfo.text = [hidePortionTextField textWithHiddenPortion];
		draftInfo.draftType = draftComment;
		draftInfo.replyStatusId = statusId_;
		
		[[MMDraftMgr shareInstance] insertAndUploadNewDraft:draftInfo];
	}

	textField.text = @"";
	[textField resignFirstResponder];
	
	replyTarget_ = nil;

	[self pushDownTextField];
	
	return YES;
}

-(void)handleTapFrom:(UITapGestureRecognizer*)recognizer {
	//[[linearLayout_ viewWithId:@"input"] resignFirstResponder];
}

#pragma mark -
#pragma mark MMSelectFriendViewDelegate
- (void)didSelectFriend:(NSArray*)selectedFriends {
	MMHidePortionTextField* hidePortionTextField = (MMHidePortionTextField*)[linearLayout_ viewWithId:@"input"] ;
    
    for (MMMomoUserInfo* friendInfo in selectedFriends) {
        MMHidePortionText* hidePortionText = [MMHidePortionText hidePortionTextWithUserName:friendInfo.realName
                                                                                        uid:friendInfo.uid];
        [hidePortionTextField appendHidePortionText:hidePortionText];
	}
}

#pragma mark -
#pragma mark action events and other
-(void)actionForAt:(id)sender {
	MMSelectFriendViewController* selectViewController = [[[MMSelectFriendViewController alloc] init] autorelease];
	selectViewController.hidesBottomBarWhenPushed = YES;
	selectViewController.delegate = self;
	[self.navigationController pushViewController:selectViewController animated:YES];
}

-(void)actionLeft:(id)sender {
    self.isViewUnload = YES;
	[self.navigationController popViewControllerAnimated: YES];	
}

- (void)actionRight:(id)sender {
	[self actionToMessage:sender];
}
-(void)actionToMessage:(id)sender {
	if (nil == messageInfo_) {
		return;
	}
	MMBrowseMessageViewController* browserViewController = [[[MMBrowseMessageViewController alloc] 
															initWithStatusId:messageInfo_.statusId] autorelease];
	browserViewController.hidesBottomBarWhenPushed = YES;
	[self.navigationController pushViewController:browserViewController animated:YES];
}

- (void)pushDownTextField {
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:0.3];
	linearLayout_.frame = CGRectMake(0, 366+5, 320, 45);
    faceBgView.frame = CGRectMake(0, 416, 320, 216);
	tableView_.frame = CGRectMake(0, 0, 320, self.view.bounds.size.height - 45.0f);
	[UIView commitAnimations];
}

- (void)pushUpTextField {
    [UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:0.3];
	
	linearLayout_.frame = CGRectMake(0, 150+5, 320, 45);
    faceBgView.frame = CGRectMake(0, 200, 320, 216);	
	tableView_.frame = CGRectMake(0, 0, 320, self.view.bounds.size.height - 216.0 - 45.0f);
	[UIView commitAnimations];
}

- (void)actionDismissInput {
	MMHidePortionTextField* sendMsgTextField = (MMHidePortionTextField*)[linearLayout_ viewWithId:@"input"];
    [sendMsgTextField resignFirstResponder];
	[self pushDownTextField];
}

- (void)actionForSelectFace {
	MMHidePortionTextField* sendMsgTextField = (MMHidePortionTextField*)[linearLayout_ viewWithId:@"input"];
	
    if ([sendMsgTextField isFirstResponder]) {
        [sendMsgTextField resignFirstResponder];
        if ((int)faceBgView.frame.origin.y < 416) {
            [self pushUpTextField];
        }
        [self pushUpTextField];
    } else {
        if ((int)faceBgView.frame.origin.y == 416) {
            [self pushUpTextField];
        } else {
            [sendMsgTextField becomeFirstResponder];
        }
    }
}

- (void)actionTitleBtn {
	
	[self actionDismissInput];
}

#pragma mark -
#pragma mark UITableViewDataSource 
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [messages_ count];
}

extern void ReplyCornersBorder(UIView *view, CGRect rect);

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	MMAboutMeMessageWithStyleText *message = [messages_ objectAtIndex:indexPath.row];
	UITableViewCell *cell = nil;
	
	//赞
	if (MMAboutMeMessageKindPraise == message.kind) {
		static const char* unfoldViewXml =
		"<root layout=\"MMRelativeLayoutManager\" backgroundColor=\"@clear\">"
		
		"<UILabel id=\"praise\" backgroundColor=\"@clear\" textSize=\"12\" layout_centerInParent=\"true\"/>"
		//背景图
		"<UIImageView id=\"bg_view\" layout_width=\"fill_parent\" layout_height=\"fill_parent\"  />"
		"</root>";
		
		cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"praise_cell"];
		if (cell == nil) {
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"praise_cell"] autorelease];
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
						
			MMViewXmlParser *parser = [[[MMViewXmlParser alloc] init] autorelease];
			[parser parseXml:unfoldViewXml container:cell.contentView];
		}
		

		UILabel *label = (UILabel*)[cell.contentView viewWithId:@"praise"];
		
        label.text = [NSString stringWithFormat:@"  %@觉得这挺赞的  ", message.ownerName];	
		
		//need modify the color
		if (!message.isRead) {
			label.backgroundColor = [UIColor colorWithRed:(CGFloat)0xf5/0xFF green:(CGFloat)0xd1/0xFF blue:(CGFloat)0x99/0xFF alpha:1.0];
		} else {
			label.backgroundColor = [UIColor clearColor];
		}
	} else {
		static const char* unfoldViewXml =
		"<root layout=\"MMAbsoluteLayoutManager\" backgroundColor=\"@clear\" >"

		"<UIView id=\"blankView\" backgroundColor=\"@clear\" layout_x=\"0\" layout_y=\"0\" layout_width=\"41\" layout_height=\"10\" />"
		
		
		//背景图
		"<MMRelativeLayout layout_x=\"0\" layout_y=\"10\" layout_width=\"fill_parent\" layout_height=\"fill_parent\" layout_marginLeft=\"2\" layout_marginRight=\"2\" >"
		"<UIImageView id=\"bg_view\" backgroundColor=\"@clear\" layout_width=\"fill_parent\" layout_height=\"fill_parent\" />"
		"</MMRelativeLayout>"
		
		"<MMAbsoluteLayout layout_width=\"fill_parent\" layout_height=\"fill_parent\" >"
		
		"<MMAvatarImageView id=\"avatar\" layout_x=\"10\" layout_y=\"15\" layout_width=\"41\" layout_height=\"41\" cornerRadius=\"3.0\" />"
		
		"<MMLinearLayout orientation=\"vertical\" layout_x=\"60\" layout_y=\"15\" layout_width=\"fill_parent\" layout_marginRight=\"10\" >"
		"<MMRelativeLayout layout_width=\"fill_parent\" layout_marginBottom=\"5\" >"
		"<UILabel id=\"name\" backgroundColor=\"@clear\" layout_alignParentLeft=\"true\"/>"
		"<UILabel id=\"date\" backgroundColor=\"@clear\" layout_alignParentRight=\"true\" layout_centerVertical=\"true\" textSize=\"12\" textColor=\"#317fb7\"/>"
		"</MMRelativeLayout>"
		"<BCTextView id=\"content\" backgroundColor=\"@clear\" layout_width=\"fill_parent\"/>"
		
		"<BCTextView id=\"source_content\" backgroundColor=\"@clear\" layout_width=\"fill_parent\" layout_marginTop=\"5\" />"
		
		"<UIView id=\"blankView\" backgroundColor=\"@clear\" layout_marginBottom=\"10\" />"
		"</MMLinearLayout>"
		"</MMAbsoluteLayout>"
		
		"</root>";
		cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"cell"];
		if (cell == nil) 
		{
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"] autorelease];
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
					
			MMViewXmlParser *parser = [[[MMViewXmlParser alloc] init] autorelease];
			[parser parseXml:unfoldViewXml container:cell.contentView];
            ((BCTextView*)[cell.contentView viewWithId:@"content"]).delegate = self;
			BCTextView *view = (BCTextView*)[cell.contentView viewWithId:@"source_content"];
            view.delegate = self;
			[view setBackgroundImp:(BACKGROUD_IMP)ReplyCornersBorder];
			view.contentInset = UIEdgeInsetsMake(10, 5, 5, 5);
	
		}
		

		
		MMAvatarImageView *avatar = (MMAvatarImageView*)[cell.contentView viewWithId:@"avatar"];
		avatar.imageURL = [[MMMomoUserMgr shareInstance] avatarImageUrlByUserId:message.ownerId];
		
		NSDate* date = [NSDate dateWithTimeIntervalSince1970:message.dateLine];
		UILabel *dateLabel = (UILabel*)[cell.contentView viewWithId:@"date"];
		dateLabel.textColor = RGBCOLOR(156,157,157);
		dateLabel.text = [MMCommonAPI getDateString:date];
		
		UILabel *nameLabel = (UILabel*)[cell.contentView viewWithId:@"name"];	
		nameLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:16];	
		nameLabel.text = [[MMMomoUserMgr shareInstance] realNameByUserId:message.ownerId];
		
		BCTextView* styledLabel = (BCTextView*)[cell.contentView viewWithId:@"content"];
		styledLabel.textFrame = message.styledComment;	
		styledLabel.textFrame.fontSize = 14.0f;
		
		if(MMAboutMeMessageKindReply == message.kind){
			styledLabel = (BCTextView*)[cell.contentView viewWithId:@"source_content"];
			styledLabel.textFrame = message.styledSrcComment;
			styledLabel.hidden = NO;
		} else {
			styledLabel = (BCTextView*)[cell.contentView viewWithId:@"source_content"];
			styledLabel.textFrame = [MMFaceTextFrame textFromHTML:@""];
			styledLabel.hidden = YES;
		}
		styledLabel.textFrame.fontSize = 12.0f;
		
		UIImageView *bg = (UIImageView *)[cell.contentView viewWithId:@"bg_view"];
		if (!message.isRead) {
			bg.image = [MMThemeMgr imageNamed:@"about_me_bg_yellow.png"];
		} else {
			bg.image = [MMThemeMgr imageNamed:@"about_me_bg_white.png"];
		}

		[cell.contentView setNeedsLayoutRecursive];
	}
	return cell;
	
	
}

#pragma mark MMFaceDelegate
-(void)selectFace:(NSString*)strFace {
	MMHidePortionTextField* sendMsgTextField = (MMHidePortionTextField*)[linearLayout_ viewWithId:@"input"];
    [sendMsgTextField appendText:strFace];
	[sendMsgTextField becomeFirstResponder];
}

#pragma mark -
#pragma mark Responding to keyboard events

- (void)keyboardWillShow:(NSNotification *)notification {
    
    /*
     Reduce the size of the text view so that it's not obscured by the keyboard.
     Animate the resize so that it's in sync with the appearance of the keyboard.
     */
    
    NSDictionary *userInfo = [notification userInfo];
    
    // Get the origin of the keyboard when it's displayed.
    NSValue* aValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    
    // Get the top of the keyboard as the y coordinate of its origin in self's view's coordinate system. The bottom of the text view's frame should align with the top of the keyboard's final position.
    CGRect keyboardRect = [aValue CGRectValue];
    keyboardRect = [self.view convertRect:keyboardRect fromView:nil];
    
    // Get the duration of the animation.
    NSValue *animationDurationValue = [userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSTimeInterval animationDuration;
    [animationDurationValue getValue:&animationDuration];
    
    // Animate the resize of the text view's frame in sync with the keyboard's appearance.
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:animationDuration];
  
    linearLayout_.top = keyboardRect.origin.y - linearLayout_.height;
    faceBgView.top = linearLayout_.bottom;
    tableView_.height = linearLayout_.top;
    
    [UIView commitAnimations];
}

@end
