//
// BXSystemEventNotifier.m
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

#import "BXSystemEventNotifier.h"
#import "BXIOKitSystemEventNotifier.h"
#import "BXProbes.h"
#import "BXValidationLock.h"

#import "../BaseTenAppKit/Sources/BXAppKitSystemEventNotifier.h"
Class BXAppKitSystemEventNotifierClass = Nil;



NSString * const kBXSystemEventNotifierProcessWillExitNotification = @"kBXSystemEventNotifierProcessWillExitNotification";
NSString * const kBXSystemEventNotifierSystemWillSleepNotification = @"kBXSystemEventNotifierSystemWillSleepNotification";
NSString * const kBXSystemEventNotifierSystemDidWakeNotification   = @"kBXSystemEventNotifierSystemDidWakeNotification";



@implementation BXSystemEventNotifier
+ (void) initialize
{
	static BOOL tooLate = NO;
	if (! tooLate)
	{
		tooLate = YES;
		BXAppKitSystemEventNotifierClass = NSClassFromString (@"BXAppKitSystemEventNotifier");
	}
}


+ (id) copyNotifier
{
	id retval = nil;
	if (BXAppKitSystemEventNotifierClass)
		retval = [BXAppKitSystemEventNotifierClass copyNotifier];
	else
		retval = [BXIOKitSystemEventNotifier copyNotifier];
	
	return retval;
}


- (id) init
{
	if ([self class] == [BXSystemEventNotifier class])
		[self doesNotRecognizeSelector: _cmd];
	
	if ((self = [super init]))
	{
		mValidationLock = [[BXValidationLock alloc] init];
	}
	return self;
}


- (void) dealloc
{
	[self invalidate];
	[mValidationLock release];
	[super dealloc];
}


- (void) install
{
}


- (void) invalidate
{
	[mValidationLock invalidate];
}


- (void) processWillExit
{
	if ([mValidationLock lockIfValid])
	{
		BASETEN_BEGIN_EXIT_PREPARATION ();
		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
		[nc postNotificationName: kBXSystemEventNotifierProcessWillExitNotification object: self];
		BASETEN_END_EXIT_PREPARATION ();
		
		[mValidationLock unlock];
	}
}


- (void) systemWillSleep
{
	if ([mValidationLock lockIfValid])
	{
		BASETEN_BEGIN_SLEEP_PREPARATION ();
		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
		[nc postNotificationName: kBXSystemEventNotifierSystemWillSleepNotification object: self];
		BASETEN_END_SLEEP_PREPARATION ();
		
		[mValidationLock unlock];
	}
}


- (void) systemDidWake
{
	if ([mValidationLock lockIfValid])
	{
		BASETEN_BEGIN_WAKE_PREPARATION ();
		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
		[nc postNotificationName: kBXSystemEventNotifierSystemDidWakeNotification object: self];
		BASETEN_END_WAKE_PREPARATION ();
		
		[mValidationLock unlock];
	}
}
@end
