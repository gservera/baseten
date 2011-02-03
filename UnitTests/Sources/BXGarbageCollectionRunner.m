//
// BXGarbageCollectionRunner.m
// BaseTen
//
// Copyright 2009-2010 Marko Karppinen & Co. LLC.
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

#import "BXGarbageCollectionRunner.h"

NSTimeInterval gRunningInterval = 0.01;


@implementation BXGarbageCollectionRunner
+ (void) install
{
	static BOOL tooLate = NO;
	if (! tooLate)
	{
		tooLate = YES;
		if ([NSGarbageCollector defaultCollector])
		{
			NSLog (@"Garbage collection is enabled; installing GC runner.");
			[NSThread detachNewThreadSelector: @selector (run) toTarget: self withObject: nil];
		}
		else
		{
			NSLog (@"Garbage collection is disabled; not installing GC runner.");
		}
	}
}

+ (void) run
{
	while (1)
	{
		[[NSGarbageCollector defaultCollector] collectExhaustively];
		[NSThread sleepForTimeInterval: gRunningInterval];
	}
}
@end
