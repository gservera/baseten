//
// BXSystemEventNotifier.h
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
#import <BaseTen/BXExport.h>
@class BXValidationLock;


BX_INTERNAL NSString * const kBXSystemEventNotifierProcessWillExitNotification;
BX_INTERNAL NSString * const kBXSystemEventNotifierSystemWillSleepNotification;
BX_INTERNAL NSString * const kBXSystemEventNotifierSystemDidWakeNotification;



@interface BXSystemEventNotifier : NSObject
{
	BXValidationLock *mValidationLock;
}
+ (id) copyNotifier;
- (void) install;
- (void) invalidate;

- (void) processWillExit;
- (void) systemWillSleep;
- (void) systemDidWake;
@end
