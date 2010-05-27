//
// BXRunLoopSocketDesciptor.m
// BaseTen
//
// Copyright (C) 2010 Marko Karppinen & Co. LLC.
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

#import "BXRunLoopSocketDesciptor.h"
#import "BXSocketDescriptorPrivate.h"
#import "BXLogger.h"


static void
SocketReady (CFSocketRef socket, CFSocketCallBackType callbackType, CFDataRef address, const void *data, void *descriptorPtr)
{
	if (kCFSocketReadCallBack & callbackType)
	{
		BXSocketDescriptor *descriptor = (id) descriptorPtr;
		[descriptor _socketReadyForReading: CFSocketGetNative (socket) estimatedSize: 0];
	}
}



@implementation BXRunLoopSocketDesciptor
- (void) _threadWillExit: (NSNotification *) notification
{
	NSThread *thread = [notification object];
	ExpectV (thread == mThread);
	BXLogError (@"Thread %@ is exiting even though socket descriptor %p has still an event source on it.",
				mThread, self);
	[self invalidate];
}


- (id) initWithSocket: (int) socket
{
	if ((self = [super initWithSocket: socket]))
	{
		CFSocketContext context = {0, self, NULL, NULL, NULL};
		CFSocketCallBackType callbacks = (CFSocketCallBackType) (kCFSocketReadCallBack | kCFSocketWriteCallBack);
		mSocket = CFSocketCreateWithNative (NULL, socket, callbacks, &SocketReady, &context);
		
		CFOptionFlags flags = ~kCFSocketCloseOnInvalidate & CFSocketGetSocketFlags (mSocket);
		CFSocketSetSocketFlags (mSocket, flags);
		
		CFSocketDisableCallBacks (mSocket, kCFSocketWriteCallBack);
		CFSocketEnableCallBacks (mSocket, kCFSocketReadCallBack);
	}
	return self;
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


- (void) install
{
	BXAssertLog (mSocket, @"Expected source to have been created.");
	BXAssertLog (CFSocketIsValid (mSocket), @"Expected socket to be valid.");
	
	mSocketSource = CFSocketCreateRunLoopSource (NULL, mSocket, 0);
	BXAssertLog (mSocketSource, @"Expected socketSource to have been created.");
	BXAssertLog (CFRunLoopSourceIsValid (mSocketSource), @"Expected socketSource to be valid.");
	
	
	[self setThread: [NSThread currentThread]];
	[self setRunLoop: CFRunLoopGetCurrent ()];
	CFRunLoopAddSource (mRunLoop, mSocketSource, (CFStringRef) kCFRunLoopCommonModes);
}


- (void) _dispatchLockCallout: (id) userInfo
{
	ExpectL ([NSThread currentThread] == mThread);
	[mDelegate socketLocked: CFSocketGetNative (mSocket) userInfo: userInfo];
}


- (void) lock: (id) userInfo
{
	if ([self isLocked])
		[self _dispatchLockCallout: userInfo];
	else
	{
		[self performSelector: @selector (_dispatchLockCallout:)
					 onThread: mThread
				   withObject: userInfo
				waitUntilDone: NO];
	}	
}


- (void) lockAndWait: (id) userInfo
{
	if ([self isLocked])
		[self _dispatchLockCallout: userInfo];
	else
	{
		[self performSelector: @selector (_dispatchLockCallout:)
					 onThread: mThread
				   withObject: userInfo
				waitUntilDone: YES];
	}
}


- (BOOL) isLocked
{
	return [NSThread currentThread] == mThread;
}


- (void) invalidate
{
	[super invalidate];
	
	if (mSocketSource)
	{
		CFRunLoopSourceInvalidate (mSocketSource);
		CFRelease (mSocketSource);
		mSocketSource = NULL;
	}
	
	if (mSocket)
	{
		CFSocketInvalidate (mSocket);
		CFRelease (mSocket);
		mSocket = NULL;
	}	
	
	if (mRunLoop)
	{
		CFRelease (mRunLoop);
		mRunLoop = NULL;
	}
	
	[self setThread: nil];
}


- (void) setThread: (NSThread *) thread
{
	if (mThread != thread)
	{
		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
		
		if (mThread)
		{
			[nc removeObserver: self name: NSThreadWillExitNotification object: mThread];
			[mThread release];
		}
		
		mThread = [thread retain];
		if (mThread)
		{
			[nc addObserver: self 
				   selector: @selector (_threadWillExit:) 
					   name: NSThreadWillExitNotification 
					 object: mThread];
		}
	}
}


- (void) setRunLoop: (CFRunLoopRef) runLoop
{
	if (mRunLoop != runLoop)
	{
		if (mRunLoop)
			CFRelease (mRunLoop);
		
		mRunLoop = runLoop;
		
		if (mRunLoop)
			CFRetain (mRunLoop);
	}
}
@end
