//
// BXSynchronizedArrayController+IBAdditions.m
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

#import "BXSynchronizedArrayController+IBAdditions.h"
#import "BXSynchronizedArrayControllerInspector.h"
#import "BXIBPlugin.h"


@implementation BXSynchronizedArrayController (IBAdditions)

- (void) ibPopulateKeyPaths: (NSMutableDictionary *) keyPaths
{
    [super ibPopulateKeyPaths: keyPaths];
    
    [[keyPaths objectForKey: IBAttributeKeyPaths] addObjectsFromArray: [NSArray arrayWithObjects:
        @"tableName", @"schemaName", @"databaseObjectClassName", @"fetchesAutomatically", @"fetchPredicate", nil]];
    [[keyPaths objectForKey: IBToOneRelationshipKeyPaths] addObjectsFromArray: [NSArray arrayWithObjects:
        @"databaseContext", @"modalWindow", nil]];
}

- (void) ibPopulateAttributeInspectorClasses: (NSMutableArray *) classes
{
    [super ibPopulateAttributeInspectorClasses: classes];
    [classes addObject: [BXSynchronizedArrayControllerInspector class]];
	
	//Get rid of the object controller inspector.
	[classes removeObjectAtIndex: 0];
}

- (BOOL) validateIBFetchPredicate: (id *) ioValue error: (NSError **) outError 
{
	BOOL retval = NO;
	@try
	{
		NSString* predicateString = *ioValue;
		NSPredicate* predicate = nil;		
		if ([predicateString length] > 0)
			predicate = [NSPredicate predicateWithFormat: predicateString argumentArray: nil];
		*ioValue = predicate;
		retval = YES;
	}
	@catch (NSException* e)
	{
        NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
								  [e reason], NSLocalizedRecoverySuggestionErrorKey, 
								  NSLocalizedString (@"NSPredicate parse error", nil), NSLocalizedDescriptionKey, 
								  nil];
		NSError* error = [NSError errorWithDomain: NSCocoaErrorDomain code: 1 userInfo: userInfo];
		if (NULL != outError)
			*outError = error;
	}
	return retval;	
}

- (void) setIBFetchPredicate: (NSPredicate *) predicate
{
	[self setFetchPredicate: predicate];
}

- (NSString *) IBFetchPredicate
{
	return [[self fetchPredicate] predicateFormat];
}

- (NSImage *) ibDefaultImage
{
	NSString* path = [[NSBundle bundleForClass: [BXIBPlugin class]] pathForImageResource: @"BXArrayController"];
	return [[[NSImage alloc] initByReferencingFile: path] autorelease];
}

#if 0
+ (NSSet *) keyPathsForValuesAffectingHasContentBinding
{
	return [NSSet setWithObject: @"contentBindingKey"];
}

- (BOOL) hasContentBinding
{
	return ([mContentBindingKey length] ? YES : NO);
}
#endif
@end
