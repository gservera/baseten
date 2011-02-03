//
// BXAppKitSystemEventNotifier.m
// BaseTen
//
// Copyright 2010 Marko Karppinen & Co. LLC.
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
