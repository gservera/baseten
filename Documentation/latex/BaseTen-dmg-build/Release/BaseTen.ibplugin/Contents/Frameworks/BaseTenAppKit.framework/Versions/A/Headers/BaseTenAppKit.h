//
// BaseTenAppKit.h
// BaseTen
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

#import <BaseTenAppKit/BXSynchronizedArrayController.h>
#import <BaseTenAppKit/BXObjectStatusToColorTransformer.h>
#import <BaseTenAppKit/BXAttributeValuePredicateEditorRowTemplateFactory.h>
#import <BaseTenAppKit/BXMultipleChoicePredicateEditorRowTemplateFactory.h>


/**
 * \defgroup baseten_appkit BaseTenAppKit
 * BaseTenAppKit is a separate framework with AppKit bindings.
 * It contains a subclass of NSArrayController, namely 
 * BXSynchronizedArrayController, generic connection panels for use with
 * Bonjour and manually entered addresses and value transformers.
 */

/**
 * \defgroup value_transformers Value Transformers
 * Transform database objects' status to various information.
 * BXDatabaseObject has BXDatabaseObject#statusInfo method which
 * returns a proxy for retrieving object's status. The status may
 * then be passed to NSValueTransformer subclasses. For example, 
 * an NSTableColumn's editable binding may be bound to a key path
 * like arrayController.arrangedObjects.statusInfo.some_key_name
 * and the value transformer may then be set to
 * BXObjectStatusToEditableTransformer.
 * \ingroup baseten_appkit
 */
