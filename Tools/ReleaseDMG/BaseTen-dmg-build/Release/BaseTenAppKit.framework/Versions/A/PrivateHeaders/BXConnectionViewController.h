//
// BXConnectionViewController.h
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

@class BXConnectionViewController;


@protocol BXConnectionViewControllerDelegate <NSObject>
- (void) connectionViewControllerOtherButtonClicked: (BXConnectionViewController *) controller;
- (void) connectionViewControllerCancelButtonClicked: (BXConnectionViewController *) controller;
- (void) connectionViewControllerConnectButtonClicked: (BXConnectionViewController *) controller;
@end


@interface BXConnectionViewController : NSObject
{
	id <BXConnectionViewControllerDelegate> mDelegate; //Weak
	IBOutlet NSView* mView;
	IBOutlet NSButton* mOtherButton;
	IBOutlet NSButtonCell* mCancelButton;
	IBOutlet NSButtonCell* mConnectButton;
	IBOutlet NSProgressIndicator* mProgressIndicator;
	IBOutlet NSResponder* mInitialFirstResponder;
	NSSize mViewSize;
	BOOL mConnecting;
	BOOL mCanCancel;
}
- (NSView *) view;
- (NSSize) viewSize;
- (NSResponder *) initialFirstResponder;

- (NSString *) host;
- (NSInteger) port;

- (void) setDelegate: (id <BXConnectionViewControllerDelegate>) object;
- (void) setCanCancel: (BOOL) aBool;
- (BOOL) canCancel;
- (void) setConnecting: (BOOL) aBool;
- (BOOL) isConnecting;

- (IBAction) otherButtonClicked: (id) sender;
- (IBAction) cancelButtonClicked: (id) sender;
- (IBAction) connectButtonClicked: (id) sender;
@end
