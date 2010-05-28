//
// BXObjCPtr.h
// BaseTen
//
// Copyright (C) 2010 Marko Karppinen & Co. LLC.
//
// Before using this software, please review the available licensing options
// by visiting http://basetenframework.org/licensing/ or by contacting
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
#import <cstddef>
#import <tr1/functional>


namespace BaseTen {
	
	class ObjCPtrBase {
		
	protected:
		__strong id mPtr;
		
	private:
		ObjCPtrBase (ObjCPtrBase const &);
		ObjCPtrBase &operator= (ObjCPtrBase const &);
		
	public:
		explicit ObjCPtrBase (): mPtr (nil) {}
		~ObjCPtrBase () { assign (nil); }
		
		void assign (id ptr);
		
		std::size_t hash () const { return [mPtr hash]; }
	};
	

	template <typename T>
	class ObjCPtr : public ObjCPtrBase {
		
	private:
		ObjCPtr &operator= (ObjCPtr const &);
		
	public:
		typedef T element_type;
		
		explicit ObjCPtr (T ptr = nil) { assign (ptr); }
		ObjCPtr (ObjCPtr const &other) { assign (other.mPtr); }
		T operator() () const { return mPtr; }
		T operator*  () const { return mPtr; }
		
		bool operator== (ObjCPtr <T> const &other) const { 
			std::equal_to <T> eq;
			return (mPtr == other.mPtr || eq (mPtr, other.mPtr));
		}
	};
}



namespace std {
	
	template <>
    struct equal_to <NSString *>
    {
		bool
		operator() (NSString const * const &a, NSString const * const &b) const
		{
			return [a isEqualToString: b];
		}
    };
	
	
	template <>
	struct equal_to <id>
	{
		bool
		operator() (id const &a, id const &b) const
		{
			return [a isEqual: b];
		}
	};
	
	
	
	namespace tr1 {
		
		template <typename T>
		struct hash <BaseTen::ObjCPtr <T> > {
			
			std::size_t
			operator() (const BaseTen::ObjCPtr <T> &val) const
			{
				return val.hash ();
			}
		};
	}
}
#endif
