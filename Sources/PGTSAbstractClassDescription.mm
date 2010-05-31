//
// PGTSAbstractClassDescription.mm
// BaseTen
//
// Copyright (C) 2006-2009 Marko Karppinen & Co. LLC.
//
// Before using this software, please review the available licensing options
// by visiting http://www.karppinen.fi/baseten/licensing/ or by contacting
// us at sales@karppinen.fi. Without an additional license, this software
// may be distributed only in compliance with the GNU General Public License.
//
//
// This program is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License, version 2.0,
// as published by the Free Software Foundation.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
//
// $Id$
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
