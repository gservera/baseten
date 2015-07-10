//
// BXValidationLock.m
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

#import "BXValidationLock.h"
#import "BXLogger.h"


@implementation BXValidationLock
- (id) init
{
	if ((self = [super init]))
	{
		Expect (0 == pthread_rwlock_init (&mLock, NULL));
		mIsValid = YES;
	}
	return self;
}


- (void) dealloc
{
	[self invalidate];
	[super dealloc];
}


- (BOOL) lockIfValid
{
	pthread_rwlock_rdlock (&mLock);
	if (! mIsValid)
		pthread_rwlock_unlock (&mLock);
	
	return mIsValid;
}


- (void) unlock
{
	pthread_rwlock_unlock (&mLock);
}


- (void) invalidate
{
	pthread_rwlock_wrlock (&mLock);
	mIsValid = NO;
	pthread_rwlock_unlock (&mLock);
}
@end
