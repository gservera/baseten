//
// BXHOM.h
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

#import <Foundation/Foundation.h>


@protocol BXHOM <NSObject>
- (id) BX_Any;
- (id) BX_Do;
- (id) BX_Collect;
- (id) BX_CollectReturning: (Class) aClass;

/**
 * \internal
 * \brief Make a dictionary of collected objects.
 *
 * Make existing objects values and collected objects keys.
 * \return An invocation recorder that creates an NSDictionary.
 */
- (id) BX_CollectD;

/**
 * \internal
 * \brief Make a dictionary of collected objects.
 *
 * Make existing objects keys and collected objects values.
 * \return An invocation recorder that creates an NSDictionary.
 */
- (id) BX_CollectDK;

/**
 * \internal
 * \brief Visit each item.
 *
 * The first parameter after self and _cmd will be replaced with the visited object.
 * \param visitor The object that will be called.
 * \return An invocation recorder.
 */
- (id) BX_Visit: (id) visitor;
@end



@protocol BXSetHOM <BXHOM>
- (id) BX_SelectFunction: (int (*)(id)) fptr;
- (id) BX_SelectFunction: (int (*)(id, void*)) fptr argument: (void *) arg;
@end



@protocol BXArrayHOM <BXHOM>
- (NSArray *) BX_Reverse;
- (id) BX_SelectFunction: (int (*)(id)) fptr;
- (id) BX_SelectFunction: (int (*)(id, void*)) fptr argument: (void *) arg;
@end



@protocol BXDictionaryHOM <BXHOM>
/**
 * \internal
 * \brief Make a dictionary of objects collected from keys.
 *
 * Make existing objects values and collected objects keys.
 * \return An invocation recorder that creates an NSDictionary.
 */
- (id) BX_KeyCollectD;

- (id) BX_ValueSelectFunction: (int (*)(id)) fptr;
- (id) BX_ValueSelectFunction: (int (*)(id, void*)) fptr argument: (void *) arg;
@end



@interface NSSet (BXHOM) <BXSetHOM>
@end



@interface NSArray (BXHOM) <BXArrayHOM>
@end



@interface NSDictionary (BXHOM) <BXDictionaryHOM>
@end



#if ! (defined (TARGET_OS_IPHONE) && TARGET_OS_IPHONE)
@interface NSHashTable (BXHOM) <BXSetHOM>
@end
#endif



#if ! (defined (TARGET_OS_IPHONE) && TARGET_OS_IPHONE)
@interface NSMapTable (BXHOM) <BXDictionaryHOM>
@end
#endif
