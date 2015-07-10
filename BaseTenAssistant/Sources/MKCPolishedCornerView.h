//
// MKCPolishedCornerView.h
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
#import "MKCPolishedHeaderView.h"


@interface MKCPolishedCornerView : NSView 
{
    NSDictionary* mColours;
    enum MKCPolishDrawingMask mDrawingMask;
    BOOL mDrawsHandle;
}

- (NSDictionary *) colours;
- (void) setColours: (NSDictionary *) aColours;

- (enum MKCPolishDrawingMask) drawingMask;
- (void) setDrawingMask: (enum MKCPolishDrawingMask) aDrawingMask;

- (BOOL) drawsHandle;
- (void) setDrawsHandle: (BOOL) flag;
- (NSRect) handleRect;

@end
