//
// BXAuthenticationPanel.h
// BaseTen
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

@import Cocoa;

@class BXDatabaseContext;

@protocol BXAuthenticationPanelDelegate <NSWindowDelegate>
- (void) authenticationPanelCancel: (id) panel;
- (void) authenticationPanelEndPanel: (id) panel;
- (void) authenticationPanel: (id) panel gotUsername: (NSString *) username password: (NSString *) password;
@end

@interface BXAuthenticationPanel : NSPanel {
    //Top-level objects
    IBOutlet NSView*                	mPasswordAuthenticationView;
    IBOutlet NSTextFieldCell*       	mUsernameField;
    IBOutlet NSSecureTextFieldCell*		mPasswordField;
    IBOutlet NSButton*              	mRememberInKeychainButton;
	IBOutlet NSTextField*				mMessageTextField;
    IBOutlet NSMatrix*              	mCredentialFieldMatrix;
	IBOutlet NSProgressIndicator*		mProgressIndicator;
	BOOL								mMessageFieldHasContent;
}

+ (instancetype)authenticationPanel;
- (IBAction)authenticate:(id)sender;
- (IBAction)cancelAuthentication:(id)sender;

@property (nonatomic, strong) NSString * address;
@property (nonatomic, strong) NSString * username;
@property (nonatomic, strong) NSString * password;
@property (nonatomic, strong) NSString * message;
@property (nonatomic, assign) BOOL shouldStorePasswordInKeychain;
@property (nonatomic, assign, getter=isAuthenticating) BOOL authenticating;
@property (weak) id <BXAuthenticationPanelDelegate> delegate;
@end

