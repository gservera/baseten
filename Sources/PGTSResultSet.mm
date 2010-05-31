//
// PGTSResultSet.m
// BaseTen
//
// Copyright (C) 2008 Marko Karppinen & Co. LLC.
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

#import <stdlib.h>
#import <limits.h>
#import <BaseTen/libpq-fe.h>
#import "PGTSConnection.h"
#import "PGTSResultSet.h"
#import "PGTSConstants.h"
#import "PGTSDatabaseDescription.h"
#import "PGTSTableDescription.h"
#import "PGTSColumnDescription.h"
#import "PGTSTypeDescription.h"
#import "PGTSFoundationObjects.h"
#import "PGTSAdditions.h"
#import "BXCollectionFunctions.h"
#import "BXLogger.h"
#import "BXArraySize.h"


using namespace BaseTen;


static NSString*
ErrorUserInfoKey (char fieldCode)
{
    NSString* retval = nil;
    switch (fieldCode)
    {
        case PG_DIAG_SEVERITY:
            retval = kPGTSErrorSeverity;
            break;
            
        case PG_DIAG_SQLSTATE:
            retval = kPGTSErrorSQLState;
            break;
            
        case PG_DIAG_MESSAGE_PRIMARY:
            retval = kPGTSErrorPrimaryMessage;
            break;
            
        case PG_DIAG_MESSAGE_DETAIL:
            retval = kPGTSErrorDetailMessage;
            break;
            
        case PG_DIAG_MESSAGE_HINT:
            retval = kPGTSErrorHint;
            break;
            
        case PG_DIAG_INTERNAL_QUERY:
            retval = kPGTSErrorInternalQuery;
            break;
            
        case PG_DIAG_CONTEXT:
            retval = kPGTSErrorContext;
            break;
            
        case PG_DIAG_SOURCE_FILE:
            retval = kPGTSErrorSourceFile;
            break;
            
        case PG_DIAG_SOURCE_FUNCTION:
            retval = kPGTSErrorSourceFunction;
            break;
            
        case PG_DIAG_STATEMENT_POSITION:
            retval = kPGTSErrorStatementPosition;
            break;
            
        case PG_DIAG_INTERNAL_POSITION:
            retval = kPGTSErrorInternalPosition;
            break;
            
        case PG_DIAG_SOURCE_LINE:
            retval = kPGTSErrorSourceLine;
            break;
            
        default:
            break;
    }
    return retval;
}



@interface PGTSResultError : NSError
{
}
@end



@interface PGTSConcreteResultSet : PGTSResultSet
{
    PGTSConnection *mConnection;
	PGresult *mResult;
    NSDictionary *mFieldIndexesByName;
    NSMutableDictionary *mFieldClassesByIndex;
	id mUserInfo;
    Class mRowClass;
    NSInteger mIdentifier;
	int mCurrentRow;
    int mFields;
    int mTuples;
    
    BOOL mKnowsFieldClasses;
    BOOL mDeterminesFieldClassesFromDB;
}
+ (id) resultWithPGresult: (PGresult *) aResult connection: (PGTSConnection *) aConnection;
- (id) initWithPGResult: (PGresult *) aResult connection: (PGTSConnection *) aConnection;
@end



@implementation PGTSResultError
- (NSString *) description
{
	return [[self userInfo] objectForKey: kPGTSErrorMessage];
}
@end



/** 
 * \internal
 * \brief Result set for a query.
 *
 * A result set contains rows that may be iterated by the user.
 */
@implementation PGTSConcreteResultSet

- (PGTSConnection *) connection
{
	id retval = nil;
	@synchronized (self)
	{
		retval = [[mConnection retain] autorelease];
	}
    return retval;
}


- (void) dealloc
{
	PQclear (mResult);
	[mFieldClassesByIndex release];
	[mFieldIndexesByName release];
    [mConnection release];
    [super dealloc];
}


- (void) finalize
{
	PQclear (mResult);
    [super finalize];
}


- (NSString *) description
{
    return [NSString stringWithFormat: @"<%@ (%p) cr: %d t: %d f: %d kc: %d ok: %d>",
        [self class], self, mCurrentRow, mTuples, mFields, mKnowsFieldClasses, [self querySucceeded]];
}


- (ExecStatusType) status
{
	ExecStatusType retval = PGRES_EMPTY_QUERY;
	@synchronized (self)
	{
		retval = PQresultStatus (mResult);
	}
	return retval;
}


- (BOOL) querySucceeded
{
    ExecStatusType s = [self status];
    return (PGRES_FATAL_ERROR != s && PGRES_BAD_RESPONSE != s);
}


+ (id) resultWithPGresult: (PGresult *) aResult connection: (PGTSConnection *) aConnection
{
	return [[[self alloc] initWithPGResult: aResult connection: aConnection] autorelease];
}


- (id) initWithPGResult: (PGresult *) result connection: (PGTSConnection *) aConnection;
{
	if ((self = [super init]))
    {
        mConnection = [aConnection retain];
        
        mResult = result;
        mCurrentRow = -1;
        mTuples = PQntuples (result);
        mFields = PQnfields (result);
		mDeterminesFieldClassesFromDB = YES;

        mFieldClassesByIndex = [[NSMutableDictionary alloc] initWithCapacity: mFields];

		{
			NSMutableDictionary *fieldIndexesByName = [NSMutableDictionary dictionaryWithCapacity: mFields];
			for (int i = 0; i < mFields; i++)
			{
				char* fname = PQfname (result, i);
				if (!fname)
				{
					mFields = i;
					break;
				}
				NSString* stringName = [NSString stringWithUTF8String: fname];
				Insert (fieldIndexesByName, stringName, i);
			}
			mFieldIndexesByName = [fieldIndexesByName copy];
		}
    }        
	return self;
}


- (void) setDeterminesFieldClassesAutomatically: (BOOL) aBool
{
	@synchronized (self)
	{
	    mDeterminesFieldClassesFromDB = aBool;
	}
}


- (void) fetchFieldDescriptions
{
	PGTSDatabaseDescription* db = [mConnection databaseDescription];
	NSDictionary* deserializationDictionary = [mConnection deserializationDictionary];
	
	@synchronized (self)
	{
		mKnowsFieldClasses = YES;
		for (int i = 0; i < mFields; i++)
		{
			PGTSTypeDescription* type = [db typeWithOid: PQftype (mResult, i)];
			NSString* name = [type name];
			Class aClass = [deserializationDictionary objectForKey: name];
			
			if (! aClass)
			{
				//Check for arrays. Other types that satisfy the condition (like int2vector and oidvector) 
				//should have an entry in deserializationDictionary, if they are used.
				if (-1 == [type length] && InvalidOid != [type elementOid])
				{
					aClass = [NSArray class];
				}
				else
				{
					//Handle other types by kind.
					switch ([type kind]) 
					{
						case 'e':
							aClass = [NSString class];
							break;
							
						case 'c':
							//FIXME: handle composite types.
						case 'd':
							//FIXME: handle domains.
						case 'p':
							//FIXME: handle pseudo-types. (On the other hand, this shouldn't get reached.)
						case 'b':
						default:
							aClass = [NSData class];					
							break;
					}				
				}
			}
			
			[self setClass: aClass forFieldAtIndex: i];
		}
	}
}


- (int) numberOfFields
{
	int retval = 0;
	@synchronized (self)
	{
		retval = mFields;
	}
	return retval;
}


- (NSArray *) resultAsArray
{
	NSMutableArray* retval = [NSMutableArray arrayWithCapacity: [self count]];
	@synchronized (self)
	{
		[self goBeforeFirstRow];
		while ([self advanceRow]) 
		{
			[retval addObject: [self currentRowAsDictionary]];
		}
	}
	return retval;
}


- (NSInteger) identifier
{
	NSInteger retval = 0;
	@synchronized (self)
	{
		retval = mIdentifier;
	}
    return retval;
}


- (void) setIdentifier: (NSInteger) anIdentifier
{
	@synchronized (self)
	{
	    mIdentifier = anIdentifier;
	}
}


- (NSString *) errorString
{
	NSString *retval = nil;
	@synchronized (self)
	{
		retval = [NSString stringWithUTF8String: PQresultErrorMessage (mResult)];
	}
	return retval;
}


- (NSError *) error
{
	NSError *retval = nil;
	@synchronized (self)
	{
		[[self class] errorForPGresult: mResult];
	}
	return retval;
}

	
- (PGresult *) PGresult
{
	PGresult *retval = NULL;
	@synchronized (self)
	{
		retval = mResult;
	}
	return retval;
}
@end



@implementation PGTSConcreteResultSet (RowAccessors)
- (BOOL) isAtEnd
{
	BOOL retval = NO;
	@synchronized (self)
	{
		retval = (mCurrentRow == mTuples - 1);
	}
    return retval;
}


- (int) currentRow
{
	int retval = 0;
	@synchronized (self)
	{
		retval = mCurrentRow;
	}
    return retval;
}


- (id <PGTSResultRowProtocol>) currentRowAsObject
{
    id retval = [[[mRowClass alloc] init] autorelease];
	
    if (retval)
        [retval PGTSSetRow: mCurrentRow resultSet: self];
    
    //We are too simple to cache and reuse these.
    return retval;
}


- (void) setRowClass: (Class) aClass
{
    if ([aClass conformsToProtocol: @protocol (PGTSResultRowProtocol)])
	{
		@synchronized (self)
		{
	        mRowClass = aClass;
		}
	}
    else
    {
        //FIXME: localize me.
        NSString* reason = @"Class %@ does not conform to protocol PGTSResultRowProtocol";
        [NSException raise: NSInvalidArgumentException 
                    format: reason, aClass];
    }
}


- (void) setValuesFromRow: (int) rowIndex target: (id) targetObject nullPlaceholder: (id) nullPlaceholder
{
	for (NSString *fieldName in [mFieldIndexesByName keyEnumerator])
	{
		int index = 0;
		FindElement (mFieldIndexesByName, fieldName, &index);
		id value = [self valueForFieldAtIndex: index row: rowIndex];
		
		if (! value)
			value = nullPlaceholder;
		
		@try
		{
			[targetObject setValue: value forKey: fieldName];
		}
		@catch (id e)
		{
		}
	}
}


/**
 * \brief Current row with field names as keys.
 *
 * NSNull is used in place of nil.
 */
- (NSDictionary *) currentRowAsDictionary
{
    NSMutableDictionary* retval = nil;
	@synchronized (self)
	{
		retval = [NSMutableDictionary dictionaryWithCapacity: mFields];
		[self setValuesFromRow: mCurrentRow target: retval nullPlaceholder: [NSNull null]];
	}
    return retval;
}


/** \brief Move to the beginning of the result set */
- (void) goBeforeFirstRow
{
    [self goToRow: -1];
}


- (BOOL) goToRow: (int) aRow
{
    BOOL retval = NO;
	@synchronized (self)
	{
		if (-1 <= aRow && aRow < mTuples)
		{
			mCurrentRow = aRow;
			retval = YES;
		}
	}
	return retval;
}


- (void) goBeforeFirstRowUsingFunction: (NSComparisonResult (*)(PGTSResultSet*, void*)) comparator context: (void *) context
								   low: (const int) low high: (const int) high
{
	int mid = round (low / 2.0 + high / 2.0);
	if (mid == high)
		[self goToRow: low];
	else
	{
		//Tail recursion.
		[self goToRow: mid];
		NSComparisonResult res = comparator (self, context);
		switch (res)
		{
			case NSOrderedAscending:
				[self goBeforeFirstRowUsingFunction: comparator context: context low: mid high: high];
				break;
				
			case NSOrderedSame:
			case NSOrderedDescending:
				[self goBeforeFirstRowUsingFunction: comparator context: context low: low high: mid];
				break;
				
			default: 
				[NSException raise: NSInternalInconsistencyException format: @"Unexpected return value from comparator."];
				break;
		}
	}
}


- (void) goBeforeFirstRowUsingFunction: (NSComparisonResult (*)(PGTSResultSet*, void*)) comparator context: (void *) context
{
	@synchronized (self)
	{
		if (! mKnowsFieldClasses && mDeterminesFieldClassesFromDB)
			[self fetchFieldDescriptions];
		
		//low is -1 because the first row might apply and -advanceRow will probably will be called after this method.
		//high is mTuples (instead of mTuples - 1) in case even the last row doesn't apply and we set it to current.
		[self goBeforeFirstRowUsingFunction: comparator context: context low: -1 high: mTuples];
	}
}


struct kv_compare_st
{
	__strong NSString* kvs_key;
	__strong id kvs_value;
};


static NSComparisonResult
KVCompare (PGTSResultSet* res, void* ctx)
{
	struct kv_compare_st* context = (struct kv_compare_st *) ctx;
	id currentValue = [res valueForKey: context->kvs_key];
	id givenValue = context->kvs_value;
	return [currentValue compare: givenValue];
}


- (void) goBeforeFirstRowWithValue: (id) value forKey: (NSString *) columnName
{
	struct kv_compare_st ctx = {columnName, value};
	[self goBeforeFirstRowUsingFunction: &KVCompare context: &ctx];
	@synchronized (self)
	{
		ExpectV (mCurrentRow == -1 || NSOrderedAscending == [[self valueForKey: columnName row: mCurrentRow] compare: value]);
		ExpectV (mCurrentRow == mTuples - 1 || NSOrderedAscending != [[self valueForKey: columnName row: mCurrentRow + 1] compare: value]);
	}
}


- (int) count
{
	int retval = 0;
	@synchronized (self)
	{
		retval = mTuples;
	}
	return retval;
}


- (unsigned long long) numberOfRowsAffectedByCommand
{
	unsigned long long retval = 0;
	@synchronized (self)
	{
		retval = strtoull (PQcmdTuples (mResult), NULL, 10);
	}
	return retval;
}


- (BOOL) advanceRow
{
    BOOL retval = NO;
	
	@synchronized (self)
	{
		if (! mKnowsFieldClasses && mDeterminesFieldClassesFromDB)
			[self fetchFieldDescriptions];
		
		//Row numbering is zero-based.
		//The number is initially -1. 
		if (mCurrentRow < mTuples - 1)
		{
			mCurrentRow++;
			retval = YES;
		}
	}
	return retval;
}


- (void) setUserInfo: (id) userInfo
{
	@synchronized (self)
	{
		if (mUserInfo != userInfo)
		{
			[mUserInfo release];
			mUserInfo = [userInfo retain];
		}
	}
}


- (id) userInfo
{
	id retval = nil;
	@synchronized (self)
	{
		retval = [[mUserInfo retain] autorelease];
	}
	return retval;
}
@end



@implementation PGTSConcreteResultSet (FieldAccessors)
/**
 * \brief Set the class that should be used with a specific field.
 * @{
 */
- (BOOL) setClass: (Class) aClass forKey: (NSString *) aName
{
    BOOL retval = NO;
	int idx = 0;
	if (FindElement (mFieldIndexesByName, aName, &idx))
		retval = [self setClass: aClass forFieldAtIndex: idx];
	return retval;
}


- (BOOL) setClass: (Class) aClass forFieldAtIndex: (int) fieldIndex
{
    BOOL retval = NO;
	@synchronized (self)
	{
		if (fieldIndex < mFields)
		{
			Insert (mFieldClassesByIndex, fieldIndex, aClass);
			retval = YES;
		}
	}
    return retval;
}
/** @} */


- (id) valueForFieldAtIndex: (int) columnIndex row: (int) rowIndex
{
    id retval = nil;
	PGTSDatabaseDescription *db = [mConnection databaseDescription];
	@synchronized (self)
	{
		if (! ((columnIndex < mFields) && (-1 < rowIndex) && (rowIndex < mTuples)))
		{
			[NSException raise: kPGTSFieldNotFoundException format: @"No field for index %d.", columnIndex];
		}
		
		if (! PQgetisnull (mResult, rowIndex, columnIndex))
		{
			Class objectClass = FindObject (mFieldClassesByIndex, columnIndex);
			if (! objectClass)
				objectClass = [NSData class];
			char* value = PQgetvalue (mResult, rowIndex, columnIndex);
			PGTSTypeDescription* typeDesc = [db typeWithOid: PQftype (mResult, columnIndex)];
			retval = [[objectClass copyForPGTSResultSet: self withCharacters: value type: typeDesc columnIndex: columnIndex] autorelease];
		}
	}
    return retval;
}


- (id) valueForFieldAtIndex: (int) columnIndex
{
	id retval = nil;
	@synchronized (self)
	{
		retval = [self valueForFieldAtIndex: columnIndex row: mCurrentRow];
	}
    return retval;
}


- (id) valueForKey: (NSString *) aName row: (int) rowIndex
{
	id retval = nil;
	int columnIndex = 0;
	if (! FindElement (mFieldIndexesByName, aName, &columnIndex))
	{
		@throw [NSException exceptionWithName: kPGTSFieldNotFoundException reason: nil 
									 userInfo: [NSDictionary dictionaryWithObjectsAndKeys:
												aName, kPGTSFieldnameKey,
												self,  kPGTSResultSetKey,
												nil]];
	}
	retval = [self valueForFieldAtIndex: columnIndex row: rowIndex];
    return retval;
}

- (id) valueForKey: (NSString *) aName
{
	id retval = nil;
	@synchronized (self)
	{
		retval = [self valueForKey: aName row: mCurrentRow];
	}
    return retval;
}
@end



@implementation PGTSResultSet
+ (id) resultWithPGresult: (PGresult *) aResult connection: (PGTSConnection *) aConnection
{
    return [[[PGTSConcreteResultSet alloc] initWithPGResult: aResult connection: aConnection] autorelease];
}


+ (NSError *) errorForPGresult: (PGresult *) result
{
	NSError* retval = nil;
	ExecStatusType status = PQresultStatus (result);
	if (PGRES_FATAL_ERROR == status || PGRES_NONFATAL_ERROR == status)
	{
		char fields [] = {
			PG_DIAG_SEVERITY,
			PG_DIAG_SQLSTATE,
			PG_DIAG_MESSAGE_PRIMARY,
			PG_DIAG_MESSAGE_DETAIL,
			PG_DIAG_MESSAGE_HINT,
			PG_DIAG_STATEMENT_POSITION,
			PG_DIAG_INTERNAL_POSITION,
			PG_DIAG_INTERNAL_QUERY,
			PG_DIAG_CONTEXT,
			PG_DIAG_SOURCE_FILE,
			PG_DIAG_SOURCE_LINE,
			PG_DIAG_SOURCE_FUNCTION
		};
		
		NSMutableDictionary* userInfo = [NSMutableDictionary dictionaryWithCapacity: BXArraySize (fields)];
		
		for (int i = 0, count = BXArraySize (fields); i < count; i++)
		{
			char* value = PQresultErrorField (result, fields [i]);
			if (! value) continue;
			
			id objectValue = nil;
			switch (fields [i])
			{
				case PG_DIAG_SEVERITY: //FIXME: perhaps add the severity as a constant number?
				case PG_DIAG_SQLSTATE:
				case PG_DIAG_MESSAGE_PRIMARY:
				case PG_DIAG_MESSAGE_DETAIL:
				case PG_DIAG_MESSAGE_HINT:
				case PG_DIAG_INTERNAL_QUERY:
				case PG_DIAG_CONTEXT:
				case PG_DIAG_SOURCE_FILE:
				case PG_DIAG_SOURCE_FUNCTION:
				{
					objectValue = [NSString stringWithUTF8String: value];
					break;
				}
					
				case PG_DIAG_STATEMENT_POSITION:
				case PG_DIAG_INTERNAL_POSITION:
				case PG_DIAG_SOURCE_LINE:
				{
					long longValue = strtol (value, NULL, 10);
					objectValue = [NSNumber numberWithLong: longValue];
					break;
				}
					
				default:
					continue;
			}
			NSString* key = ErrorUserInfoKey (fields [i]);
			if (objectValue && key) [userInfo setObject: objectValue forKey: key];
		}
		
		{
			//Human-readable error message.
			NSString* message = [NSString stringWithUTF8String: PQresultErrorMessage (result)];
			[userInfo setObject: message forKey: kPGTSErrorMessage];
			//FIXME: I'm not quite sure which key should have the human-readable message and what should be made the exception name.
			[userInfo setObject: message forKey: NSLocalizedFailureReasonErrorKey];
			[userInfo setObject: message forKey: NSLocalizedRecoverySuggestionErrorKey];
		}
		
		retval = [[PGTSResultError alloc] initWithDomain: kPGTSErrorDomain code: kPGTSUnsuccessfulQueryError userInfo: userInfo];
		[retval autorelease];
	}
	return retval;
}
@end
