//
// PGTSMetadataStorage.m
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


@class PGTSMetadataContainer;


#import "PGTSMetadataStorage.h"
#import "PGTSMetadataContainer.h"
#import "BXLogger.h"
#import "BXDictionaryFunctions.h"


__strong static id gSharedInstance = nil;


@implementation PGTSMetadataStorage
+ (void) initialize
{
	static BOOL tooLate = NO;
	if (! tooLate)
	{
		tooLate = YES;
		[self defaultStorage];
	}
}

- (id) init
{
	if ((self = [super init]))
	{
		mMetadataByURI = BXDictionaryCreateMutableWeakNonretainedObjects ();
	}
	return self;
}


- (void) dealloc
{
	[mMetadataByURI release];
	[super dealloc];
}


+ (id) defaultStorage
{
	if (! gSharedInstance)
	{
		gSharedInstance = [[self alloc] init];
	}
	return gSharedInstance;
}


//NOT thread-safe! Intended to be used from the creating thread.
- (void) setContainerClass: (Class) aClass
{
	mContainerClass = aClass;
}


- (PGTSMetadataContainer *) metadataContainerForURI: (NSURL *) databaseURI
{
	id retval = nil;
	@synchronized (mMetadataByURI)
	{
		retval = [mMetadataByURI objectForKey: databaseURI];
		if (retval)
			[[retval retain] autorelease];
		else
		{
			retval = [[[mContainerClass alloc] initWithStorage: self key: databaseURI] autorelease];
			[mMetadataByURI setObject: retval forKey: databaseURI];
		}
	}
	return retval;
}

- (void) containerWillDeallocate: (NSURL *) key
{
	@synchronized (mMetadataByURI)
	{
		[mMetadataByURI removeObjectForKey: key];
	}
}
@end
