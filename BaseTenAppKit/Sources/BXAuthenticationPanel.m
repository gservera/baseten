//
// BXAuthenticationPanel.m
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
#import "BXAuthenticationPanel.h"


__strong static NSNib* gAuthenticationViewNib = nil;
static const CGFloat kSizeDiff = 25.0;

@implementation BXAuthenticationPanel

+ (void)initialize {
    if (self == [BXAuthenticationPanel class]) {
        gAuthenticationViewNib = [[NSNib alloc] initWithNibNamed:@"AuthenticationView"
                                                          bundle:[NSBundle bundleForClass:self]];
    }
}

+ (instancetype)authenticationPanel {
	return [[self alloc] initWithContentRect:NSZeroRect
                                   styleMask:NSTitledWindowMask
                                     backing:NSBackingStoreBuffered
                                       defer:YES];
}

- (instancetype)initWithContentRect:(NSRect)contentRect
                          styleMask:(NSUInteger)aStyle
                            backing:(NSBackingStoreType)b
                              defer:(BOOL)flag {
    self = [super initWithContentRect:contentRect styleMask:aStyle backing:b defer:flag];
    if (self) {
        [gAuthenticationViewNib instantiateWithOwner: self topLevelObjects: NULL];
		
		NSRect contentFrame = [mPasswordAuthenticationView frame];
        contentFrame.size.height -= kSizeDiff;
		NSRect windowFrame = [self frameRectForContentRect: contentFrame];
		[self setFrame: windowFrame display: NO];
		[self setMinSize: windowFrame.size];
		
		[self setContentView: mPasswordAuthenticationView];
		[mPasswordAuthenticationView setAutoresizingMask:
		 NSViewMinXMargin | NSViewMaxXMargin | NSViewWidthSizable |
		 NSViewMinYMargin | NSViewMaxYMargin | NSViewHeightSizable];

        self.hidesOnDeactivate = NO;
    }
    return self;
}

- (NSString *)username {
    return (_username.length > 0)? _username : nil;
}

- (NSString *)password {
    return (_password.length > 0)? _password : nil;
}

- (NSString *)address {
    return (_address.length > 0)? _address : nil;
}

- (NSString *)message {
    return (_message.length > 0)? _message : nil;
}

- (void)setMessage:(NSString *)message {
	if (self.message != message) {
        id oldMessage = self.message;
        _message = message;
        BOOL isVisible = [self isVisible];
        NSRect frame = [self frame];
        
        if (![oldMessage length] && [message length]) {
            frame.size.height += kSizeDiff;
            frame.origin.y -= kSizeDiff;
        } else if ([oldMessage length] && ![message length]) {
            frame.size.height -= kSizeDiff;
            frame.origin.y += kSizeDiff;
        }
        [self setFrame: frame display: isVisible animate: isVisible];
	}
}

#pragma mark - IBActions

- (IBAction)authenticate:(id)sender {
    [_delegate authenticationPanel:self gotUsername:_username password:_password];
    self.authenticating = YES;
    self.password = nil;
}

- (IBAction)cancelAuthentication:(id)sender { //For unlock focus
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_authenticating) {
            [_delegate authenticationPanelCancel:self];
            self.authenticating = NO;
        } else {
            [_delegate authenticationPanelEndPanel:self];
        }
    });
}

@synthesize message = _message;
@dynamic delegate;
@end
