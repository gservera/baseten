//
// Additions.m
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

#import "Additions.h"


@implementation NSTextFieldCell (BXAAdditions)
- (void) makeEtchedSmall: (BOOL) makeSmall
{
    NSAttributedString* originalText = [self attributedStringValue];
    NSShadow* shadow = [[[NSShadow alloc] init] autorelease];
    [shadow setShadowBlurRadius: 0.0];
    
    NSColor* shadowColor = nil;
    if (makeSmall)
        shadowColor = [NSColor colorWithDeviceWhite: 222.0 / 255.0 alpha: 1.0];
    else
        shadowColor = [NSColor whiteColor];
    
    [shadow setShadowColor: shadowColor];
    [shadow setShadowOffset: NSMakeSize (0.0, -1.0)];
    NSMutableDictionary* attrs = nil;
    if (0 == [originalText length])
        attrs = [NSMutableDictionary dictionary];
    else
    {
        attrs = [NSMutableDictionary dictionaryWithDictionary: 
            [originalText attributesAtIndex: 0 effectiveRange: NULL]];
    }
    [attrs setObject: shadow forKey: NSShadowAttributeName];
    [attrs setObject: [NSColor blackColor] forKey: NSStrokeColorAttributeName];
	CGFloat smallFontSize = [NSFont smallSystemFontSize];
    if (makeSmall)
        [attrs setObject: [NSFont systemFontOfSize: smallFontSize] forKey: NSFontAttributeName];
	else
        [attrs setObject: [NSFont systemFontOfSize: smallFontSize + 0.5] forKey: NSFontAttributeName];
    NSMutableAttributedString* text = [[[NSMutableAttributedString alloc] initWithAttributedString: originalText] autorelease];
    [text setAttributes: attrs range: NSMakeRange (0, [text length])];
    [self setAttributedStringValue: text];    
}
@end


@implementation NSTextField (BXAAdditions)
- (void) makeEtchedSmall: (BOOL) makeSmall
{
    [[self cell] makeEtchedSmall: makeSmall];
}
@end


@implementation NSWindow (BXAAdditions)
- (IBAction) MKCToggle: (id) sender
{
    if ([self isVisible])
        [self orderOut: nil];
    else
        [self makeKeyAndOrderFront: nil];
}
@end


@implementation NSArrayController (BXAAdditions)
- (BOOL) MKCHasEmptySelection
{
    return NSNotFound == [self selectionIndex];
}
@end


const static float kRightOffset = 5.0;
static NSImage* kActiveTriangle = nil;
static NSImage* kInactiveTriangle = nil;


NSSize
MKCTriangleSize ()
{
    if (nil == kActiveTriangle)
        kActiveTriangle = [[NSImage imageNamed: @"triangle-active"] retain];
    if (nil == kInactiveTriangle)
        kInactiveTriangle = [[NSImage imageNamed: @"triangle-inactive"] retain];
    NSCAssert (NSEqualSizes ([kActiveTriangle size], [kInactiveTriangle size]), @"Expected image sizes to match.");    
    return [kActiveTriangle size];
}


NSRect
MKCTriangleRect (NSRect cellFrame)
{
    NSSize imageSize = MKCTriangleSize ();
    NSRect imageRect = NSZeroRect;
    imageRect.size = imageSize;
    imageRect.origin.x = cellFrame.origin.x + cellFrame.size.width - (imageSize.width + kRightOffset);
    imageRect.origin.y = cellFrame.origin.y + (cellFrame.size.height - imageSize.height) / 2.0;    
    return imageRect;
}


void
MKCDrawTriangleAtCellEnd (NSView* controlView, NSCell* cell, NSRect cellFrame)
{            
    NSImage* image = kInactiveTriangle;
    if ([cell cellAttribute: NSCellHighlighted] || [cell isHighlighted])
        image = kActiveTriangle;
    
    NSRect imageRect = NSZeroRect;
    imageRect.size = MKCTriangleSize ();
    [image drawInRect: MKCTriangleRect (cellFrame)
             fromRect: imageRect 
            operation: NSCompositeSourceOver
             fraction: 1.0];
}


CFStringRef 
MKCCopyDescription (const void *value)
{
    return (CFStringRef) [[(id) value description] retain];
}

CFHashCode 
MKCHash (const void *value)
{
    return [(id) value hash];
}

const void*
MKCSetRetain (CFAllocatorRef allocator, const void *value)
{
    return CFRetain (value);
}

void 
MKCRelease (CFAllocatorRef allocator, const void *value)
{
    CFRelease (value);
}

Boolean 
MKCEqualRelationshipDescription (const void *value1, const void *value2)
{
	Boolean retval = FALSE;
    id v1 = (id) value1;
    id v2 = (id) value2;
	if ([v1 isKindOfClass: [NSRelationshipDescription class]] &&
        [v2 isKindOfClass: [NSRelationshipDescription class]])
	{
		if ([[v1 name] isEqual: [v2 name]] &&
			[[v1 entity] isEqual: [v2 entity]] &&
			[[v1 destinationEntity] isEqual: [v2 destinationEntity]])
			retval = YES;
	} 
	return retval;
}

