//
// PGTSAbstractClassDescription.mm
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

#import "PGTSAbstractClassDescription.h"
#import "PGTSACLItem.h"
#import "PGTSRoleDescription.h"
#import "BXCollectionFunctions.h"
#import "BXEnumerate.h"
#import "BXLogger.h"


using namespace BaseTen;


/** 
 * \internal
 * \brief Abstract base class for database class objects.
 */
@implementation PGTSAbstractClassDescription
- (id) init
{
    if ((self = [super init]))
    {
		mRelkind = '\0';
    }
    return self;
}

- (void) dealloc
{
	[mACLItemsByRoleOid release];
    [super dealloc];
}


- (void) setACL: (NSArray *) ACL
{
	NSMutableDictionary *ACLItemsByRoleOid = [[NSMutableDictionary alloc] initWithCapacity: [ACL count]];
	for (PGTSACLItem *item in ACL)
	{
		Oid oid = [[item role] oid];
		InsertConditionally (ACLItemsByRoleOid, oid, item);		
	}
	
	[mACLItemsByRoleOid release];
	mACLItemsByRoleOid = [ACLItemsByRoleOid copy];
}


- (char) kind
{
    return mRelkind;
}

- (void) setKind: (char) kind
{
    mRelkind = kind;
}

- (BOOL) role: (PGTSRoleDescription *) aRole 
 hasPrivilege: (enum PGTSACLItemPrivilege) aPrivilege
{
	Expect (aRole);
	
    //First try the user's privileges, then PUBLIC's and last different groups'.
    //The owner has all the privileges.
    BOOL retval = (mOwner == aRole || [mOwner isEqual: aRole]);
    if (! retval)
	{
		PGTSACLItem *item = FindObject (mACLItemsByRoleOid, [aRole oid]);
        retval = (0 != (aPrivilege & [item privileges]));
	}
	
    if (! retval)
	{
        retval = (0 != (aPrivilege & [FindObject (mACLItemsByRoleOid, kPGTSPUBLICOid) privileges]));
	}
	
    if (! retval)
    {
		for (PGTSACLItem *item in mACLItemsByRoleOid)
		{
			if (aPrivilege & [item privileges] && [[item role] hasMember: aRole])
            {
                retval = YES;
                break;
            }
        }
    }
    return retval;
}
@end
