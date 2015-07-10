//
// MKCPolishedCornerView.m
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

#import "MKCPolishedCornerView.h"
#import "MKCPolishedHeaderView.h"


@implementation MKCPolishedCornerView

- (void) stateChanged: (NSNotification *) notification
{
	[self setNeedsDisplay: YES];
}

- (id) initWithFrame: (NSRect) frame
{
    if ((self = [super initWithFrame: frame]))
    {
		NSWindow* window = [self window];
		NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
		[nc addObserver: self selector: @selector (stateChanged:) name: NSApplicationDidBecomeActiveNotification object: NSApp];
		[nc addObserver: self selector: @selector (stateChanged:) name: NSApplicationDidResignActiveNotification object: NSApp];
		[nc addObserver: self selector: @selector (stateChanged:) name: NSWindowDidBecomeKeyNotification object: window];
		[nc addObserver: self selector: @selector (stateChanged:) name: NSWindowDidResignKeyNotification object: window];
    }
    return self;
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver: self];
    [mColours release];
    [super dealloc];
}

- (void) drawRect: (NSRect) rect
{
    if (nil == mColours)
        [self setColours: [MKCPolishedHeaderView darkColours]];
	
	NSDictionary* enabledColours = nil;
	if (MKCShouldDrawEnabled ([self window]))
		enabledColours = [mColours objectForKey: kMKCEnabledColoursKey];
	else
		enabledColours = [mColours objectForKey: kMKCDisabledColoursKey];

    NSRect bounds = [self bounds];
    float height = bounds.size.height;
    NSRect polishRect = rect;
    polishRect.size.height = height;
    polishRect.origin.y = 0.0;
    MKCDrawPolishInRect (polishRect, enabledColours, mDrawingMask);

    //Lines at the end
    if (kMKCPolishDrawRightAccent & mDrawingMask)
    {
        NSRect endRect = bounds;
        endRect.origin.x = bounds.size.width - 2.0;
        endRect.origin.y += 1.0;
        endRect.size.width = 1.0;
        endRect.size.height -= 2.0;
        NSRect intersection = NSIntersectionRect (endRect, rect);
        if (NO == NSIsEmptyRect (intersection))
        {
            [(NSColor*)[enabledColours objectForKey: kMKCRightLineColourKey] set];
            NSRectFill (intersection);
        }
    }
    
    if (kMKCPolishDrawRightLine & mDrawingMask)
    {
        NSRect endRect = bounds;
        endRect.origin.x = bounds.size.width - 1.0;
        endRect.origin.y += 1.0;
        endRect.size.width = 1.0;
        endRect.size.height -= 2.0;
        NSRect intersection = NSIntersectionRect (endRect, rect);
        if (NO == NSIsEmptyRect (intersection))
        {
            [(NSColor*)[enabledColours objectForKey: kMKCRightLineColourKey] set];
            NSRectFill (intersection);
        }
    }
    
    if (mDrawsHandle)
    {
        NSRect bottomDarkLine = NSMakeRect (1.0, 6.0, 1.0, 6.0);
        NSRect topDarkLine = NSMakeRect (1.0, 12.0, 1.0, 4.0);
        NSRect whiteLine = NSMakeRect (2.0, 5.0, 1.0, 10.0);

        NSColor* bottomDarkColor = [NSColor colorWithDeviceWhite: 91.0 / 255.0 alpha: 1.0];
        NSColor* topDarkColor = [NSColor colorWithDeviceWhite: 97.0 / 255.0 alpha: 1.0];
        NSColor* whiteColor = [NSColor whiteColor];
        
        for (int i = 0; i < 3; i++)
        {
            NSRect intersection = NSZeroRect;
            
            intersection = NSIntersectionRect (rect, bottomDarkLine);
            if (NO == NSIsEmptyRect (intersection))
            {
                [bottomDarkColor set];
                NSRectFill (intersection);
            }
            
            intersection = NSIntersectionRect (rect, topDarkLine);
            if (NO == NSIsEmptyRect (intersection))
            {
                [topDarkColor set];
                NSRectFill (intersection);
            }
            
            intersection = NSIntersectionRect (rect, whiteLine);
            if (NO == NSIsEmptyRect (whiteLine))
            {
                [whiteColor set];
                NSRectFill (intersection);
            }
            
            bottomDarkLine.origin.x += 3.0;
            topDarkLine.origin.x += 3.0;
            whiteLine.origin.x += 3.0;
        }
    }
}

- (BOOL) drawsHandle
{
    return mDrawsHandle;
}

- (void) setDrawsHandle: (BOOL) flag
{
    mDrawsHandle = flag;
}

- (NSRect) handleRect
{
    return NSMakeRect (1.0, 6.0, 8.0, 10.0);
}

- (BOOL) isFlipped
{
    return NO;
}

- (NSDictionary *) colours
{
    return mColours; 
}

- (void) setColours: (NSDictionary *) aColours
{
    if (mColours != aColours) {
        [mColours release];
        mColours = [aColours retain];
    }
}

- (enum MKCPolishDrawingMask) drawingMask
{
    return mDrawingMask;
}

- (void) setDrawingMask: (enum MKCPolishDrawingMask) aDrawingMask
{
    mDrawingMask = aDrawingMask;
}

@end
