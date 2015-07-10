//
// BXNetServiceConnector.m
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


#import "BXNetServiceConnector.h"
#import "BXHostPanel.h"
#import "BXAuthenticationPanel.h"
#import "BXDatabaseContextAdditions.h"
#import <BaseTen/BaseTen.h>
#import "BXDatabaseContextPrivateARC.h"
#import <BaseTen/NSURL+BaseTenAdditions.h>
#import <BaseTen/BXLogger.h>
#import <BaseTen/BXHostResolver.h>


@interface BXNetServiceConnector ()
- (void) _endConnecting: (NSNotification *) notification;
@property (nonatomic, copy) NSString * hostName;
@end



@interface BXWindowModalNSConnectorImplementation : BXNSConnectorImplementation <BXNSConnectorImplementation>
@end



@interface BXApplicationModalNSConnectorImplementation : BXNSConnectorImplementation <BXNSConnectorImplementation>
{
	BOOL mBegunSendingPeriodicEvents;
	BOOL mHavePanel;
}
@end



static NSInvocation* MakeInvocation (const id target, const SEL selector) {
	NSMethodSignature* sig = [target methodSignatureForSelector: selector];
	NSInvocation* invocation = [NSInvocation invocationWithMethodSignature: sig];
	[invocation setSelector: selector];
	[invocation setTarget: target];
	return invocation;	
}

@implementation BXNSConnectorImplementation

- (instancetype)initWithConnector:(BXNetServiceConnector *)connector {
    self = [super init];
	if (self) {
		mConnector = connector;
	}
	return self;
}


- (void) endHostPanel: (BXHostPanel *) hostPanel
{
	[hostPanel endConnecting];
	[hostPanel setMessage: nil];	
}


- (void) endAuthenticationPanel: (BXAuthenticationPanel *) panel
{
	[panel setAuthenticating: NO];
	[panel setMessage: nil];
}
@end


@implementation BXWindowModalNSConnectorImplementation
- (void) beginConnectionAttempt
{
}


- (void) endConnectionAttempt
{
}


- (NSString *) runLoopMode
{
	return NSDefaultRunLoopMode;
}


- (void) _didPresentErrorWithRecovery: (BOOL) didRecover contextInfo: (void *) contextInfo
{
	NSInvocation* callback = MakeInvocation (mConnector, (SEL) contextInfo);
	[callback setArgument: &didRecover atIndex: 2];
	[callback invoke];
}


- (void) presentError: (NSError *) error didEndSelector: (SEL) selector
{
	[NSApp presentError: error modalForWindow: [mConnector modalWindow] delegate: self 
	 didPresentSelector: @selector (_didPresentErrorWithRecovery:contextInfo:) contextInfo: selector];
}


- (void) displayHostPanel: (BXHostPanel *) hostPanel
{
	[NSApp beginSheet: hostPanel modalForWindow: [mConnector modalWindow]
		modalDelegate: nil didEndSelector: NULL contextInfo: NULL];
}


- (void) endHostPanel: (BXHostPanel *) hostPanel
{
	[hostPanel orderOut: nil];
	[NSApp endSheet: hostPanel];
	[super endHostPanel: hostPanel];
}


- (void) displayAuthenticationPanel: (BXAuthenticationPanel *) authenticationPanel
{
	[NSApp beginSheet: authenticationPanel modalForWindow: [mConnector modalWindow]
		modalDelegate: nil didEndSelector: NULL contextInfo: NULL];
}


- (void) endAuthenticationPanel: (BXAuthenticationPanel *) authenticationPanel
{
	[authenticationPanel orderOut: nil];
	[NSApp endSheet: authenticationPanel];
	[super endAuthenticationPanel: authenticationPanel];
}
@end



@implementation BXApplicationModalNSConnectorImplementation
- (void) beginConnectionAttempt
{
	@try 
	{
		//This is rather stupid: NSApplication doesn't check if its
		//run loop should be run after a modal session but instead
		//requires some event before that happens. In other words,
		//our next connection panel won't be displayed if the user
		//doesn't click somewhere. (Initial mouse movement events are
		//discarded?!?)
		//We try to solve the problem by generating events for 
		//NSApplication, so it can happily run the run loop.
		[NSEvent startPeriodicEventsAfterDelay: 0.0 withPeriod: 0.5];
		mBegunSendingPeriodicEvents = YES;
	}
	@catch (NSException * e) 
	{
		if (! [NSInternalInconsistencyException isEqual: [e name]])
			[e raise];
	}
	@catch (id e) 
	{
		[e raise];
	}
}


- (void) endConnectionAttempt
{
	if (mBegunSendingPeriodicEvents)
		[NSEvent stopPeriodicEvents];
}


- (NSString *) runLoopMode
{
	NSString* retval = (mHavePanel ? NSModalPanelRunLoopMode : NSDefaultRunLoopMode);
	return retval;
}


- (void) presentError2: (NSError *) error callback: (SEL) selector
{
	BOOL didRecover = [(NSApplication *) NSApp presentError: error];
	NSInvocation* callback = MakeInvocation (mConnector, selector);
	[callback setArgument: &didRecover atIndex: 2];
	[callback invoke];
}


- (void) presentError: (NSError *) error didEndSelector: (SEL) selector
{
	//If we don't schedule this, the error panel won't be centered.
	NSInvocation* invocation = MakeInvocation (self, @selector (presentError2:callback:));
	[invocation setArgument: &error atIndex: 2];
	[invocation setArgument: &selector atIndex: 3];
	[invocation retainArguments];
	NSArray* modes = [NSArray arrayWithObject: NSDefaultRunLoopMode];
	[[NSRunLoop currentRunLoop] performSelector: @selector (invoke) target: invocation
									   argument: nil order: NSUIntegerMax modes: modes];
}


- (void) displayHostPanel2: (BXHostPanel *) hostPanel
{
	[hostPanel makeKeyAndOrderFront: nil];
	[hostPanel center];
	mHavePanel = YES;
	[NSApp runModalForWindow: hostPanel];
	mHavePanel = NO;
}


- (void) displayHostPanel: (BXHostPanel *) hostPanel
{
	//We need to schedule this or else we'll be filling up the stack.
	NSArray* modes = [NSArray arrayWithObject: NSDefaultRunLoopMode];
	[[NSRunLoop currentRunLoop] performSelector: @selector (displayHostPanel2:) target: self
									   argument: hostPanel order: NSUIntegerMax modes: modes];
}


- (void) endHostPanel: (BXHostPanel *) hostPanel
{
	[NSApp stopModal];
	[hostPanel orderOut: nil];
	[super endHostPanel: hostPanel];
}


- (void) displayAuthenticationPanel2: (BXAuthenticationPanel *) authenticationPanel
{
	[authenticationPanel makeKeyAndOrderFront: nil];
	[authenticationPanel center];
	mHavePanel = YES;
	[NSApp runModalForWindow: authenticationPanel];
	mHavePanel = NO;
}


- (void) displayAuthenticationPanel: (BXAuthenticationPanel *) authenticationPanel
{
	//We need to schedule this or else we'll be filling up the stack.
	NSArray* modes = [NSArray arrayWithObject: NSDefaultRunLoopMode];
	[[NSRunLoop currentRunLoop] performSelector: @selector (displayAuthenticationPanel2:) target: self
									   argument: authenticationPanel order: NSUIntegerMax modes: modes];
}


- (void) endAuthenticationPanel: (BXAuthenticationPanel *) authenticationPanel
{
	[NSApp stopModal];
	[authenticationPanel orderOut: nil];
	[super endAuthenticationPanel: authenticationPanel];
}
@end



/**
 * \brief A connection setup manager for use with Bonjour.
 *
 * Determines connection information from the database URI
 * and then presents dialogs for the missing information.
 * \note Presently one is created automatically in BXDatabaseContext::connect:.
 * \ingroup baseten_appkit
 */
@implementation BXNetServiceConnector

- (instancetype)init {
    self = [super init];
	if (self) {
		mHostResolver = [[BXHostResolver alloc] init];
		[mHostResolver setDelegate: self];
	}
	return self;
}


- (void)dealloc {
    [mHostResolver cancelResolution];
}

- (BXHostPanel *)hostPanel {
	if (! mHostPanel) {
		mHostPanel = [BXHostPanel hostPanel];
		[mHostPanel setDelegate: self];
	}
	return mHostPanel;
}


- (BXAuthenticationPanel *) authenticationPanel {
	if (! mAuthenticationPanel) {
		mAuthenticationPanel = [BXAuthenticationPanel authenticationPanel];
		[mAuthenticationPanel setDelegate: self];
	}
	
	[mAuthenticationPanel setAddress:_hostName];
	return mAuthenticationPanel;
}


- (void) endPanelUnless: (enum BXNSConnectorCurrentPanel) panel
{
	if (panel != mCurrentPanel)
	{
		switch (mCurrentPanel)
		{
			case kBXNSConnectorHostPanel:
				[mConnectorImpl endHostPanel: [self hostPanel]];
				break;
				
			case kBXNSConnectorAuthenticationPanel:
				[mConnectorImpl endAuthenticationPanel: [self authenticationPanel]];
				break;
				
			case kBXNSConnectorNoPanel:
			default:
				break;
		}
		
		mCurrentPanel = kBXNSConnectorNoPanel;
	}
}


- (void) setDatabaseContext: (BXDatabaseContext *) context
{
	NSNotificationCenter* nc = nil;
	
	if (nil != context)
	{
		nc = [context notificationCenter];
		[nc removeObserver: self name: kBXConnectionFailedNotification object: context];
		[nc removeObserver: self name: kBXConnectionSuccessfulNotification object: context];
	}
	
	if (nil != context)
	{
		mContext = context;
		nc = [mContext notificationCenter];
		[nc addObserver: self selector: @selector (_endConnecting:) 
				   name: kBXConnectionFailedNotification object: mContext];
		[nc addObserver: self selector: @selector (_endConnecting:) 
				   name: kBXConnectionSuccessfulNotification object: mContext];    
	}
}

#pragma mark Start here
- (IBAction) connect: (id) sender
{	
	mPort = -1;
	mCurrentPanel = kBXNSConnectorNoPanel;
	[mContext setStoresURICredentials: NO];
	
	if (mConnectorImpl){
		mConnectorImpl = nil;
	}
	
	if (_modalWindow)
		mConnectorImpl = [[BXWindowModalNSConnectorImplementation alloc] initWithConnector: self];
	else
		mConnectorImpl = [[BXApplicationModalNSConnectorImplementation alloc] initWithConnector: self];
	
	if (! [mContext databaseURI])
		[mContext setDatabaseURI: [NSURL URLWithString: @"pgsql:///"]];
	
	[mConnectorImpl beginConnectionAttempt];
	
	//If we have a host, try to reach it. Otherwise, display the panel.
	NSString* host = [[mContext databaseURI] host];
	if (0 < [host length])
	{
		[self setHostName: host];
		[mHostResolver setRunLoop: CFRunLoopGetCurrent ()];
		[mHostResolver setRunLoopMode: [mConnectorImpl runLoopMode]];
		[mHostResolver resolveHost: host];
	}
	else
	{
		mCurrentPanel = kBXNSConnectorHostPanel;
		[mConnectorImpl displayHostPanel: [self hostPanel]];
	}
}


- (void) hostPanelEndPanel: (id) panel
{
	mCurrentPanel = kBXNSConnectorNoPanel;
	[mConnectorImpl endHostPanel: panel];
	[self endConnectionAttempt];
}


- (void) hostPanelCancel: (id) panel
{
	[mHostResolver cancelResolution];
	[mContext disconnect];
}


- (void) hostPanel: (id) panel connectToHost: (NSString *) host port: (NSInteger) port
{
	[self setHostName: host];
	mPort = port;
	[mHostResolver setRunLoop: CFRunLoopGetCurrent ()];
	[mHostResolver setRunLoopMode: [mConnectorImpl runLoopMode]];
	[mHostResolver resolveHost: host];
}


- (void) hostResolverDidFail: (BXHostResolver *) resolver error: (NSError *) error
{
	[[self hostPanel] setMessage: [error localizedRecoverySuggestion]];
	if (kBXNSConnectorHostPanel == mCurrentPanel)
		[mHostPanel endConnecting];
	else
	{
		[self endPanelUnless: kBXNSConnectorHostPanel];
		mCurrentPanel = kBXNSConnectorHostPanel;
		[mConnectorImpl displayHostPanel: [self hostPanel]];
	}	
}


- (void) hostResolverDidSucceed: (BXHostResolver *) resolver addresses: (NSArray *) addresses
{
	//Complete the database URI. If we're allowed to use the Keychain, try to fetch some credentials.
	//If none are found, display the authentication panel. Otherwise connect.
	NSURL* oldURI = [mContext databaseURI];
	NSURL* newURI = [oldURI BXURIForHost: _hostName
									port: (-1 == mPort ? nil : [NSNumber numberWithInteger: mPort])
								database: nil
								username: nil
								password: nil];
	
	
	//Don't use -setDatabaseURIInternal: because we just got a new host name.
	//If old URI already contains the host name, the context might already
	//have given entity descriptions, and we don't want to replace the object model.
	if (! [oldURI isEqual: newURI])
		[mContext setDatabaseURI: newURI];
	
	if ([mContext usesKeychain])
		[mContext fetchPasswordFromKeychain];
	
	if (0 < [[[mContext databaseURI] user] length])
		[mContext connectAsync];
	else
	{
		[self endPanelUnless: kBXNSConnectorAuthenticationPanel];			
		mCurrentPanel = kBXNSConnectorAuthenticationPanel;
		[mConnectorImpl displayAuthenticationPanel: [self authenticationPanel]];
	}
}


- (void) authenticationPanelCancel: (id) panel
{
	//Make the context forget the password.
	NSURL* databaseURI = [mContext databaseURI];
	databaseURI = [databaseURI BXURIForHost: nil database: nil username: nil password: @""];
	[mContext setDatabaseURIInternal: databaseURI];	
	
	[mContext disconnect];
}


- (void) authenticationPanelEndPanel: (id) panel
{
	NSURL* databaseURI = [mContext databaseURI];
	databaseURI = [databaseURI BXURIForHost: nil database: nil username: @"" password: @""];
	[mContext setDatabaseURIInternal: databaseURI];
	
	[mConnectorImpl endAuthenticationPanel: panel];
	mCurrentPanel = kBXNSConnectorHostPanel;
	[mConnectorImpl displayHostPanel: [self hostPanel]];
}


- (void) authenticationPanel: (id) panel gotUsername: (NSString *) username password: (NSString *) password
{
	[mContext setStoresURICredentials: [panel shouldStorePasswordInKeychain]];
	NSURL* databaseURI = [mContext databaseURI];
	databaseURI = [databaseURI BXURIForHost: nil database: nil username: username password: password ?: @""];
	
	[mContext setDatabaseURIInternal: databaseURI];
	[mContext connectAsync];
}


- (void) databaseContext: (BXDatabaseContext *) context displayPanelForTrust: (SecTrustRef) trust
{
	[self endPanelUnless: kBXNSConnectorNoPanel];
	[context displayPanelForTrust: trust modalWindow: _modalWindow];
}


- (void) _endConnecting: (NSNotification *) notification
{	
	if ([[notification name] isEqualToString: kBXConnectionSuccessfulNotification])
	{
		[self endPanelUnless: kBXNSConnectorNoPanel];
		[self endConnectionAttempt];
	}
	else
	{	
		NSDictionary* userInfo = [notification userInfo];
		NSError* error = [userInfo objectForKey: kBXErrorKey];
		BOOL shouldReset = YES;
		BOOL presentError = YES;
		ExpectL (error);
		
		if (error && [[error domain] isEqualToString: kBXErrorDomain])
		{
			switch ([error code])
			{
				case kBXErrorAuthenticationFailed:
				{
					//FIXME: localization
					[[self authenticationPanel] setMessage: @"Authentication failed."];

					if (kBXNSConnectorAuthenticationPanel == mCurrentPanel)
						[mAuthenticationPanel setAuthenticating: NO];
					else
					{
						[self endPanelUnless: kBXNSConnectorAuthenticationPanel];
						mCurrentPanel = kBXNSConnectorAuthenticationPanel;
						[mConnectorImpl displayAuthenticationPanel: [self authenticationPanel]];
					}					
					
					shouldReset = NO;
					presentError = NO;
					break;
				}
					
				case kBXErrorSSLCertificateVerificationFailed:
					shouldReset = NO;
					presentError = NO;
					break;
					
				case kBXErrorUserCancel:
					shouldReset = YES;
					presentError = NO;
					break;
					
				default:
					shouldReset = YES;
					presentError = YES;
					break;
			}
		}
		
		if (shouldReset)
		{
			[self endPanelUnless: kBXNSConnectorNoPanel];
			if (presentError)
				[mConnectorImpl presentError: error didEndSelector: @selector (recoveredFromConnectionError:)];
			else
				[self recoveredFromConnectionError: NO];
		}
	}
}


- (void) recoveredFromConnectionError: (BOOL) didRecover
{
	if (didRecover)
	{
		[self endConnectionAttempt];
	}
	else
	{
		NSURL* databaseURI = [mContext databaseURI];
		databaseURI = [databaseURI BXURIForHost: @""
										   port: [NSNumber numberWithInteger: -1]
									   database: nil 
									   username: @""
									   password: @""];
		[mContext setDatabaseURIInternal: databaseURI];
		
		if (kBXNSConnectorHostPanel != mCurrentPanel)
		{
			mCurrentPanel = kBXNSConnectorHostPanel;
			[mConnectorImpl displayHostPanel: [self hostPanel]];
		}
	}
}


- (void) endConnectionAttempt
{
	[mConnectorImpl endConnectionAttempt];
	[mContext connectionSetupManagerFinishedAttempt];
}
@end
