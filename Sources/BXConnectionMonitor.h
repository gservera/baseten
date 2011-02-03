//
// BXConnectionMonitor.h
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
#import <BaseTen/BXSocketReachabilityObserver.h>
#import <SystemConfiguration/SystemConfiguration.h>
@class BXConnectionMonitor;
@class BXSystemEventNotifier;
@class BXConnectionMonitorThread;
@class NSMapTable;



@protocol BXConnectionMonitorClient <NSObject>
- (int) socketForConnectionMonitor: (BXConnectionMonitor *) monitor;
- (void) connectionMonitorProcessWillExit: (BXConnectionMonitor *) monitor;
- (void) connectionMonitorSystemWillSleep: (BXConnectionMonitor *) monitor;
- (void) connectionMonitorSystemDidWake: (BXConnectionMonitor *) monitor;
- (void) connectionMonitor: (BXConnectionMonitor *) monitor
	  networkStatusChanged: (SCNetworkConnectionFlags) flags;
@end



@interface BXConnectionMonitor : NSObject 
{
	NSMapTable *mConnections;
	BXSystemEventNotifier *mSystemEventNotifier;
	BXConnectionMonitorThread *mMonitorThread;
}
+ (id) sharedInstance;

- (void) clientDidStartConnectionAttempt: (id <BXConnectionMonitorClient>) connection;
- (void) clientDidFailConnectionAttempt: (id <BXConnectionMonitorClient>) connection;
- (void) clientDidConnect: (id <BXConnectionMonitorClient>) connection;
- (void) clientWillDisconnect: (id <BXConnectionMonitorClient>) connection;
- (BOOL) clientCanSend: (id <BXConnectionMonitorClient>) connection;
@end



@interface BXConnectionMonitor (BXSocketReachabilityObserverDelegate) <BXSocketReachabilityObserverDelegate>
@end
