//
// PGTSOids.mm
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

#import "PGTSOids.h"
#import "BXCollectionFunctions.h"
#import "BXLogger.h"


/**
 * \internal
 * \brief Return the value as an object.
 *
 * \sa PGTSOidValue
 */
id 
PGTSOidAsObject (Oid o)
{
    //Methods inherited from NSValue seem to return an NSValue instead of an NSNumber.
	//Thus, we use NSNumber.
    return BaseTen::ObjectValue (o);
}


@implementation NSNumber (PGTSOidAdditions)
/**
 * \internal
 * \brief Return the value as Oid.
 * \sa PGTSOidAsObject
 */
- (Oid) PGTSOidValue
{
	Oid retval = InvalidOid;
	BaseTen::ValueGetter <Oid> getter;
	BOOL status = getter (self, &retval);
	
	ExpectR (status, InvalidOid);
	return retval;
}
@end
