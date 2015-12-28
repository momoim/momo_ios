//
//  MMAboutMeViewController.m
//  momo
//
//  Created by houxh on 11-5-4.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MMAboutMeViewController.h"
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
#import "MMPreference.h"

#define TABLE_HEIGHT 416
#define DRAG_WIDTH 320
#define DRAG_HEIGHT 300      //整个dragView高度
#define DRAG_VIEW_HEIGHT 200    //手指感应的区域高度 
#define DRAG_Y 30


enum  {
	LISTMODE,
	DRAGMODE,
};

#define REFRESH_FOOTER_HEIGHT 40.0f

@implementation MMAboutMeViewController
@synthesize refreshing = refreshing_;
@synthesize records = records_;

-(NSMutableArray*)mutableUnreadedMessages {
    return [self mutableArrayValueForKeyPath:@"unreadedMessages"];
}

- (id)init {
	if (self = [super init]) {
		isLoading_ = NO;
        NSNotificationCenter * center = [NSNotificationCenter defaultCenter];
		[center addObserver:self selector:@selector(getNewAboutMeMessage:) name:kMMNewAboutMeMsg object:nil];
		[center addObserver:self selector:@selector(deleteMessage:) name:kMMMessageDeleted object:nil];
		[center addObserver:self selector:@selector(deleteAllMessage) name:kMMAllMessageDeleted object:nil];
        		
        [self addObserver:self forKeyPath:@"unreadedMessages.@count" options:NSKeyValueObservingOptionNew
                  context:nil];
        
        [self reload];
	}
	return self;
}

- (void)dealloc {
	NSNotificationCenter * center = [NSNotificationCenter defaultCenter];
    [center removeObserver:self name:kMMNewAboutMeMsg object:nil];
	[center removeObserver:self name:kMMMessageDeleted object:nil];
	[center removeObserver:self name:kMMAllMessageDeleted object:nil];
    [self removeObserver:self forKeyPath:@"unreadedMessages.@count"];

	[tableView_ release];
	[footerLabel_ release];
    
    self.records = nil;
	[super dealloc];
}

- (void)viewDidUnload {
	[tableView_ release];
	tableView_ = nil;
	[footerLabel_ release];
	footerLabel_ = nil;
	
    refreshHeaderView = nil;
	
	[super viewDidUnload];
}

- (void)loadView {
	[super loadView];

    self.navigationItem.title = @"MO我的";
    
	UIImage *image = nil;
    
    UIButton* buttonLeft_ = [[[UIButton alloc] initWithFrame:CGRectMake(0, 0, 34, 30)] autorelease];
	image = [MMThemeMgr imageNamed:@"topbar_back.png"];
	[buttonLeft_ setImage:image forState:UIControlStateNormal];
	[buttonLeft_ setImage:image forState:UIControlStateHighlighted];
	[buttonLeft_ setBackgroundImage:[MMThemeMgr imageNamed:@"common_topbar_ic_press.png"] forState:UIControlStateHighlighted];
	[buttonLeft_ addTarget:self action:@selector(actionLeft:) forControlEvents:UIControlEventTouchUpInside];
	self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:buttonLeft_] autorelease];
	
	tableView_ = [[UITableView alloc] initWithFrame:CGRectMake(0.0, 0.0, TABLE_WIDTH, (iPhone5)?TABLE_HEIGHT+88:TABLE_HEIGHT) style:UITableViewStylePlain];
	tableView_.dataSource = self;
	tableView_.delegate = self;
	tableView_.tableFooterView = [[[UIView alloc] init] autorelease];
    [self.view addSubview:tableView_];

	//header
	CGRect tableBounds = tableView_.bounds;
	refreshHeaderView = [[EGORefreshTableHeaderView alloc] initWithFrame:CGRectMake(0.0f, 0.0f - tableBounds.size.height, tableBounds.size.width, tableBounds.size.height)];
	refreshHeaderView.delegate = self;
	[tableView_ addSubview:refreshHeaderView];	
	[refreshHeaderView refreshLastUpdatedDate];
	[refreshHeaderView release];
	
	//refresh footer
	footerButton_ = [UIButton buttonWithType:UIButtonTypeCustom];
	footerButton_.frame = CGRectMake(0, 1, 320, 44);
	[footerButton_ addTarget:self action:@selector(actionDownMoreAboutMe) forControlEvents:UIControlEventTouchUpInside];
	[footerButton_ setTitle:@"更多关于我的..." forState:UIControlStateNormal];
    footerButton_.titleLabel.font = [UIFont systemFontOfSize:16];
	[footerButton_ setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
	footerButton_.hidden = NO;
	
	footerRefreshSpinner_ = [[[UIActivityIndicatorView alloc]
							 initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray] autorelease];
	footerRefreshSpinner_.center = CGPointMake(footerButton_.frame.size.width / 5, footerButton_.frame.size.height / 2);
	footerRefreshSpinner_.hidesWhenStopped = YES;
	[footerButton_ addSubview:footerRefreshSpinner_];
	tableView_.tableFooterView = footerButton_;
    
    //回复框
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
    linearLayout_.hidden = YES;
	
	faceBgView = [[UIView alloc] initWithFrame:CGRectMake(0, iPhone5?416+88:416, 320, 216)];
    faceBgView.backgroundColor = RGBCOLOR(175, 221, 234);
    [self.view addSubview:faceBgView];
    faceBgView.hidden = YES;
    
    MMFaceView* faceView = [[[MMFaceView alloc] init] autorelease];
    [faceView initPara];
	faceView.frame = CGRectMake(0, 0, 320, 216);
	faceView.delegate_ = self;
	[faceBgView addSubview:faceView];
    
    UISwipeGestureRecognizer* swipeGesture = [[[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(actionLeft:)] autorelease];
    [self.view addGestureRecognizer:swipeGesture];
    
    if (!viewFirstLoad_) {
        viewFirstLoad_ = YES;
        [self startLoading];
    }
    
    //显示引导图
    if (![[MMPreference shareInstance] isGuideImageShowed:@"about_me.png"]) {
        UIButton* button = [UIButton buttonWithType:UIButtonTypeCustom];
        UIWindow* window = [[UIApplication sharedApplication] keyWindow];
        button.frame = window.frame;
        [button setImage:[MMThemeMgr imageWithContentOfFile:@"about_me.png"] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(actionDismissGuide:) forControlEvents:UIControlEventTouchDown];
        [window addSubview:button];
    }
}	

- (void)startLoading {
    CHECK_NETWORK;

	[refreshHeaderView egoRefreshScrollViewAutoScrollToLoading:tableView_];
}

- (void)stopLoading {
	[refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:tableView_];	//停止刷新
}


- (void)pushDownTextField {
    pushUp_ = NO;
    
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:0.3];
	linearLayout_.frame = CGRectMake(0, iPhone5?366+5+88:366+5, 320, 45);
    linearLayout_.hidden = YES;
    faceBgView.frame = CGRectMake(0, iPhone5?416+88:416, 320, 216);
    faceBgView.hidden = YES;
	tableView_.frame = CGRectMake(0, 0, 320, self.view.bounds.size.height);
	[UIView commitAnimations];
}

- (void)pushUpTextField {
    pushUp_ = YES;
    
    [UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:0.3];
	
	linearLayout_.frame = CGRectMake(0, iPhone5?150+5+88:150+5, 320, 45);
    faceBgView.frame = CGRectMake(0, iPhone5?200+88:200, 320, 216);
    linearLayout_.hidden = NO;
    faceBgView.hidden = NO;
	tableView_.frame = CGRectMake(0, 0, 320, self.view.bounds.size.height - 216.0 - 45.0f);
	[UIView commitAnimations];
}

- (void)viewWillAppear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

#pragma mark -
#pragma mark UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [self tableView:tableView cellForRowAtIndexPath:indexPath];
	CGSize ss = CGSizeMake(cell.bounds.size.width, 0);
	CGSize size = [cell.contentView sizeThatFits:ss];
	return size.height;
}	

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	MMAboutMeRecord *record = [self.records objectAtIndex:indexPath.row];
    MMAboutMeMessage *msg = record.message;
    
    //设为异读
    if (!record.message.isRead) {
        [self clearUnReadFlagByRecord:record];
    }
    
    replyTarget_ = msg;
    MMHidePortionText* hidePortionText = [MMHidePortionText hidePortionTextWithUserName:msg.ownerName
                                                                                    uid:msg.ownerId];
	MMHidePortionTextField* hidePortionTextField = (MMHidePortionTextField*)[linearLayout_ viewWithId:@"input"];
    [hidePortionTextField clearTextAndHidePortion];
    [hidePortionTextField appendHidePortionText:hidePortionText];
	
	if (![hidePortionTextField.textField isFirstResponder]) {
		[hidePortionTextField.textField becomeFirstResponder];
	} else {
		//
	}
	
	[tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
}

#pragma mark -
#pragma mark UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	if (scrollView == tableView_) {
		[refreshHeaderView egoRefreshScrollViewDidScroll:scrollView];
	}
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
	if (tableView_ == scrollView && scrollView.contentOffset.y < 0) {
		[refreshHeaderView egoRefreshScrollViewDidEndDragging:scrollView];
		return;
    }
}

#pragma mark -
#pragma mark EGORefreshTableHeaderDelegate
- (void)egoRefreshTableHeaderDidTriggerRefresh:(EGORefreshTableHeaderView*)view{
	[self refresh];
}

- (BOOL)egoRefreshTableHeaderDataSourceIsLoading:(EGORefreshTableHeaderView*)view{
	//判断是否刷新
	return self.refreshing;
}

- (NSDate*)egoRefreshTableHeaderDataSourceLastUpdated:(EGORefreshTableHeaderView*)view{
	return [NSDate date];
}


#pragma mark -
#pragma mark UITableViewDataSource data

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"unreadedMessages.@count"]) {
        NSNumber *count = [change objectForKey:NSKeyValueChangeNewKey];
        if ([count intValue] == 0) {
            int64_t timeLine = [[MMAboutMeManager shareInstance] getMaxDateLine];
            
            [[MMLoginService shareInstance] increaseActiveCount];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
                NSDictionary *object = [NSDictionary dictionaryWithObject:[NSNumber numberWithLongLong:timeLine] forKey:@"timeline"];
                ASIHTTPRequest *request = [ASIHTTPRequest requestWithPath:@"statuses/aboutme_read.json" withObject:object];
                [ASIHTTPRequest startSynchronous:request];
                NSInteger statusCode = [request responseStatusCode];
                if (statusCode != 200) {
                    MLOG(@"set boutme state fail");
                }
                [[MMLoginService shareInstance] decreaseActiveCount];
            });
        } 
    }
}

- (MMMessageInfo*)messageFromCache:(NSString*)statusId {
    for (MMAboutMeRecord* record in records_) {
        if ([record.messageInfo.statusId isEqualToString:statusId]) {
            return record.messageInfo;
        }
    }
    return nil;
}

-(NSArray*) getAboutMeList:(int)curCount {
    NSArray* aboutMes = [[MMAboutMeManager shareInstance] getAboutMessageList:YES listCount:curCount+30];
    NSMutableArray* records = [NSMutableArray array];
    NSMutableDictionary* messageIdAndObject = [NSMutableDictionary dictionary];
    for (MMAboutMeMessage* aboutMe in aboutMes) {
        MMAboutMeRecord *record = [[[MMAboutMeRecord alloc] init] autorelease];
        
        MMMessageInfo* messageInfo = [messageIdAndObject objectForKey:aboutMe.statusId];
        if (!messageInfo) {
            messageInfo = [[MMUIMessage instance] getMessage:aboutMe.statusId ownerId:[[MMLoginService shareInstance] getLoginUserId]];
            if (nil == messageInfo) {
                MLOG(@"error:message is't exist");
				[[MMAboutMeManager shareInstance] deleteMessageWithStatusId:aboutMe.statusId];
                continue;
            }
            [messageIdAndObject setObject:messageInfo forKey:aboutMe.statusId];
        }
        
        record.message = aboutMe;
		record.messageInfo = messageInfo;
		[records addObject:record];
    }
    
    return records;
}

-(void)reload {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableArray* array = [NSMutableArray arrayWithArray:[self getAboutMeList:0]];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.records = array;
            if (nil == tableView_) {
                return;
            }
            [tableView_ reloadData];
        });
    });
}

- (void)getNewAboutMeMessage:(NSNotification*)notification {
    MMAboutMeMessage* msg = (MMAboutMeMessage*)notification.object;
    if (!msg) {
        return;
    }
    
    [self addMessage:msg];
}

-(BOOL) addMessage:(MMAboutMeMessage*)message {
//	assert(!message.isRead);
		
    MMAboutMeRecord *record = [[[MMAboutMeRecord alloc] init] autorelease];
    record.message = message;
    
    MMMessageInfo* messageInfo = [self messageFromCache:message.statusId];
    if (!messageInfo) {
        messageInfo = [[MMUIMessage instance] getMessage:message.statusId ownerId:[[MMLoginService shareInstance] getLoginUserId]];
        if (!messageInfo) {
            return NO;
        }
    }
    
    assert(messageInfo);
    record.messageInfo = messageInfo;
    [records_ insertObject:record atIndex:0];
    [tableView_ reloadData];
    
	return YES;
}

-(void)refresh {
	if (refreshing_) {
		return;
	}
	refreshing_ = YES;
	
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSInteger count = [[MMAboutMeManager shareInstance] refreshAboutMe];
        dispatch_async(dispatch_get_main_queue(), ^{
			self.refreshing = NO;
			[self stopLoading];
			if (count > 0 || !records_) {
				[self reload];
			}
        });
		
	});
	
	//[MMHttpRequestThread detachNewThreadSelector:@selector(threadRefresh) toTarget:self withObject:nil cancelOnLogout:YES];
}

- (void)deleteMessage:(id)sender {
	NSNotification *note = (NSNotification *)sender;
	MMMessageInfo *messageInfo = (MMMessageInfo *)(note.object);
	[[MMAboutMeManager shareInstance] deleteMessageWithStatusId:messageInfo.statusId];
	[self reload];
}

- (void)deleteAllMessage {
	[[MMAboutMeManager shareInstance] deleteAllMessage];
	//页面刷新 
	[self reload];
	[self refresh];
}

#pragma mark -
#pragma mark UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [records_ count];		
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	assert(indexPath.row < [records_ count]);
	MMAboutMeRootCell *cell = (MMAboutMeRootCell *)[tableView dequeueReusableCellWithIdentifier:@"cell"];
    
	if (cell == nil) {
        cell = [[[MMAboutMeRootCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cell"] autorelease];
        cell.delegate = self;
    } 

	MMAboutMeRecord *record = [records_ objectAtIndex:indexPath.row];
    assert(record.messageInfo);
    [cell setRecord:record];
    
    for (MMAboutMeRecord* tmpRecord in records_) {
        if (!record.messageText && [tmpRecord.messageInfo.statusId isEqualToString:record.messageInfo.statusId]) {
            record.messageText = record.messageText;
        }
    }

   	return cell;
}


#pragma mark -
#pragma mark action events and other

- (void)actionLeft:(id)sender {
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[MMAboutMeManager shareInstance] clearUnreadFlag];
	});
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)actionRight:(id)sender {

}

- (void)actionRefresh {
	[self refresh];
}

- (void)actionDownMoreAboutMe {
	if (!isLoading_) {
		isLoading_ = YES;
		[footerRefreshSpinner_ startAnimating];
		[footerButton_ setTitle:@"更多关于我的载入中..." forState:UIControlStateNormal];
		
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
			NSMutableArray* array = [NSMutableArray arrayWithArray:[self getAboutMeList:[records_ count]]];
			dispatch_async(dispatch_get_main_queue(), ^{
				self.records = array;
				[tableView_ reloadData];
				isLoading_ = NO;
				[footerButton_ setTitle:@"更多关于我的..." forState:UIControlStateNormal];
				[footerRefreshSpinner_ stopAnimating];
			});
		});
	}
}

-(void)actionForAt:(id)sender {
	MMSelectFriendViewController* selectViewController = [[[MMSelectFriendViewController alloc] init] autorelease];
	selectViewController.hidesBottomBarWhenPushed = YES;
	selectViewController.delegate = self;
	[self.navigationController pushViewController:selectViewController animated:YES];
}


- (void)actionForSelectFace {
	MMHidePortionTextField* sendMsgTextField = (MMHidePortionTextField*)[linearLayout_ viewWithId:@"input"];
	
    if ([sendMsgTextField isFirstResponder]) {
        [sendMsgTextField resignFirstResponder];
        if ((int)faceBgView.frame.origin.y < iPhone5?416+88:416) {
            [self pushUpTextField];
        }
        [self pushUpTextField];
    } else {
        if ((int)faceBgView.frame.origin.y == iPhone5?416+88:416) {
            [self pushUpTextField];
        } else {
            [sendMsgTextField becomeFirstResponder];
        }
    }
}

- (void)clearUnReadFlagByStatusId:(NSString*)statusId {
    NSMutableArray* indexPaths = [NSMutableArray array];
    
    for (int i = 0; i < records_.count; i++) {
        MMAboutMeRecord* record = [records_ objectAtIndex:i];
        if ([record.message.statusId isEqualToString:statusId]) {
            record.message.isRead = YES;
            [indexPaths addObject:[NSIndexPath indexPathForRow:i inSection:0]];
        }
    }
    [[MMAboutMeManager shareInstance] clearUnreadFlagWithStatusId:statusId];
    
    [tableView_ reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
}

- (void)clearUnReadFlagByRecord:(MMAboutMeRecord*)record {
    NSInteger index = [records_ indexOfObject:record];
    if (index != NSNotFound) {
        [[MMAboutMeManager shareInstance] clearUnReadFlagWithMessageId:record.message.id];
        
        record.message.isRead = YES;
        NSArray* indexPaths = [NSArray arrayWithObject:[NSIndexPath indexPathForRow:index inSection:0]];
        [tableView_ reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
    }
}

- (void)actionDismissGuide:(UIButton*)guideButton {
    [guideButton removeFromSuperview];
    
    [[MMPreference shareInstance] setGuideImage:@"about_me.png" isShowed:YES];
}

#pragma mark MMAboutMeRootCellDelegate
- (void)didClickAtAvatar:(MMAboutMeRootCell *)cell {

}

- (void)didSwipeToLeft:(MMAboutMeRootCell *)cell {
    MMBrowseMessageViewController* viewController = [[[MMBrowseMessageViewController alloc] 
                                                      initWithStatusId:cell.aboutMeRecord.messageInfo.statusId] autorelease];
    viewController.fromAboutMeMessage = YES;
    [self.navigationController pushViewController:viewController animated:YES];
    
    double delayInSeconds = 0.5;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self clearUnReadFlagByStatusId:cell.aboutMeRecord.message.statusId];
    });
}

#pragma mark UIScrollViewDelegate
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    MMHidePortionTextField* sendMsgTextField = (MMHidePortionTextField*)[linearLayout_ viewWithId:@"input"];
    if (pushUp_) {
        [sendMsgTextField resignFirstResponder];
        [self pushDownTextField];
    }
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
    
    pushUp_ = YES;
    linearLayout_.top = keyboardRect.origin.y - linearLayout_.height;
    faceBgView.top = linearLayout_.bottom;
    tableView_.height = linearLayout_.top;
    
    linearLayout_.hidden = NO;
    faceBgView.hidden = NO;
    
    [UIView commitAnimations];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    
    NSDictionary* userInfo = [notification userInfo];
    
    /*
     Restore the size of the text view (fill self's view).
     Animate the resize so that it's in sync with the disappearance of the keyboard.
     */
    NSValue *animationDurationValue = [userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSTimeInterval animationDuration;
    [animationDurationValue getValue:&animationDuration];
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:animationDuration];
    
    [self pushDownTextField];
    
    [UIView commitAnimations];
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
        
        if (MMAboutMeMessageKindPraise != replyTarget_.kind) {
            draftInfo.replyCommentId = replyTarget_.commentId; 
        }
		
		[[MMDraftMgr shareInstance] insertAndUploadNewDraft:draftInfo];
		//当无未选中某条评论时的回复 当作回复该动态
	}
    
	textField.text = @"";
	[textField resignFirstResponder];
	
	replyTarget_ = nil;
	[self pushDownTextField];
	
	return YES;
}

#pragma mark MMSelectFriendViewDelegate
- (void)didSelectFriend:(NSArray*)selectedFriends {
	MMHidePortionTextField* hidePortionTextField = (MMHidePortionTextField*)[linearLayout_ viewWithId:@"input"] ;
    
    for (MMMomoUserInfo* friendInfo in selectedFriends) {
        MMHidePortionText* hidePortionText = [MMHidePortionText hidePortionTextWithUserName:friendInfo.realName
                                                                                        uid:friendInfo.uid];
        [hidePortionTextField appendHidePortionText:hidePortionText];
	}
}

@end
