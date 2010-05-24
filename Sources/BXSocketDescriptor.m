//
// BXSocketDescriptor.m
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

#import "BXSocketDescriptor.h"
#import "BXDispatchSocketDescriptor.h"
#import "BXRunLoopSocketDesciptor.h"
#import <dispatch/dispatch.h>



/** 
 * \internal
 * \brief An abstract superclass for CFRunLoop and GCD based socket event sources.
 *
 * \note Instances of this class are thread safe after creation.
 * \ingroup basetenutility
 */
@implementation BXSocketDescriptor
/** 
 * \brief Instantiate an event source.
 */
+ (id) copyDescriptorWithSocket: (int) socket
{
	id retval = nil;
#if 0 // Enable after testing.
	if (NULL != dispatch_get_current_queue)
		retval = [[BXDispatchSocketDescriptor alloc] initWithSocket: socket];
	else
#endif
		retval = [[BXRunLoopSocketDesciptor alloc] initWithSocket: socket];
	
	return retval;
}


- (id) initWithSocket: (int) socket
{
	[self doesNotRecognizeSelector: _cmd];
	return nil;
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
	[self doesNotRecognizeSelector: _cmd];
}


/**
 * \brief The delegate.
 */
- (id <BXSocketDescriptorDelegate>) delegate
{
	id <BXSocketDescriptorDelegate> retval = nil;
	@synchronized (self)
	{
		retval = mDelegate;
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
