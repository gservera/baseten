//
// BXDatabaseContext+IBAdditions.m
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

#import <BaseTen/BaseTen.h>
#import <BaseTen/BXSafetyMacros.h>
#import "BXDatabaseContext+IBAdditions.h"
#import "BXDatabaseContextInspector.h"
#import "BXIBPlugin.h"


@implementation BXDatabaseContext (IBAdditions)

- (void) ibDidAddToDesignableDocument: (IBDocument *) document
{
	[self setConnectsOnAwake: YES];
}

- (void) ibPopulateKeyPaths: (NSMutableDictionary *) keyPaths
{
    [super ibPopulateKeyPaths: keyPaths];
    
    [[keyPaths objectForKey: IBAttributeKeyPaths] addObjectsFromArray: [NSArray arrayWithObjects:
        @"databaseURI", @"autocommits", @"connectsOnAwake", nil]];
    [[keyPaths objectForKey: IBToOneRelationshipKeyPaths] addObjectsFromArray: [NSArray arrayWithObjects:
        @"delegate", @"modalWindow", nil]];
}

- (void) ibPopulateAttributeInspectorClasses: (NSMutableArray *) classes
{
    [super ibPopulateAttributeInspectorClasses: classes];
    [classes addObject: [BXDatabaseContextInspector class]];
}

- (NSString *) IBDatabaseURI
{
	return [[self databaseURI] absoluteString];
}

- (BOOL) validateIBDatabaseURI: (id *) ioValue error: (NSError **) outError 
{
    BOOL succeeded = NO;
	id givenURI = *ioValue;
    NSURL* newURI = nil;

	//FIXME: move validation to BXDatabaseContext.
	if (nil == givenURI)
		succeeded = YES;
	else
	{
		NSString* errorMessage = nil;
		
		if ([givenURI isKindOfClass: [NSURL class]])
		{
			newURI = givenURI;
		}
		else if ([givenURI isKindOfClass: [NSString class]])
		{
		    if (0 < [givenURI length])
				newURI = [NSURL URLWithString: givenURI];
			else
			{
				succeeded = YES;
				goto bail;
			}
		}
		else
		{
			errorMessage = @"Expected to receive either an NSString or an NSURL.";
			goto bail;
		}
		
		if (nil == newURI)
		{
			errorMessage = @"The URI was malformed.";
			goto bail;
		}
		if (! [@"pgsql" isEqualToString: [newURI scheme]])
		{
			errorMessage = @"The only supported scheme is pgsql.";
			goto bail;
		}
		NSArray* pathComponents = [[newURI path] pathComponents];
		//The first path component is the initial slash.
		if ([pathComponents count] < 2 || [@"/" isEqualToString: [pathComponents objectAtIndex: 1]])
		{
			errorMessage = @"The URI path should contain the database name.";
			goto bail;
		}
		if (2 < [pathComponents count])
		{
			errorMessage = @"The URI path should only contain the database name.";
			goto bail;
		}		
		succeeded = YES;

		bail:
		if (succeeded)
			*ioValue = newURI;
		else if (NULL != outError)
		{
			NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
	            @"", NSLocalizedFailureReasonErrorKey,
	            BXSafeObj (errorMessage), NSLocalizedRecoverySuggestionErrorKey,
				nil];
			NSError* error = [NSError errorWithDomain: kBXErrorDomain 
												 code: kBXErrorMalformedDatabaseURI 
											 userInfo: userInfo];
			*outError = error;
		}
	}
	
	return succeeded;
}

- (void) setIBDatabaseURI: (NSURL *) anURI
{
	[self setDatabaseURI: anURI];
}

- (NSImage *) ibDefaultImage
{
	NSString* path = [[NSBundle bundleForClass: [BXIBPlugin class]] pathForImageResource: @"BXDatabaseObject"];
	return [[[NSImage alloc] initByReferencingFile: path] autorelease];
}

@end
