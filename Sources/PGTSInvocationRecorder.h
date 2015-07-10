//
// PGTSInvocationRecorder.h
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

#import <Foundation/Foundation.h>



@class PGTSInvocationRecorderHelper;



@interface PGTSInvocationRecorder : NSObject
{
	PGTSInvocationRecorderHelper* mHelper;
	NSInvocation** mOutInvocation;
}
- (void) setTarget: (id) target;
- (NSInvocation *) invocation;
- (id) record;
- (id) recordWithTarget: (id) target;
- (id) recordWithTarget: (id) target outInvocation: (NSInvocation **) outInvocation;
+ (id) recordWithTarget: (id) target outInvocation: (NSInvocation **) outInvocation;
@end



@interface PGTSPersistentTargetInvocationRecorder : PGTSInvocationRecorder
{
}
@end



@interface PGTSCallbackInvocationRecorder : PGTSInvocationRecorder
{
	id mUserInfo;
	id mCallbackTarget;
	SEL mCallback;
}
- (void) setCallbackTarget: (id) target;
- (void) setCallback: (SEL) callback; //- (void) myCallback: (NSInvocation *) invocation userInfo: (id) userInfo;
- (void) setUserInfo: (id) anObject;
- (id) userInfo;
@end



@interface PGTSHOMInvocationRecorder : PGTSCallbackInvocationRecorder
{
}
- (void) setCallback: (SEL) callback target: (id) target;
@end
