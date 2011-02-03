//
// Additions.h
// BaseTen Setup
//
// Copyright 2008-2009 Marko Karppinen & Co. LLC.
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


@interface NSTextFieldCell (BXAAdditions)
- (void) makeEtchedSmall: (BOOL) makeSmall;
@end

@interface NSTextField (BXAAdditions)
- (void) makeEtchedSmall: (BOOL) makeSmall;
@end

@interface NSWindow (BXAAdditions)
- (IBAction) MKCToggle: (id) sender;
@end

NSSize MKCTriangleSize ();
NSRect MKCTriangleRect (NSRect cellFrame);
void MKCDrawTriangleAtCellEnd (NSView* controlView, NSCell* cell, NSRect cellFrame);

CFStringRef MKCCopyDescription (const void *value);
CFHashCode MKCHash (const void *value);
const void* MKCSetRetain (CFAllocatorRef allocator, const void *value);
void MKCRelease (CFAllocatorRef allocator, const void *value);
Boolean MKCEqualRelationshipDescription (const void *value1, const void *value2);
