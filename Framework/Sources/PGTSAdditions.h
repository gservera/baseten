//
// PGTSAdditions.h
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

#import <Foundation/Foundation.h>
#import <PGTS/PGTSResultSet.h>
#import <PGTS/PGTSResultRowProtocol.h>
#import <PGTS/postgresql/libpq-fe.h> 


@class PGTSTypeInfo;

@interface NSNumber (PGTSAdditions)
- (Oid) PGTSOidValue;
@end

@interface NSString (PGTSAdditions)
- (NSString *) PGTSEscapedString: (PGTSConnection *) connection;
- (int) PGTSParameterCount;
+ (NSString *) PGTSFieldAliases: (unsigned int) count;
+ (NSString *) PGTSFieldAliases: (unsigned int) count start: (unsigned int) start;
@end

@interface NSObject (PGTSAdditions)
+ (id) newForPGTSResultSet: (PGTSResultSet *) set withCharacters: (const char *) value typeInfo: (PGTSTypeInfo *) typeInfo;
- (char *) PGTSParameterLength: (int *) length connection: (PGTSConnection *) connection;
- (NSString *) PGTSEscapedObjectParameter: (PGTSConnection *) connection;
- (NSString *) PGTSEscapedName: (PGTSConnection *) connection;
- (NSString *) PGTSQualifiedName: (PGTSConnection *) connection;
@end

@interface NSArray (PGTSAdditions)
- (NSString *) PGTSFieldnames: (PGTSConnection *) connection;
@end

@interface NSDictionary (PGTSAdditions)
- (NSString *) PGTSConnectionString;
+ (id) PGTSDeserializationDictionary;
- (NSDictionary *) PGTSFieldsSortedByTable;
- (NSString *) PGTSSetClauseParameters: (NSMutableArray *) parameters connection: (PGTSConnection *) connection;
- (NSString *) PGTSWhereClauseParameters: (NSMutableArray *) parameters connection: (PGTSConnection *) connection;
@end

@interface NSMutableDictionary (PGTSAdditions) <PGTSResultRowProtocol>
@end

@interface NSNotificationCenter (PGTSAdditions)
+ (NSNotificationCenter *) PGTSNotificationCenter;
@end

@interface NSDate (PGTSAdditions)
@end

@interface NSCalendarDate (PGTSAdditions)
@end

@interface NSURL (PGTSAdditions)
- (NSMutableDictionary *) PGTSConnectionDictionary;
@end

@interface PGTSAbstractClass : NSObject
{
}
@end

@interface PGTSFloat : PGTSAbstractClass
{
}
@end

@interface PGTSDouble : PGTSAbstractClass
{
}
@end

@interface PGTSBool : PGTSAbstractClass
{
}
@end

@interface PGTSPoint : PGTSAbstractClass
{
}
@end

@interface PGTSSize : PGTSAbstractClass
{
}
@end