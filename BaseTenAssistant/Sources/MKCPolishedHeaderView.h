//
// MKCPolishedHeaderView.h
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


extern NSString* kMKCEnabledColoursKey;
extern NSString* kMKCDisabledColoursKey;
extern NSString* kMKCSelectedColoursKey;


extern NSString* kMKCGradientKey;
extern NSString* kMKCTopAccentColourKey;
extern NSString* kMKCLeftAccentColourKey;
extern NSString* kMKCLeftLineColourKey;
extern NSString* kMKCRightLineColourKey;
extern NSString* kMKCTopLineColourKey;
extern NSString* kMKCBottomLineColourKey;
extern NSString* kMKCRightAccentColourKey;
extern NSString* kMKCSeparatorLineColourKey;


enum MKCPolishDrawingMask {
    kMKCPolishDrawingMaskEmpty   = 0,
    kMKCPolishDrawTopLine        = 1 << 1,
    kMKCPolishDrawBottomLine     = 1 << 2,
    kMKCPolishDrawLeftLine       = 1 << 3,
    kMKCPolishDrawRightLine      = 1 << 4,
    kMKCPolishDrawTopAccent      = 1 << 5,
    kMKCPolishDrawLeftAccent     = 1 << 8,
    kMKCPolishDrawRightAccent    = 1 << 9,
    kMKCPolishDrawSeparatorLines = 1 << 10,
	
	kMKCPolishNoLeftAccentForLeftmostColumn = 1 << 6,
	
    MKCPolishDrawAllLines = (kMKCPolishDrawTopLine | 
                             kMKCPolishDrawBottomLine | 
                             kMKCPolishDrawLeftLine | 
                             kMKCPolishDrawRightLine | 
                             kMKCPolishDrawTopAccent | 
                             kMKCPolishDrawLeftAccent | 
                             kMKCPolishDrawRightAccent | 
                             kMKCPolishDrawSeparatorLines),
};


void
MKCDrawPolishInRect (NSRect rect, NSDictionary* colours, enum MKCPolishDrawingMask mask);

BOOL
MKCShouldDrawEnabled (NSWindow* window);


@interface MKCPolishedHeaderView : NSTableHeaderView 
{
    NSDictionary* mColours;
    enum MKCPolishDrawingMask mDrawingMask;
	NSTableColumn* mColumnSortedBy;
	BOOL mReversedOrder;
}

+ (NSDictionary *) darkColours;
+ (NSDictionary *) lightColours;
+ (NSDictionary *) testColours;

- (NSDictionary *) colours;
- (void) setColours: (NSDictionary *) aColours;
- (enum MKCPolishDrawingMask) drawingMask;
- (void) setDrawingMask: (enum MKCPolishDrawingMask) aDrawingMask;

@end
