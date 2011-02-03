//
// MKCPolishedSeparatorView.m
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

#import "MKCPolishedSeparatorView.h"


@implementation MKCPolishedSeparatorView

- (id) initWithFrame: (NSRect) frame 
{
    if ((self = [super initWithFrame: frame]))
    {
    }
    return self;
}

- (BOOL) isFlipped
{
    return YES;
}

- (void) drawRect: (NSRect) rect 
{
    NSRect intersection = NSZeroRect;

    NSRect topRect =  NSMakeRect (0.0, 0.0, 1.0, 1.0);
    if (NSIntersectsRect (rect, topRect))
    {
        [[NSColor blackColor] set];
        NSRectFill (topRect);
    }
    
    NSRect topRect2 = NSMakeRect (0.0, 1.0, 1.0, 21.0);
    if (NSIntersectsRect (rect, topRect2))
    {
		//Patch by Tim Bedford 2008-08-11
        //[[NSColor colorWithDeviceWhite: 127.0 / 255.0 alpha: 1.0] set];
		[[NSColor colorWithCatalogName:@"Developer" colorName:@"controlColor"] set];
		//End patch
        NSRectFill (topRect2);
    }
    
    NSRect topRect3 = NSMakeRect (0.0, 22.0, 1.0, 1.0);
    if (NSIntersectsRect (rect, topRect3))
    {
		//Patch by Tim Bedford 2008-08-11
        //[[NSColor colorWithDeviceWhite: 62.0 / 255.0 alpha: 1.0] set];
		[[NSColor colorWithCatalogName:@"Developer" colorName:@"windowFrameColor"] set];
		//End patch
        NSRectFill (topRect3);
    }
    
    NSRect bottomRect = NSMakeRect (0.0, 23.0, 1.0, [self frame].size.height - 23.0);
    intersection = NSIntersectionRect (rect, bottomRect);
    if (NO == NSIsEmptyRect (intersection))
    {
		//Patch by Tim Bedford 2008-08-11
        //[[NSColor colorWithDeviceWhite: 178.0 / 255.0 alpha: 1.0] set];
		[[NSColor colorWithCatalogName:@"Developer" colorName:@"controlShadowColor"] set];
		//End patch
        NSRectFill (intersection);
    }
}

@end
