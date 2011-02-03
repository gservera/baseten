//
// PGTSACLItem.m
// BaseTen
//
// Copyright 2006-2010 Marko Karppinen & Co. LLC.
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

#import "PGTSACLItem.h"
#import "PGTSConnection.h"
#import "PGTSResultSet.h"
#import "PGTSConstants.h"
#import "PGTSDatabaseDescription.h"
#import "BXLogger.h"


@class PGTSTypeDescription;


@implementation PGTSACLItem

- (id) init
{
    if ((self = [super init]))
    {
        mPrivileges = kPGTSPrivilegeNone;
    }
    return self;
}


- (void) dealloc
{
    [mRole release];
    [mGrantingRole release];
    [super dealloc];
}


- (PGTSRoleDescription *) role
{
    return mRole;
}

- (void) setRole: (PGTSRoleDescription *) aRole
{
    if (mRole != aRole) 
	{
        [mRole release];
        mRole = [aRole retain];
    }
}

- (PGTSRoleDescription *) grantingRole
{
    return mGrantingRole; 
}

- (void) setGrantingRole: (PGTSRoleDescription *) aGrantingRole
{
    if (mGrantingRole != aGrantingRole) 
	{
        [mGrantingRole release];
        mGrantingRole = [aGrantingRole retain];
    }
}

- (enum PGTSACLItemPrivilege) privileges
{
    return mPrivileges;
}

- (void) setPrivileges: (enum PGTSACLItemPrivilege) anEnum
{
    mPrivileges = anEnum;
}

+ (id) copyForPGTSResultSet: (PGTSResultSet *) res withCharacters: (const char *) value type: (PGTSTypeDescription *) typeInfo
{        
    //Role and privileges are separated by an equals sign
    id retval = nil;
	size_t length = strlen (value) + 1;
    char* grantingRole = alloca (length);
	strlcpy (grantingRole, value, length);
    char* role = strsep (&grantingRole, "=");
    char* privileges = strsep (&grantingRole, "/");
    
    //Zero-length but not NULL
    BXAssertValueReturn (NULL != privileges && NULL != role && NULL != grantingRole, nil, @"Unable to parse privileges (%s).", value);
    
    //Role is zero-length if the privileges are for PUBLIC
    retval = [[PGTSACLItem alloc] init];
    if (0 != strlen (role))
    {
        PGTSDatabaseDescription* database = [[res connection] databaseDescription];
        
        //Remove "group " from beginning
        if (role == strstr (role, "group "))
            role = &role [6]; //6 == strlen ("group ");
        if (grantingRole == strstr (role, "group "))
            grantingRole = &grantingRole [6];
        
        [retval setRole: [database roleNamed: [NSString stringWithUTF8String: role]]];
        [retval setGrantingRole: [database roleNamed: [NSString stringWithUTF8String: grantingRole]]];
    }
    
    //Parse the privileges
    enum PGTSACLItemPrivilege userPrivileges = kPGTSPrivilegeNone;
    enum PGTSACLItemPrivilege grantOption = kPGTSPrivilegeNone;
    for (unsigned int i = 0, length = strlen (privileges); i < length; i++)
    {
        switch (privileges [i])
        {
            case 'r': //SELECT
                userPrivileges |= kPGTSPrivilegeSelect;
                grantOption = kPGTSPrivilegeSelectGrant;
                break;
            case 'w': //UPDATE
                userPrivileges |= kPGTSPrivilegeUpdate;
                grantOption = kPGTSPrivilegeUpdateGrant;
                break;
            case 'a': //INSERT
                userPrivileges |= kPGTSPrivilegeInsert;
                grantOption = kPGTSPrivilegeInsertGrant;
                break;
            case 'd': //DELETE
                userPrivileges |= kPGTSPrivilegeDelete;
                grantOption = kPGTSPrivilegeDeleteGrant;
                break;
            case 'x': //REFERENCES
                userPrivileges |= kPGTSPrivilegeReferences;
                grantOption = kPGTSPrivilegeReferencesGrant;
                break;
            case 't': //TRIGGER
                userPrivileges |= kPGTSPrivilegeTrigger;
                grantOption = kPGTSPrivilegeTriggerGrant;
                break;
            case 'X': //EXECUTE
                userPrivileges |= kPGTSPrivilegeExecute;
                grantOption = kPGTSPrivilegeExecuteGrant;
                break;
            case 'U': //USAGE
                userPrivileges |= kPGTSPrivilegeUsage;
                grantOption = kPGTSPrivilegeUsageGrant;
                break;
            case 'C': //CREATE
                userPrivileges |= kPGTSPrivilegeCreate;
                grantOption = kPGTSPrivilegeCreateGrant;
                break;
            case 'c': //CONNECT
                userPrivileges |= kPGTSPrivilegeConnect;
                grantOption = kPGTSPrivilegeConnectGrant;
                break;
            case 'T': //TEMPORARY
                userPrivileges |= kPGTSPrivilegeTemporary;
                grantOption = kPGTSPrivilegeTemporaryGrant;
                break;
            case '*': //Grant option
                userPrivileges |= grantOption;
                grantOption = kPGTSPrivilegeNone;
                break;
            default:
                break;
        }
    }
    [retval setPrivileges: userPrivileges];
    
    return retval;    
}
@end
