//
// BXPropertyDescription.h
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

#import <Foundation/Foundation.h>
#import <BaseTen/BXAbstractDescription.h>

@class BXEntityDescription;


enum BXPropertyFlag
{
	kBXPropertyNoFlag				= 0,
	kBXPropertyOptional				= 1 << 0,
	kBXPropertyPrimaryKey			= 1 << 1,
	kBXPropertyExcluded				= 1 << 2,
	kBXPropertyIsArray				= 1 << 3,
	kBXPropertyExcludedByDefault	= 1 << 4,
	kBXPropertyInherited			= 1 << 5
};

#ifdef __cplusplus
inline BXPropertyFlag operator |= (BXPropertyFlag x, BXPropertyFlag y) { return static_cast <BXPropertyFlag> (x | y); }
inline BXPropertyFlag operator &= (BXPropertyFlag x, BXPropertyFlag y) { return static_cast <BXPropertyFlag> (x & y); }
#endif 


@interface BXPropertyDescription : BXAbstractDescription <NSCopying> //, NSCoding>
{
    BXEntityDescription*  mEntity; //Weak
	enum BXPropertyFlag   mFlags;
}
- (BXEntityDescription *) entity;
- (BOOL) isOptional;
- (enum BXPropertyKind) propertyKind;
@end
