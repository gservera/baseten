//
// BXAInspectorPanelController.h
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

#import <Cocoa/Cocoa.h>

@class BXEntityDescription;
@class BXPropertyDescription;


@interface BXAInspectorPanelController : NSWindowController
{
	IBOutlet NSView *mEntityAttributesView;
	IBOutlet NSImageView *mEntityTypeImageView;
	IBOutlet NSTableView *mAttributesTableView;
	IBOutlet NSDictionaryController *mPropertyController;
	
	BXEntityDescription *mEntity;
}

+ (id) inspectorPanelController;
- (id) init;
- (void) awakeFromNib;

@property(readonly) NSPredicate* attributeFilterPredicate;
@property(retain) BXEntityDescription* entity;
@property(readonly) NSString* entityTitle;
@property(readonly) NSString* entityName;
@property(readonly) NSImage* entityIcon;
@property(readonly) BOOL isWindowVisible;

- (IBAction) closeWindow: (id) sender;
- (IBAction) propertyDoubleClick: (id) sender;
- (void) bindEntityToObject: (id) observable withKeyPath: (NSString *) keypath;
- (void) displayProperty: (BXPropertyDescription *) property;
- (void) selectProperty: (BXPropertyDescription *) property;
@end