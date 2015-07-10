//
// BXDatabaseContextAdditions.h
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

#import <BaseTen/BaseTen.h>

@class NSWindow;


@interface BXDatabaseContext (BaseTenAppKitAdditions)
- (void) displayPanelForTrust: (SecTrustRef) trust;
- (void) displayPanelForTrust: (SecTrustRef) trust modalWindow: (NSWindow *) aWindow;
- (void) certificateTrustSheetDidEnd: (NSWindow *) sheet returnCode: (int) returnCode contextInfo: (void *) trust;
- (id <BXConnector>) copyDefaultConnectionSetupManager;
@end
