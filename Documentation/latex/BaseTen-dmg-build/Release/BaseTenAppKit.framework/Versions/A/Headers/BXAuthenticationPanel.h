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

#import <Cocoa/Cocoa.h>
#import <BaseTenAppKit/BXPanel.h>

@class BXDatabaseContext;


@protocol BXAuthenticationPanelDelegate <NSObject>
- (void) authenticationPanelCancel: (id) panel;
- (void) authenticationPanelEndPanel: (id) panel;
- (void) authenticationPanel: (id) panel gotUsername: (NSString *) username password: (NSString *) password;
@end


@interface BXAuthenticationPanel : BXPanel 
{	
	//Retained
	NSString*							mUsername;
	NSString*							mPassword;
	NSString*							mMessage;
	NSString*							mAddress;
	
    //Top-level objects
    IBOutlet NSView*                	mPasswordAuthenticationView;
    
    IBOutlet NSTextFieldCell*       	mUsernameField;
    IBOutlet NSSecureTextFieldCell*		mPasswordField;
    IBOutlet NSButton*              	mRememberInKeychainButton;
	IBOutlet NSTextField*				mMessageTextField;
    IBOutlet NSMatrix*              	mCredentialFieldMatrix;
	IBOutlet NSProgressIndicator*		mProgressIndicator;

	id <BXAuthenticationPanelDelegate>	mDelegate;

    BOOL                            	mIsAuthenticating;
	BOOL								mShouldStorePasswordInKeychain;
	BOOL								mMessageFieldHasContent;
}

+ (id) authenticationPanel;

- (BOOL) shouldStorePasswordInKeychain;
- (void) setShouldStorePasswordInKeychain: (BOOL) aBool;
- (NSString *) username;
- (void) setUsername: (NSString *) aString;
- (NSString *) password;
- (void) setPassword: (NSString *) aString;
- (NSString *) message;
- (void) setMessage: (NSString *) aString;
- (NSString *) address;
- (void) setAddress: (NSString *) aString;
- (BOOL) isAuthenticating;
- (void) setAuthenticating: (BOOL) aBool;
- (id <BXAuthenticationPanelDelegate>) delegate;
- (void) setDelegate: (id <BXAuthenticationPanelDelegate>) object;
@end


@interface BXAuthenticationPanel (IBActions)
- (IBAction) authenticate: (id) sender;
- (IBAction) cancelAuthentication: (id) sender;
@end
