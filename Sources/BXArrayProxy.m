//
// BXArrayProxy.m
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

#import "BXArrayProxy.h"
#import "BXDatabaseContext.h"
#import "BXConstants.h"


/**
 * \brief An NSArray or NSMutableArray-style self-updating container proxy.
 * \ingroup auto_containers
 */
@implementation BXArrayProxy

- (id) BXInitWithArray: (NSMutableArray *) anArray NS_RETURNS_RETAINED
{
    if ((self = [super BXInitWithArray: anArray]))
    {
		if (anArray)
	        mContainer = [anArray retain];
		else
			mContainer = [[NSMutableArray alloc] init];
        mNonMutatingClass = [NSArray class]; 
        mIsMutable = YES; //To allow sorting.
    }
    return self;
}

- (void) handleRemovedObjects: (NSArray *) objectArray
{
    [mContainer removeObjectsInArray: objectArray];
}

@end
