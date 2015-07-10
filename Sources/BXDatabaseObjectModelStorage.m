//
// BXDatabaseObjectModelStorage.m
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

#import "BXDatabaseObjectModelStorage.h"
#import "BXDatabaseObjectModel.h"
#import "BXDatabaseObjectModelPrivate.h"
#import "BXDictionaryFunctions.h"



/** 
 * \brief The database object model storage.
 * 
 * A database object model storage associates a common database object model with each database URI.
 *
 * \note This class is thread-safe.
 * \ingroup baseten
 */
@implementation BXDatabaseObjectModelStorage
__strong static volatile id gSharedInstance = nil;

+ (void) initialize
{
	static BOOL tooLate = NO;
	if (! tooLate)
	{
		tooLate = YES;
		[self defaultStorage];
	}
}


/** 
 * \brief The default storage.
 */
+ (id) defaultStorage
{
	// No synchronization needed because this gets called from +initialize.
	if (! gSharedInstance)
	{
		gSharedInstance = [[self alloc] init];
	}
	return gSharedInstance;
}


- (id) init
{
	if ((self = [super init]))
	{
		mModelsByURI = BXDictionaryCreateMutableWeakNonretainedObjects ();
	}
	return self;
}


- (void) dealloc
{
	[mModelsByURI release];
	[super dealloc];
}


/** 
 * \brief The object model for a given database URI.
 * \param databaseURI The database URI.
 * \return The common BXDatabaseObjectModel.
 */
- (BXDatabaseObjectModel *) objectModelForURI: (NSURL *) databaseURI
{
	id retval = nil;
	@synchronized (mModelsByURI)
	{
		retval = [mModelsByURI objectForKey: databaseURI];
		if (retval)
			[[retval retain] autorelease];
		else
		{
			retval = [[[BXDatabaseObjectModel alloc] initWithStorage: self key: databaseURI] autorelease];
			[mModelsByURI setObject: retval forKey: databaseURI];
		}
	}
	return retval;
}
@end



@implementation BXDatabaseObjectModelStorage (PrivateMethods)
- (void) objectModelWillDeallocate: (NSURL *) key
{
	@synchronized (mModelsByURI)
	{
		[mModelsByURI removeObjectForKey: key];
	}
}
@end
