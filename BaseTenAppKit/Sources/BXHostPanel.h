//
// BXHostPanel.h
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

#import <Cocoa/Cocoa.h>
#import <BaseTenAppKit/BXPanel.h>
#import <BaseTenAppKit/BXConnectionViewController.h>
@class BXConnectByHostnameViewController;
@class BXConnectUsingBonjourViewController;


@protocol BXHostPanelDelegate <NSObject>
- (void) hostPanelCancel: (id) panel;
- (void) hostPanelEndPanel: (id) panel;
- (void) hostPanel: (id) panel connectToHost: (NSString *) host port: (NSInteger) port;
@end


@interface BXHostPanel : BXPanel <BXConnectionViewControllerDelegate>
{
	BXConnectByHostnameViewController* mByHostnameViewController;
	BXConnectUsingBonjourViewController* mUsingBonjourViewController;
	BXConnectionViewController* mCurrentController;
	IBOutlet NSView* mMessageView;
	NSSize mMessageViewSize;
	NSString* mMessage;
	id <BXHostPanelDelegate> mDelegate; //Weak
	BOOL mConnecting;
}
+ (id) hostPanel;
- (void) setDelegate: (id <BXHostPanelDelegate>) object;
- (void) setMessage: (NSString *) string;
- (void) endConnecting;
@end
