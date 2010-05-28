//
// BXCollections.h
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
#import <BaseTen/BXScannedMemoryAllocator.h>
#import <BaseTen/BXScannedMemoryObject.h>
#import <BaseTen/BXObjCPtr.h>
#import <BaseTen/BXObjCPair.h>
#import <list>
#import <tr1/unordered_set>
#import <tr1/unordered_map>
namespace BaseTen
{
	namespace internal {
		
		template <typename T>
		class list :
			public std::list <T, BaseTen::ScannedMemoryAllocator <T> >,
			public BaseTen::ScannedMemoryObject
		{
		public:
			typedef std::list <T, BaseTen::ScannedMemoryAllocator <T> > _Base;
			
			explicit list () : _Base () {};
			explicit list (typename _Base::size_type size) : _Base (size) {};
		};
		
		
		template <typename T>
		class unordered_set : 
			public std::tr1::unordered_set <
				T,
				std::tr1::hash <T>,
				std::equal_to <T>,
				BaseTen::ScannedMemoryAllocator <T>
			>,
			public BaseTen::ScannedMemoryObject
		{
		public:
			typedef std::tr1::unordered_set <
				T,
				std::tr1::hash <T>,
				std::equal_to <T>,
				BaseTen::ScannedMemoryAllocator <T>
			> _Base;

			explicit unordered_set (typename _Base::size_type size = 10) : _Base (size) {};
		};
		
		
		template <typename T, typename U>
		class unordered_map :
			public std::tr1::unordered_map <
				T,
				U,
				std::tr1::hash <T>,
				std::equal_to <T>,
				BaseTen::ScannedMemoryAllocator <std::pair <
					const T, U
				> >
			>,
			public BaseTen::ScannedMemoryObject
		{
		public:
			typedef std::tr1::unordered_map <
				T,
				U,
				std::tr1::hash <T>,
				std::equal_to <T>,
				BaseTen::ScannedMemoryAllocator <std::pair <
					const T, U
				> >
			> _Base;
			
			explicit unordered_map (typename _Base::size_type size = 10) : _Base (size) {};
		};
	}
	
	
	typedef ObjCPtr <id> IdPtr;
	typedef ObjCPair <id, id> IdPair;

	
	typedef BaseTen::internal::list <IdPtr> IdList;
	typedef BaseTen::internal::unordered_set <IdPair> IdPairSet;
	typedef BaseTen::internal::unordered_map <IdPtr, IdPtr> IdMap;
	typedef BaseTen::internal::unordered_map <NSInteger, IdPtr> IndexMap;
}

#define BX_IdList    __strong BaseTen::IdList
#define BX_IdMap     __strong BaseTen::IdMap
#define BX_IndexMap  __strong BaseTen::IndexMap
#define BX_IdPairSet __strong BaseTen::IdPairSet

#else
#define BX_IdList    __strong void
#define BX_IdMap     __strong void
#define BX_IndexMap  __strong void
#define BX_IdPairSet __strong void
#endif
