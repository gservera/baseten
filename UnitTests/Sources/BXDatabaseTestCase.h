//
//  BXDatabaseTestCase.h
//  BaseTen
//
//  Created by Guillem on 13/9/14.
//
//

#import <XCTest/XCTest.h>
#import <BaseTen/BaseTen.h>

@interface BXDatabaseTestCase : XCTestCase <BXDatabaseContextDelegate> {
    BXDatabaseContext *mContext;
    BXDatabaseObjectModelStorage *mStorage;
}

@property (readonly) NSURL * databaseURI;
@property (readonly) NSDictionary * connectionDictionary;
@end

@interface BXDatabaseObject (UnitTestAdditions)
- (id) resolveNoncachedRelationshipNamed: (NSString *) aName;
@end