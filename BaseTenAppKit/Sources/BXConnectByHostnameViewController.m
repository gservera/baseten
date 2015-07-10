//
// BXConnectByHostnameViewController.m
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


#import "BXConnectByHostnameViewController.h"


@implementation BXConnectByHostnameViewController

__strong static NSNib* gNib = nil;

+ (void)initialize {
    if (self == [BXConnectByHostnameViewController class]) {
        gNib = [[NSNib alloc] initWithNibNamed:@"ConnectByHostnameView"
                                        bundle:[NSBundle bundleForClass:self]];
    }
}

+ (NSNib *)nibInstance {
	return gNib;
}

- (void)setHost:(NSString *)host {
    if (mAddress != host) {
        mAddress = host;
    }
}

@synthesize host = mAddress;
@end
