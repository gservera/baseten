//
// BXConnectionMonitor.m
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

#import "BXConnectionMonitor.h"
#import "BXSocketReachabilityObserver.h"
#import "BXSystemEventNotifier.h"
#import "BXArraySize.h"
#import "BXLogger.h"
#import "BXEnumerate.h"
#import <libkern/OSAtomic.h>



@interface BXConnectionMonitorThread : NSThread
{
	CFRunLoopRef mRunLoop;
}
@end



static NSArray*
DictionaryKeys (NSMapTable *dict)
{
	NSArray *retval = nil;
	@synchronized (dict)
	{
		retval = [[dict keyEnumerator] allObjects];
	}
	return retval;
}



@implementation BXConnectionMonitorThread
- (void) main
{
	mRunLoop = CFRunLoopGetCurrent ();
	
	NSPort *port = [[NSPort alloc] init];
	[port scheduleInRunLoop: [NSRunLoop currentRunLoop] forMode: NSDefaultRunLoopMode];
	
	while (1)
	{
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		SInt32 res = CFRunLoopRunInMode (kCFRunLoopDefaultMode, 0, false);
		[pool drain];

		if (kCFRunLoopRunStopped == res || kCFRunLoopRunFinished == res)
			break;
	}
	
	[port release];
	mRunLoop = NULL;
}


- (void) finalize
{
	if (mRunLoop)
		CFRunLoopStop (mRunLoop);
	
	[super finalize];
}


- (CFRunLoopRef) runLoop
{
	return mRunLoop;
}
@end



/**
 * \internal
 * \brief A façade for various event monitors.
 * \note Instances of this class may be used from multiple threads after creation.
 *       However, in-order execution isn't enforced for -clientDidConnect: and
 *       -clientWillDisconnect:.
 * \ingroup basetenutility
 */
@implementation BXConnectionMonitor
- (void) _scheduleObserver: (BXSocketReachabilityObserver *) observer
{
	[observer setRunLoop: [mMonitorThread runLoop]];
	[observer install];
}


- (void) _scheduleSystemEventNotifier: (BXSystemEventNotifier *) notifier
{
	[notifier install];
}


- (void) _processWillExit: (NSNotification *) notification
{
	for (id <BXConnectionMonitorClient> connection in DictionaryKeys (mConnections))
		[connection connectionMonitorProcessWillExit: self];
}


- (void) _systemWillSleep: (NSNotification *) notification
{
	for (id <BXConnectionMonitorClient> connection in DictionaryKeys (mConnections))
		[connection connectionMonitorSystemWillSleep: self];
}


- (void) _systemDidWake: (NSNotification *) notification
{
	for (id <BXConnectionMonitorClient> connection in DictionaryKeys (mConnections))
		[connection connectionMonitorSystemDidWake: self];
}


+ (id) sharedInstance
{
	__strong static id sharedInstance = nil;
	@synchronized (self)
	{
		if (! sharedInstance)
		{
			sharedInstance = [[BXConnectionMonitor alloc] init];
		}
	}
	return sharedInstance;
}


- (id) init
{
	if ((self = [super init]))
	{
		{
			mSystemEventNotifier = [BXSystemEventNotifier copyNotifier];
			NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
			SEL const callbacks [] = {
				@selector (_processWillExit:),
				@selector (_systemWillSleep:),
				@selector (_systemDidWake:)
			};
			NSString * const notifications [] = {
				kBXSystemEventNotifierProcessWillExitNotification,
				kBXSystemEventNotifierSystemWillSleepNotification,
				kBXSystemEventNotifierSystemDidWakeNotification
			};
			
			unsigned int count = BXArraySize (callbacks);
			Expect (BXArraySize (notifications) == count);
			for (unsigned int i = 0; i < count; i++)
				[nc addObserver: self selector: callbacks [i] name: notifications [i] object: mSystemEventNotifier];
		}
		
		mConnections = [[NSMapTable mapTableWithStrongToStrongObjects] retain];
		mMonitorThread = [[BXConnectionMonitorThread alloc] init];
		[mMonitorThread setName: @"org.basetenframework.ConnectionMonitorThread"];
		[mMonitorThread start];
		
		[self performSelector: @selector (_scheduleSystemEventNotifier:)
					 onThread: mMonitorThread 
				   withObject: mSystemEventNotifier
				waitUntilDone: NO];
	}
	return self;
}


- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	[mSystemEventNotifier invalidate];
	[mSystemEventNotifier release];
	
	CFRunLoopRef runLoop = [mMonitorThread runLoop];
	if (runLoop)
		CFRunLoopStop ([mMonitorThread runLoop]);
	
	[mMonitorThread release];
	[mConnections release];
	[super dealloc];
}


- (void) clientDidStartConnectionAttempt: (id <BXConnectionMonitorClient>) connection
{
	@synchronized (mConnections)
	{
		[mConnections setObject: [NSNull null] forKey: connection];
	}
}


- (void) clientDidFailConnectionAttempt: (id <BXConnectionMonitorClient>) connection
{
	@synchronized (mConnections)
	{
		[mConnections removeObjectForKey: connection];
	}
}


- (void) clientDidConnect: (id <BXConnectionMonitorClient>) connection
{
	int socket = [connection socketForConnectionMonitor: self];
	BXSocketReachabilityObserver *observer = [BXSocketReachabilityObserver copyObserverWithSocket: socket];
	
	if (observer)
	{
		[observer setDelegate: self];
		[observer setUserInfo: connection];
		
		[self performSelector: @selector (_scheduleObserver:) 
					 onThread: mMonitorThread
				   withObject: observer
				waitUntilDone: NO];
		
		@synchronized (mConnections)
		{
			[mConnections setObject: observer forKey: connection];
		}
		
		[observer release];
	}
}


- (void) clientWillDisconnect: (id <BXConnectionMonitorClient>) connection
{
	BXSocketReachabilityObserver *observer = nil;
	@synchronized (mConnections)
	{
		observer = [mConnections objectForKey: connection];
		[observer retain];
		[connection retain];
		[mConnections removeObjectForKey: connection];
	}
	
	if ((id) [NSNull null] != observer)
	{
		[observer invalidate];
		[observer setDelegate: nil];
	}
	
	[observer release];
	[connection release];
}


- (BOOL) clientCanSend: (id <BXConnectionMonitorClient>) connection
{
	BOOL retval = NO;
	@synchronized (mConnections)
	{
		BXSocketReachabilityObserver *observer = [mConnections objectForKey: connection];
		if ((id) kCFNull == observer)
		{
			//If we don't have an observer, it wasn't needed.
			retval = YES;
		}
		else
		{
			SCNetworkConnectionFlags flags = 0;
			if ([observer getReachabilityFlags: &flags])
			{
				if (kSCNetworkFlagsReachable & flags ||
					kSCNetworkFlagsConnectionAutomatic & flags)
				{
					retval = YES;
				}				
			}
		}
	}
	return retval;
}
@end



@implementation BXConnectionMonitor (BXSocketReachabilityObserverDelegate)
- (void) socketReachabilityObserver: (BXSocketReachabilityObserver *) observer 
			   networkStatusChanged: (SCNetworkConnectionFlags) flags
{
	[(id <BXConnectionMonitorClient>) [observer userInfo] connectionMonitor: self networkStatusChanged: flags];
}
@end