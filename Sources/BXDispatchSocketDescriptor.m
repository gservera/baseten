//
// BXDispatchSocketDescriptor.m
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

#import "BXDispatchSocketDescriptor.h"
#import "BXSocketDescriptorPrivate.h"
#import <libkern/OSAtomic.h>


@implementation BXDispatchSocketDescriptor
+ (int32_t) nextQueueIndex
{
    // No barrier needed since we are only incrementing a counter.
	static volatile int32_t idx = 0;
	return OSAtomicIncrement32 (&idx);
}


- (id) initWithSocket: (int) socket
{
	if ((self = [super initWithSocket: socket]))
	{
		mSocket = socket;
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
	NSString *delegateClassName = [[mDelegate class] description];
	
	char *identifier = NULL;
	asprintf (&identifier, "org.basetenframework.BXDispatchSocketDescriptor.%d.%s", 
			  [[self class] nextQueueIndex], [delegateClassName UTF8String]);
	if (identifier)
	{
		mQueue = dispatch_queue_create (identifier, NULL);
		mSocketSource = dispatch_source_create (DISPATCH_SOURCE_TYPE_READ, mSocket, 0, mQueue);
		
		dispatch_source_set_event_handler (mSocketSource, ^{
			unsigned long estimated = dispatch_source_get_data (mSocketSource);			
			[self _socketReadyForReading: mSocket estimatedSize: estimated];
		});
		
		// No cancellation handler because libpq manages the socket.
		
		dispatch_resume (mSocketSource);
		free (identifier);
	}
	
	[delegateClassName self];	
}


- (void) lock: (id) userInfo
{
	[userInfo retain];
	dispatch_async (mQueue, ^{
		[mDelegate socketLocked: mSocket userInfo: userInfo];
		[userInfo release];
	});
}


- (void) lockAndWait: (id) userInfo
{
	if ([self isLocked])
		[mDelegate socketLocked: mSocket userInfo: userInfo];
	else
	{
		dispatch_sync (mQueue, ^{
			[mDelegate socketLocked: mSocket userInfo: userInfo];
		});
	}
}


- (BOOL) isLocked
{
	return dispatch_get_current_queue () == mQueue;
}


- (void) invalidate
{
	[super invalidate];
	
	if (mSocketSource)
	{
		dispatch_source_cancel (mSocketSource);
		dispatch_release (mSocketSource);
		mSocketSource = NULL;
	}
	
	if (mQueue)
	{
		dispatch_release (mQueue);
		mQueue = NULL;
	}
}
@end
