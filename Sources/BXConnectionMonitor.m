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
DictionaryKeys (CFDictionaryRef dict)
{
	NSArray *retval = nil;
	@synchronized ((id) dict)
	{
		retval = [(id) dict allKeys];
	}
	return retval;
}



@implementation BXConnectionMonitorThread
- (void) main
{
	mRunLoop = CFRunLoopGetCurrent ();
	
	NSPort *port = [NSPort port];
	[port scheduleInRunLoop: [NSRunLoop currentRunLoop] forMode: NSDefaultRunLoopMode];
	
	while (1)
	{
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		SInt32 res = CFRunLoopRunInMode (kCFRunLoopDefaultMode, 0, false);
		[pool drain];

		if (kCFRunLoopRunStopped == res || kCFRunLoopRunFinished == res)
			break;
	}
	
	mRunLoop = NULL;
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
		
		mConnections = CFDictionaryCreateMutable (kCFAllocatorDefault, 0, 
												  &kCFTypeDictionaryKeyCallBacks,
												  &kCFTypeDictionaryValueCallBacks);
		mMonitorThread = [[BXConnectionMonitorThread alloc] init];
		[mMonitorThread setName: @"org.basetenframework.ConnectionMonitorThread"];
		[mMonitorThread start];
		
		OSMemoryBarrier (); // Make sure that the variables get written.
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
	[mSystemEventNotifier release];
	
	CFRunLoopRef runLoop = [mMonitorThread runLoop];
	if (runLoop)
		CFRunLoopStop ([mMonitorThread runLoop]);
	
	[mMonitorThread release];
	
	if (mConnections)
		CFRelease (mConnections);
	
	[super dealloc];
}


- (void) finalize
{
	CFRunLoopRef runLoop = [mMonitorThread runLoop];
	if (runLoop)
		CFRunLoopStop ([mMonitorThread runLoop]);
	
	[mSystemEventNotifier invalidate];
	
	if (mConnections)
		CFRelease (mConnections);

	[super finalize];
}


- (void) clientDidStartConnectionAttempt: (id <BXConnectionMonitorClient>) connection
{
	@synchronized ((id) mConnections)
	{
		CFDictionarySetValue (mConnections, connection, kCFNull);
	}
}


- (void) clientDidFailConnectionAttempt: (id <BXConnectionMonitorClient>) connection
{
	@synchronized ((id) mConnections)
	{
		CFDictionaryRemoveValue (mConnections, connection);
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
		
		@synchronized ((id) mConnections)
		{
			CFDictionarySetValue (mConnections, connection, observer);
		}
		
		[observer release];
	}
}


- (void) clientWillDisconnect: (id <BXConnectionMonitorClient>) connection
{
	BXSocketReachabilityObserver *observer = nil;
	@synchronized ((id) mConnections)
	{
		observer = (id) CFDictionaryGetValue (mConnections, connection);
		[observer retain];
		CFDictionaryRemoveValue (mConnections, connection);
	}
	
	if ((id) kCFNull != observer)
		[observer invalidate];
	
	[observer release];
}


- (BOOL) clientCanSend: (id <BXConnectionMonitorClient>) connection
{
	BOOL retval = NO;
	@synchronized ((id) mConnections)
	{
		BXSocketReachabilityObserver *observer = (id) CFDictionaryGetValue (mConnections, connection);
		if ((id) kCFNull == observer)
		{
			//If we don't have an observer, it wasn't needed.
			retval = YES;
		}
		else
		{
			SCNetworkReachabilityFlags flags = 0;
			if ([observer getReachabilityFlags: &flags])
			{
				if (kSCNetworkReachabilityFlagsReachable & flags ||
					kSCNetworkReachabilityFlagsConnectionAutomatic & flags)
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
			   networkStatusChanged: (SCNetworkReachabilityFlags) flags
{
	[(id <BXConnectionMonitorClient>) [observer userInfo] connectionMonitor: self networkStatusChanged: flags];
}
@end