//
// TestLoader.m
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

#import "TestLoader.h"
#import <BaseTen/BaseTen.h>
#import <BaseTen/BXLogger.h>
#import <BaseTen/BXSocketDescriptor.h>
#import "MKCSenTestCaseAdditions.h"
#import "BXGarbageCollectionRunner.h"

#import "PGTSInvocationRecorderTests.h"
#import "BXHOMTests.h"
#import "BXDelegateProxyTests.h"
#import "NSPredicate+BaseTenAdditionsTests.h"
#import "NSArray+BaseTenAdditionsTests.h"
#import "PGTSValueTests.h"
#import "BXKeyPathComponentTest.h"
#import "BXPredicateTests.h"
#import "BXHostResolverTests.h"
#import "BXDatabaseContextTests.h"

#import "PGTSMetadataTests.h"
#import "PGTSTypeTests.h"
#import "PGTSParameterTests.h"
#import "PGTSNotificationTests.h"
#import "PGTSPgBouncerTests.h"

#import "BXConnectionTests.h"
#import "BXSSLConnectionTests.h"
#import "BXMetadataTests.h"
#import "BXDataModelTests.h"
#import "BXSQLTests.h"
#import "BXDatabaseObjectTests.h"
#import "EntityTests.h"
#import "ObjectIDTests.h"
#import "CreateTests.h"
#import "FetchTests.h"
#import "BXModificationTests.h"
#import "BXArbitrarySQLTests.h"
#import "ForeignKeyTests.h"
#import "ForeignKeyModificationTests.h"
#import "MTOCollectionTest.h"
#import "MTMCollectionTest.h"
#import "UndoTests.h"
#import "ToOneChangeNotificationTests.h"


@implementation BXTestLoader
- (void) test
{
	BXLogSetLevel (kBXLogLevelWarning);
	BXLogSetAbortsOnAssertionFailure (YES);
	[BXGarbageCollectionRunner install];
	//NSLog (@"waiting");
	//sleep (10);
	
	NSArray* testClasses = [NSArray arrayWithObjects:
							[PGTSInvocationRecorderTests class],
							[BXHOMTests class],
							[BXDelegateProxyTests class],
							[NSPredicate_BaseTenAdditionsTests class],
							[NSArray_BaseTenAdditionsTests class],
							[PGTSValueTests class],
							[BXKeyPathComponentTest class],
							[BXPredicateTests class],
							[BXHostResolverTests class],
							[BXDatabaseContextTests class],
							
							[PGTSMetadataTests class],
							[PGTSTypeTests class],
							[PGTSParameterTests class],
							[PGTSNotificationTests class],
							[PGTSPgBouncerTests class],
							
							[BXConnectionTests class],
							[BXSSLConnectionTests class],
							[BXMetadataTests class],
							[BXDataModelTests class],
							[BXSQLTests class],
							[BXDatabaseObjectTests class],
							[EntityTests class],
							[ObjectIDTests class],
							[CreateTests class],
							[FetchTests class],
							[BXModificationTests class],
							[BXArbitrarySQLTests class],
							[ForeignKeyTests class],
							[ForeignKeyModificationTests class],
							[MTOCollectionTest class],
							[MTMCollectionTest class],
							[UndoTests class],
							[ToOneChangeNotificationTests class],
							nil];
	
	//testClasses = [NSArray arrayWithObject: [BXSQLTests class]];
	
	for (int i = 0; i < 2; i++)
	{
		if (1 == i)
		{
			[BXSocketDescriptor setUsesGCD: YES];
			NSLog (@"Using GCD with BXSocketDescriptor.");
		}
		else
		{
			[BXSocketDescriptor setUsesGCD: NO];
			NSLog (@"Not using GCD with BXSocketDescriptor.");
		}
		
		for (Class testCaseClass in testClasses)
		{
			NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
			SenTestSuite *suite = [SenTestSuite testSuiteForTestCaseClass: testCaseClass];
			SenTestRun *testRun = [suite run];
			STAssertTrue (0 == [testRun unexpectedExceptionCount], @"Had %u unexpected exceptions.", [testRun unexpectedExceptionCount]);
			[pool drain];
		}
	}
}
@end
