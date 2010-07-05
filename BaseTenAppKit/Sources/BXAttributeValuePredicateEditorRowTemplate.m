//
// BXAttributeValuePredicateEditorRowTemplate.m
// BaseTen
//
// Copyright (C) 2010 Marko Karppinen & Co. LLC.
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

#import "BXAttributeValuePredicateEditorRowTemplate.h"


@implementation BXAttributeValuePredicateEditorRowTemplate
- (NSArray *) rightExpressions
{
	id retval = nil;
	if ([self rightExpressionAttributeType] == NSBooleanAttributeType)
		retval = [NSArray arrayWithObject: [NSExpression expressionForConstantValue: [NSNumber numberWithBool: NO]]];
	else
		retval = [super rightExpressions];
	return retval;
}


- (NSArray *) templateViews
{
	id retval = [super templateViews];
	if ([self rightExpressionAttributeType] == NSBooleanAttributeType)
	{
		retval = [[retval mutableCopy] autorelease];
		
		[retval removeObjectAtIndex: 2];
		NSPopUpButton* button = [retval objectAtIndex: 1];
		[[button itemAtIndex: 0] setTitle: @"is false"]; // FIXME: localization.
		[[button itemAtIndex: 1] setTitle: @"is true"];
	}
	return retval;
}
@end
