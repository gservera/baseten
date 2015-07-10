//
// MKCForcedSizeToFitButtonCell.m
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

#import "MKCForcedSizeToFitButtonCell.h"


@implementation MKCForcedSizeToFitButtonCell

- (void) drawWithFrame: (NSRect) cellFrame inView: (NSView *) controlView
{
    NSSize oldSize = cellFrame.size;
    cellFrame.size = [self cellSize];
    
    if (oldSize.width > cellFrame.size.width)
        cellFrame.origin.x += (oldSize.width - cellFrame.size.width) / 2.0;
    if (oldSize.height > cellFrame.size.height)
        cellFrame.origin.y += (oldSize.height - cellFrame.size.height) / 2.0;
    
    [super drawWithFrame: cellFrame inView: controlView];
}

@end
