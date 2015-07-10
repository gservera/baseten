//
// BXSocketReachabilityObserver.h
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
