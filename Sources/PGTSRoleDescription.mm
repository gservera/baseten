//
// PGTSRoleDescription.mm
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


#import "PGTSRoleDescription.h"
#import "BXCollectionFunctions.h"
#import "BXLogger.h"


using namespace BaseTen;


@implementation PGTSRoleDescription
- (void) dealloc
{
	[mMembersByOid release];
	[super dealloc];
}


/** 
 * \brief Check if given role is member of self.
 */
- (BOOL) hasMember: (PGTSRoleDescription *) aRole
{
	ExpectR (aRole, NO);
	return (FindObject (mMembersByOid, [aRole oid]) ? YES : NO);
}


- (void) setMembers: (NSArray *) roles
{
	NSMutableDictionary *membersByOid = [[NSMutableDictionary alloc] initWithCapacity: [roles count]];
	for (PGTSRoleDescription *role in roles)
		InsertConditionally (membersByOid, [role oid], role);
	
	[mMembersByOid release];
	mMembersByOid = [membersByOid copy];
}
@end
