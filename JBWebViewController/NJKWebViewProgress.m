//
//  NJKWebViewProgress.m
//
//  Created by Satoshi Aasano on 4/20/13.
//  Copyright (c) 2013 Satoshi Asano. All rights reserved.
//

#import "NJKWebViewProgress.h"

NSString *completeRPCURLPath = @"/njkwebviewprogressproxy/complete";

const float NJKInitialProgressValue = 0.1f;
const float NJKInteractiveProgressValue = 0.5f;
const float NJKFinalProgressValue = 0.9f;

@implementation NJKWebViewProgress
{
    NSUInteger _loadingCount;
    NSUInteger _maxLoadCount;
    NSURL *_currentURL;
    BOOL _interactive;
}

- (id)init
{
    self = [super init];
    if (self) {
        _maxLoadCount = _loadingCount = 0;
        _interactive = NO;
    }
    return self;
}

- (void)startProgress
{
    if (_progress < NJKInitialProgressValue) {
        [self setProgress:NJKInitialProgressValue];
    }
}

- (void)incrementProgress
{
    float progress = self.progress;
    float maxProgress = _interactive ? NJKFinalProgressValue : NJKInteractiveProgressValue;
    float remainPercent = (float)_loadingCount / (float)_maxLoadCount;
    float increment = (maxProgress - progress) * remainPercent;
    progress += increment;
    progress = fmin(progress, maxProgress);
    [self setProgress:progress];
}

- (void)completeProgress
{
    [self setProgress:1.0];
}

- (void)setProgress:(float)progress
{
    // progress should be incremental only
    if (progress > _progress || progress == 0) {
        _progress = progress;
        if ([_progressDelegate respondsToSelector:@selector(webViewProgress:updateProgress:)]) {
            [_progressDelegate webViewProgress:self updateProgress:progress];
        }
        if (_progressBlock) {
            _progressBlock(progress);
        }
    }
}

- (void)reset
{
    _maxLoadCount = _loadingCount = 0;
    _interactive = NO;
    [self setProgress:0.0];
}

#pragma mark -
#pragma mark WKNavigationDelegate

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    if ([navigationAction.request.URL.path isEqualToString:completeRPCURLPath]) {
        [self completeProgress];
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    
    if ([_webViewProxyDelegate respondsToSelector:@selector(webView:decidePolicyForNavigationAction:decisionHandler:)]) {
        [_webViewProxyDelegate webView:webView decidePolicyForNavigationAction:navigationAction decisionHandler:decisionHandler];
    }
    
    BOOL isFragmentJump = NO;
    if (navigationAction.request.URL.fragment) {
        NSString *nonFragmentURL = [navigationAction.request.URL.absoluteString stringByReplacingOccurrencesOfString:[@"#" stringByAppendingString:navigationAction.request.URL.fragment] withString:@""];
        isFragmentJump = [nonFragmentURL isEqualToString:webView.URL.absoluteString];
    }

    BOOL isTopLevelNavigation = [navigationAction.request.mainDocumentURL isEqual:navigationAction.request.URL];

    BOOL isHTTPOrLocalFile = [navigationAction.request.URL.scheme isEqualToString:@"http"] || [navigationAction.request.URL.scheme isEqualToString:@"https"] || [navigationAction.request.URL.scheme isEqualToString:@"file"];
    if (!isFragmentJump && isHTTPOrLocalFile && isTopLevelNavigation) {
        _currentURL = navigationAction.request.URL;
        [self reset];
    }
    decisionHandler(WKNavigationActionPolicyAllow);
}

- (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation
{
    if ([_webViewProxyDelegate respondsToSelector:@selector(webView:didCommitNavigation:)]) {
        [_webViewProxyDelegate webView:webView didCommitNavigation:navigation];
    }

    _loadingCount++;
    _maxLoadCount = fmax(_maxLoadCount, _loadingCount);

    [self startProgress];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
    if ([_webViewProxyDelegate respondsToSelector:@selector(webView:didFinishNavigation:)]) {
        [_webViewProxyDelegate webView:webView didFinishNavigation:navigation];
    }
    
    _loadingCount--;
    [self incrementProgress];
    
    [webView evaluateJavaScript:@"document.readyState" completionHandler:^(id _Nullable readyState, NSError * _Nullable error) {
        BOOL interactive = [readyState isEqualToString:@"interactive"];
        if (interactive) {
            _interactive = YES;
            NSString *waitForCompleteJS = [NSString stringWithFormat:@"window.addEventListener('load',function() { var iframe = document.createElement('iframe'); iframe.style.display = 'none'; iframe.src = '%@://%@%@'; document.body.appendChild(iframe);  }, false);", webView.URL.scheme, webView.URL.host, completeRPCURLPath];
            [webView evaluateJavaScript:waitForCompleteJS completionHandler:^(id _Nullable result, NSError * _Nullable error) {

            }];
        }
        BOOL isNotRedirect = _currentURL && [_currentURL isEqual:webView.URL];
        BOOL complete = [readyState isEqualToString:@"complete"];
        if (complete && isNotRedirect) {
            [self completeProgress];
        }
    }];
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error
{
    if ([_webViewProxyDelegate respondsToSelector:@selector(webView:didFailNavigation:withError:)]) {
        [_webViewProxyDelegate webView:webView didFailNavigation:navigation withError:error];
    }
    
    _loadingCount--;
    [self incrementProgress];

    [webView evaluateJavaScript:@"document.readyState" completionHandler:^(id _Nullable readyState, NSError * _Nullable error) {
        BOOL interactive = [readyState isEqualToString:@"interactive"];
        if (interactive) {
            _interactive = YES;
            NSString *waitForCompleteJS = [NSString stringWithFormat:@"window.addEventListener('load',function() { var iframe = document.createElement('iframe'); iframe.style.display = 'none'; iframe.src = '%@://%@%@'; document.body.appendChild(iframe);  }, false);", webView.URL.scheme, webView.URL.host, completeRPCURLPath];
            [webView evaluateJavaScript:waitForCompleteJS completionHandler:^(id _Nullable result, NSError * _Nullable error) {

            }];
        }
        BOOL isNotRedirect = _currentURL && [_currentURL isEqual:webView.URL];
        BOOL complete = [readyState isEqualToString:@"complete"];
        if (complete && isNotRedirect) {
            [self completeProgress];
        }
    }];
}

@end
