//
// BXDatabaseContextAdditions.m
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

#import "BXDatabaseContextAdditions.h"
#import "BXNetServiceConnector.h"
#import <Cocoa/Cocoa.h>
#import <BaseTen/BXDatabaseContextPrivate.h>
#import <BaseTen/BXDelegateProxy.h>
#import <BaseTen/BXInterface.h>
#import <SecurityInterface/SFCertificateTrustPanel.h>


@implementation BXDatabaseContext (BaseTenAppKitAdditions)
- (void) awakeFromNib
{
	[(BXDelegateProxy *) mDelegateProxy setDelegateForBXDelegateProxy: delegate];
	
	if (mConnectsOnAwake)
	{
		[modalWindow makeKeyAndOrderFront: nil];
		[[NSRunLoop currentRunLoop] performSelector: @selector (connect:)
											 target: self 
										   argument: nil
											  order: UINT_MAX
											  modes: [NSArray arrayWithObject: NSDefaultRunLoopMode]];
	}
}

- (void) displayPanelForTrust: (SecTrustRef) trust
{
	[self displayPanelForTrust: (SecTrustRef) trust modalWindow: modalWindow];
}

- (void) displayPanelForTrust: (SecTrustRef) trust modalWindow: (NSWindow *) aWindow
{
	mDisplayingSheet = YES;
	SFCertificateTrustPanel* panel = [SFCertificateTrustPanel sharedCertificateTrustPanel];
	NSBundle* appKitBundle = [NSBundle bundleWithPath: @"/System/Library/Frameworks/AppKit.framework"];
	[panel setAlternateButtonTitle: [appKitBundle localizedStringForKey: @"Cancel" value: @"Cancel" table: @"Common"]];
	
	if (aWindow)
	{
		[panel beginSheetForWindow: aWindow modalDelegate: self 
					didEndSelector: @selector (certificateTrustSheetDidEnd:returnCode:contextInfo:)
					   contextInfo: trust trust: trust message: nil];
	}
	else
	{
		NSInteger status = [panel runModalForTrust: trust message: nil];
		[self certificateTrustSheetDidEnd: nil returnCode: status contextInfo: trust];
	}
}

- (void) certificateTrustSheetDidEnd: (NSWindow *) sheet returnCode: (int) returnCode contextInfo: (void *) trust
{
	mDisplayingSheet = NO;
	BOOL accepted = (NSFileHandlingPanelOKButton == returnCode);
	[mDatabaseInterface handledTrust: (SecTrustRef) trust accepted: accepted];
	
	if (accepted)
		[self connectAsync];
	else
	{
		[self setCanConnect: YES];
		
		//FIXME: userinfo?
		NSError* error = [NSError errorWithDomain: kBXErrorDomain code: kBXErrorUserCancel userInfo: nil];
		
		NSDictionary* notificationUserInfo = [NSDictionary dictionaryWithObject: error forKey: kBXErrorKey];
		NSNotification* notification = [NSNotification notificationWithName: kBXConnectionFailedNotification object: self 
																   userInfo: notificationUserInfo];
		[mDelegateProxy databaseContext: self failedToConnect: error];
		[[self notificationCenter] postNotification: notification];
	}
}

- (id <BXConnector>) copyDefaultConnectionSetupManager
{
	return [[BXNetServiceConnector alloc] init];
}

@end
