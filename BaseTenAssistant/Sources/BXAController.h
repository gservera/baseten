//
// BXAController.h
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

#import <Cocoa/Cocoa.h>
#import <BaseTen/BaseTen.h>
#import <BaseTen/BXDataModelCompiler.h>
#import <BaseTen/BXPGSQLScriptReader.h>
#import <BaseTen/BXRegularExpressions.h>

@class MKCBackgroundView;
@class MKCPolishedCornerView;
@class BXAImportController;
@class BXAGetInfoWindowController;
@class MKCStackView;


@interface BXAController : NSObject
#if defined(MAC_OS_X_VERSION_10_6) && MAC_OS_X_VERSION_10_6 <= MAC_OS_X_VERSION_MAX_ALLOWED
<NSNetServiceBrowserDelegate, NSNetServiceDelegate>
#endif
{
	struct bx_regular_expression_st mCompilationErrorRegex;
	struct bx_regular_expression_st mCompilationFailedRegex;

	MKCPolishedCornerView* mCornerView;
	NSButtonCell* mInspectorButtonCell;
	BXAImportController* mImportController;
	BXDataModelCompiler* mCompiler;
	BXPGSQLScriptReader* mReader;
	NSNumber* mBundledSchemaVersionNumber;
		
	IBOutlet BXDatabaseContext* mContext;
	IBOutlet NSDictionaryController* mEntitiesBySchema;
	IBOutlet NSDictionaryController* mEntities;
	IBOutlet NSDictionaryController* mAttributes;

	IBOutlet NSWindow* mMainWindow;
	IBOutlet NSTableView* mDBSchemaView;
	IBOutlet NSTableView* mDBTableView;
	IBOutlet MKCBackgroundView* mToolbar;
	IBOutlet NSTableColumn* mTableNameColumn;
	IBOutlet NSTableColumn* mTableEnabledColumn;
	IBOutlet NSTextField* mStatusTextField;
	
	IBOutlet NSPanel* mProgressPanel;
	IBOutlet NSProgressIndicator* mProgressIndicator;
	IBOutlet NSTextField* mProgressField;
	IBOutlet NSButton* mProgressCancelButton;
	
	IBOutlet NSPanel* mInspectorWindow;
	IBOutlet NSTableView* mAttributeTable;
	IBOutlet NSTableColumn* mAttributeIsPkeyColumn;
	
	IBOutlet NSWindow* mLogWindow;
	IBOutlet NSTextView* mLogView;
	
	IBOutlet NSPanel* mConnectPanel;
    IBOutlet id mHostCell;
    IBOutlet id mPortCell;
    IBOutlet id mDBNameCell;
    IBOutlet id mUserNameCell;
    IBOutlet NSSecureTextField* mPasswordField;
	//Patch by Tim Bedford 2008-08-11
	IBOutlet NSPopUpButton* mBonjourPopUpButton;
    
	NSSavePanel* mSavePanel;
	IBOutlet NSView* mDataModelExportView;
	IBOutlet NSPopUpButton* mModelFormatButton;
	
	NSNetServiceBrowser* mServiceBrowser;
    NSMutableArray* mServices; // Keeps track of available services
    BOOL mSearching; // Keeps track of Bonjour search status
	//End patch
	
	IBOutlet NSPanel* mMomcErrorPanel;
	IBOutlet MKCStackView* mMomcErrorView;
			
	BOOL mLastSelectedEntityWasView;
	BOOL mDeniedSchemaInstall;
	BOOL mExportUsingFkeyNames;
	BOOL mExportUsingTargetRelationNames;
}

@property (readonly) BOOL hasBaseTenSchema;
@property (readonly) NSWindow* mainWindow;
@property (readwrite, retain) NSSavePanel* savePanel;
@property (readwrite, assign) BOOL exportsUsingFkeyNames;
@property (readwrite, assign) BOOL exportsUsingTargetRelationNames;


- (id) init; //Patch by Tim Bedford 2008-08-11
- (void) process: (BOOL) newState entity: (BXEntityDescription *) entity;
- (void) process: (BOOL) newState attribute: (BXAttributeDescription *) attribute;
- (void) logAppend: (NSString *) string;
- (void) finishedImporting;
- (NSError *) schemaInstallError;
- (BOOL) schemaInstallDenied;
- (void) upgradeBaseTenSchema;
- (void) refreshCaches: (SEL) callback;
- (void) confirmRefreshCachesWithCallback: (SEL) callback cancelCallback: (SEL) cancelCallback;
- (void) selectEntity: (BXEntityDescription *) entity;
- (BXAGetInfoWindowController *) displayInfoForEntity: (BXEntityDescription *) entity;
@end


@interface BXAController (IBActions)
- (IBAction) disconnect: (id) sender;
- (IBAction) terminate: (id) sender;
- (IBAction) chooseBonjourService: (id) sender; //Patch by Tim Bedford 2008-08-11
- (IBAction) connect: (id) sender;
- (IBAction) importDataModel: (id) sender;
- (IBAction) dismissMomcErrorPanel: (id) sender;
- (IBAction) exportLog: (id) sender; //Patch by Tim Bedford 2008-08-11
- (IBAction) exportObjectModel: (id) sender;
- (IBAction) clearLog: (id) sender;
- (IBAction) displayLogWindow: (id) sender;

- (IBAction) reload: (id) sender;

- (IBAction) refreshCacheTables: (id) sender;
- (IBAction) prune: (id) sender;

- (IBAction) getInfo: (id) sender; //Patch by Tim Bedford 2008-08-11
- (IBAction) toggleMainWindow: (id) sender; //Patch by Tim Bedford 2008-08-11
- (IBAction) toggleInspector: (id) sender; //Patch by Tim Bedford 2008-08-11

- (IBAction) upgradeSchema: (id) sender;
- (IBAction) removeSchema: (id) sender;
- (IBAction) cancelSchemaInstall: (id) sender;

- (IBAction) changeModelFormat: (id) sender;

- (IBAction) openHelp: (id) sender; //Patch by Tim Bedford 2008-08-12
@end


@interface BXAController (ProgressPanel)
- (void) displayProgressPanel: (NSString *) message;
- (void) hideProgressPanel;
- (void) setProgressMin: (double) min max: (double) max;
- (void) setProgressValue: (double) value;
- (void) advanceProgress;
@end


@interface BXAController (Delegation) <BXDatabaseContextDelegate, BXDataModelCompilerDelegate, BXPGSQLScriptReaderDelegate>
- (void) alertDidEnd: (NSAlert *) alert returnCode: (int) returnCode contextInfo: (void *) ctx;
- (void) importOpenPanelDidEnd: (NSOpenPanel *) panel returnCode: (int) returnCode contextInfo: (void *) contextInfo;

- (void) reloadAfterRefresh: (PGTSResultSet *) res;
- (void) disconnectAfterRefresh: (PGTSResultSet *) res;
- (void) terminateAfterRefresh: (PGTSResultSet *) res;
@end

//Patch by Tim Bedford 2008-08-11
@interface BXAController (NSSplitViewDelegate)
- (float)splitView:(NSSplitView *)splitView constrainMinCoordinate:(float)proposedCoordinate ofSubviewAt:(int)index;
- (float)splitView:(NSSplitView *)splitView constrainMaxCoordinate:(float)proposedCoordinate ofSubviewAt:(int)index;
- (void)splitView:(NSSplitView*)sender resizeSubviewsWithOldSize:(NSSize)oldSize;
@end

@interface BXAController (NetServiceMethods)
- (void)applyNetService:(NSNetService*)netService;
- (void)updateBonjourUI;
- (void)handleNetServiceBrowserError:(NSNumber *)error;
- (void)handleNetServiceError:(NSNumber *)error withService:(NSNetService *)service;
@end

@interface BXAController (NSSavePanelDelegate)
//End patch.
- (void) exportLogSavePanelDidEnd: (NSSavePanel *) sheet returnCode: (int) returnCode contextInfo: (void *) contextInfo;
- (void) exportModelSavePanelDidEnd: (NSSavePanel *) sheet returnCode: (int) returnCode contextInfo: (void *) contextInfo;
//Patch by Tim Bedford 2008-08-11
@end

@interface BXAController (NetServiceBrowserDelegate)
- (void)netServiceBrowserWillSearch:(NSNetServiceBrowser *)browser;
- (void)netServiceBrowserDidStopSearch:(NSNetServiceBrowser *)browser;
- (void)netServiceBrowser:(NSNetServiceBrowser *)browser
			 didNotSearch:(NSDictionary *)errorDict;
- (void)netServiceBrowser:(NSNetServiceBrowser *)browser
		   didFindService:(NSNetService *)aNetService
			   moreComing:(BOOL)moreComing;
- (void)netServiceBrowser:(NSNetServiceBrowser *)browser
		 didRemoveService:(NSNetService *)aNetService
			   moreComing:(BOOL)moreComing;
@end


@interface BXAController (NSNetServiceDelegate)
- (void)resolveNetServiceAtIndex:(NSInteger)index;
- (void)netServiceDidResolveAddress:(NSNetService *)netService;
- (void)netService:(NSNetService *)netService
	 didNotResolve:(NSDictionary *)errorDict;
@end
//End patch
