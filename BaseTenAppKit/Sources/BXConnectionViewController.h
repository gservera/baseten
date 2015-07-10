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
@import Cocoa;

@protocol BXConnectionViewControllerDelegate <NSObject>
- (void)connectionViewControllerOtherButtonClicked:(BXConnectionViewController *)controller;
- (void)connectionViewControllerCancelButtonClicked:(BXConnectionViewController *)controller;
- (void)connectionViewControllerConnectButtonClicked:(BXConnectionViewController *)controller;
@end

@interface BXConnectionViewController : NSObject {
	IBOutlet NSView* mView;
	IBOutlet NSButton* mOtherButton;
	IBOutlet NSButtonCell* mCancelButton;
	IBOutlet NSButtonCell* mConnectButton;
	IBOutlet NSProgressIndicator* mProgressIndicator;
	IBOutlet NSResponder* mInitialFirstResponder;
	NSSize mViewSize;
}

- (NSView *)view;
- (NSSize)viewSize;
- (NSResponder *)initialFirstResponder;
- (NSString *)host;
- (NSInteger)port;
- (IBAction)otherButtonClicked:(id)sender;
- (IBAction)cancelButtonClicked:(id)sender;
- (IBAction)connectButtonClicked:(id)sender;

@property (nonatomic, assign, getter=isConnecting) BOOL connecting;
@property (nonatomic, assign) BOOL canCancel;
@property (nonatomic, weak) id <BXConnectionViewControllerDelegate> delegate;
@end
