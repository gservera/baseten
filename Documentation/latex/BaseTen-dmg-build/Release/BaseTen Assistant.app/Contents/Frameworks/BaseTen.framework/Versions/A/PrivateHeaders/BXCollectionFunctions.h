//
// BXCollectionFunctions.h
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
#import <BaseTen/BXExport.h>
#import <BaseTen/BXLogger.h>
#import <BaseTen/BXValueGetter.h>


BX_EXPORT NSValue *FindElementValue (id collection, id key);


#if defined(__cplusplus)

namespace BaseTen {	

	template <typename T>
	inline BOOL FindElement (id collection, id key, T *outValue)
	{
		ExpectR (outValue, NO);
		
		BOOL retval = NO;
		NSValue *value = FindElementValue (collection, key);
		if (value)
		{
			ValueGetter <T> getter;
			retval = getter (value, outValue);
		}
		return retval;
	}

	
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
