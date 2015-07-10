//
// PGTSValueTypes.m
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


#import "PGTSValueTypes.h"
#import "PGTSTypeDescription.h"
#import "PGTSResultSet.h"


@implementation PGTSFloat
+ (id) copyForPGTSResultSet: (PGTSResultSet *) set withCharacters: (const char *) value type: (PGTSTypeDescription *) typeInfo
{
    return [[NSNumber alloc] initWithFloat: strtof (value, NULL)];
}
@end


@implementation PGTSDouble
+ (id) copyForPGTSResultSet: (PGTSResultSet *) set withCharacters: (const char *) value type: (PGTSTypeDescription *) typeInfo
{
    return [[NSNumber alloc] initWithDouble: strtod (value, NULL)];
}
@end


@implementation PGTSBool
+ (id) copyForPGTSResultSet: (PGTSResultSet *) set withCharacters: (const char *) value type: (PGTSTypeDescription *) typeInfo
{
    BOOL boolValue = (value [0] == 't' ? YES : NO);
    return [[NSNumber alloc] initWithBool: boolValue];
}
@end


@implementation PGTSPoint
+ (id) copyForPGTSResultSet: (PGTSResultSet *) set withCharacters: (const char *) value type: (PGTSTypeDescription *) typeInfo
{
    NSPoint retval = NSZeroPoint;
    NSString* pointString = [NSString stringWithUTF8String: value];
    NSScanner* pointScanner = [NSScanner scannerWithString: pointString];
    [pointScanner setScanLocation: 1];
	
#if CGFLOAT_IS_DOUBLE
    [pointScanner scanDouble: &(retval.x)];
#else
    [pointScanner scanFloat: &(retval.x)];
#endif
	
    [pointScanner setScanLocation: [pointScanner scanLocation] + 1];
	
#if CGFLOAT_IS_DOUBLE
    [pointScanner scanDouble: &(retval.y)];
#else
    [pointScanner scanFloat: &(retval.y)];
#endif
	
    return [[NSValue valueWithPoint: retval] retain];
}
@end
