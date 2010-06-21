//
// BXSocketReachabilityObserver.m
// BaseTen
//
// Copyright (C) 2010 Marko Karppinen & Co. LLC.
//
// Before using this software, please review the available licensing options
// by visiting http://basetenframework.org/licensing/ or by contacting
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

#import "BXSocketReachabilityObserver.h"
#import "BXValidationLock.h"
#import "BXLogger.h"
#import <sys/socket.h>
#import <arpa/inet.h>


@interface BXSocketReachabilityObserver ()
- (void) _networkStatusChanged: (SCNetworkConnectionFlags) flags;
@end



static void
NetworkStatusChanged (SCNetworkReachabilityRef target, SCNetworkConnectionFlags flags, void *observerPtr)
{
	BXSocketReachabilityObserver* observer = (BXSocketReachabilityObserver *) observerPtr;
	[observer _networkStatusChanged: flags];
}



/**
 * \internal
 * \brief A wrapper for SCNetworkReachability.
 * \note Instances of this class can safely be used from only one thread at a time,
 *       except for the method -getReachabilityFlags:.
 */
@implementation BXSocketReachabilityObserver
+ (BOOL) getAddress: (struct sockaddr **) addressPtr forPeer: (BOOL) peerAddress ofSocket: (int) socket
{
	ExpectR (addressPtr, NO);
	ExpectR (! *addressPtr, NO);

	BOOL retval = NO;
	const size_t size = SOCK_MAXADDRLEN;
	*addressPtr = calloc (1, size);
	socklen_t addressLength = size;
	
	int status = 0;
	if (peerAddress)
		status = getpeername (socket, *addressPtr, &addressLength);
	else
		status = getsockname (socket, *addressPtr, &addressLength);
	
	if (0 == status)
		retval = YES;
	else if (*addressPtr)
		free (*addressPtr);

	return retval;
}


+ (id) copyObserverWithSocket: (int) socket
{
	id retval = nil;
	struct sockaddr *address     = NULL;
	struct sockaddr *peerAddress = NULL;
	
	if ([self getAddress: &address forPeer: NO  ofSocket: socket] &&
		[self getAddress: &peerAddress forPeer: YES ofSocket: socket])
	{
		//We don't need to monitor UNIX internal protocols and SC functions seem to return
		//bad values for them anyway.
		if (! (AF_UNIX == address->sa_family || AF_UNIX == peerAddress->sa_family))
			retval = [self copyObserverWithAddress: address peerAddress: peerAddress];
	}
	
	if (address)
		free (address);
	
	if (peerAddress)
		free (peerAddress);
	
	return retval;
}


+ (id) copyObserverWithAddress: (struct sockaddr *) address 
				   peerAddress: (struct sockaddr *) peerAddress
{
	BXSocketReachabilityObserver *retval = nil;
	
	SCNetworkReachabilityRef r1 = NULL, r2 = NULL;
	r1 = SCNetworkReachabilityCreateWithAddressPair (kCFAllocatorDefault, address, peerAddress);
	r2 = SCNetworkReachabilityCreateWithAddressPair (kCFAllocatorDefault, address, peerAddress);
	
	if (! (r1 && r2))
		goto bail;
	
	SCNetworkReachabilityRef reachabilities [] = {r1, r2};
	retval = [[self alloc] initWithReachabilities: reachabilities];

bail:
	if (r1)
		CFRelease (r1);
	
	if (r2)
		CFRelease (r2);
	
	return retval;
}


- (id) initWithReachabilities: (SCNetworkReachabilityRef [2]) reachabilities
{
	if ((self = [super init]))
	{
		mValidationLock = [[BXValidationLock alloc] init];
		
		// Apparently two SCNetworkReachabilities are needed to allow both
		// asynchronous notification and thread safe synchronous checks:
		//
		// "It is thread safe in that different threads can allocate and operate 
		// on different SCF objects. Having two threads operating on the same 
		// SCF object would be unwise."
		//
		// Retrieved from http://lists.apple.com/archives/Macnetworkprog/2005/Jul/msg00042.html
		
		mAsyncReachability = reachabilities [0];
		mSyncReachability  = reachabilities [1];
		CFRetain (mAsyncReachability);
		CFRetain (mSyncReachability);
	}
	return self;
}


- (id) init
{
	[self doesNotRecognizeSelector: _cmd];
	return nil;
}


- (void) _networkStatusChanged: (SCNetworkConnectionFlags) flags
{
	if ([mValidationLock lockIfValid])
	{
		[[self delegate] socketReachabilityObserver: self networkStatusChanged: flags];
		[mValidationLock unlock];
	}
}


/**
 * \brief Install the observer into a run loop.
 */
- (BOOL) install
{
	BOOL retval = NO;
	@synchronized (self)
	{
		if (mAsyncReachability && mRunLoop)
		{
			SCNetworkReachabilityContext ctx = {0, self, NULL, NULL, NULL};
			SCNetworkReachabilitySetCallback (mAsyncReachability, &NetworkStatusChanged, &ctx);
			if (SCNetworkReachabilityScheduleWithRunLoop (mAsyncReachability, mRunLoop, kCFRunLoopCommonModes))
				retval = YES;
		}
	}
	return retval;
}


/**
 * \brief Invalidate the observer and remove it from the run loop.
 */
- (void) invalidate
{
	[mValidationLock invalidate];
	
	if (mAsyncReachability && mRunLoop)
		SCNetworkReachabilityUnscheduleFromRunLoop (mAsyncReachability, mRunLoop, kCFRunLoopCommonModes);
	
	if (mAsyncReachability)
	{
		CFRelease (mAsyncReachability);
		mAsyncReachability = NULL;
	}
	
	if (mRunLoop)
	{
		CFRelease (mRunLoop);
		mRunLoop = NULL;
	}
	
	@synchronized (self)
	{
		if (mSyncReachability)
		{
			CFRelease (mSyncReachability);
			mSyncReachability = NULL;
		}
	}
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


- (BOOL) getReachabilityFlags: (SCNetworkConnectionFlags *) flags
{
	ExpectR (flags, NO);
	BOOL retval = NO;
	@synchronized (self)
	{
		retval = SCNetworkReachabilityGetFlags (mSyncReachability, flags);
	}
	return retval;
}


/**
 * \brief Set the run loop.
 */
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


/**
 * \brief The run loop.
 */
- (CFRunLoopRef) runLoop
{
	return mRunLoop;
}


/**
 * \brief Set the delegate.
 */
- (void) setDelegate: (id <BXSocketReachabilityObserverDelegate>) delegate
{
	mDelegate = delegate;
}


/**
 * \brief The delegate.
 */
- (id <BXSocketReachabilityObserverDelegate>) delegate
{
	return mDelegate;
}


- (void) setUserInfo: (void *) userInfo
{
	mUserInfo = userInfo;
}


- (void *) userInfo
{
	return mUserInfo;
}
@end
