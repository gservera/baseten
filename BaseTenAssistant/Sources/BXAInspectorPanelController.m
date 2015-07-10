//
// BXAInspectorPanelController.m
// BaseTen Assistant
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
// $Id$
//

#import "BXAController.h"
#import "BXAGetInfoWindowController.h"
#import <BaseTen/BaseTen.h>


__strong static NSString* kBXAInspectorPanelControllerKVOContext = @"kBXAInspectorPanelControllerKVOContext";
static NSPoint gLastPoint = {};


@implementation BXAInspectorPanelController
- (void) moveTableViewUp: (BOOL) moveUp
{
	CGFloat diff = 59.0;
	NSView* view = [[mAttributesTableView superview] superview];
	NSRect frame = [view frame];
	
	if (moveUp)
	{
		frame.origin.y += diff;
		frame.size.height -= diff;
		[view setFrame: frame];		
	}
	else
	{
		frame.origin.y -= diff;
		frame.size.height += diff;
		[view setFrame: frame];		
	}
}


#pragma mark Initialisation & Dealloc

+ (void)initialize
{
	static BOOL tooLate = NO;
	if (! tooLate)
	{
		tooLate = YES;
		
		NSRect frame = [[NSScreen mainScreen] frame];
		gLastPoint = NSMakePoint (0.0, frame.origin.y + frame.size.height);
	}	
}


+ (id) inspectorPanelController
{
	static BXAInspectorPanelController* sInspector;
	
	if(!sInspector)
	{
		sInspector = [[BXAInspectorPanelController alloc] init];
	}
	
	return sInspector;
}


- (NSWindow *) windowPrototype: (NSRect) contentRect
{
	NSUInteger windowStyle = NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask | NSResizableWindowMask | NSUtilityWindowMask;
	NSPanel* window = [[[NSPanel alloc] initWithContentRect: contentRect styleMask: windowStyle 
													backing: NSBackingStoreBuffered defer: YES] autorelease];
	[window setFloatingPanel: YES];
	return window;
}


- (id) init
{
	if ((self = [super initWithWindowNibName: @"InspectorView"]))
	{
	}
	return self;
}


- (void) awakeFromNib
{
	NSWindow* window = [self windowPrototype: [mEntityAttributesView frame]];
	gLastPoint = [window cascadeTopLeftFromPoint: gLastPoint];

	[self setWindow: window];
	[window bind: @"title" toObject: self withKeyPath: @"entity.name" options: nil];
	[window setContentView: mEntityAttributesView];
	[window setFrameTopLeftPoint: gLastPoint];
	
	// Set up default sort descriptors
	NSSortDescriptor* descriptor = [[mAttributesTableView tableColumnWithIdentifier:@"name"] sortDescriptorPrototype];
	NSArray* descriptors = [NSArray arrayWithObject:descriptor];
	[mAttributesTableView setSortDescriptors:descriptors];
	
	[mAttributesTableView setTarget: self];
	[mAttributesTableView setDoubleAction: @selector (propertyDoubleClick:)];
	
	[self moveTableViewUp: NO];
	[self addObserver: self	forKeyPath: @"entity" 
			  options: NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld | NSKeyValueObservingOptionInitial
			  context: kBXAInspectorPanelControllerKVOContext];
}


#pragma mark Accessors

@synthesize entity = mEntity;

- (NSPredicate *) attributeFilterPredicate
{
	return [NSPredicate predicateWithFormat: @"value.isExcluded == false && value.isDeprecated == false"];
}


+ (NSSet *) keyPathsForValuesAffectingEntityTitle
{
	return [NSSet setWithObject: @"entity"];
}


- (NSString *) entityTitle
{
	NSString* outTitle;
	
	if([self entity] == nil)
		outTitle = NSNoSelectionMarker;
	else if([[self entity] isView])
		outTitle = [NSString stringWithFormat:NSLocalizedString(@"ViewInfoTitleFormat", @"Title format"), [[self entity] name]];
	else
		outTitle = [NSString stringWithFormat:NSLocalizedString(@"TableInfoTitleFormat", @"Title format"), [[self entity] name]];
	
	return outTitle;
}


+ (NSSet *) keyPathsForValuesAffectingEntityName
{
	return [NSSet setWithObject: @"entity"];
}


- (NSString *) entityName
{
	if([self entity] == nil)
		return NSNoSelectionMarker;
	else
		return [[self entity] name];
}


+ (NSSet *) keyPathsForValuesAffectingEntityIcon
{
	return [NSSet setWithObject: @"entity"];
}


- (NSImage *) entityIcon
{
	NSImage* outImage = nil;
	
	if([[self entity] isView])
		outImage = [NSImage imageNamed:@"View16"];
	else
		outImage = [NSImage imageNamed:@"Table16"];
	
	return outImage;
}


- (BOOL) isWindowVisible
{
	return [[self window] isVisible];
}


- (IBAction) closeWindow: (id) sender;
{
	[[self window] performClose: sender];
}


- (IBAction) propertyDoubleClick: (id) sender
{
	BXPropertyDescription *property = (id) [[[mPropertyController selectedObjects] lastObject] value];
	if (property && [property propertyKind] == kBXPropertyKindRelationship)
		[self displayProperty: [(BXRelationshipDescription *) property inverseRelationship]];
}


- (void) displayProperty: (BXPropertyDescription *) property
{
	[(BXAController*)[NSApp delegate] selectEntity: [property entity]];
	[self selectProperty: property];
}


- (void) selectProperty: (BXPropertyDescription *) property
{
	// The dictionary controller seems to require the key-value-pair for selection.
	NSArray *arrangedObjects = [mPropertyController arrangedObjects];
	for (id pair in arrangedObjects)
	{
		if ((id) [pair value] == property)
		{
			[mPropertyController setSelectedObjects: [NSArray arrayWithObject: pair]];
			break;
		}
	}	
}


- (void) bindEntityToObject: (id) observable withKeyPath: (NSString *) keypath
{
	[self unbind:@"entity"];
	[self bind:@"entity" toObject: observable withKeyPath: keypath options:nil];
}


- (void) observeValueForKeyPath: (NSString *) keyPath ofObject: (id) object 
						 change: (NSDictionary *) change context: (void *) context
{
    if (context == kBXAInspectorPanelControllerKVOContext) 
	{
		BXEntityDescription* oldEntity = [change objectForKey: NSKeyValueChangeOldKey];
		BXEntityDescription* newEntity = [change objectForKey: NSKeyValueChangeNewKey];
		if ([NSNull null] == (id) oldEntity) oldEntity = nil;
		if ([NSNull null] == (id) newEntity) newEntity = nil;
		
		if ([oldEntity isView] && ![newEntity isView])
			[self moveTableViewUp: NO];
		else if (![oldEntity isView] && [newEntity isView])
			[self moveTableViewUp: YES];
	}
	else 
	{
		[super observeValueForKeyPath: keyPath ofObject: object change: change context: context];
	}
}
@end
