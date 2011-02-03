//
// BXError.m
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

#import "BXError.h"


@implementation BXError
- (NSString *) description
{
	NSString* reason = [self localizedRecoverySuggestion] ?: [self localizedFailureReason];
	NSMutableString* retval = [NSMutableString stringWithFormat: @"%@ (%@: %d): %@: %@",
							   [self class], [self domain], [self code], [self localizedDescription], reason];

	NSError* underlyingError = [[self userInfo] objectForKey: NSUnderlyingErrorKey];
	if (underlyingError)
		[retval appendFormat: @"\n\tUnderlying error: %@", [underlyingError description]];
	
	return [[retval copy] autorelease];
}
@end
