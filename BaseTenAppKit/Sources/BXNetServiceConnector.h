//
// BXNetServiceConnector.h
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
#import <BaseTen/BaseTen.h>
#import <BaseTen/BXHostResolver.h>
#import <BaseTen/BXConnectionSetupManagerProtocol.h>
#import <BaseTenAppKit/BXHostPanel.h>
#import <BaseTenAppKit/BXAuthenticationPanel.h>
@class BXAuthenticationPanel;
@class BXNetServiceConnector;
@class BXDatabaseContext;


enum BXNSConnectorCurrentPanel
{
	kBXNSConnectorNoPanel = 0,
	kBXNSConnectorHostPanel,
	kBXNSConnectorAuthenticationPanel
};



@protocol BXNSConnectorImplementation <NSObject>
- (void) beginConnectionAttempt;
- (void) endConnectionAttempt;
- (NSString *) runLoopMode;
- (void) presentError: (NSError *) error didEndSelector: (SEL) selector;
- (void) displayHostPanel: (BXHostPanel *) hostPanel;
- (void) endHostPanel: (BXHostPanel *) hostPanel;
- (void) displayAuthenticationPanel: (BXAuthenticationPanel *) authenticationPanel;
- (void) endAuthenticationPanel: (BXAuthenticationPanel *) authenticationPanel;
@end



@interface BXNSConnectorImplementation : NSObject
{
	BXNetServiceConnector* mConnector;
}
- (id) initWithConnector: (BXNetServiceConnector *) connector;
@end



@interface BXNetServiceConnector : NSObject <BXConnector, BXHostPanelDelegate, BXAuthenticationPanelDelegate, BXHostResolverDelegate>
{
	NSWindow* mModalWindow; //Weak
	BXDatabaseContext* mContext; //Weak
	BXNSConnectorImplementation <BXNSConnectorImplementation> *mConnectorImpl;
	BXHostResolver *mHostResolver;
	
	BXHostPanel* mHostPanel;
	BXAuthenticationPanel* mAuthenticationPanel;
	enum BXNSConnectorCurrentPanel mCurrentPanel;
	
	NSString* mHostName;
	NSInteger mPort;
}
- (NSWindow *) modalWindow;
- (void) recoveredFromConnectionError: (BOOL) didRecover;
- (void) endConnectionAttempt;
@end
