//
// BXForeignKey.m
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

#import "BXForeignKey.h"
#import "BXLogger.h"
#import "BXAttributeDescription.h"
#import "BXDatabaseObjectID.h"
#import "BXDatabaseObjectIDPrivate.h"
#import "BXDatabaseObject.h"


struct srcdst_dictionary_st
{
	__strong NSMutableDictionary* sd_target;
	__strong id sd_object;
	__strong NSDictionary* sd_attributes_by_name;
};


static void
SrcDstDictionary (NSString* attributeName, NSString* objectKey, void* ctx)
{
	struct srcdst_dictionary_st* sd = (struct srcdst_dictionary_st *) ctx;
	
	NSDictionary* attrs = sd->sd_attributes_by_name;
	id object = sd->sd_object;
	BXAttributeDescription* attr = [attrs objectForKey: attributeName];
	[sd->sd_target setObject: (object ? [object primitiveValueForKey: objectKey] : [NSNull null]) forKey: attr];
}


NSMutableDictionary* 
BXFkeySrcDictionary (id <BXForeignKey> fkey, BXEntityDescription* entity, BXDatabaseObject* valuesFrom)
{
	ExpectC (fkey);
	ExpectC (entity);
	
	NSMutableDictionary* retval = [NSMutableDictionary dictionaryWithCapacity: [fkey numberOfColumns]];
	NSDictionary* attributes = [entity attributesByName];
	struct srcdst_dictionary_st ctx = {retval, valuesFrom, attributes};
	[fkey iterateColumnNames: &SrcDstDictionary context: &ctx];
	return retval;	
}


NSMutableDictionary* 
BXFkeyDstDictionaryUsing (id <BXForeignKey> fkey, BXEntityDescription* entity, BXDatabaseObject* valuesFrom)
{
	ExpectC (fkey);
	ExpectC (entity);
	
	NSMutableDictionary* retval = [NSMutableDictionary dictionaryWithCapacity: [fkey numberOfColumns]];
	NSDictionary* attributes = [entity attributesByName];
	struct srcdst_dictionary_st ctx = {retval, valuesFrom, attributes};
	[fkey iterateReversedColumnNames: &SrcDstDictionary context: &ctx];
	return retval;
}


struct object_ids_st
{
	__strong NSMutableDictionary* oi_values;
	__strong id oi_object;
	BOOL oi_fire_fault;
};

static void
ObjectIDs (NSString* name, NSString* objectKey, void* ctx)
{
	struct object_ids_st* os = (struct object_ids_st *) ctx;
	if (os->oi_values)
	{
		id value = nil;
		if (os->oi_fire_fault)
			value = [os->oi_object primitiveValueForKey: objectKey];
		else
		{
			value = [os->oi_object cachedValueForKey: objectKey];
			if ([NSNull null] == value)
				value = nil;
		}

		if (value)
			[os->oi_values setObject: value forKey: name];
		else
			os->oi_values = nil;
	}
}

BXDatabaseObjectID*
BXFkeySrcObjectID (id <BXForeignKey> fkey, BXEntityDescription* entity, BXDatabaseObject* valuesFrom, BOOL fireFault)
{
	NSMutableDictionary* values = [NSMutableDictionary dictionaryWithCapacity: [fkey numberOfColumns]];
	struct object_ids_st ctx = {values, valuesFrom, fireFault};
	[fkey iterateColumnNames: &ObjectIDs context: &ctx];

	BXDatabaseObjectID* retval = nil;
	if (ctx.oi_values)
		retval = [BXDatabaseObjectID IDWithEntity: entity primaryKeyFields: values];
	return retval;
}

BXDatabaseObjectID*
BXFkeyDstObjectID (id <BXForeignKey> fkey, BXEntityDescription* entity, BXDatabaseObject* valuesFrom, BOOL fireFault)
{
	NSMutableDictionary* values = [NSMutableDictionary dictionaryWithCapacity: [fkey numberOfColumns]];
	struct object_ids_st ctx = {values, valuesFrom, fireFault};
	[fkey iterateReversedColumnNames: &ObjectIDs context: &ctx];
	
	BXDatabaseObjectID* retval = nil;
	if (ctx.oi_values)
		retval = [BXDatabaseObjectID IDWithEntity: entity primaryKeyFields: values];
	return retval;
}
