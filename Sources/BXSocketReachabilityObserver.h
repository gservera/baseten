//
// BXSocketReachabilityObserver.h
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

#import <Foundation/Foundation.h>
#import <SystemConfiguration/SystemConfiguration.h>
@class BXSocketReachabilityObserver;
@class BXValidationLock;



@protocol BXSocketReachabilityObserverDelegate <NSObject>
- (void) socketReachabilityObserver: (BXSocketReachabilityObserver *) observer 
			   networkStatusChanged: (SCNetworkConnectionFlags) flags;
@end



@interface BXSocketReachabilityObserver : NSObject
{
	SCNetworkReachabilityRef mSyncReachability;
	SCNetworkReachabilityRef mAsyncReachability;
	CFRunLoopRef mRunLoop;
	BXValidationLock *mValidationLock;
	id <BXSocketReachabilityObserverDelegate> mDelegate;
	void *mUserInfo;
}
+ (BOOL) getAddress: (struct sockaddr **) addressPtr forPeer: (BOOL) peerAddress ofSocket: (int) socket;

+ (id) copyObserverWithSocket: (int) socket;
+ (id) copyObserverWithAddress: (struct sockaddr *) address 
				   peerAddress: (struct sockaddr *) peerAddress;

- (id) initWithReachabilities: (SCNetworkReachabilityRef [2]) reachabilities;
- (BOOL) install;
- (void) invalidate;

- (BOOL) getReachabilityFlags: (SCNetworkConnectionFlags *) flags;
- (void) setRunLoop: (CFRunLoopRef) runLoop;
- (CFRunLoopRef) runLoop;
- (void) setDelegate: (id <BXSocketReachabilityObserverDelegate>) delegate;
- (id <BXSocketReachabilityObserverDelegate>) delegate;
- (void) setUserInfo: (void *) userInfo;
- (void *) userInfo;
@end
