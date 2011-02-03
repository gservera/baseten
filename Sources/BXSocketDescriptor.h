//
// BXSocketDescriptor.h
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
@class BXSocketDescriptor;
@class BXValidationLock;



@protocol BXSocketDescriptorDelegate <NSObject>
- (void) socketDescriptor: (BXSocketDescriptor *) desc readyForReading: (int) fd estimatedSize: (unsigned long) size;
- (void) socketDescriptor: (BXSocketDescriptor *) desc lockedSocket: (int) fd userInfo: (id) userInfo;
@end



@interface BXSocketDescriptor : NSObject
{
	BXValidationLock *mValidationLock;
	id <BXSocketDescriptorDelegate> mDelegate;
}
+ (BOOL) usesGCD;
+ (void) setUsesGCD: (BOOL) useGCD;

+ (id) copyDescriptorWithSocket: (int) socket;
- (id) initWithSocket: (int) socket;
- (void) install;
- (void) lock: (id) userInfo;
- (void) lockAndWait: (id) userInfo;
- (BOOL) isLocked;
- (void) invalidate;

- (id <BXSocketDescriptorDelegate>) delegate;
- (void) setDelegate: (id <BXSocketDescriptorDelegate>) delegate;
@end
