//
//  MMWebViewController.h
//  momo
//
//  Created by  on 11-9-18.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MMGlobalCategory.h"

@protocol MMWebViewControllerDelegate;
@interface MMWebViewController : UIViewController <UIWebViewDelegate, UIActionSheetDelegate>
{
@protected
    UIWebView*        _webView;
    
    MMToolbar*        _toolbar;
    
    UIView*           _headerView;
    
    UIBarButtonItem*  _backButton;
    UIBarButtonItem*  _forwardButton;
    UIBarButtonItem*  _refreshButton;
    UIBarButtonItem*  _stopButton;
    UIBarButtonItem*  _actionButton;
    UIBarButtonItem*  _activityItem;
    
    NSURL*            _loadingURL;
    
    UIActionSheet*    _actionSheet;
    
    id<MMWebViewControllerDelegate> _delegate;
    
    //页面载入后执行js
    NSString* scriptToExec_;
    NSString* pageToExecScript_;
    
    BOOL canOpenInExteralBrowser_;  //是否允许再外部打开
}


@property (nonatomic, readonly) NSURL*  URL;

/**
 * A view that is inserted at the top of the web view, within the scroller.
 */
@property (nonatomic, retain)   UIView* headerView;

/**
 * The web controller delegate, currently does nothing.
 */
@property (nonatomic, assign)   id<MMWebViewControllerDelegate> delegate;

@property (nonatomic) BOOL canOpenInExteralBrowser;


- (UIWebView*)webView;

/**
 * Navigate to the given URL.
 */
- (void)openURL:(NSURL*)URL;

/**
 * Load the given request using UIWebView's loadRequest:.
 *
 * @param request  A URL request identifying the location of the content to load.
 */
- (void)openRequest:(NSURLRequest*)request;

- (void)addScript:(NSString*)script forURL:(NSString*)url;

@end

@protocol MMWebViewControllerDelegate <NSObject>
// XXXjoe Need to make this similar to UIWebViewDelegate
@end