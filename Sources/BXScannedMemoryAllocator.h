//
// BXScannedMemoryAllocator.h
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
#import <objc/objc-auto.h>
#import <new>
#import <limits>


namespace BaseTen {
	class ScannedMemoryAllocatorBase {
	public:
		static BOOL collection_enabled;
		static void *allocate (size_t);
		static void deallocate (void *);
	};	
	
	
	template <typename T> 
	class ScannedMemoryAllocator : private ScannedMemoryAllocatorBase {
		
	public:		
		typedef T                 value_type;
		typedef value_type*       pointer;
		typedef const value_type* const_pointer;
		typedef value_type&       reference;
		typedef const value_type& const_reference;
		typedef std::size_t       size_type;
		typedef std::ptrdiff_t    difference_type;
		
		template <typename U> struct rebind { typedef ScannedMemoryAllocator <U> other; };
		
		explicit ScannedMemoryAllocator () {}
		ScannedMemoryAllocator (const ScannedMemoryAllocator&) {}
		
		template <typename U> ScannedMemoryAllocator (const ScannedMemoryAllocator <U> &) {}
		~ScannedMemoryAllocator () {}
		
		pointer address (reference x) const { return &x; }
		const_pointer address (const_reference x) const { return x; }
		
		pointer allocate (size_type n, const_pointer = 0) 
		{
			return static_cast <pointer> (ScannedMemoryAllocatorBase::allocate (n * sizeof (T)));
		}
		
		void deallocate (pointer p, size_type n) 
		{
			ScannedMemoryAllocatorBase::deallocate (p);
		}
		
		size_type max_size () const 
		{
			return std::numeric_limits <size_type>::max () / sizeof (T);
		}
		
		void construct (pointer p, const value_type& x) 
		{ 
			new (p) value_type (x); 
		}
		
		void destroy (pointer p) 
		{ 
			p->~value_type (); 
		}
		
	private:
		void operator= (const ScannedMemoryAllocator&);
	};
	
	
	template <> class ScannedMemoryAllocator <void>
	{
	public:
		typedef void			value_type;
		typedef void*			pointer;
		typedef const void*		const_pointer;
		typedef std::size_t		size_type;
		typedef std::ptrdiff_t	difference_type;
		
		template <typename U> 
		struct rebind { typedef ScannedMemoryAllocator <U> other; };
		
		void *allocate (size_type n, const_pointer = 0)
		{
			return ScannedMemoryAllocatorBase::allocate (n);
		}
		
		void deallocate (pointer p, size_type = 0)
		{
			ScannedMemoryAllocatorBase::deallocate (p);
		}		
	};
	
	
	template <typename T> inline bool 
	operator== (const ScannedMemoryAllocator <T> &, const ScannedMemoryAllocator <T> &)
	{
		return true;
	}
	
	
	template <typename T> inline bool 
	operator!= (const ScannedMemoryAllocator <T> &, const ScannedMemoryAllocator <T> &) 
	{
		return false;
	}
}
