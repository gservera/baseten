//
// MTOCollectionTest.h
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

#import <XCTest/XCTest.h>
#import "BXTestCase.h"
@class BXDatabaseContext;
@class BXEntityDescription;


@interface MTOCollectionTest : BXDatabaseTestCase 
{
    BXEntityDescription* mMtocollectiontest1;
    BXEntityDescription* mMtocollectiontest2;
    BXEntityDescription* mMtocollectiontest1v;
    BXEntityDescription* mMtocollectiontest2v;
}

- (void) modMany: (BXEntityDescription *) manyEntity toOne: (BXEntityDescription *) oneEntity;
- (void) modMany2: (BXEntityDescription *) manyEntity toOne: (BXEntityDescription *) oneEntity;

@end
