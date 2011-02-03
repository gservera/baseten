//
// BXPGNotificationHandler.m
// BaseTen
//
// Copyright 2008 Marko Karppinen & Co. LLC.
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

#import "BXPGNotificationHandler.h"
#import "BXPGAdditions.h"
#import "BXLogger.h"


@implementation BXPGNotificationHandler
- (void) dealloc
{
	[mConnection release];
	[mLastCheck release];
	[super dealloc];
}

- (void) setLastCheck: (NSDate *) aDate
{
	if (!mLastCheck || NSOrderedAscending == [mLastCheck compare: aDate])
	{
		[mLastCheck release];
		mLastCheck = [aDate retain];
	}
}

- (void) handleNotification: (PGTSNotification *) notification
{
	[self doesNotRecognizeSelector: _cmd];
}

- (void) setConnection: (PGTSConnection *) connection
{
	if (mConnection != connection)
	{
		[mConnection release];
		mConnection = [connection retain];
	}
}

- (void) setInterface: (BXPGInterface *) anInterface
{
	mInterface = anInterface;
}

- (void) prepare
{
	ExpectV (mConnection);
}
@end
