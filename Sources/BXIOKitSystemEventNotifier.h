//
// BXIOKitSystemEventNotifier.h
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

#import <BaseTen/BXSystemEventNotifier.h>
#import <IOKit/pwr_mgt/IOPMLib.h>
#import <IOKit/IOMessage.h>


@interface BXIOKitSystemEventNotifier : BXSystemEventNotifier
{
	CFRunLoopRef mRunLoop;
	CFRunLoopSourceRef mRunLoopSource;
	IONotificationPortRef mIONotificationPort;
	io_object_t mIONotifier;
	io_connect_t mIOPowerSession;
}
- (void) invalidate;
- (io_connect_t) IOPowerSession;
@end
