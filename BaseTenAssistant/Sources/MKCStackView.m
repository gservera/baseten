//
// MKCStackView.m
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

#import "MKCStackView.h"


@implementation MKCStackView
- (id) initWithFrame: (NSRect) frame
{
	if ((self = [super initWithFrame: frame]))
	{
		[self setAutoresizesSubviews: YES];
	}
	return self;
}

- (BOOL) isFlipped
{
	return YES;
}

- (BOOL) isOpaque
{
	return YES;
}

- (void) drawRect: (NSRect) aRect
{
	NSRect mask = NSZeroRect;
	int i = 0;
	NSColor* lightBlue = [NSColor colorWithCalibratedRed: 236.0 / 255.0 green: 243.0 / 255.0 blue: 254.0 / 255.0 alpha: 1.0];
	for (NSView* subview in [self subviews])
	{
		NSRect subviewRect = [subview frame];
		NSUnionRect (subviewRect, mask);
		
		if (NSIntersectsRect (subviewRect, aRect))
		{
			if (i % 2)
				[lightBlue set];
			else
				[[NSColor whiteColor] set];
			
			NSRectFill (NSIntersectionRect (subviewRect, aRect));
		}
		i++;
	}
	
	if (! NSContainsRect (mask, aRect))
	{
		CGFloat endY = aRect.origin.y + aRect.size.height;
		CGFloat originY = endY - (mask.origin.y + mask.size.height);

		aRect.origin.y = originY;
		aRect.size.height = endY - originY;
		[[NSColor whiteColor] set];
		NSRectFill (aRect);
	}
}

- (void) addViewToStack: (NSView *) aView
{	
	//An extra step for height-tracking text views.
	{
		NSSize mySize = [self frame].size;
		NSSize viewSize = [aView frame].size;
		viewSize.width = mySize.width;
		[aView setFrameSize: viewSize];
	}
	
	[aView setPostsFrameChangedNotifications: YES];
	NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
	[nc addObserver: self selector: @selector (viewFrameChanged:) 
			   name: NSViewFrameDidChangeNotification object: aView];	
	
	NSArray* subviews = [self subviews];
	NSView* last = [subviews lastObject];
	NSPoint lastOrigin = (last ? [last frame].origin: NSZeroPoint);
	NSRect frame = [aView frame];
	
	NSSize size = [self frame].size;
	size.height += frame.size.height;
	[self setFrameSize: size];
	
	frame.origin = lastOrigin;
	frame.origin.y += frame.size.height;
	[aView setFrame: frame];
	[aView setAutoresizingMask: NSViewWidthSizable];
	[self addSubview: aView];
}

- (void) removeViewFromStack: (NSView *) aView
{
	BOOL found = NO;
	CGFloat height = [aView frame].size.height;
	for (NSView* subview in [[self subviews] copy])
	{
		if (found)
		{
			NSPoint origin = [subview frame].origin;
			origin.y -= height;
			[subview setFrameOrigin: origin];
		}
		else if (subview == aView)
		{
			found = YES;
			NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
			[nc removeObserver: self
						  name: NSViewFrameDidChangeNotification 
						object: aView];
			[aView removeFromSuperview];
		}
	}
}

- (void) removeAllViews
{
	NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
	for (NSView* subview in [[self subviews] copy])
	{
		[nc removeObserver: self
					  name: NSViewFrameDidChangeNotification 
					object: subview];
		[subview removeFromSuperview];
	}
}

- (void) viewFrameChanged: (NSNotification *) notification
{
	NSView* view = [notification object];
	CGFloat nextY = 0.0;
	CGFloat totalHeight = 0.0;
	BOOL found = NO;
	for (NSView* subview in [self subviews])
	{
		NSRect frame = [subview frame];
		totalHeight += frame.size.height;
		if (found)
		{
			CGFloat temp = nextY + frame.size.height;
			frame.origin.y = nextY;
			[subview setFrameOrigin: frame.origin];
			nextY = temp;
		}
		else if (subview == view)
		{
			found = YES;
			nextY = frame.origin.y + frame.size.height;
		}
	}
	
	NSSize size = [self frame].size;
	size.height = totalHeight;
	[self setFrameSize: size];
}
@end
