//
// BXCollectionFunctions.h
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
#import <BaseTen/BXExport.h>


BX_INTERNAL BOOL FindElement (id collection, id key, void *outValue);



#if defined(__cplusplus)
namespace BaseTen {
	
	template <typename T>
	inline id ObjectValue (T value)
	{
		return [NSValue valueWithBytes: &value objCType: @encode (T)];
	}
	
	template <> id ObjectValue (float value);
	template <> id ObjectValue (double value);
	template <> id ObjectValue (char value);
	template <> id ObjectValue (short value);
	template <> id ObjectValue (int value);
	template <> id ObjectValue (long value);
	template <> id ObjectValue (long long value);
	template <> id ObjectValue (unsigned char value);
	template <> id ObjectValue (unsigned short value);
	template <> id ObjectValue (unsigned int value);
	template <> id ObjectValue (unsigned long value);
	template <> id ObjectValue (unsigned long long value);
	
	
	template <typename T>
	inline id FindObject (NSDictionary *collection, T *key)
	{
		return [collection objectForKey: key];
	}

	
	template <typename T>
	inline id FindObject (NSDictionary *collection, T key)
	{
		NSValue *keyObject = ObjectValue (key);
		return FindObject (collection, keyObject);
	}
	
	
	template <typename T, typename U>
	inline void Insert (NSMutableDictionary *collection, T key, U value)
	{
		NSValue *keyObject = ObjectValue (key);
		NSValue *valueObject = ObjectValue (value);
		Insert (collection, keyObject, valueObject);
	}
	
	
	template <typename T, typename U>
	inline void Insert (NSMutableDictionary *collection, T *key, U *value)
	{
		[collection setObject: value forKey: key];
	}	
	
	
	template <typename T, typename U>
	inline void Insert (NSMutableDictionary *collection, T *key, U value)
	{
		NSValue *valueObject = ObjectValue (value);
		Insert (collection, key, valueObject);
	}
	
	
	template <typename T, typename U>
	inline void Insert (NSMutableDictionary *collection, T key, U *value)
	{
		NSValue *keyObject = ObjectValue (key);
		Insert (collection, keyObject, value);
	}
	
	
	template <typename T, typename U>
	inline void InsertConditionally (NSMutableDictionary *collection, T key, U value)
	{
		NSValue *keyObject = ObjectValue (key);
		if (! [collection objectForKey: keyObject])
			Insert (collection, keyObject, value);
	}
	
	
	template <typename T, typename U>
	inline void InsertConditionally (NSMutableDictionary *collection, T *key, U value)
	{
		if (! [collection objectForKey: key])
			Insert (collection, key, value);
	}
}
#endif
