//
// BXAImportController.m
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

#import "BXAImportController.h"
#import "BXAController.h"
#import "MKCPolishedHeaderView.h"
#import "MKCPolishedCornerView.h"
#import "MKCEventPassingTextField.h"
#import "Additions.h"
#import <BaseTen/BXHOM.h>
#import <BaseTen/BXDatabaseContextPrivate.h>
#import <BaseTen/PGTSConnection.h>
#import <BaseTen/PGTSResultSet.h>
#import <BaseTen/BXPGInterface.h>
#import <BaseTen/BXPGTransactionHandler.h>
#import <BaseTen/BXPGEntityImporter.h>

static NSString* kBXAShouldImportKey = @"kBXAShouldImportKey";
static NSString* kBXATextColorKey = @"kBXATextColorKey";


@interface NSEntityDescription (BXAImportControllerAdditions)
- (BOOL) shouldImportBXA;
- (void) setShouldImportBXA: (BOOL) flag;
@end


@implementation NSEntityDescription (BXAImportControllerAdditions)
- (NSColor *) BXATextColor
{
	return ([[self userInfo] objectForKey: kBXATextColorKey] ?: [NSColor blackColor]);
}

- (void) setBXATextColor: (NSColor *) aColor
{
	NSColor* currentColor = [self BXATextColor];
	if (![currentColor isEqual: aColor])
	{
		NSMutableDictionary* userInfo = [[self userInfo] mutableCopy];		
		[userInfo setObject: aColor forKey: kBXATextColorKey];
		[self setUserInfo: userInfo];
	}
}

- (BOOL) shouldImportBXA
{
	return [[[self userInfo] objectForKey: kBXAShouldImportKey] boolValue];
}

- (void) setShouldImportBXA: (BOOL) flag
{
	NSMutableDictionary* userInfo = [[self userInfo] mutableCopy];
	[userInfo setObject: [NSNumber numberWithBool: flag] forKey: kBXAShouldImportKey];
	[self setUserInfo: userInfo];
}
@end



@implementation BXAImportController
@synthesize objectModel = mModel;
@synthesize schemaName = mSchemaName;
@synthesize databaseContext = mContext;
@synthesize controller = mController;
@synthesize conflictingEntities = mConflictingEntities;

- (void) checkNameConflicts
{
	NSMutableArray* conflictingEntities = nil;	
	NSString* schemaName = mSchemaName ?: @"public";
	
	for (NSEntityDescription* entity in [mEntities arrangedObjects])
	{
		BXEntityDescription* bxEntity = [[mContext databaseObjectModel] matchingEntity: entity inSchema: schemaName];
		if (bxEntity)
		{
			if (! conflictingEntities)
				conflictingEntities = [NSMutableArray array];
			
			[conflictingEntities addObject: bxEntity];
			[entity setBXATextColor: [NSColor redColor]];
		}
		else
		{
			[entity setBXATextColor: [NSColor blackColor]];
		}
	}
	
	[self setConflictingEntities: conflictingEntities];
}

- (void) windowDidLoad
{
	NSDictionary* lightColours = [MKCPolishedHeaderView lightColours];
	[mLeftHeaderView setColours: lightColours];
	[mLeftHeaderView setDrawingMask: kMKCPolishDrawBottomLine | kMKCPolishDrawTopLine | kMKCPolishDrawSeparatorLines];
	
	[mRightHeaderView setColours: lightColours];
	[mRightHeaderView setDrawingMask: kMKCPolishDrawLeftLine | kMKCPolishDrawTopLine | kMKCPolishDrawBottomLine];
	
    {
        NSRect cornerRect = NSMakeRect (0.0, 0.0, 15.0, 20.0);
        MKCPolishedCornerView* cornerView = [[[MKCPolishedCornerView alloc] initWithFrame: cornerRect] autorelease];
        [cornerView setDrawingMask: kMKCPolishDrawBottomLine | kMKCPolishDrawTopLine | kMKCPolishDrawRightLine];
        [cornerView setColours: lightColours];
        [mTableView setCornerView: cornerView];
        
        cornerRect.size.width -= 5.0;
        cornerView = [[[MKCPolishedCornerView alloc] initWithFrame: cornerRect] autorelease];
        [cornerView setDrawingMask: kMKCPolishDrawBottomLine | kMKCPolishDrawTopLine | kMKCPolishDrawRightLine];
        [cornerView setColours: lightColours];
        [mFieldView setCornerView: cornerView];
    }
    
    {
        NSColor* lightBackgroundColor = [NSColor colorWithDeviceWhite: 222.0 / 255.0 alpha: 1.0];
        [[self window] setBackgroundColor: lightBackgroundColor];
    }
	
	//The text "Tables" spans column borders, so we place it differently.
	{
		NSRect frame = [mLeftHeaderView frame];
		frame.origin.x += 5.0;
		NSTextField* textField = [[MKCEventPassingTextField alloc] initWithFrame: frame];
		[textField setBordered: NO];
		[textField setEditable: NO];
		[textField setSelectable: NO];
		[textField setDrawsBackground: NO];
		[textField setStringValue: NSLocalizedString(@"Tables", @"TableView header label")]; //Patch by Tim Bedford 2008-08-11
		[textField makeEtchedSmall: NO];
		[mLeftHeaderView addSubview: textField];
	}	
}

- (void) showPanel
{
	//Ensure that the window gets loaded.
	[self window];
	
	NSMutableArray* configurations = [[mModel configurations] mutableCopy];
	[configurations insertObject: NSLocalizedString(@"Default Configuration", @"Configurations menu item") atIndex: 0]; //Patch by Tim Bedford 2008-08-11
	[self willChangeValueForKey: @"entitiesForSelectedConfiguration"];
	[mConfigurations setContent: configurations];		
	[self didChangeValueForKey: @"entitiesForSelectedConfiguration"];
	
	[self selectedConfiguration: nil];		
	
	[NSApp beginSheet: [self window] modalForWindow: [mController mainWindow] modalDelegate: self 
	   didEndSelector: @selector (importPanelDidEnd:returnCode:contextInfo:) contextInfo: NULL];
}

- (void) entityImporterAdvanced: (BXPGEntityImporter *) importer
{
	[mController advanceProgress];
}

- (void) entityImporter: (BXPGEntityImporter *) importer finishedImporting: (BOOL) succeeded error: (NSError *) error
{
	[mController hideProgressPanel];

	if (! succeeded)
	{
		[NSApp presentError: error modalForWindow: [mController mainWindow]
				   delegate: nil didPresentSelector: NULL contextInfo: NULL];
	}
	
	[NSApp stopModalWithCode: succeeded];	
}

static int 
ShouldImport (id entity)
{
	return ([entity shouldImportBXA]);
}

- (void) import: (BOOL) modifyDatabase usingSheet: (BOOL) useSheet
{
	BOOL shouldContinue = YES;
	NSArray* importedEntities = [[mEntities arrangedObjects] BX_SelectFunction: &ShouldImport];

	if (! mEntityImporter)
	{
		mEntityImporter = [[BXPGEntityImporter alloc] init];		
		[mEntityImporter setDatabaseContext: mContext];
		[mEntityImporter setDelegate: self];
	}
	[mEntityImporter setSchemaName: mSchemaName];
	[mEntityImporter setEntities: importedEntities];
	
	NSArray* errors = nil;
	NSArray* statements = [mEntityImporter importStatements: &errors];
	
	if (0 < [errors count])
	{
		shouldContinue = NO;
		[mImportErrors setContent: errors];

		if (useSheet)
		{
			[NSApp beginSheet: mChangePanel modalForWindow: [mController mainWindow]
				modalDelegate: self didEndSelector: NULL contextInfo: NULL];
			shouldContinue = [NSApp runModalForWindow: [mController mainWindow]];
		}
		else
		{
			shouldContinue = [NSApp runModalForWindow: mChangePanel];
		}
	}
	
	if (shouldContinue)
	{
		if (! modifyDatabase)
		{
			[mController displayLogWindow: nil];
			[mController logAppend: NSLocalizedString(@"beginDryRun", @"Log separator")]; //Patch by Tim Bedford 2008-08-11
			for (NSString* statement in statements)
			{
				[mController logAppend: statement];
				[mController logAppend: @"\n"];
			}
			[mController logAppend: NSLocalizedString(@"endDryRun", @"Log separator")]; //Patch by Tim Bedford 2008-08-11
		}
		else
		{
			if (0 < [mConflictingEntities count])
			{
				shouldContinue = NO;
				//Patch by Tim Bedford 2008-08-11
				NSString* message = NSLocalizedString(@"nameConflictMessage", @"Alert message");
				NSAlert* alert = [NSAlert alertWithMessageText: NSLocalizedString(@"Replace existing entities with matching names?", @"Alert message")
												 defaultButton: NSLocalizedString(@"Replace", @"Default button label")
											   alternateButton: NSLocalizedString(@"Cancel", @"Button label")
												   otherButton: nil 
								  //End patch
									 informativeTextWithFormat: message];
				[alert layout];
				NSArray* buttons = [alert buttons];
				[[buttons objectAtIndex: 0] setKeyEquivalent: @""];
				[[buttons objectAtIndex: 1] setKeyEquivalent: @"\r"];
				
				[alert beginSheetModalForWindow: [mController mainWindow] modalDelegate: self 
								 didEndSelector: @selector (nameConflictAlertDidEnd:returnCode:contextInfo:) contextInfo: NULL];
				shouldContinue = [NSApp runModalForWindow: [mController mainWindow]];
			}
			
			if (! shouldContinue)
				[self showPanel];
			else
			{
				[mController setProgressMin: 0.0 max: (double) [statements count]];
				//FIXME: progress cancel?
				//Patch by Tim Bedford 2008-08-11
				[mController displayProgressPanel: NSLocalizedString(@"Importing data model", @"Progress panel message")];
				[mController logAppend: NSLocalizedString(@"beginImport", @"Log separator")];
				//End patch
				
				NSError* error = nil;
				if (0 < [mConflictingEntities count] && ! [mEntityImporter disableEntities: mConflictingEntities error: &error])
				{
					shouldContinue = NO;
					[NSApp presentError: error modalForWindow: [mController mainWindow] 
							   delegate: nil didPresentSelector: NULL contextInfo: NULL];
					[NSApp runModalForWindow: [mController mainWindow]];
				}
				
				if (shouldContinue)
				{
					[mEntityImporter importEntities];
					
					shouldContinue = [NSApp runModalForWindow: [mController mainWindow]];
					[mController logAppend: NSLocalizedString(@"endImport", @"Log separator")]; //Patch by Tim Bedford 2008-08-11
					if (shouldContinue)
					{
						if (! [mController hasBaseTenSchema])
						{
							shouldContinue = NO;
							//See if the user didn't want to install the schema.
							if (! [mController schemaInstallDenied])
							{
								NSError* error = [mController schemaInstallError];
								[NSApp presentError: error modalForWindow: [mController mainWindow] 
										   delegate: self didPresentSelector: @selector (errorEnded:contextInfo:) contextInfo: NULL];
								shouldContinue = [NSApp runModalForWindow: [mController mainWindow]];
							}
						}
						
						if (shouldContinue)
						{
							NSError* error = nil;
							[mEntityImporter enableEntities: &error];
							if (error)
							{
								[NSApp presentError: error modalForWindow: [mController mainWindow] 
										   delegate: nil didPresentSelector: NULL contextInfo: NULL];
								[NSApp runModalForWindow: [mController mainWindow]];
							}					
						}
					}
				}
				[mController finishedImporting];
			}
		}
	}
}

			
- (void) errorEnded: (BOOL) didRecover contextInfo: (void *) contextInfo
{
	[NSApp stopModalWithCode: didRecover];
}

- (void) nameConflictAlertDidEnd: (NSAlert *) alert returnCode: (int) returnCode contextInfo: (void *) ctx
{
	[NSApp stopModalWithCode: (NSAlertDefaultReturn == returnCode ? YES : NO)];
}

- (void) importPanelDidEnd: (NSWindow *) sheet returnCode: (int) returnCode contextInfo: (void *) contextInfo
{
	if (returnCode)
		[self import: YES usingSheet: YES];
}
@end


//Patch by Tim Bedford 2008-08-11
@implementation BXAImportController (NSSplitViewDelegate)
- (float)splitView:(NSSplitView *)splitView constrainMinCoordinate:(float)proposedCoordinate ofSubviewAt:(int)index
{
	return proposedCoordinate + 128.0f;
}

- (float)splitView:(NSSplitView *)splitView constrainMaxCoordinate:(float)proposedCoordinate ofSubviewAt:(int)index
{
	return proposedCoordinate - 128.0f;
}
@end
//End patch


@implementation BXAImportController (IBActions)
- (IBAction) endEditingForSchemaName: (id) sender
{
	[self checkNameConflicts];
}

- (IBAction) endErrorPanel: (id) sender
{
	[mChangePanel orderOut: nil];
	[NSApp endSheet: mChangePanel];
	[NSApp stopModalWithCode: [sender tag]];
}

- (IBAction) endImportPanel: (id) sender
{
	NSWindow* panel = [self window];
	[panel orderOut: nil];
	[NSApp endSheet:panel returnCode:[sender tag]];
}

- (IBAction) dryRun: (id) sender
{
	[self import: NO usingSheet: NO];
}

- (IBAction) selectedConfiguration: (id) sender
{
	NSArray* content = nil;
	if (0 == [sender indexOfSelectedItem])
		content = [mModel entities];
	else
	{
		NSMenuItem* selectedItem = [sender selectedItem];
		NSString* title = [selectedItem title];
		content = [mModel entitiesForConfiguration: title];
	}
	
	[mEntities setContent: content];
	[self checkNameConflicts];
}

//Patch by Tim Bedford 2008-08-11
- (IBAction) checkAllEntities: (id) sender
{	
	for(NSEntityDescription *entityDescription in [mEntities content])
	{
		[entityDescription setShouldImportBXA:YES];
	}
}

- (IBAction) checkNoEntities: (id) sender
{
	for(NSEntityDescription *entityDescription in [mEntities content])
	{
		[entityDescription setShouldImportBXA:NO];
	}
}
//End patch

//Patch by Tim Bedford 2008-08-12
- (IBAction) openHelp: (id) sender
{
	// We use the sender's tag to form the help anchor. Anchors in the help book are in the form bxahelp###
	NSString *bookName = [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleHelpBookName"];
	NSHelpManager* helpManager = [NSHelpManager sharedHelpManager];
	NSString* anchor = [NSString stringWithFormat:@"bxahelp%d", [sender tag]]; 
	
	[helpManager openHelpAnchor:anchor inBook:bookName];
}
//End patch
@end
