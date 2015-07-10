//
// PGTSTypeDescription.m
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

#import "PGTSTypeDescription.h"


/** 
 * \internal
 * \brief Data type in a database.
 */
@implementation PGTSTypeDescription

- (id) init
{
    if ((self = [super init]))
    {
        mElementOid = InvalidOid;
        mDelimiter = '\0';
    }
    return self;
}

//These are set once and never changed.
- (Oid) elementOid
{
	return mElementOid;
}

- (NSInteger) length
{
	return mLength;
}

- (char) delimiter
{
    return mDelimiter;
}

- (char) kind
{
	return mKind;
}

- (void) setElementOid: (Oid) elementOid
{
	mElementOid = elementOid;
}

- (void) setLength: (NSInteger) length
{
	mLength = length;
}

- (void) setDelimiter: (char) delimiter
{
	mDelimiter = delimiter;
}

- (void) setKind: (char) kind
{
	mKind = kind;
}
@end
