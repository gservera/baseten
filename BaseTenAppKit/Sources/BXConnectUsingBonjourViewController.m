//
// BXConnectUsingBonjourViewController.m
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


#import "BXConnectUsingBonjourViewController.h"


@implementation BXConnectUsingBonjourViewController
__strong static NSNib* gNib = nil;

+ (void) initialize
{
	static BOOL tooLate = NO;
	if (! tooLate)
	{
		tooLate = YES;
		gNib = [[NSNib alloc] initWithNibNamed: @"ConnectUsingBonjourView" bundle: [NSBundle bundleForClass: self]];
	}
}

+ (NSNib *) nibInstance
{
	return gNib;
}

- (void) dealloc
{
	[mAddressTable release];
	[mBonjourArrayController release];
	[mNetServiceBrowser release];
	[mNetServices release];
	[super dealloc];
}

- (NSString *) host
{
	return [[[mBonjourArrayController selectedObjects] lastObject] hostName];
}

- (NSInteger) port
{
	NSNetService *service = [[mBonjourArrayController selectedObjects] lastObject];
	return [service port];
}

- (void) startDiscovery
{	
	if (! mDiscovering)
	{
		mDiscovering = YES;
		if (! mNetServiceBrowser)
		{
			mNetServiceBrowser = [[NSNetServiceBrowser alloc] init];
			[mNetServiceBrowser setDelegate: self];
		}
		if (! mNetServices)
			mNetServices = [[NSMutableSet alloc] init];
		
		[mNetServiceBrowser searchForServicesOfType: @"_postgresql._tcp." inDomain: @""];
	}
}

- (void) stopDiscovery
{
	if (mDiscovering)
	{
		mDiscovering = NO;
		[mNetServiceBrowser stop];
		[mNetServices removeAllObjects];
	}
}
@end



@implementation BXConnectUsingBonjourViewController (NSNetServiceBrowserDelegate)
- (void) netServiceBrowser: (NSNetServiceBrowser *) netServiceBrowser 
			didFindService: (NSNetService *) netService moreComing: (BOOL) moreServicesComing
{
	if (! [mNetServices containsObject: netService])
	{
		[mNetServices addObject: netService];
		[netService resolveWithTimeout: 10.0];
		[netService setDelegate: self];
	}
}
@end



@implementation BXConnectUsingBonjourViewController (NSNetServiceDelegate)
- (void) netServiceDidResolveAddress: (NSNetService *) netService
{
	[mBonjourArrayController addObject: netService];
}


- (void) netService: (NSNetService *) netService didNotResolve: (NSDictionary *) errorDict
{
}
@end
