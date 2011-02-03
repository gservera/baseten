//
// BXAImportController.h
// BaseTen Assistant
//
// Copyright 2008 Marko Karppinen & Co. LLC.
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
#import <BaseTen/BXPGEntityImporter.h>
@class MKCPolishedHeaderView;
@class BXAController;


@interface BXAImportController : NSWindowController <BXPGEntityImporterDelegate>
{
	BXAController* mController;
	BXDatabaseContext* mContext;
	NSManagedObjectModel* mModel;
	NSString* mSchemaName;
	BXPGEntityImporter* mEntityImporter; //Currently we only support PostgreSQL.
	NSArray* mConflictingEntities;
	
	IBOutlet NSArrayController* mConfigurations;
	IBOutlet NSArrayController* mEntities;
	IBOutlet NSArrayController* mProperties;
	
	IBOutlet MKCPolishedHeaderView* mLeftHeaderView;
	IBOutlet MKCPolishedHeaderView* mRightHeaderView;
	
	IBOutlet NSTableView* mTableView;
	IBOutlet NSTableView* mFieldView;
	
	IBOutlet NSArrayController* mImportErrors;
	IBOutlet NSPanel* mChangePanel;	
}
@property (readwrite, retain) BXAController* controller;
@property (readwrite, retain) NSManagedObjectModel* objectModel;
@property (readwrite, retain) NSString* schemaName;
@property (readwrite, retain) BXDatabaseContext* databaseContext;
@property (readwrite, retain) NSArray* conflictingEntities;
- (void) showPanel;

- (void) errorEnded: (BOOL) didRecover contextInfo: (void *) contextInfo;
- (void) nameConflictAlertDidEnd: (NSAlert *) alert returnCode: (int) returnCode contextInfo: (void *) ctx;
- (void) importPanelDidEnd: (NSWindow *) sheet returnCode: (int) returnCode contextInfo: (void *) contextInfo;
@end

//Patch by Tim Bedford 2008-08-11
@interface BXAImportController (NSSplitViewDelegate)
- (float)splitView:(NSSplitView *)splitView constrainMinCoordinate:(float)proposedCoordinate ofSubviewAt:(int)index;
- (float)splitView:(NSSplitView *)splitView constrainMaxCoordinate:(float)proposedCoordinate ofSubviewAt:(int)index;
@end
//End patch

@interface BXAImportController (IBActions)
- (IBAction) endEditingForSchemaName: (id) sender;
- (IBAction) selectedConfiguration: (id) sender;
- (IBAction) endErrorPanel: (id) sender;
- (IBAction) endImportPanel: (id) sender;
- (IBAction) dryRun: (id) sender;
//Patch by Tim Bedford 2008-08-11
- (IBAction) checkAllEntities: (id) sender;
- (IBAction) checkNoEntities: (id) sender;
//End patch
- (IBAction) openHelp: (id) sender; //Patch by Tim Bedford 2008-08-12
@end
