//
// BXHostPanel.m
// BaseTen
//
// Copyright 2009-2010 Marko Karppinen & Co. LLC.
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


#import "BXHostPanel.h"
#import "BXConnectByHostnameViewController.h"
#import "BXConnectUsingBonjourViewController.h"


@implementation BXHostPanel
__strong static NSString* kNSKVOContext = @"kBXHostPanelNSKVOContext";
__strong static NSNib* gNib = nil;

+ (void) initialize
{
	static BOOL tooLate = NO;
	if (! tooLate)
	{
		tooLate = YES;
		gNib = [[NSNib alloc] initWithNibNamed: @"MessageView" bundle: [NSBundle bundleForClass: self]];
	}
}

+ (id) hostPanel
{
	BXHostPanel* retval = [[[self alloc] initWithContentRect: NSZeroRect styleMask: NSTitledWindowMask | NSResizableWindowMask
													 backing: NSBackingStoreBuffered defer: YES] autorelease];	
	return retval;
}

- (id) initWithContentRect: (NSRect) contentRect styleMask: (NSUInteger) styleMask
				   backing: (NSBackingStoreType) bufferingType defer: (BOOL) deferCreation
{
	if ((self = [super initWithContentRect: contentRect styleMask: styleMask backing: bufferingType defer: deferCreation]))
	{
		[gNib instantiateWithOwner: self topLevelObjects: NULL];
		mMessageViewSize = [mMessageView frame].size;
		
		mByHostnameViewController = [[BXConnectByHostnameViewController alloc] init];
		mUsingBonjourViewController = [[BXConnectUsingBonjourViewController alloc] init];
		
		[mByHostnameViewController setDelegate: self];
		[mUsingBonjourViewController setDelegate: self];
		[mByHostnameViewController setCanCancel: YES];
		[mUsingBonjourViewController setCanCancel: YES];

		mCurrentController = mUsingBonjourViewController;
		NSView* content = [mUsingBonjourViewController view];	
		NSSize containerSize = [mUsingBonjourViewController viewSize];
		containerSize.height += 10.0;
		[self setContentSize: containerSize];
		
		NSRect containerFrame = NSZeroRect;
		containerFrame.size = containerSize;
		NSView* container = [[[NSView alloc] initWithFrame: containerFrame] autorelease];
		
		[container addSubview: content];
		[self setContentView: container];
		[self makeFirstResponder: [mUsingBonjourViewController initialFirstResponder]];
		
		NSRect frame = NSZeroRect;
		frame.size = containerSize;
		[self setMinSize: [self frameRectForContentRect: frame].size];
		
		[self addObserver: self forKeyPath: @"message" options: 0 context: kNSKVOContext];
	}
	return self;
}

- (void) dealloc
{
	[mByHostnameViewController release];
	[mUsingBonjourViewController release];
	[mMessageView release];
	[mMessage release];
	[super dealloc];
}

- (void) becomeKeyWindow
{
	[super becomeKeyWindow];
	[mUsingBonjourViewController startDiscovery];
}

- (void) becomeMainWindow
{
	[super becomeMainWindow];
	[mUsingBonjourViewController startDiscovery];
}

- (void) endConnecting
{
	[mCurrentController setConnecting: NO];
	if ([self isVisible])
		[self makeFirstResponder: [mCurrentController initialFirstResponder]];
}

- (NSString *) message
{
	return mMessage;
}

- (void) setMessage: (NSString *) string
{
	if (mMessage != string)
	{
		[mMessage release];
		mMessage = [string retain];
	}
}

- (void) setDelegate: (id <BXHostPanelDelegate>) object
{
	mDelegate = object;
}

- (void) connectionViewControllerOtherButtonClicked: (BXConnectionViewController *) controller
{
	NSRect currentFrame = [self frame];
	NSRect newFrame = currentFrame;

	[[controller view] removeFromSuperview];
	[self display];
		
	mCurrentController = mByHostnameViewController;
	if (controller == mByHostnameViewController)
		mCurrentController = mUsingBonjourViewController;

	NSView* newContent = [mCurrentController view];
	newFrame.size = [mCurrentController viewSize];
	newFrame.size.height += 10.0;
	
	if ([[[self contentView] subviews] containsObject: mMessageView])
		newFrame.size.height += [mMessageView frame].size.height;
	
	newFrame = [self frameRectForContentRect: newFrame];
	newFrame.origin.y -= newFrame.size.height - currentFrame.size.height;
	[self setFrame: newFrame display: YES animate: YES];
	[self setMinSize: newFrame.size];
	[[self contentView] addSubview: newContent];
	
	NSRect contentFrame = NSZeroRect;
	contentFrame.size = [mCurrentController viewSize];
	[newContent setFrame: contentFrame];
	
	[self makeFirstResponder: [mCurrentController initialFirstResponder]];
}

- (void) connectionViewControllerCancelButtonClicked: (BXConnectionViewController *) controller
{
	if ([controller isConnecting])
	{
		[controller setConnecting: NO];		
		[mDelegate hostPanelCancel: self];
	}
	else
	{
		[mDelegate hostPanelEndPanel: self];
		[self setMessage: nil];
		[mUsingBonjourViewController stopDiscovery];
	}
}

- (void) connectionViewControllerConnectButtonClicked: (BXConnectionViewController *) controller
{
	[controller setConnecting: YES];
	[mDelegate hostPanel: self connectToHost: [controller host] port: [controller port]];
}

- (NSSize) windowWillResize: (NSWindow *) window toSize: (NSSize) proposedFrameSize
{
	if (mCurrentController == mByHostnameViewController)
	{
		NSSize oldSize = [window frame].size;
		proposedFrameSize.height = oldSize.height;
	}
	return proposedFrameSize;
}

- (void) observeValueForKeyPath: (NSString *) keyPath ofObject: (id) object change: (NSDictionary *) change context: (void *) context
{
    if (kNSKVOContext == context) 
	{
		NSView* content = [mCurrentController view];
		BOOL hasMessageView = [[[self contentView] subviews] containsObject: mMessageView];
		BOOL isVisible = [self isVisible];
		if (mMessage && !hasMessageView)
		{
			NSUInteger mask = [content autoresizingMask];
			[content setAutoresizingMask: NSViewNotSizable];
			
			NSRect frame = [self frame];
			frame.size.height += mMessageViewSize.height;
			frame.origin.y -= mMessageViewSize.height;
			
			[self setFrame: frame display: isVisible animate: isVisible];
			
			NSRect contentFrame = [content frame];
			NSPoint origin = contentFrame.origin;
			origin.y += contentFrame.size.height;
			[mMessageView setFrameOrigin: origin];
			[[self contentView] addSubview: mMessageView];
			
			[content setAutoresizingMask: mask];
			
			NSSize minSize = [mCurrentController viewSize];
			minSize.height += mMessageViewSize.height;
			[self setMinSize: minSize];
		}
		else if (!mMessage && hasMessageView)
		{
			[mMessageView removeFromSuperview];

			NSUInteger mask = [content autoresizingMask];
			[content setAutoresizingMask: NSViewNotSizable];
			
			NSRect frame = [self frame];
			frame.size.height -= mMessageViewSize.height;
			frame.origin.y += mMessageViewSize.height;
			
			[self setFrame: frame display: isVisible animate: isVisible];
			[content setAutoresizingMask: mask];
			
			[self setMinSize: [mCurrentController viewSize]];
		}
	}
	else 
	{
		[super observeValueForKeyPath: keyPath ofObject: object change: change context: context];
	}
}
@end
