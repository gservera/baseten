//
// BXAuthenticationPanel.m
// BaseTen
//
// Copyright 2008-2010 Marko Karppinen & Co. LLC.
// 
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// 
//     http://www.apache.org/licenses/LICENSE-2.0
// 
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import <BaseTen/BaseTen.h>
#import "BXAuthenticationPanel.h"


__strong static NSNib* gAuthenticationViewNib = nil;
__strong static NSString* kNSKVOContext = @"kBXAuthenticationPanelNSKVOContext";
static const CGFloat kSizeDiff = 25.0;



@implementation BXAuthenticationPanel
+ (void) initialize
{
    [super initialize];
    static BOOL tooLate = NO;
    if (NO == tooLate)
    {
        tooLate = YES;
        gAuthenticationViewNib = [[NSNib alloc] initWithNibNamed: @"AuthenticationView" 
                                                          bundle: [NSBundle bundleForClass: self]];
    }
}


+ (id) authenticationPanel
{
	return [[[self alloc] initWithContentRect: NSZeroRect styleMask: NSTitledWindowMask
									  backing: NSBackingStoreBuffered defer: YES] autorelease];
}


- (id) initWithContentRect: (NSRect) contentRect styleMask: (NSUInteger) styleMask
                   backing: (NSBackingStoreType) bufferingType defer: (BOOL) deferCreation
{
    if ((self = [super initWithContentRect: contentRect styleMask: styleMask 
                                   backing: bufferingType defer: deferCreation]))
    {
        [gAuthenticationViewNib instantiateWithOwner: self topLevelObjects: NULL];
		
		NSRect contentFrame = [mPasswordAuthenticationView frame];
        contentFrame.size.height -= kSizeDiff;
		NSRect windowFrame = [self frameRectForContentRect: contentFrame];
		[self setFrame: windowFrame display: NO];
		[self setMinSize: windowFrame.size];
		
		[self setContentView: mPasswordAuthenticationView];
		[mPasswordAuthenticationView setAutoresizingMask:
		 NSViewMinXMargin | NSViewMaxXMargin | NSViewWidthSizable |
		 NSViewMinYMargin | NSViewMaxYMargin | NSViewHeightSizable];

		[self addObserver: self forKeyPath: @"message" 
				  options: NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew 
				  context: kNSKVOContext];
    }
    return self;
}


- (void) dealloc
{
    [mPasswordAuthenticationView release];
	[mUsernameField release];
	[mPasswordField release];
	[mRememberInKeychainButton release];
	[mMessageTextField release];
	[mCredentialFieldMatrix release];
	[mProgressIndicator release];
	
	[mUsername release];
	[mPassword release];
	[mMessage release];
    [super dealloc];
}


- (id <BXAuthenticationPanelDelegate>) delegate
{
	return mDelegate;
}


- (void) setDelegate: (id <BXAuthenticationPanelDelegate>) object
{
	mDelegate = object;
}


- (BOOL) isAuthenticating
{
    return mIsAuthenticating;
}


- (void) setAuthenticating: (BOOL) aBool
{
	mIsAuthenticating = aBool;
}


- (BOOL) shouldStorePasswordInKeychain
{
	return mShouldStorePasswordInKeychain;
}


- (void) setShouldStorePasswordInKeychain: (BOOL) aBool
{
	mShouldStorePasswordInKeychain = aBool;
}


- (NSString *) username
{
	NSString* retval = mUsername;
	if (0 == [retval length])
		retval = nil;
	return retval;
}


- (NSString *) password
{
	NSString* retval = mPassword;
	if (0 == [retval length])
		retval = nil;
	return retval;
}


- (NSString *) message
{
	NSString* retval = mMessage;
	if (0 == [retval length])
		retval = nil;
	return retval;
}


- (NSString *) address
{
	NSString *retval = mAddress;
	if (0 == [retval length])
		retval = nil;
	return retval;
}


- (void) setUsername: (NSString *) aString
{
	if (mUsername != aString)
	{
		[mUsername release];
		mUsername = [aString retain];
	}
}


- (void) setPassword: (NSString *) aString
{
	if (mPassword != aString)
	{
		[mPassword release];
		mPassword = [aString retain];
	}
}


- (void) setMessage: (NSString *) aString
{
	if (mMessage != aString)
	{
		[mMessage release];
		mMessage = [aString retain];
	}
}


- (void) setAddress: (NSString *) aString
{
	if (mAddress != aString)
	{
		[mAddress release];
		mAddress = [aString retain];
	}
}


- (void) observeValueForKeyPath: (NSString *) keyPath ofObject: (id) object change: (NSDictionary *) change context: (void *) context
{
    if (kNSKVOContext == context) 
	{
		BOOL isVisible = [self isVisible];
		NSRect frame = [self frame];
		id oldMessage = [change objectForKey: NSKeyValueChangeOldKey];
		id newMessage = [change objectForKey: NSKeyValueChangeNewKey];
		if ([NSNull null] == oldMessage)
			oldMessage = nil;
		if ([NSNull null] == newMessage)
			newMessage = nil;
				
		if (![oldMessage length] && [newMessage length])
		{
			frame.size.height += kSizeDiff;
			frame.origin.y -= kSizeDiff;
		}
		else if ([oldMessage length] && ![newMessage length])
		{
			frame.size.height -= kSizeDiff;
			frame.origin.y += kSizeDiff;
		}
		
		[self setFrame: frame display: isVisible animate: isVisible];
	}
	else 
	{
		[super observeValueForKeyPath: keyPath ofObject: object change: change context: context];
	}
}
@end



@implementation BXAuthenticationPanel (IBActions)
- (IBAction) authenticate: (id) sender
{
	[mDelegate authenticationPanel: self gotUsername: mUsername password: mPassword];
	[self setAuthenticating: YES];
	[self setPassword: nil];
}


- (void) cancelAuthentication2
{
	if (mIsAuthenticating)
	{
		[mDelegate authenticationPanelCancel: self];
		[self setAuthenticating: NO];
	}
	else
	{
		[mDelegate authenticationPanelEndPanel: self];
	}
}


- (IBAction) cancelAuthentication: (id) sender
{
	//This is required, if we don't want the cancel button to stay highlighted.
	//Tested with NSButtons as well as a matrix of NSButtonCells.
	NSRunLoop* rl = [NSRunLoop currentRunLoop];
	NSArray* modes = [NSArray arrayWithObjects: NSDefaultRunLoopMode, NSModalPanelRunLoopMode, nil];
	[rl performSelector: @selector (cancelAuthentication2) target: self argument: nil order: NSUIntegerMax modes: modes];
}
@end
