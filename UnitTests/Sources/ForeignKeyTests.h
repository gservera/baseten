//
// ForeignKeyTests.h
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


@interface ForeignKeyTests : BXDatabaseTestCase 
{
    BXEntityDescription* mTest1;
    BXEntityDescription* mTest2;
    BXEntityDescription* mOtotest1;
    BXEntityDescription* mOtotest2;
    BXEntityDescription* mMtmtest1;
    BXEntityDescription* mMtmtest2;
    
    BXEntityDescription* mTest1v;
    BXEntityDescription* mTest2v;
    BXEntityDescription* mOtotest1v;
    BXEntityDescription* mOtotest2v;
    BXEntityDescription* mMtmtest1v;
    BXEntityDescription* mMtmtest2v;
	BXEntityDescription* mMtmrel1;
}

- (void) many: (BXEntityDescription *) manyEntity toOne: (BXEntityDescription *) oneEntity;
- (void) one: (BXEntityDescription *) oneEntity toMany: (BXEntityDescription *) manyEntity;
- (void) one: (BXEntityDescription *) entity1 toOne: (BXEntityDescription *) entity2;
- (void) many: (BXEntityDescription *) entity1 toMany: (BXEntityDescription *) entity2;
- (void) MTMHelper: (BXEntityDescription *) entity;
@end
