//
// BXEntityDescription+BXAAdditions.m
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


#import <Foundation/Foundation.h>
#import <BaseTen/BaseTen.h>
#import "BXAController.h"


@implementation BXEntityDescription (BXAControllerAdditions)
+ (NSSet *) keyPathsForValuesAffectingCanSetPrimaryKey
{
	return [NSSet setWithObjects: @"isEnabled", nil];
}

- (BOOL) canSetPrimaryKey
{
	return ([self isView] && ![self isEnabled]);
}

+ (NSSet *) keyPathsForValuesAffectingCanEnableForAssistant
{
	return [NSSet setWithObject: @"primaryKeyFields"];
}

- (BOOL) canEnableForAssistant
{
	return (0 < [[self primaryKeyFields] count]);
}

+ (NSSet *) keyPathsForValuesAffectingCanEnableForAssistantV
{
	return [NSSet setWithObject: @"primaryKeyFields"];
}

- (BOOL) canEnableForAssistantV
{
	return (0 < [[self primaryKeyFields] count] || [self isView]);
}

+ (NSSet *) keyPathsForValuesAffectingEnabledForAssistant
{
	return [NSSet setWithObject: @"enabled"];
}

- (BOOL) isEnabledForAssistant
{
	return [self isEnabled];
}

- (void) setEnabledForAssistant: (BOOL) aBool
{
	[[NSApp delegate] process: aBool entity: self];
}

- (BOOL) validateEnabledForAssistant: (id *) ioValue error: (NSError **) outError
{
	BOOL retval = YES;
	if ([self isView] && 0 == [[self primaryKeyFields] count])
	{
		if (ioValue)
			*ioValue = [NSNumber numberWithBool: NO];
	}
	else if (! [[NSApp delegate] hasBaseTenSchema])
	{
		retval = NO;
		if (outError)
			*outError = [[NSApp delegate] schemaInstallError];
	}
	return retval;
}
@end
