//
//  MMWebViewController.m
//  momo
//
//  Created by  on 11-9-18.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import "MMWebViewController.h"
#import "MMThemeMgr.h"
#import "MMGlobalCategory.h"
#import "MMUIDefines.h"
#import "MMGlobalStyle.h"
#import "MMCommonAPI.h"

///////////////////////////////////////////////////////////////////////////////////////////////////
BOOL MMIsPad() {
#ifdef __IPHONE_3_2
    return UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad;
#else
    return NO;
#endif
}

#define MM_ROW_HEIGHT 44
#define MM_LANDSCAPE_TOOLBAR_HEIGHT  33
///////////////////////////////////////////////////////////////////////////////////////////////////
CGFloat MMToolbarHeightForOrientation(UIInterfaceOrientation orientation) {
    if (UIInterfaceOrientationIsPortrait(orientation) || MMIsPad()) {
        return MM_ROW_HEIGHT;
        
    } else {
        return MM_LANDSCAPE_TOOLBAR_HEIGHT;
    }
}

///////////////////////////////////////////////////////////////////////////////////////////////////
UIInterfaceOrientation MMInterfaceOrientation() {
    UIInterfaceOrientation orient = [UIApplication sharedApplication].statusBarOrientation;
#if 0
    if (UIDeviceOrientationUnknown == orient) {
        return [MMBaseNavigator globalNavigator].visibleViewController.interfaceOrientation;
        
    } else {
        return orient;
    }
#endif
    return orient;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
CGFloat MMToolbarHeight() {
    return MMToolbarHeightForOrientation(MMInterfaceOrientation());
}

///////////////////////////////////////////////////////////////////////////////////////////////////
CGRect MMToolbarNavigationFrame() {
    CGRect frame = [UIScreen mainScreen].applicationFrame;
    return CGRectMake(0, 0, frame.size.width, frame.size.height - MMToolbarHeight()*2);
}

BOOL MMIsSupportedOrientation(UIInterfaceOrientation orientation) {
    if (MMIsPad()) {
        return YES;
        
    } else {
        switch (orientation) {
            case UIInterfaceOrientationPortrait:
            case UIInterfaceOrientationLandscapeLeft:
            case UIInterfaceOrientationLandscapeRight:
                return YES;
            default:
                return NO;
        }
    }
}

@implementation MMWebViewController

@synthesize delegate    = _delegate;
@synthesize headerView  = _headerView;
@synthesize canOpenInExteralBrowser = canOpenInExteralBrowser_;

- (UIWebView*)webView {
	return _webView;
}

- (id)init
{
    self = [super init];
    if (self) {
        self.hidesBottomBarWhenPushed = YES;
        canOpenInExteralBrowser_ = YES;
    }
    
    return self;
}

- (id)initWithNavigatorURL:(NSURL*)URL query:(NSDictionary*)query {
    if (self = [self init]) {
        NSURLRequest* request = [query objectForKey:@"request"];
        if (nil != request) {
            [self openRequest:request];
            
        } else {
            [self openURL:URL];
        }
    }
    return self;
}

- (void)dealloc {
    _webView.delegate = nil;
    MM_RELEASE_SAFELY(_webView);
    MM_RELEASE_SAFELY(_toolbar);
    MM_RELEASE_SAFELY(_backButton);
    MM_RELEASE_SAFELY(_forwardButton);
    MM_RELEASE_SAFELY(_refreshButton);
    MM_RELEASE_SAFELY(_stopButton);
    MM_RELEASE_SAFELY(_actionButton);
    MM_RELEASE_SAFELY(_activityItem);
    
    MM_RELEASE_SAFELY(_loadingURL);
    MM_RELEASE_SAFELY(_headerView);
    MM_RELEASE_SAFELY(_actionSheet);
    
    MM_RELEASE_SAFELY(scriptToExec_);
    MM_RELEASE_SAFELY(pageToExecScript_);
    
    [super dealloc];
}

#pragma mark -
#pragma mark Private

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)backAction {
    [_webView goBack];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)forwardAction {
    [_webView goForward];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)refreshAction {
    [_webView reload];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)stopAction {
    [_webView stopLoading];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)shareAction {
    if (nil == _actionSheet) {
        _actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                   delegate:self
                                          cancelButtonTitle:@"取消"
                                     destructiveButtonTitle:nil
                                          otherButtonTitles:@"在Safari中打开",
                        nil];
        [_actionSheet showInView: self.view];
    } else {
        [_actionSheet dismissWithClickedButtonIndex:-1 animated:YES];
        MM_RELEASE_SAFELY(_actionSheet);
    }
    
}

- (void)actionLeft:(id)sender {
    _webView.delegate = nil;
    [_webView stopLoading];
    
	[self.navigationController popViewControllerAnimated:YES];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)updateToolbarWithOrientation:(UIInterfaceOrientation)interfaceOrientation {
    CGRect newFrame = _toolbar.frame;
    newFrame.size.height = MMToolbarHeight();
    newFrame.origin.y = self.view.frame.size.height - newFrame.size.height;
    _toolbar.frame = newFrame;
    
    newFrame = _webView.frame;
    newFrame.size.height = self.view.frame.size.height - _toolbar.frame.size.height;
    _webView.frame = newFrame;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)loadView {
    
    [super loadView];
    
    self.navigationItem.hidesBackButton = YES;
	
	UIButton* buttonLeft_ = [[[UIButton alloc] initWithFrame:CGRectMake(0, 0, 34, 30)] autorelease];
	UIImage* image = [MMThemeMgr imageNamed:@"topbar_back.png"];
	[buttonLeft_ setImage:image forState:UIControlStateNormal];
	[buttonLeft_ setImage:image forState:UIControlStateHighlighted];
	[buttonLeft_ setBackgroundImage:[MMThemeMgr imageNamed:@"common_topbar_ic_press.png"] forState:UIControlStateHighlighted];
	[buttonLeft_ addTarget:self action:@selector(actionLeft:) forControlEvents:UIControlEventTouchUpInside];
	self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:buttonLeft_] autorelease];
    
	_webView = [[UIWebView alloc] initWithFrame:MMToolbarNavigationFrame()];
	_webView.delegate = self;
	_webView.autoresizingMask = UIViewAutoresizingFlexibleWidth
	| UIViewAutoresizingFlexibleHeight;
	_webView.scalesPageToFit = YES;
    _webView.multipleTouchEnabled = YES;
    //    _webView.dataDetectorTypes = UIDataDetectorTypeLink; //不自动识别链接
	[self.view addSubview:_webView];
	
	UIActivityIndicatorView* spinner =
    [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:
      UIActivityIndicatorViewStyleWhite] autorelease];
	[spinner startAnimating];
	_activityItem = [[UIBarButtonItem alloc] initWithCustomView:spinner];
	
	_backButton =
    [[UIBarButtonItem alloc] initWithImage:[MMThemeMgr imageNamed:@"backIcon.png"]
                                     style:UIBarButtonItemStylePlain
                                    target:self
                                    action:@selector(backAction)];
	_backButton.tag = 2;
	_backButton.enabled = NO;
	_forwardButton =
    [[UIBarButtonItem alloc] initWithImage:[MMThemeMgr imageNamed:@"forwardIcon.png"]
                                     style:UIBarButtonItemStylePlain
                                    target:self
                                    action:@selector(forwardAction)];
	_forwardButton.tag = 1;
	_forwardButton.enabled = NO;
	_refreshButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:
					  UIBarButtonSystemItemRefresh target:self action:@selector(refreshAction)];
	_refreshButton.tag = 3;
	_stopButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:
				   UIBarButtonSystemItemStop target:self action:@selector(stopAction)];
	_stopButton.tag = 3;
	_actionButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:
					 UIBarButtonSystemItemAction target:self action:@selector(shareAction)];
	
	UIBarItem* space = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:
						 UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease];
	
	_toolbar = [[MMToolbar alloc] initWithFrame:
				CGRectMake(0, self.view.frame.size.height - MMToolbarHeight(),
						   self.view.frame.size.width, MMToolbarHeight())];
	_toolbar.autoresizingMask =
	UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
	_toolbar.tintColor = RGBCOLOR(109, 132, 162);
    
    if (canOpenInExteralBrowser_) {
        _toolbar.items = [NSArray arrayWithObjects:
                          _backButton,
                          space,
                          _forwardButton,
                          space,
                          _refreshButton,
                          space,
                          _actionButton,
                          nil];
    } else {
        _toolbar.items = [NSArray arrayWithObjects:
                          _backButton,
                          space,
                          _forwardButton,
                          space,
                          _refreshButton,
                          nil];
    }

	[self.view addSubview:_toolbar];
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)setCanOpenInExteralBrowser:(BOOL)canOpenInExteralBrowser {
    canOpenInExteralBrowser_ = canOpenInExteralBrowser;
    
    UIBarItem* space = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:
						 UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease];
    if (canOpenInExteralBrowser_) {
        _toolbar.items = [NSArray arrayWithObjects:
                          _backButton,
                          space,
                          _forwardButton,
                          space,
                          _refreshButton,
                          space,
                          _actionButton,
                          nil];
    } else {
        _toolbar.items = [NSArray arrayWithObjects:
                          _backButton,
                          space,
                          _forwardButton,
                          space,
                          _refreshButton,
                          nil];
    }
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updateToolbarWithOrientation:self.interfaceOrientation];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)viewWillDisappear:(BOOL)animated {
    // If the browser launched the media player, it steals the key window and never gives it
    // back, so this is a way to try and fix that
    [self.view.window makeKeyWindow];
    
    [super viewWillDisappear:animated];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return MMIsSupportedOrientation(interfaceOrientation);
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
                                         duration:(NSTimeInterval)duration {
    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    [self updateToolbarWithOrientation:toInterfaceOrientation];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (UIView*)rotatingFooterView {
    return _toolbar;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark UTViewController (MMCategory)


///////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)persistView:(NSMutableDictionary*)state {
    NSString* URL = self.URL.absoluteString;
    if (URL.length && ![URL isEqualToString:@"about:blank"]) {
        [state setObject:URL forKey:@"URL"];
        return YES;
        
    } else {
        return NO;
    }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)restoreView:(NSDictionary*)state {
    NSString* URL = [state objectForKey:@"URL"];
    if (URL.length && ![URL isEqualToString:@"about:blank"]) {
        [self openURL:[NSURL URLWithString:URL]];
    }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark UIWebViewDelegate


///////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)webView:(UIWebView*)webView shouldStartLoadWithRequest:(NSURLRequest*)request
 navigationType:(UIWebViewNavigationType)navigationType {
    if ([[request.URL absoluteString] hasPrefix:@"momo://"] || [[request.URL absoluteString] hasPrefix:@"momonav://"]) {
        [MMCommonAPI openUrl:[request.URL absoluteString]];
         return NO;
    }
    
    [_loadingURL release];
    _loadingURL = [request.URL retain];
    _backButton.enabled = [_webView canGoBack];
    _forwardButton.enabled = [_webView canGoForward];
    return YES;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)webViewDidStartLoad:(UIWebView*)webView {
    self.title = @"载入中...";
    if (!self.navigationItem.rightBarButtonItem) {
        [self.navigationItem setRightBarButtonItem:_activityItem animated:YES];
    }
    [_toolbar replaceItemWithTag:3 withItem:_stopButton];
    _backButton.enabled = [_webView canGoBack];
    _forwardButton.enabled = [_webView canGoForward];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)webViewDidFinishLoad:(UIWebView*)webView {
    MM_RELEASE_SAFELY(_loadingURL);
    self.title = [_webView stringByEvaluatingJavaScriptFromString:@"document.title"];
    if (self.navigationItem.rightBarButtonItem == _activityItem) {
        [self.navigationItem setRightBarButtonItem:nil animated:YES];
    }
    [_toolbar replaceItemWithTag:3 withItem:_refreshButton];
    
    _backButton.enabled = [_webView canGoBack];
    _forwardButton.enabled = [_webView canGoForward];
    
    
    if (pageToExecScript_ && [[self.URL absoluteString] rangeOfString:pageToExecScript_].location != NSNotFound) {
        [webView stringByEvaluatingJavaScriptFromString:scriptToExec_];
    }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)webView:(UIWebView*)webView didFailLoadWithError:(NSError*)error {
    MM_RELEASE_SAFELY(_loadingURL);
    [self webViewDidFinishLoad:webView];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark UIActionSheetDelegate


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)actionSheet:(UIActionSheet*)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        [[UIApplication sharedApplication] openURL:self.URL];
    }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (NSURL*)URL {
    return _loadingURL ? _loadingURL : _webView.request.URL;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setHeaderView:(UIView*)headerView {
    if (headerView != _headerView) {
        BOOL addingHeader = !_headerView && headerView;
        BOOL removingHeader = _headerView && !headerView;
        
        [_headerView removeFromSuperview];
        [_headerView release];
        _headerView = [headerView retain];
        _headerView.frame = CGRectMake(0, 0, _webView.frame.size.width, _headerView.frame.size.height);
        
        [self view];
        UIView* scroller = [_webView descendantOrSelfWithClass:NSClassFromString(@"UIScroller")];
        UIView* docView = [scroller descendantOrSelfWithClass:NSClassFromString(@"UIWebDocumentView")];
        [scroller addSubview:_headerView];
        
        if (addingHeader) {
            docView.top += headerView.height;
            docView.height -= headerView.height;
            
        } else if (removingHeader) {
            docView.top -= headerView.height;
            docView.height += headerView.height;
        }
    }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)openURL:(NSURL*)URL {
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:URL];
    [self openRequest:request];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)openRequest:(NSURLRequest*)request {
    [self view];
    [_webView loadRequest:request];
}

- (void)addScript:(NSString*)script forURL:(NSString*)url {
    MM_RELEASE_SAFELY(scriptToExec_);
    MM_RELEASE_SAFELY(pageToExecScript_);
    scriptToExec_ = [script copy];
    pageToExecScript_ = [url copy];
}

@end
