//
// PGTSAbstractDescription.m
// BaseTen
//
// Copyright (C) 2006 Marko Karppinen & Co. LLC.
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

#import <PGTS/PGTSAbstractDescription.h>
#import <PGTS/PGTSConstants.h>


/** 
 * Abstract base class
 */
@implementation PGTSAbstractDescription

+ (BOOL) accessInstanceVariablesDirectly
{
    return NO;
}

- (id) init
{
    return [self initWithConnection: nil];
}

- (id) initWithConnection: (PGTSConnection *) aConnection
{
    if ((self = [super init]))
        [self setConnection: aConnection];
    return self;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    [name release];
    [super dealloc];
}

- (void) setName: (NSString *) aString
{
    if (aString != name)
    {
        [name release];
        name = [aString copy];
    }
}

- (PGTSConnection *) connection
{
    return connection;
}

- (void) setConnection: (PGTSConnection *) aConnection
{
    connection = aConnection;
}

- (NSString *) name
{
    return name;
}

/**
 * Copy the object
 * In reality, we only retain the object, since there should be no need to have different versions 
 * of the database object info.
 */
- (id) copyWithZone: (NSZone *) zone
{
    return [self retain];
}

- (BOOL) isEqual: (id) anObject
{
    BOOL rval = NO;
    if (NO == [anObject isKindOfClass: [self class]])
        rval = [super isEqual: anObject];
    else
    {
        PGTSAbstractDescription* anInfo = (PGTSAbstractDescription *) anObject;
        rval = ([connection isEqual: anInfo->connection] &&
                [name isEqualToString: anInfo->name]);
    }
    return rval;
}

- (unsigned int) hash
{
    if (0 == hash)
        hash = ([connection hash] ^ [name hash]);
    return hash;
}
@end