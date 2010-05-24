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
#import "BXLogger.h"
#import <sys/socket.h>
#import <arpa/inet.h>



static void
NetworkStatusChanged (SCNetworkReachabilityRef target, SCNetworkConnectionFlags flags, void *observerPtr)
{
	BXSocketReachabilityObserver* observer = (BXSocketReachabilityObserver *) observerPtr;
	[[observer delegate] socketReachabilityObserver: observer networkStatusChanged: flags];
}



/**
 * \internal
 * \brief A wrapper for SCNetworkReachability.
 * \note Instances of this class can safely be used from only one thread at a time.
 */
@implementation BXSocketReachabilityObserver
+ (id) copyObserverWithSocket: (int) socket
{
	const size_t size = SOCK_MAXADDRLEN;
	
	id retval = nil;
	struct sockaddr *address     = calloc (1, size);
	struct sockaddr *peerAddress = calloc (1, size);
	socklen_t addressLength      = size;
	socklen_t peerAddressLength  = size;
	
	if (0 != getsockname (socket, address, &addressLength))
		goto bail;
	
	if (0 != getpeername (socket, peerAddress, &peerAddressLength))
		goto bail;
	
	//We don't need to monitor UNIX internal protocols and SC functions seem to return
	//bad values for them anyway.
	if (AF_UNIX == address->sa_family || AF_UNIX == peerAddress->sa_family)
		goto bail;
	
	retval = [self copyObserverWithAddress: address peerAddress: peerAddress];
	
bail:
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
	
	SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithAddressPair (kCFAllocatorDefault, address, peerAddress);
	if (! reachability)
		goto bail;
	
	retval = [[self alloc] initWithReachability: reachability];
			
bail:
	CFRelease (reachability);
	return retval;
}


- (id) initWithReachability: (SCNetworkReachabilityRef) reachability
{
	if ((self = [super init]))
	{
		mReachability = reachability;
		CFRetain (reachability);
	}
	return self;
}


- (id) init
{
	[self doesNotRecognizeSelector: _cmd];
	return nil;
}


/**
 * \brief Install the observer into a run loop.
 */
- (BOOL) install
{
	ExpectR (mRunLoop, NO);
	ExpectR (mReachability, NO);
	
	SCNetworkReachabilityContext ctx = {0, self, NULL, NULL, NULL};
	SCNetworkReachabilitySetCallback (mReachability, &NetworkStatusChanged, &ctx);
	return (SCNetworkReachabilityScheduleWithRunLoop (mReachability, mRunLoop, kCFRunLoopCommonModes) ? YES : NO);
}


/**
 * \brief Invalidate the observer and remove it from the run loop.
 */
- (void) invalidate
{
	if (mReachability && mRunLoop)
		SCNetworkReachabilityUnscheduleFromRunLoop (mReachability, mRunLoop, kCFRunLoopCommonModes);
	
	if (mReachability)
	{
		CFRelease (mReachability);
		mReachability = NULL;
	}
	
	if (mRunLoop)
	{
		CFRelease (mRunLoop);
		mRunLoop = NULL;
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
