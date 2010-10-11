//
// BXMultipleChoicePredicateEditorRowTemplate.mm
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

#import "BXMultipleChoicePredicateEditorRowTemplate.h"
#import <BaseTen/BaseTen.h>
#import <BaseTen/BXLogger.h>
#import <BaseTen/BXCollectionFunctions.h>
#import <BaseTen/BXArraySize.h>

static NSString * const kKVOCtx = @"BXMultipleChoicePredicateEditorRowTemplateKeyValueObservingContext";
using namespace BaseTen;


@interface BXMultipleChoicePredicateEditorRowTemplate ()
@property (readwrite, copy) NSArray *rightExpressions;
@property (readwrite, retain, nonatomic) id optionObjects;
@property (readwrite, copy) NSString *displayName;
@property (readwrite, copy) NSString *optionDisplayNameKeyPath;
@end



@implementation BXMultipleChoicePredicateEditorRowTemplate
@synthesize rightExpressions = mRightExpressions;
@synthesize displayName = mDisplayName;
@synthesize optionDisplayNameKeyPath = mOptionDisplayNameKeyPath;

+ (BOOL) automaticallyNotifiesObserversForKey: (NSString *) key
{
	if ([key isEqualToString: @"optionObjects"])
		return NO;
	else
		return [super automaticallyNotifiesObserversForKey: key];
}


+ (NSSet *) keyPathsForValuesAffectingLeftExpressions
{
	return [NSSet setWithObject: @"optionObjects"];
}


+ (NSSet *) keyPathsForValuesAffectingTemplateViews
{
	return [NSSet setWithObject: @"rightExpressions"];
}


- (id) initWithLeftExpression: (NSExpression *) leftExpression
	   rightExpressionOptions: (id) options 
	 optionDisplayNameKeyPath: (NSString *) optionDisplayNameKeyPath
	leftExpressionDisplayName: (NSString *) displayName
					 modifier: (NSComparisonPredicateModifier) modifier
{
	Expect (leftExpression);
	Expect (options);
	Expect (optionDisplayNameKeyPath);
	Expect (displayName);
	
	id operators [] = {
		ObjectValue <NSPredicateOperatorType> (NSEqualToPredicateOperatorType),
		ObjectValue <NSPredicateOperatorType> (NSNotEqualToPredicateOperatorType)
	};
	
	NSExpression *exp = [NSExpression expressionForConstantValue: [NSNumber numberWithBool: NO]];
	if ((self = [super initWithLeftExpressions: [NSArray arrayWithObject: leftExpression]
							  rightExpressions: [NSArray arrayWithObject: exp] 
									  modifier: modifier
									 operators: [NSArray arrayWithObjects: operators count: BXArraySize (operators)]
									   options: 0]))
	{
		[self setDisplayName: displayName];
		[self setOptionDisplayNameKeyPath: optionDisplayNameKeyPath];
		[self setOptionObjects: options];
		[self addObserver: self forKeyPath: @"optionObjects" options: NSKeyValueObservingOptionInitial context: kKVOCtx];
	}
	return self;
}


- (void) dealloc
{
	[mOptions release];
	[mRightExpressions release];
	[mDisplayName release];
	[mOptionDisplayNameKeyPath release];
	[super dealloc];
}


- (double) matchForPredicate: (NSPredicate *) inPredicate
{
	double retval = 0.0;
	if ([inPredicate isKindOfClass: [NSComparisonPredicate class]])
	{
		NSComparisonPredicate *predicate = (id) inPredicate;
		NSExpression* lhs = [predicate leftExpression];
		if ([[self leftExpressions] containsObject: lhs])
			retval = 1.0;
	}
	return retval;
}


- (void) observeValueForKeyPath: (NSString *) keyPath ofObject: (id) object change: (NSDictionary *) change context: (void *) context
{
    if (kKVOCtx == context)
	{
		if ([keyPath isEqualToString: @"optionObjects"])
		{
			NSUInteger count = [mOptions count];
			if (count)
			{
				NSMutableArray *rightExpressions = [NSMutableArray arrayWithCapacity: [mOptions count]];
				for (BXDatabaseObject *object in [self optionObjects])
					[rightExpressions addObject: [NSExpression expressionForConstantValue: object]];
				[self setRightExpressions: rightExpressions];
			}
			else
			{
				[self setRightExpressions: [super rightExpressions]];
			}
		}
	}
	else
	{
		[super observeValueForKeyPath: keyPath ofObject: object change: change context: context];
	}
}


- (NSArray *) templateViews
{
	NSArray *retval = [super templateViews];
	
	[[[[retval objectAtIndex: 0] itemArray] objectAtIndex: 0] setTitle: mDisplayName];
	
	NSPopUpButton *optionsButton = [retval objectAtIndex: 2];
	NSMenu *optionsMenu = [optionsButton menu];
	
	for (NSInteger i = 0, count = [optionsMenu numberOfItems]; i < count; i++)
		[optionsMenu removeItemAtIndex: 0];
	
	if ([mOptions count])
	{
		for (NSExpression *currentExp in mRightExpressions)
		{
			NSMenuItem *currentItem = [[NSMenuItem alloc] init];
			[currentItem setEnabled: YES];
			[currentItem setTitle: [[currentExp constantValue] valueForKeyPath: mOptionDisplayNameKeyPath]];
			[currentItem setRepresentedObject: currentExp];
			[optionsMenu addItem: currentItem];
			[currentItem release];
		}
	}
	else
	{
		NSExpression *exp = [mRightExpressions lastObject];
		Expect (exp);
		
		NSMenuItem *noValuesItem = [[NSMenuItem alloc] init];
		[noValuesItem setEnabled: NO];
		[noValuesItem setTitle: @"No values"]; // FIXME: localization.
		[noValuesItem setRepresentedObject: exp];
		[optionsMenu addItem: noValuesItem];
		[noValuesItem release];
	}
	
	return retval;
}


@dynamic optionObjects;
- (id) optionObjects
{
	return mOptions;
}

- (void) setOptionObjects: (id) options
{
	if (mOptions != options)
	{
		[self willChangeValueForKey: @"optionObjects"];
		[mOptions release];
		mOptions = [options retain];
		[mOptions setKey: @"optionObjects"];
		[mOptions setOwner: self];
		[self didChangeValueForKey: @"optionObjects"];
	}
}
@end



@implementation BXMultipleChoicePredicateEditorRowTemplate (NSCopying)
- (id) copyWithZone: (NSZone *) zone
{
	BXMultipleChoicePredicateEditorRowTemplate *retval = [super copyWithZone: zone];
	Expect ([retval isKindOfClass: [self class]]);
	
	[retval setDisplayName: mDisplayName];
	[retval setOptionDisplayNameKeyPath: mOptionDisplayNameKeyPath];
	[retval setOptionObjects: mOptions];
	[retval addObserver: retval forKeyPath: @"optionObjects" options: NSKeyValueObservingOptionInitial context: kKVOCtx];
	
	return retval;
}
@end
