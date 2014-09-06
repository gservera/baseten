//
// BXAGetInfoWindowController.m
// BaseTen Assistant
//
// Copyright 2008-2010 Marko Karppinen & Co. LLC.
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
// $Id$
//

#import "BXAController.h"
#import "BXAGetInfoWindowController.h"


@implementation BXAGetInfoWindowController
#pragma mark Initialisation & Dealloc
+ (id) getInfoWindowController
{
	return [[[BXAGetInfoWindowController alloc] init] autorelease];
}


- (NSWindow *) windowPrototype: (NSRect) contentRect
{
	NSUInteger windowStyle = NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask | NSResizableWindowMask;
	NSWindow* window = [[[NSWindow alloc] initWithContentRect: contentRect styleMask: windowStyle 
													  backing: NSBackingStoreBuffered defer: YES] autorelease];
	return window;
}


- (void) displayProperty: (BXPropertyDescription *) property
{
	BXAGetInfoWindowController *windowController = [(BXAController*)[NSApp delegate] displayInfoForEntity: [property entity]];
	[windowController selectProperty: property];
}
@end



@implementation BXAGetInfoWindowController (NSWindowDelegate)
- (void) windowWillClose: (NSNotification *) notification
{
	// Dispose of get info windows after they are closed
	[self autorelease];
}
@end
