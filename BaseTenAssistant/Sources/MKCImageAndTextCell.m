//
// MKCImageAndTextCell.m
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

#import "MKCImageAndTextCell.h"


@implementation MKCImageAndTextCell
@synthesize image = mImage;

- (id) init 
{
    if ((self = [super init])) 
	{
        [self setLineBreakMode: NSLineBreakByTruncatingTail];
    }
    return self;
}

- (void) dealloc
{
	[super dealloc];
}

- (NSRect) titleRectForBounds: (NSRect) bounds
{
	NSRect retval = [super titleRectForBounds: bounds];
	retval.origin.y += 2.0;
	retval.size.height -= 2.0;
	if (nil != [self image])
	{
		NSRect imageRect = [self imageRectForBounds: bounds];
		CGFloat delta = 2 * (imageRect.origin.x - bounds.origin.x);
		delta += imageRect.size.width;
		retval.origin.x += delta;
		retval.size.width -= delta;
	}
	return retval;
}

- (NSRect) imageRectForBounds: (NSRect) bounds
{
	NSSize imageSize = [[self image] size];
	CGFloat delta = MIN (bounds.size.width - imageSize.width, bounds.size.height - imageSize.height) / 2.0;
	delta = MAX (1.5, delta);
	
	NSRect retval = NSInsetRect (bounds, delta, delta);
	retval.size.width  = MIN (retval.size.width,  imageSize.width);
	retval.size.height = MIN (retval.size.height, imageSize.height);
	return retval;
}

- (void) drawWithFrame: (NSRect) cellFrame inView: (NSView *) controlView
{
	NSRect titleFrame = [self titleRectForBounds: cellFrame];
	[super drawWithFrame: titleFrame inView: controlView];
	if (nil != [self image])
	{
		NSRect imageRect = [self imageRectForBounds: cellFrame];
		NSPoint origin = imageRect.origin;
		if ([controlView isFlipped])
			origin.y += imageRect.size.height;
		imageRect.origin = NSZeroPoint;
        [[self image] drawAtPoint:origin fromRect:imageRect operation:NSCompositeSourceOver fraction:1.0];        
	}
}
@end
