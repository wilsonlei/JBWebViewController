//
//  JBWebViewController.h
//  JBWebViewController
//
//  Created by Jonas Boserup on 28/10/14.
//  Copyright (c) 2014 Jonas Boserup. All rights reserved.
//

// Required Apple libraries
#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

// Required third-party libraries
#import <ARChromeActivity/ARChromeActivity.h>
#import <ARSafariActivity/ARSafariActivity.h>
#import "NJKWebViewProgress.h"
#import "NJKWebViewProgressView.h"

@interface JBWebViewController : UIViewController <WKNavigationDelegate, NJKWebViewProgressDelegate>

// Typedef for completion block
typedef void (^completion)(JBWebViewController *controller);

// Loding string
@property (nonatomic, strong) NSString *loadingString;

// Public variables
@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, assign) BOOL hideAddressBar;

// Public header methods
- (id)initWithUrl:(NSURL *)url;
- (void)show;
- (void)showFromController:(UIViewController*)controller;
- (void)dismiss;
- (void)reload;
- (void)share;
- (void)setWebTitle:(NSString *)title;
- (void)setWebSubtitle:(NSString *)subtitle;
- (void)showControllerWithCompletion:(completion)completion;
- (void)showFromController:(UIViewController*)controller WithCompletion:(completion)completion;
- (void)navigateToURL:(NSURL *)url;
- (void)loadRequest:(NSURLRequest *)request;
- (void)setProgressBarColor:(UIColor *)color;

// Public return methods
- (NSString *)getWebTitle;
- (NSString *)getWebSubtitle;

@end
