//
// BXPGSQLScanner.h
// BaseTen
//
// Copyright 2008 Marko Karppinen & Co. LLC.
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

#ifndef PSQLSCAN_H
typedef void* PsqlScanState;
#endif

#ifndef PQEXPBUFFER_H
typedef void* PQExpBuffer;
#endif


@class BXPGSQLScanner;

@protocol BXPGSQLScannerDelegate <NSObject>
- (const char *) nextLineForScanner: (BXPGSQLScanner *) scanner;
- (void) scanner: (BXPGSQLScanner *) scanner scannedQuery: (NSString *) query complete: (BOOL) isComplete;
- (void) scanner: (BXPGSQLScanner *) scanner scannedCommand: (NSString *) command options: (NSString *) options;
@end


@interface BXPGSQLScanner : NSObject 
{
	PsqlScanState mScanState;
    PQExpBuffer mQueryBuffer;
	const char* mCurrentLine;
	id <BXPGSQLScannerDelegate> mDelegate;
	BOOL mShouldStartScanning;
}
- (void) setDelegate: (id <BXPGSQLScannerDelegate>) anObject;
- (void) continueScanning;
@end
