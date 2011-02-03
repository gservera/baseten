//
// BXAttributeDescription+BXAAdditions.m
// BaseTen Assistant
//
// Copyright 2009 Marko Karppinen & Co. LLC.
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


#import <Cocoa/Cocoa.h>
#import <BaseTen/BaseTen.h>
#import "BXAController.h"


@implementation BXAttributeDescription (BXAControllerAdditions)
- (BOOL) isAttribute
{
	return YES;
}

- (BOOL) isPrimaryKeyForAssistant
{
	return [self isPrimaryKey];
}

- (void) setPrimaryKeyForAssistant: (BOOL) aBool
{
	[[NSApp delegate] process: aBool attribute: self];
}

- (BOOL) validatePrimaryKeyForAssistant: (id *) ioValue error: (NSError **) outError
{
	BOOL retval = YES;
	if (! [[NSApp delegate] hasBaseTenSchema])
	{
		retval = NO;
		
		if (ioValue)
			*ioValue = [NSNumber numberWithBool: NO];
				
		if (outError)
			*outError = [[NSApp delegate] schemaInstallError];
	}
	return retval;
}

- (NSString *) databaseTypeNameForAssistant
{
	return [self databaseTypeName];
}
@end
