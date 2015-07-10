//
// PGTSAbstractObjectDescription.mm
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

#import "PGTSAbstractObjectDescription.h"


@implementation PGTSAbstractObjectDescription
- (id) init
{
    if ((self = [super init]))
    {
        mOid = InvalidOid;
    }
    return self;
}

- (NSString *) description
{
	id retval = nil;
	@synchronized (self)
	{
    	retval = [NSString stringWithFormat: @"<%@ (%p) %@ (%u)>", [self class], self, mName, mOid];
	}
	return retval;
}

- (Oid) oid
{
    return mOid;
}

- (void) setOid: (Oid) anOid
{
    mOid = anOid;
}

- (NSUInteger) hash
{
    if (0 == mHash)
        mHash = ([mName hash] ^ mOid);
    return mHash;
}

- (BOOL) isEqual: (PGTSAbstractObjectDescription *) anObject
{
    return ([super isEqual: anObject] && anObject->mOid == mOid); 
}
@end
