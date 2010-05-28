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


#if defined(__cplusplus)
namespace BaseTen {
	
	namespace CollectionFunctions {

		template <typename T>
		BOOL ContainsKey (T *container, typename T::key_type key)
		{
			BOOL retval = NO;
			if (container)
			{
				typename T::const_iterator it = container->find (key);
				if (container->end () != it)
					retval = YES;
			}
			return retval;
		}
		
		
		template <typename T>
		BOOL ContainsKey (T *container, typename T::key_type::element_type key)
		{
			BOOL retval = NO;
			if (container)
			{
				BaseTen::ObjCPtr <typename T::key_type::element_type> keyPtr (key);
				typename T::const_iterator it = container->find (keyPtr);
				if (container->end () != it)
					retval = YES;
			}
			return retval;
		}		
		
		
		template <typename T>
		BOOL FindElement (T *container, typename T::key_type key, typename T::mapped_type *outVal)
		{
			BOOL retval = NO;
			if (container && outVal)
			{
				typename T::const_iterator it = container->find (key);
				if (container->end () != it)
				{
					*outVal = it->second;
					retval = YES;
				}
			}
			return retval;
		}
		
		
		template <typename T>
		BOOL FindElement (T *container, typename T::key_type::element_type key, typename T::mapped_type *outVal)
		{
			BOOL retval = NO;
			if (container && outVal)
			{
				BaseTen::ObjCPtr <typename T::key_type::element_type> keyPtr (key);
				typename T::const_iterator it = container->find (keyPtr);
				if (container->end () != it)
				{
					*outVal = it->second;
					retval = YES;
				}
			}
			return retval;
		}		
		
		
		template <typename T>
		typename T::mapped_type::element_type FindObject (T *container, typename T::key_type key)
		{
			typename T::mapped_type::element_type retval = nil;
			if (container)
			{
				typename T::const_iterator it = container->find (key);
				if (container->end () != it)
					retval = *it->second;
			}
			return retval;
		}
		
		
		template <typename T>
		typename T::mapped_type::element_type FindObject (T *container, typename T::key_type::element_type key)
		{
			typename T::mapped_type::element_type retval = nil;
			if (container)
			{
				BaseTen::ObjCPtr <typename T::key_type::element_type> keyPtr (key);
				typename T::const_iterator it = container->find (keyPtr);
				if (container->end () != it)
					retval = *it->second;
			}
			return retval;
		}		
		
		
		template <typename T>
		void Insert (T *container, typename T::key_type key, typename T::mapped_type val)
		{
			container->insert (std::make_pair (key, val));
		}
		
		
		template <typename T>
		void Insert (T *container, typename T::key_type::element_type key, typename T::mapped_type val)
		{
			typename T::key_type keyPtr (key);
			container->insert (std::make_pair (keyPtr, val));
		}
		
		
		template <typename T>
		void Insert (T *container, typename T::key_type key, typename T::mapped_type::element_type val)
		{
			typename T::mapped_type valPtr (val);
			container->insert (std::make_pair (key, valPtr));
		}
		
		
		template <typename T>
		void Insert (T *container, typename T::key_type::element_type key, typename T::mapped_type::element_type val)
		{
			typename T::key_type keyPtr (key);
			typename T::mapped_type valPtr (val);
			container->insert (std::make_pair (keyPtr, valPtr));
		}		
		
		
		template <typename T>
		void InsertConditionally (T *container, typename T::key_type key, typename T::mapped_type val)
		{
			if (! ContainsKey (container, key))
				Insert (container, key, val);
		}
		
		
		template <typename T>
		void InsertConditionally (T *container, typename T::key_type::element_type key, typename T::mapped_type val)
		{
			if (! ContainsKey (container, key))
				Insert (container, key, val);
		}		
		
		
		template <typename T>
		void InsertConditionally (T *container, typename T::key_type key, typename T::mapped_type::element_type val)
		{
			if (! ContainsKey (container, key))
				Insert (container, key, val);
		}
		
		
		template <typename T>
		void InsertConditionally (T *container, typename T::key_type::element_type key, typename T::mapped_type::element_type val)
		{
			if (! ContainsKey (container, key))
				Insert (container, key, val);
		}
		
		
		template <typename T>
		void PushBack (T *container, typename T::value_type::element_type val)
		{
			if (container)
			{
				typename T::value_type valPtr (val);
				container->push_back (valPtr);
			}
		}
	}
}
#endif
