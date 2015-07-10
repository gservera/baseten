//
// MKCPolishedHeaderCell.m
// BaseTen Setup
//
// Copyright 2008 Marko Karppinen & Co. LLC.
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

#import "MKCPolishedHeaderCell.h"
#import "Additions.h"


@implementation MKCPolishedHeaderCell

- (id) init
{
    if ((self = [super init]))
    {
        _cFlags.vCentered = 1;
		[self setDrawsBackground: NO];
		[self setBezeled: NO];
		[self setBordered: NO];
		[self setBackgroundColor: [NSColor clearColor]];
    }
    return self;
}

- (BOOL) drawsBackground
{
	return NO;
}

- (BOOL) isOpaque
{
	return NO;
}

- (void) _drawBezelWithFrame: (NSRect) fp8 highlighted: (BOOL) fp24 inView: (id) fp28
{
	//It seems that the bezel cannot be prevented in any other manner.
}
@end
