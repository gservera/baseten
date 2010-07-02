//
// BXAppKitSystemEventNotifier.m
// BaseTen
//
// Copyright (C) 2008-2010 Marko Karppinen & Co. LLC.
//
// Before using this software, please review the available licensing options
// by visiting http://www.karppinen.fi/baseten/licensing/ or by contacting
// us at sales@karppinen.fi. Without an additional license, this software
// may be distributed only in compliance with the GNU General Public License.
//
//
// This program is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License, version 2.0,
// as published by the Free Software Foundation.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
//
// $Id$
//

#import "BXAppKitSystemEventNotifier.h"
#import <BaseTen/BXValidationLock.h>
#import <AppKit/AppKit.h>



@implementation BXAppKitSystemEventNotifier
- (void) _applicationWillTerminate: (NSNotification *) notification
{
	[self processWillExit];
}


- (void) _workspaceWillSleep: (NSNotification *) notification
{
	[self systemWillSleep];
}


- (void) _workspaceDidWake: (NSNotification *) notification
{
	[self systemDidWake];
}


+ (id) copyNotifier
{
	return [[self alloc] init];
}


- (id) init
{
	if ((self = [super init]))
	{
		NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
		[nc addObserver: self 
			   selector: @selector (_applicationWillTerminate:)
				   name: NSApplicationWillTerminateNotification 
				 object: NSApp];
		
		nc = [[NSWorkspace sharedWorkspace] notificationCenter];
		[nc addObserver: self 
			   selector: @selector (_workspaceWillSleep:) 
				   name: NSWorkspaceWillSleepNotification 
				 object: nil];
		[nc addObserver: self 
			   selector: @selector (_workspaceDidWake:) 
				   name: NSWorkspaceDidWakeNotification 
				 object: nil];
	}
	return self;
}


- (void) dealloc
{
	[self invalidate];
	
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	[[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver: self];
	
	[super dealloc];
}
@end
