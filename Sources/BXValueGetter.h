//
// BXValueGetter.h
// BaseTen
//
// Copyright (C) 2010 Marko Karppinen & Co. LLC.
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


#if defined(__cplusplus)
#import <Foundation/Foundation.h>
#import <limits>
#import <BaseTen/NSValue+BaseTenAdditions.h>


namespace BaseTen {
	
	class ValueGetterBase {
		
		template <typename T>
		struct NumberType {
			static CFNumberType const numberType = 0;
		};
		
		template <bool> class Signedness {};
		template <typename T, bool isIntegral> class Integrality {};
		template <typename T, bool isSpecialized> class NumericSpecialization {};
	};
	
	
	
	template <typename T>
	class ValueGetter : public ValueGetterBase {
		
	public:
		BOOL operator() (id value, T *outValue);
	};
	
	
	
	template <> struct ValueGetterBase::NumberType <char>      { static CFNumberType const numberType = kCFNumberCharType;     };
	template <> struct ValueGetterBase::NumberType <short>     { static CFNumberType const numberType = kCFNumberShortType;    };
	template <> struct ValueGetterBase::NumberType <int>       { static CFNumberType const numberType = kCFNumberIntType;      };
	template <> struct ValueGetterBase::NumberType <long>      { static CFNumberType const numberType = kCFNumberLongType;     };
	template <> struct ValueGetterBase::NumberType <long long> { static CFNumberType const numberType = kCFNumberLongLongType; };
	template <> struct ValueGetterBase::NumberType <float>     { static CFNumberType const numberType = kCFNumberFloatType;    };
	template <> struct ValueGetterBase::NumberType <double>    { static CFNumberType const numberType = kCFNumberDoubleType;   };
	
	
	
	template <> 
	class ValueGetterBase::Signedness <true> {
	public: 
		typedef intmax_t  integralType;
	};
	
	template <>
	class ValueGetterBase::Signedness <false> {
	public:
		typedef uintmax_t integralType;
	};
	
	
	
	template <typename T>
	class ValueGetterBase::Integrality <T, true> {
	public:
		BOOL operator() (id value, T *outValue)
		{
			// Support for uintmax_t is missing from NSValue & NSNumber additions.
			typedef typename Signedness <true>::integralType integralType;
			//typedef typename Signedness <std::numeric_limits <T>::is_signed>::integralType integralType;
			
			BOOL retval = NO;
			integralType i = 0;
			
			if ([value BXGetValue: &i length: sizeof (i) numberType: NumberType <integralType>::numberType encoding: @encode (integralType)])
			{
				// Support for uintmax_t is missing from NSValue & NSNumber additions.
				if ((integralType) std::numeric_limits <T>::min () <= i && (i < 0 || (0 <= i && static_cast <T> (i) <= std::numeric_limits <T>::max ())))
				//if (std::numeric_limits <T>::min () <= i && i <= std::numeric_limits <T>::max ())
				{
					retval = YES;
					*outValue = i;
				}
				else
				{
					BXLogAssertionFailure (@"Unable to copy '%@'; value out of bounds.", value);
				}
			}
			else
			{
				BXLogAssertionFailure (@"Unable to copy '%@'; type mismatch.", value);
			}
			return retval;
		}
	};
	
	template <typename T>
	class ValueGetterBase::Integrality <T, false> {
	public:
		BOOL operator() (id value, T *outValue)
		{
			typedef double fpType;
			
			BOOL retval = NO;
			fpType f = 0.0;
			
			if ([value BXGetValue: &f length: sizeof (fpType) numberType: NumberType <fpType>::numberType encoding: @encode (fpType)])
			{
				if (abs (f) <= std::numeric_limits <T>::max ())
				{
					retval = YES;
					*outValue = f;
				}
				else
				{
					BXLogAssertionFailure (@"Unable to copy '%@'; value out of bounds.", value);
				}
			}
			else
			{
				BXLogAssertionFailure (@"Unable to copy '%@'; type mismatch.", value);
			}			
			return retval;
		}
	};
	
	
	
	template <typename T>
	class ValueGetterBase::NumericSpecialization <T, true> {
	public:
		BOOL operator() (id value, T *outValue)
		{
			Integrality <T, std::numeric_limits <T>::is_integer> integrality;
			return integrality (value, outValue);
		}
	};
	
	template <typename T>
	class ValueGetterBase::NumericSpecialization <T, false> {
	public:
		BOOL operator() (id value, T *outValue)
		{
			BXLogAssertionFailure (@"Unable to copy '%@'; type information unavailable.", value);
			return NO;
		}
	};	
	
	
	
	template <typename T>
	BOOL ValueGetter <T>::operator() (id value, T *outValue)
	{
		// If the value can be fetched to the given buffer, return immediately.
		// Otherwise, get the type of T and try to make a larger buffer that is compatible with the type.
		
		BOOL retval = NO;
		if ([value BXGetValue: outValue length: sizeof (T) numberType: NumberType <T>::numberType encoding: @encode (T)])
			retval = YES;
		else
		{
			NumericSpecialization <T, std::numeric_limits <T>::is_specialized> spec;
			retval = spec (value, outValue);
		}
		return retval;
	}	
}
#endif
