//
// BXWeakNotification.m
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

#import "BXWeakNotification.h"


@implementation BXWeakNotification
- (id) init
{
	//Don't call super's implementation, see NSNotification's documentation on subclassing.
	return self;
}

- (void) setObject: (id) anObject
{
	mObject = anObject;
}

- (void) setName: (NSString *) aName
{
	if (mName != aName)
	{
		[mName release];
		mName = [aName retain];
	}
}

- (NSString *) name
{
	return mName;
}

- (NSDictionary *) userInfo
{
	return mUserInfo;
}

- (id) object
{
	return mObject;
}

- (void) dealloc
{
	[mName release];
	[mUserInfo release];
	[super dealloc];
}

+ (id) notificationWithName: (NSString *) aName object: (id) anObject
{
	id retval = [[[self alloc] init] autorelease];
	[retval setName: aName];
	[retval setObject: anObject];
	return retval;
}
@end
