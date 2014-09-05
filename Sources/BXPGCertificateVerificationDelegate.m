//
// BXPGCertificateVerificationDelegate.m
// BaseTen
//
// Copyright 2008-2009 Marko Karppinen & Co. LLC.
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

#import "BXPGCertificateVerificationDelegate.h"
#import "BXDatabaseContextPrivate.h"
#import "BXSafetyMacros.h"
#import "BXLogger.h"
#import <openssl/x509.h>


static BOOL CertArrayCompare (CFArrayRef a1, CFArrayRef a2) {
    BOOL retval = NO;
    CFIndex count = CFArrayGetCount (a1);
    if (CFArrayGetCount (a2) == count) {
        CFDataRef data1;
        CFDataRef data2;
        
        for (CFIndex i = 0; i < count; i++) {
            SecCertificateRef c1 = (SecCertificateRef) CFArrayGetValueAtIndex (a1, i);
            SecCertificateRef c2 = (SecCertificateRef) CFArrayGetValueAtIndex (a2, i);
            
            data1 = SecCertificateCopyData(c1);
            data2 = SecCertificateCopyData(c2);
            
            if ((data1 == NULL) || (data2 == NULL)) {
                return NO;
            }
            
            if (CFDataGetLength(data1) != CFDataGetLength(data2)) {
                CFRelease(data1);
                CFRelease(data2);
                return NO;
            }
            
            if (!CFEqual(data1, data2)) {
                CFRelease(data1);
                CFRelease(data2);
                return NO;
            }
            CFRelease(data1);
            CFRelease(data2);
        }
        
        retval = YES;
    }
    return retval;
}


@implementation BXPGCertificateVerificationDelegate
- (void) dealloc
{
	SafeCFRelease (mCertificates);
	[super dealloc];
}


- (void) finalize
{
	SafeCFRelease (mCertificates);
	[super finalize];
}


- (void) setHandler: (id <BXPGTrustHandler>) anObject
{
	mHandler = anObject;
}


- (void) setCertificates: (CFArrayRef) anArray
{
	if (mCertificates != anArray)
	{
		if (mCertificates)
			CFRelease (mCertificates);
		
		if (anArray)
			mCertificates = CFRetain (anArray);
	}
}


- (BOOL) PGTSAllowSSLForConnection: (PGTSConnection *) connection context: (void *) x509_ctx_ptr preverifyStatus: (int) preverifyStatus
{
	BOOL retval = NO;
	CFArrayRef certificates = [self copyCertificateArrayFromOpenSSLCertificates: (X509_STORE_CTX *) x509_ctx_ptr];
	
	//If we already have a certificate chain, the received chain has to match it.
	//Otherwise, create a trust and evaluate it.
	if (mCertificates)
	{
		if (CertArrayCompare (certificates, mCertificates))
			retval = YES;
		else
		{
			//FIXME: create an error indicating that the certificates have changed.
			BXLogError (@"Certificates seem to have changed between connection attempts?");
			retval = NO;
		}
	}
	else
	{
		[self setCertificates: certificates];
		
		SecTrustResultType result = kSecTrustResultInvalid;
		SecTrustRef trust = [self copyTrustFromCertificates: certificates];
		OSStatus status = SecTrustEvaluate (trust, &result);

		if (noErr != status)
			retval = NO;
		else if (kSecTrustResultProceed == result)
			retval = YES;
		else
			retval = [mHandler handleInvalidTrust: trust result: result];
		
		SafeCFRelease (trust);
	}
	
	SafeCFRelease (certificates);	
	return retval;
}

@end
