//
// BXPGTableNotificationHandler.m
// BaseTen
//
// Copyright 2008-2009 Marko Karppinen & Co. LLC.
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

#import "BXPGTableNotificationHandler.h"
#import "BXPGAdditions.h"
#import "BXLogger.h"


@implementation BXPGTableNotificationHandler
- (void) dealloc
{
	[mEntity release];
	[mNotificationName release];
	[super dealloc];
}

- (void) prepare
{
	[super prepare];
	ExpectV (mLastCheck);
}

- (void) setEntity: (BXEntityDescription *) entity
{
	if (mEntity != entity)
	{
		[mEntity release];
		mEntity = [entity retain];
	}
}

- (void) setNotificationName: (NSString *) name
{
	if (mNotificationName != name)
	{
		[mNotificationName release];
		mNotificationName = [name retain];
	}
}
@end
