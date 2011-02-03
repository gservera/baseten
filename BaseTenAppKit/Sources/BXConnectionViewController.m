//
// BXConnectionViewController.m
// BaseTen
//
// Copyright 2009 Marko Karppinen & Co. LLC.
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

#import "BXConnectionViewController.h"


@implementation BXConnectionViewController
+ (NSNib *) nibInstance
{
	[NSException raise: NSInternalInconsistencyException format: @"This is an abstract class."];
	return nil;
}

- (id) init
{
	if ((self = [super init]) && [[[self class] nibInstance] instantiateNibWithOwner: self topLevelObjects: NULL])
	{
		mViewSize = [mView frame].size;
	}
	return self;
}

- (void) dealloc
{
	[mView release];
	[mOtherButton release];
	[mCancelButton release];
	[mConnectButton release];
	[mProgressIndicator release];
	[super dealloc];
}

- (NSView *) view
{
	return mView;
}

- (NSSize) viewSize
{
	return mViewSize;
}

- (NSResponder *) initialFirstResponder
{
	return mInitialFirstResponder;
}

- (NSString *) host
{
	return nil;
}

- (NSInteger) port
{
	return -1;
}

- (void) setCanCancel: (BOOL) aBool
{
	mCanCancel = aBool;
}

- (void) setConnecting: (BOOL) aBool
{
	mConnecting = aBool;
}

- (BOOL) isConnecting
{
	return mConnecting;
}

- (BOOL) canCancel
{
	return mCanCancel;
}

- (void) setDelegate: (id <BXConnectionViewControllerDelegate>) object
{
	mDelegate = object;
}

- (IBAction) otherButtonClicked: (id) sender
{
	[mDelegate connectionViewControllerOtherButtonClicked: self];
}

- (IBAction) cancelButtonClicked: (id) sender
{
	[mDelegate connectionViewControllerCancelButtonClicked: self];
}

- (IBAction) connectButtonClicked: (id) sender
{
	[mDelegate connectionViewControllerConnectButtonClicked: self];
}
@end
