//
// BXPGSQLScriptReader.h
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
#import <stdio.h>

@class PGTSConnection;
@class PGTSResultSet;
@class BXPGSQLScanner;
@class BXPGSQLScriptReader;
@protocol BXPGSQLScannerDelegate;


@protocol BXPGSQLScriptReaderDelegate <NSObject>
- (void) SQLScriptReaderSucceeded: (BXPGSQLScriptReader *) reader userInfo: (id) userInfo;
- (void) SQLScriptReader: (BXPGSQLScriptReader *) reader failed: (PGTSResultSet *) res userInfo: (id) userInfo;
- (void) SQLScriptReader: (BXPGSQLScriptReader *) reader advancedToPosition: (off_t) position userInfo: (id) userInfo;
@end



#define BXPGSQLScannerBufferSize 1024

@interface BXPGSQLScriptReader : NSObject 
{
	char mBuffer [BXPGSQLScannerBufferSize];
	off_t mFileSize;

	FILE* mFile;
	PGTSConnection* mConnection;
	BXPGSQLScanner* mScanner;
	id <BXPGSQLScriptReaderDelegate> mDelegate;
	id mDelegateUserInfo;
	
	BOOL mCanceling;
	BOOL mIgnoresErrors;
	BOOL mAsynchronous;
}
- (void) setConnection: (PGTSConnection *) connection;
- (void) setDelegate: (id <BXPGSQLScriptReaderDelegate>) anObject;
- (void) setDelegateUserInfo: (id) anObject;
- (id) delegateUserInfo;
- (void) setIgnoresErrors: (BOOL) flag;

- (BOOL) openFileAtURL: (NSURL *) fileURL;
- (off_t) length;
- (void) readAndExecuteAsynchronously;
- (void) readAndExecuteSynchronously;
- (void) cancel;

- (void) setScanner: (BXPGSQLScanner *) scanner;
@end
