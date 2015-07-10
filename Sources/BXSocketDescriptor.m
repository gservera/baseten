//
// BXSocketDescriptor.m
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

#import "BXSocketDescriptorPrivate.h"
#import "BXDispatchSocketDescriptor.h"
#import "BXRunLoopSocketDesciptor.h"
#import "BXValidationLock.h"

#import <dispatch/dispatch.h>


static volatile BOOL stUsesGCD = YES;


/** 
 * \internal
 * \brief An abstract superclass for CFRunLoop and GCD based socket event sources.
 *
 * \note Instances of this class are thread safe after creation.
 * \ingroup basetenutility
 */
@implementation BXSocketDescriptor
+ (BOOL) usesGCD
{
	BOOL retval = NO;
	@synchronized (self)
	{
		retval = stUsesGCD;
	}
	return retval;
}


+ (void) setUsesGCD: (BOOL) useGCD
{
	@synchronized (self)
	{
		stUsesGCD = useGCD;
	}
}


/** 
 * \brief Instantiate an event source.
 */
+ (id) copyDescriptorWithSocket:(int)socket {
	id retval = nil;
	@synchronized (self) {
        if (stUsesGCD) {
			retval = [[BXDispatchSocketDescriptor alloc] initWithSocket: socket];
        } else {
			retval = [[BXRunLoopSocketDesciptor alloc] initWithSocket: socket];
        }
	}
	return retval;
}


- (id) initWithSocket: (int) socket
{
	if ([self class] == [BXSocketDescriptor class])
		[self doesNotRecognizeSelector: _cmd];
	
	if ((self = [super init]))
	{
		mValidationLock = [[BXValidationLock alloc] init];
	}
	return self;
}


- (void) dealloc
{
	[mValidationLock invalidate];
	[mValidationLock release];
	[super dealloc];
}


- (void) _socketReadyForReading: (int) fd estimatedSize: (unsigned long) size
{
	if ([mValidationLock lockIfValid])
	{
		[[self delegate] socketDescriptor: self readyForReading: fd estimatedSize: size];
		[mValidationLock unlock];
	}
}


/**
 * \brief Install the event source.
 * \note This method needs to be run from the thread that is going to listen to the event source.
 */
- (void) install
{
	[self doesNotRecognizeSelector: _cmd];
}


/**
 * \brief Access the socket in an asynchronous manner.
 * \param userInfo The parameter to be passed to the delegate.
 * Returns immediately. When the socket is available, calls the
 * delegate's method -socketLocked:userInfo:.
 */
- (void) lock: (id) userInfo
{
	[self doesNotRecognizeSelector: _cmd];
}


/**
 * \brief Access the socket in a synchronous manner.
 * \param userInfo The parameter to be passed to the delegate.
 * Blocks and calls the delegate's method -socketLocked:userInfo:.
 */
- (void) lockAndWait: (id) userInfo
{
	[self doesNotRecognizeSelector: _cmd];
}


/**
 * \brief Whether this is the thread that has lock on the socket.
 */
- (BOOL) isLocked
{
	[self doesNotRecognizeSelector: _cmd];
	return NO;
}


/**
 * \brief Invalidate the event source.
 */
- (void) invalidate
{
	[mValidationLock invalidate];
}


/**
 * \brief The delegate.
 */
- (id <BXSocketDescriptorDelegate>) delegate
{
	id <BXSocketDescriptorDelegate> retval = nil;
	@synchronized (self)
	{
		retval = [[mDelegate retain] autorelease];
	}
	return retval;
}


/**
 * \brief Set the delegate.
 */
- (void) setDelegate: (id <BXSocketDescriptorDelegate>) delegate
{
	@synchronized (self)
	{
		mDelegate = delegate;
	}
}
@end
