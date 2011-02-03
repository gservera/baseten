//
// BXDispatchSocketDescriptor.m
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

#if defined(MAC_OS_X_VERSION_10_6) && MAC_OS_X_VERSION_10_6 <= MAC_OS_X_VERSION_MAX_ALLOWED

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
		[[self delegate] socketDescriptor: self lockedSocket: mSocket userInfo: userInfo];
		[userInfo release];
	});
}


- (void) lockAndWait: (id) userInfo
{
	if ([self isLocked])
		[[self delegate] socketDescriptor: self lockedSocket: mSocket userInfo: userInfo];
	else
	{
		dispatch_sync (mQueue, ^{
			[[self delegate] socketDescriptor: self lockedSocket: mSocket userInfo: userInfo];
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

#endif
