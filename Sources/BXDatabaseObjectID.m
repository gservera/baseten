//
// BXDatabaseObjectID.m
// BaseTen
//
// Copyright 2008-2010 Marko Karppinen & Co. LLC.
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

#import "BXDatabaseObjectModel.h"
#import "BXDatabaseObjectID.h"
#import "BXDatabaseObjectIDPrivate.h"
#import "BXEntityDescription.h"
#import "BXEntityDescriptionPrivate.h"
#import "BXDatabaseContext.h"
#import "BXInterface.h"
#import "BXAttributeDescription.h"
#import "BXDatabaseObject.h"
#import "BXDatabaseObjectPrivate.h"
#import "BXLogger.h"
#import "BXEnumerate.h"
#import "BXURLEncoding.h"
#import "BXException.h"
#import "NSURL+BaseTenAdditions.h"


/**
 * \brief A unique identifier for a database object.
 *
 * \ingroup baseten
 */
@implementation BXDatabaseObjectID

+ (NSURL *) URIRepresentationForEntity: (BXEntityDescription *) anEntity primaryKeyFields: (NSDictionary *) pkeyDict
{
    NSURL* databaseURI = [anEntity databaseURI];
    NSMutableArray* parts = [NSMutableArray arrayWithCapacity: [pkeyDict count]];
    
    //If the pkey fields are unknown, we have to trust the user on this one.
    NSArray* keys = nil;
    if ([anEntity primaryKeyFields])
    {
        NSMutableArray* temp = [NSMutableArray array];
        BXEnumerate (currentKey, e, [[anEntity primaryKeyFields] objectEnumerator])
        {
            if ([currentKey isPrimaryKey])
                [temp addObject: [currentKey name]];
        }
        [temp sortUsingSelector: @selector (compare:)];
        keys = temp;
    }
    else
    {
        keys = [pkeyDict keysSortedByValueUsingSelector: @selector (compare:)];
    }
    
    BXEnumerate (currentKey, e, [keys objectEnumerator])
    {
        id currentValue = [pkeyDict objectForKey: currentKey];
        BXAssertValueReturn ([NSNull null] != currentValue, nil, @"A pkey value was NSNull. Entity: %@", anEntity);
        
        NSString* valueForURL = @"";
        char argtype = 'd';
        //NSStrings and NSNumbers get a special treatment
        if ([currentValue isKindOfClass: [NSString class]])
        {
            valueForURL = [currentValue stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
            argtype = 's';
        }
        else if ([currentValue isKindOfClass: [NSNumber class]])
        {
            valueForURL = [currentValue stringValue];
            argtype = 'n';
        }
        else
        {
#if ! (defined (TARGET_OS_IPHONE) && TARGET_OS_IPHONE)
            //Just use NSData
            valueForURL = [NSString BXURLEncodedData: [NSArchiver archivedDataWithRootObject: currentValue]];            
#endif
        }
        
        [parts addObject: [NSString stringWithFormat: @"%@,%c=%@", 
            [currentKey stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding],
            argtype, valueForURL]];
    }
    
    NSString* absolutePath = [[NSString stringWithFormat: @"/%@/%@/%@?",
        [databaseURI path],
        [[anEntity schemaName] stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding],
        [[anEntity name] stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]] stringByStandardizingPath];
    absolutePath = [absolutePath stringByAppendingString: [parts componentsJoinedByString: @"&"]];
    
    NSURL* URIRepresentation = [[NSURL URLWithString: absolutePath relativeToURL: databaseURI] absoluteURL];
    return URIRepresentation;
}

+ (BOOL) parseURI: (NSURL *) anURI
           entity: (NSString **) outEntityName
           schema: (NSString **) outSchemaName
 primaryKeyFields: (NSDictionary **) outPkeyDict
{
    //FIXME: URI validation?
    //NSString* absoluteURI = [anURI absoluteString];
    NSString* query = [anURI query];
    NSString* path = [anURI path];
    
    NSArray* pathComponents = [path pathComponents];
    NSUInteger count = [pathComponents count];
    NSString* tableName = [pathComponents objectAtIndex: count - 1];
    NSString* schemaName = [pathComponents objectAtIndex: count - 2];
    //FIXME: object address and context address should be compared.
    //NSString* dbAddress = [absoluteURI substringToIndex: [absoluteURI length] - ([tableName length] + 1 + [query length])];
        
	NSMutableDictionary* pkeyDict = [NSMutableDictionary dictionary];
	NSScanner* queryScanner = [NSScanner scannerWithString: query];
	while (NO == [queryScanner isAtEnd])
	{
		NSString* key = nil;
		NSString* type = nil;
		id value = nil;
		
		[queryScanner scanUpToString: @"," intoString: &key];
		[queryScanner scanString: @"," intoString: NULL];
		[queryScanner scanUpToString: @"=" intoString: &type];
		[queryScanner scanString: @"=" intoString: NULL];
		
		unichar c = [type characterAtIndex: 0];
		switch (c)
		{
			case 's':
				[queryScanner scanUpToString: @"&" intoString: &value];
				value = [value stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
				break;
			case 'n':
			{
				NSDecimal dec;
				[queryScanner scanDecimal: &dec];
				value = [NSDecimalNumber decimalNumberWithDecimal: dec];
				break;
			}
			case 'd':
			{
#if ! (defined (TARGET_OS_IPHONE) && TARGET_OS_IPHONE)
				NSString* encodedString = nil;
				[queryScanner scanUpToString: @"&" intoString: &encodedString];
				NSData* archivedData = [encodedString BXURLDecodedData];
				value = [NSUnarchiver unarchiveObjectWithData: archivedData];
#endif
				break;
			}
			default:
                goto bail;
                break;
		}	
		[pkeyDict setObject: value forKey: key];
		
		[queryScanner scanUpToString: @"&" intoString: NULL];
		[queryScanner scanString: @"&" intoString: NULL];
	}
    
    if (NULL != outEntityName) *outEntityName = tableName;
    if (NULL != outSchemaName) *outSchemaName = schemaName;
    if (NULL != outPkeyDict) *outPkeyDict = pkeyDict;
    
	return YES;
	
bail:
	{
		return NO;
	}
}

/** 
 * \brief Create an object identifier from an NSURL.
 * \note This is not the designated initializer.
 */
- (id) initWithURI: (NSURL *) anURI context: (BXDatabaseContext *) context
{
    NSString* entityName = nil;
    NSString* schemaName = nil;
    NSDictionary* pkeyDict = nil;

    if ([[self class] parseURI: anURI entity: &entityName
                        schema: &schemaName primaryKeyFields: &pkeyDict])
    {
		BXEntityDescription *entity = [[context databaseObjectModel] entityForTable: entityName inSchema: schemaName];
		if (! entity)
		{
			NSError *error = [BXDatabaseObjectModel errorForMissingEntity: entityName inSchema: schemaName];
			@throw [error BXExceptionWithName: NSInvalidArgumentException];
		}
		
        [[self class] verifyPkey: pkeyDict entity: entity];
        self = [self initWithEntity: entity objectURI: anURI];
    }
    return self;
}

- (id) initWithURI: (NSURL *) anURI context: (BXDatabaseContext *) context error: (NSError **) error
{
	BXDeprecationLog ();
	return [self initWithURI: anURI context: context];
}

- (NSString *) description
{
    return [NSString stringWithFormat: @"<%@ (%p) %@>", [self class], self, [self URIRepresentation]];
}

- (void) dealloc
{
    if (YES == mRegistered)
        [mEntity unregisterObjectID: self];
    
    [mURIRepresentation release];
    [mEntity release];
    [super dealloc];
}

/** \brief The entity of the receiver. */
- (BXEntityDescription *) entity
{
    return mEntity;
}

/** \brief URI representation of the receiver. */
- (NSURL *) URIRepresentation
{
    return mURIRepresentation;
}

- (NSUInteger) hash
{
    return mHash;
}

/** 
 * \brief An NSPredicate for this object ID.
 * The predicate can be used to fetch the object from the database, for example.
 */
- (NSPredicate *) predicate
{
    NSPredicate* retval = nil;
    NSDictionary* pkeyFValues = nil;
    BOOL ok = [[self class] parseURI: mURIRepresentation entity: NULL schema: NULL primaryKeyFields: &pkeyFValues];
    if (ok)
    {
        NSDictionary* attributes = [mEntity attributesByName];
		Expect (attributes);
        NSMutableArray* predicates = [NSMutableArray arrayWithCapacity: [pkeyFValues count]];
    
        BXEnumerate (currentKey, e, [pkeyFValues keyEnumerator])
        {
            NSExpression* rhs = [NSExpression expressionForConstantValue: [pkeyFValues objectForKey: currentKey]];
            NSExpression* lhs = [NSExpression expressionForKeyPath: currentKey];
            NSPredicate* predicate = 
                [NSComparisonPredicate predicateWithLeftExpression: lhs
                                                   rightExpression: rhs
                                                          modifier: NSDirectPredicateModifier
                                                              type: NSEqualToPredicateOperatorType
                                                           options: 0];
            [predicates addObject: predicate];
        }
        
        if (0 < [predicates count])
            retval = [NSCompoundPredicate andPredicateWithSubpredicates: predicates];
    }
    
    return retval;
}

- (BOOL) isEqual: (id) anObject
{
    BOOL retval = NO;
    if (NO == [anObject isKindOfClass: [BXDatabaseObjectID class]])
        retval = [super isEqual: anObject];
    else
    {
        BXDatabaseObjectID* anId = (BXDatabaseObjectID *) anObject;
        if (0 == anId->mHash || 0 == mHash || anId->mHash == mHash)
        {
            retval = [mURIRepresentation isEqual: anId->mURIRepresentation];
        }
    }
    return retval;
}

@end


@implementation BXDatabaseObjectID (NSCopying)
/** \brief Retain on copy. */
- (id) copyWithZone: (NSZone *) zone
{
    return [self retain];
}

- (id) mutableCopyWithZone: (NSZone *) zone
{
    return [[[self class] allocWithZone: zone]
        initWithEntity: mEntity objectURI: mURIRepresentation];
}
@end


@implementation BXDatabaseObjectID (PrivateMethods)

+ (void) verifyPkey: (NSDictionary *) pkeyDict entity: (BXEntityDescription *) entity
{
    NSArray* pkeyFields = [entity primaryKeyFields];
    if (nil != pkeyFields)
    {
        BXAssertVoidReturn ([pkeyFields count] <= [pkeyDict count],
                              @"Expected to have received values for all primary key fields.");
        BXEnumerate (currentAttribute, e, [pkeyFields objectEnumerator])
        {
            BXAssertVoidReturn (nil != [pkeyDict objectForKey: [currentAttribute name]], 
                                  @"Primary key not included: %@ given: %@", currentAttribute, pkeyDict);
        }
    }
}

/** 
 * \internal
 * \name Creating object IDs */
//@{
/**
 * \internal
 * \brief A convenience method.
 */
+ (id) IDWithEntity: (BXEntityDescription *) aDesc primaryKeyFields: (NSDictionary *) pkeyFValues
{
    NSArray* keys = [pkeyFValues allKeys];
    BXEnumerate (currentKey, e, [keys objectEnumerator])
    {
        BXAssertValueReturn ([currentKey isKindOfClass: [NSString class]],
                               nil, @"Expected to receive only NSStrings as keys. Keys: %@", keys);
    }
    [self verifyPkey: pkeyFValues entity: aDesc];

    NSURL* uri = [[self class] URIRepresentationForEntity: aDesc primaryKeyFields: pkeyFValues];
    BXAssertValueReturn (nil != uri, nil, @"Expected to have received an URI.");
    return [[[[self class] alloc] initWithEntity: aDesc objectURI: uri] autorelease];
}

/** 
 * \internal
 * \brief The designated initializer.
 */
- (id) initWithEntity: (BXEntityDescription *) anEntity objectURI: (NSURL *) anURI
{
    BXAssertValueReturn (nil != anEntity, nil, @"Expected entity not to be nil.");
    BXAssertValueReturn (nil != anURI, nil, @"Expected anURI not to be nil.");
    
    if ((self = [super init]))
    {
		{
			NSString* entityName = nil;
			NSString* schemaName = nil;
			BOOL status = [[self class] parseURI: anURI entity: &entityName schema: &schemaName primaryKeyFields: NULL];
			BXAssertValueReturn (status, nil, @"Expected object URI to be parseable.");
			BXAssertValueReturn ([[anEntity name] isEqualToString: entityName], nil, @"Expected entity names to match.");
			BXAssertValueReturn ([[anEntity schemaName] isEqualToString: schemaName], nil, @"Expected schema names to match.");
		}
		
        mURIRepresentation = [anURI retain];
        mEntity = [anEntity retain];
        mRegistered = NO;
        mHash = [mURIRepresentation BXHash];
    }
    return self;
}
//@}

- (id) init
{
    //We need either an URI or an entity and primary key fields
    [self release];
    return nil;
}

- (void) setStatus: (BXObjectDeletionStatus) status forObjectRegisteredInContext: (BXDatabaseContext *) context
{
	[[context registeredObjectWithID: self] setDeleted: status];
}

- (NSDictionary *) allValues
{
	NSDictionary* retval = nil;
	BOOL ok = [[self class] parseURI: mURIRepresentation
							  entity: NULL
							  schema: NULL
					primaryKeyFields: &retval];
	BXAssertLog (ok, @"Expected URI to have been parsed correctly: %@", mURIRepresentation);
	return retval;
}

- (void) setEntity: (BXEntityDescription *) entity
{
    BXAssertVoidReturn (NO == mRegistered, @"Expected object ID not to have been registered.");
    NSString* path = [NSString stringWithFormat: @"../%@/%@?%@", 
        [entity schemaName], [entity name], [mURIRepresentation query]];
    
    mHash = 0;
    NSURL* newURI = [NSURL URLWithString: path relativeToURL: mURIRepresentation];
    [mURIRepresentation release];
    mURIRepresentation = [[newURI absoluteURL] retain];
}

@end
