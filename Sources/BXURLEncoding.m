//
// BXURLEncoding.m
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

#import "BXURLEncoding.h"
#import "BXConstants.h"
#import "BXArraySize.h"


static NSData*
URLEncode (const char* bytes, size_t length)
{
    NSMutableData* retval = [NSMutableData data];
    char hex [4] = "\0\0\0\0";
    for (unsigned int i = 0; i < length; i++)
    {
        char c = bytes [i];
        if (('0' <= c && c <= '9') || ('A' <= c && c <= 'Z') || ('a' <= c && c <= 'z') || 
            '-' == c || '_' == c || '.' == c || '~' == c)
            [retval appendBytes: &c length: sizeof (char)];
        else
        {
            snprintf (hex, BXArraySize (hex), "%%%02hhx", c);
            [retval appendBytes: hex length: 3 * sizeof (char)];
        }
    }
    return [[retval copy] autorelease];
}

static NSData* 
URLDecode (const char* bytes, size_t length, id sender)
{
    NSMutableData* retval = [NSMutableData data];
    char hex [3] = "\0\0\0";
    for (unsigned int i = 0; i < length; i++)
    {
        char c = bytes [i];
        if ('%' != c)
            [retval appendBytes: &c length: sizeof (char)];
        else
        {
            if (length < i + BXArraySize (hex))
            {
                @throw [NSException exceptionWithName: NSRangeException reason: nil 
                                             userInfo: [NSDictionary dictionaryWithObject: sender forKey: kBXObjectKey]];
            }
            i++;
            strlcpy ((char *) &hex, &bytes [i], BXArraySize (hex));
            char c = (char) strtol ((char *) &hex, NULL, 16);
            [retval appendBytes: &c length: sizeof (char)];
            i++;
        }
    }
    return [[retval copy] autorelease];
}


@implementation NSData (BXDatabaseAdditions)
- (NSData *) BXURLDecodedData;
{
    return URLDecode ((char *) [self bytes], [self length], self);
}

- (NSData *) BXURLEncodedData
{
    return URLEncode ((char *) [self bytes], [self length]);
}
@end


@implementation NSString (BXDatabaseAdditions)
+ (NSString *) BXURLEncodedData: (id) data
{
    return [[[self alloc] initWithData: [data BXURLEncodedData] 
                              encoding: NSASCIIStringEncoding] autorelease];
}

+ (NSString *) BXURLDecodedData: (id) data
{
    return [[[self alloc] initWithData: [data BXURLDecodedData]
                              encoding: NSUTF8StringEncoding] autorelease];
}

- (NSData *) BXURLDecodedData
{
    return [[self dataUsingEncoding: NSASCIIStringEncoding] BXURLDecodedData];
}

- (NSData *) BXURLEncodedData
{
    const char* UTF8String = [self UTF8String];
    size_t length = strlen (UTF8String);
    return URLEncode (UTF8String, length);
}

- (NSString *) BXURLEncodedString
{
    return [NSString BXURLEncodedData: self];
}

- (NSString *) BXURLDecodedString
{
    return [NSString BXURLDecodedData: self];
}
@end
