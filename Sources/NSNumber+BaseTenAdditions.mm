//
// NSNumber+BaseTenAdditions.mm
// BaseTen
//
// Copyright 2010 Marko Karppinen & Co. LLC.
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

#import "NSNumber+BaseTenAdditions.h"
#import "NSValue+BaseTenAdditions.h"
#import "BXLogger.h"


@implementation NSNumber (BaseTenAdditions)
- (size_t) BXValueSize
{
	return CFNumberGetByteSize ((CFNumberRef) self);
}


- (BOOL) BXGetValue: (void *) buffer 
			 length: (size_t) bufferLength
		 numberType: (CFNumberType) expectedNumberType 
		   encoding: (const char *) expectedEncoding
{
	BOOL retval = NO;
	
	if (expectedNumberType)
		retval = CFNumberGetValue ((CFNumberRef) self, expectedNumberType, buffer);
	else
		retval = [super BXGetValue: buffer length: bufferLength numberType: expectedNumberType encoding: expectedEncoding];
	
	return retval;
}
@end



@implementation NSNumber (BXExpressionValue)
- (enum BXExpressionValueType) getBXExpressionValue: (id *) outValue usingContext: (NSMutableDictionary *) context;
{
	ExpectR (outValue, kBXExpressionValueTypeUndefined);
	
	if (0 == strcmp ("c", [self objCType]))
		*outValue = ([self boolValue] ? @"true" : @"false");
	else
		*outValue = self;
	
	return kBXExpressionValueTypeConstant;
}
@end
