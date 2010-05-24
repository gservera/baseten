//
// BXHOM.h
// BaseTen
//
// Copyright (C) 2008-2010 Marko Karppinen & Co. LLC.
//
// Before using this software, please review the available licensing options
// by visiting http://www.karppinen.fi/baseten/licensing/ or by contacting
// us at sales@karppinen.fi. Without an additional license, this software
// may be distributed only in compliance with the GNU General Public License.
//
//
// This program is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License, version 2.0,
// as published by the Free Software Foundation.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
//
// $Id$
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



@interface NSSet (BXHOM) <BXHOM>
- (id) BX_SelectFunction: (int (*)(id)) fptr;
- (id) BX_SelectFunction: (int (*)(id, void*)) fptr argument: (void *) arg;
@end



@interface NSArray (BXHOM) <BXHOM>
- (NSArray *) BX_Reverse;
- (id) BX_SelectFunction: (int (*)(id)) fptr;
- (id) BX_SelectFunction: (int (*)(id, void*)) fptr argument: (void *) arg;
@end



@interface NSDictionary (BXHOM) <BXHOM>
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
