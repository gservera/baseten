//
// NSURL+BaseTenAdditions.m
// BaseTen
//
// Copyright 2008-2009 Marko Karppinen & Co. LLC.
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


#import "NSURL+BaseTenAdditions.h"
#import "BXURLEncoding.h"


@implementation NSURL (BaseTenAdditions)
- (NSUInteger) BXHash
{
    NSUInteger u = 0;
	u = [[self scheme] hash];
	u ^= [[self host] hash];
	u ^= [[self port] hash];
	u ^= [[self path] hash];
	u ^= [[self query] hash];
    return u;
}

- (NSURL *) BXURIForHost: (NSString *) host database: (NSString *) dbName username: (NSString *) username password: (id) password
{
	return [self BXURIForHost: host port: nil database: dbName username: username password: password];
}

- (NSURL *) BXURIForHost: (NSString *) host port: (NSNumber *) port database: (NSString *) dbName username: (NSString *) username password: (id) password
{
	//FIXME: shouldn't we allow empty scheme?
	NSString* scheme = [self scheme];
	NSURL* retval = nil;
	
	if (nil != scheme)
	{
		NSMutableString* URLString = [NSMutableString string];
		[URLString appendFormat: @"%@://", scheme];

		if (nil == username) username = [self user];
		
		if (nil == password) password = [self password];
		else if ([NSNull null] == password) password = nil;
		
		if (nil != password && 0 < [password length])
			[URLString appendFormat: @"%@:%@@", [username BXURLEncodedString] ?: @"", [password BXURLEncodedString]];
		else if (nil != username && 0 < [username length])
			[URLString appendFormat: @"%@@", [username BXURLEncodedString]];
	
		if (! host) 
			host = [self host];
		
		if (host)
		{
			if (NSNotFound != [host rangeOfString: @":"].location)
			{
				//IPv6
				[URLString appendString: @"["];
				[URLString appendString: host];
				[URLString appendString: @"]"];
			}
			else
			{
				[URLString appendString: host];
			}
		}
		
		if (! port)
			port = [self port];
		if (port && -1 != [port integerValue]) [URLString appendFormat: @":%@", port];
	
		if (nil != dbName)
            dbName = [dbName BXURLEncodedString];
        else
            dbName = [[self path] substringFromIndex: 1];
        
        if (nil != dbName) [URLString appendFormat: @"/%@", dbName];
		retval = [NSURL URLWithString: URLString];
	}
	return retval;
}
@end
