//
// BXIOKitSystemEventNotifier.m
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

#import "BXIOKitSystemEventNotifier.h"
#import "BXLogger.h"


static CFMutableSetRef stInstances = NULL;


static void
DispatchProcessWillExit (const void *notifierPtr, void *ctx)
{
	[(id) notifierPtr processWillExit];
}


static void
ProcessWillExit ()
{
	@synchronized ([BXIOKitSystemEventNotifier class])
	{
		CFSetApplyFunction (stInstances, &DispatchProcessWillExit, NULL);
		CFRelease (stInstances);
	}
}


static void
WorkspaceWillSleep (void *refCon, io_service_t service, natural_t messageType, void *messageArgument)
{
	
	BXIOKitSystemEventNotifier *notifier = (id) refCon;
    switch (messageType)
    {
        case kIOMessageCanSystemSleep:
        case kIOMessageSystemWillSleep:
		{
			[notifier systemWillSleep];
            IOAllowPowerChange ([notifier IOPowerSession], (long) messageArgument);
            break;
		}
			
		case kIOMessageSystemHasPoweredOn:
		{
			[notifier systemDidWake];
			break;
		}
			
        default:
            break;
    }

}


@implementation BXIOKitSystemEventNotifier
- (void) _setRunLoopSource: (CFRunLoopSourceRef) source 
					  port: (IONotificationPortRef) port
				  notifier: (io_object_t) notifier
				   session: (io_connect_t) session
{
	mRunLoopSource = source;
	CFRetain (source);
	
	mIONotificationPort = port;
	mIONotifier = notifier;
	mIOPowerSession = session;	
}


- (id) _init
{
	if ((self = [super init]))
	{
	}
	return self;
}


- (id) init
{
	[self doesNotRecognizeSelector: _cmd];
	return nil;
}


+ (id) copyNotifier
{
	id retval = [[self alloc] _init];
	
	io_object_t ioNotifier = 0;
	IONotificationPortRef ioNotificationPort = NULL;
	io_connect_t ioPowerSession = IORegisterForSystemPower (retval, &ioNotificationPort, &WorkspaceWillSleep, &ioNotifier);
	if (MACH_PORT_NULL == ioPowerSession)
		goto bail;
	
	CFRunLoopSourceRef source = IONotificationPortGetRunLoopSource (ioNotificationPort);
	if (! source)
		goto bail;
	
	[retval _setRunLoopSource: source port: ioNotificationPort notifier: ioNotifier session: ioPowerSession];
	return retval;
	
bail:
	[retval release];
	return nil;
}


- (void) install
{
	ExpectV (! mRunLoop);
	ExpectV (mRunLoopSource);
	ExpectV (MACH_PORT_NULL != mIOPowerSession);
	
	mRunLoop = CFRunLoopGetCurrent ();
	CFRetain (mRunLoop);
	
	CFRunLoopAddSource (mRunLoop, mRunLoopSource, kCFRunLoopCommonModes);
	
	@synchronized ([self class])
	{
		static BOOL tooLate = NO;
		if (! tooLate)
		{
			tooLate = YES;
			
			CFSetCallBacks callbacks = {
				0,
				NULL,
				NULL,
				NULL,
				NULL,
				NULL
			};
			stInstances = CFSetCreateMutable (kCFAllocatorDefault, 0, &callbacks);
			
			atexit (&ProcessWillExit);
		}
		CFSetAddValue (stInstances, self);
	}	
}


- (void) invalidate
{
	@synchronized ([self class])
	{
		CFSetRemoveValue (stInstances, self);
	}
	
	if (mRunLoop && mRunLoopSource)
		CFRunLoopRemoveSource (mRunLoop, mRunLoopSource, kCFRunLoopCommonModes);
	
	if (mRunLoopSource)
	{
		CFRelease (mRunLoopSource);
		mRunLoopSource = NULL;
	}
	
	if (mRunLoop)
	{
		CFRelease (mRunLoop);
		mRunLoop = NULL;
	}
	
	if (MACH_PORT_NULL != mIOPowerSession)
	{
		IODeregisterForSystemPower (&mIONotifier);
		IONotificationPortDestroy (mIONotificationPort);
		mIOPowerSession = MACH_PORT_NULL;
	}
}


- (io_connect_t) IOPowerSession
{
	return mIOPowerSession;
}


- (void) dealloc
{	
	[self invalidate];
	[super dealloc];
}


- (void) finalize
{
	[self invalidate];
	[super finalize];
}
@end
