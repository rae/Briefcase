//
//  FAQController.m
//  Briefcase
//
//  Created by Michael Taylor on 30/10/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import "FAQController.h"


@implementation FAQController

- (void)loadView 
{
    UIWebView * web_view = [[UIWebView alloc] initWithFrame:CGRectZero];
    web_view.scalesPageToFit = YES;
    self.view = web_view;
    web_view.delegate = self; 
    
    NSURL * url = [NSURL URLWithString:@"http://www.heymacsoftware.com/faq_iphone"];
    [web_view loadRequest:[NSURLRequest requestWithURL:url]];
    
    self.navigationItem.title = @"FAQ";
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)dealloc 
{
    [mySpinner release];
    [super dealloc];
}

#pragma mark UIWebViewDelegate methods

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSRange find_range;
    
    find_range = [[[request URL] relativeString] rangeOfString:@"faq_iphone"];
    
    if (find_range.location != NSNotFound)
	return YES;
        
    [[UIApplication sharedApplication] openURL:[request URL]];
    return NO;
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    if (!mySpinner)
    {
	mySpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
	[mySpinner sizeToFit];
	mySpinner.center = self.view.center;
	[self.view addSubview:mySpinner];
	mySpinner.hidesWhenStopped = YES;
    }
    
    [mySpinner startAnimating];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [mySpinner stopAnimating];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    [mySpinner stopAnimating];
    
    UINavigationController * controller = (UINavigationController*)self.parentViewController;
    [controller popViewControllerAnimated:YES];
    
    UIAlertView * alert;
    alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"FAQ Load Error", @"Title for error message when FAQ fails to load") 
				       message:NSLocalizedString(@"You must be connected to the Internet to view the FAQ", @"Message displayed when the FAQ page failes to load") 
				      delegate:nil 
			     cancelButtonTitle:NSLocalizedString(@"OK", @"Label for OK button") 
			     otherButtonTitles:nil];
    [alert show];	
    [alert release];
    
}

@end
