//
// Introspection.m
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


// NOTE! This example doesn't currently work in Release build configuration. Build with Debug instead.


#import <Foundation/Foundation.h>
#import <BaseTen/BaseTen.h>

int main (int argc, const char * argv []) 
{
	int retval = 0;
	
	// We use garbage collection, so no autorelease pool is needed.
    @autoreleasepool {
        if (2 != argc)
        {
            printf ("Usage: Introspection database_uri\n");
            printf ("The URI format is pgsql://username@server/database\n");
        }
        else
        {
            NSError* error = nil;
            
            // Get the database URI from arguments and create a database context with it.
            NSString* uriString = [NSString stringWithUTF8String: argv [1]];
            NSURL* databaseURI = [NSURL URLWithString: uriString];
            BXDatabaseContext* context = [BXDatabaseContext contextWithDatabaseURI: databaseURI];
            
            // Try to connect. Since we don't have a run loop, we call -connectSync: which blocks.
            NSTimeInterval t1 = [NSDate timeIntervalSinceReferenceDate];
            if (! [context connectSync: &error])
            {
                NSLog (@"Error connecting to the database: %@", [error localizedRecoverySuggestion]);
                retval = 1;
            }
            else
            {
                // Get all entities in all schemas. Normally we would use -entityForTable:error: or -entityForTable:inSchema:error:
                // to get a specific entity, but for introspection, this method is more suitable.
                NSDictionary* schemas = [context entitiesBySchemaAndName: NO error: &error];
                
                NSTimeInterval t2 = [NSDate timeIntervalSinceReferenceDate];
                printf ("Connecting to the database took about %f seconds.\n", t2 - t1);
                
                if (! schemas)
                {
                    NSLog (@"Error fetching entities: %@", [error localizedRecoverySuggestion]);
                    retval = 1;
                }
                else
                {
                    // List all schemas in alphabetical order. The default schema is called 'public'.
                    for (NSString* schemaName in [[schemas allKeys] sortedArrayUsingSelector: @selector (caseInsensitiveCompare:)])
                    {
                        printf ("Schema %s:\n", [schemaName UTF8String]);
                        
                        // List all entities (tables and views) in the current schema.
                        NSDictionary* entities = [schemas objectForKey: schemaName];
                        for (NSString* entityName in [entities keysSortedByValueUsingSelector: @selector (caseInsensitiveCompare:)])
                        {
                            BXEntityDescription* entity = [entities objectForKey: entityName];
                            
                            // We could use -[BXEntityDescription name], too.
                            printf ("\tEntity %s", [entityName UTF8String]);
                            
                            if (! [entity isEnabled])
                                printf(" (not BaseTen enabled)");
                            
                            printf (":\n");
                            
                            
                            // Get all attributes (columns) from the current entity.
                            NSDictionary* attributes = [entity attributesByName];
                            
                            // PostgreSQL creates some hidden columns (cmin, cmax, ...) in all tables, which we don't want list here.
                            // BaseTen makes them excluded from fetches by default, so we use that as an indicator, whether
                            // an attribute should be listed or not.
                            NSUInteger excludedCount = 0;
                            for (BXAttributeDescription* attr in [attributes objectEnumerator])
                            {
                                if ([attr isExcluded])
                                    excludedCount++;
                            }
                            
                            if (excludedCount < [attributes count])
                            {
                                printf ("\t\tAttributes:\n");
                                // List all non-hidden attributes in the current entity.
                                for (NSString* attName in [[attributes allKeys] sortedArrayUsingSelector: @selector (caseInsensitiveCompare:)])
                                {
                                    BXAttributeDescription* attr = [attributes objectForKey: attName];
                                    if (! [attr isExcluded])
                                    {
                                        printf ("\t\t\t%s\t\t", [attName UTF8String]);
                                        
                                        // We also like to know, what are the Objective-C classes of fetched values and
                                        // which attributes are part of the primary key.
                                        if ([attr isPrimaryKey])
                                            printf ("pkey, ");
                                        
                                        printf ("%s\n", [[attr attributeValueClassName] UTF8String] ?: "(no type)");
                                    }
                                }
                            }
                            
                            
                            // Get all relationships from the current entity.
                            // BaseTen enabling is needed for this, so we first check, if the 
                            // entity can list its relationships.
                            if ([entity hasCapability: kBXEntityCapabilityRelationships])
                            {
                                NSDictionary* relationships = [entity relationshipsByName];
                                if ([relationships count])
                                {
                                    printf ("\t\tRelationships:\n");
                                    for (NSString* relName in [[relationships allKeys] sortedArrayUsingSelector: @selector (caseInsensitiveCompare:)])
                                    {
                                        BXRelationshipDescription* rel = [relationships objectForKey: relName];
                                        
                                        // Some relationship names are deprecated and are marked as such. We don't print them here.
                                        if (! [rel isDeprecated])
                                        {
                                            printf ("\t\t\t%s\n", [relName UTF8String]);
                                            
                                            BXRelationshipDescription* inverseRelationship = [rel inverseRelationship];
                                            BXEntityDescription* dstEntity = [rel destinationEntity];
                                            printf ("\t\t\t\t%s-to-%s\n", ([inverseRelationship isToMany] ? "Many" : "One"), ([rel isToMany] ? "many" : "one"));
                                            printf ("\t\t\t\tDestination: %s.%s\n", [[dstEntity schemaName] UTF8String], [[dstEntity name] UTF8String]);
                                            printf ("\t\t\t\tInverse relationship: %s\n", [[inverseRelationship name] UTF8String]);
                                        }
                                    }
                                }
                            }
                            printf ("\n");
                        }
                        printf ("\n");
                    }
                }
            }
        }

    }
	
    return retval;
}
