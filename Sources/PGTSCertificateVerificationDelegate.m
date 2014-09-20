//
// PGTSCertificateVerificationDelegate.m
// BaseTen
//
// Copyright 2007-2010 Marko Karppinen & Co. LLC.
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

#import "PGTSCertificateVerificationDelegate.h"
#import "BXSafetyMacros.h"
#import <Security/Security.h>
#import "BXOpenSSLCompatibility.h"
#import "BXArraySize.h"


__strong static id <PGTSCertificateVerificationDelegate> gDefaultCertDelegate = nil;

/**
 * \internal
 * \brief Default implementation for verifying OpenSSL X.509 certificates.
 *
 * This class is thread-safe.
 */
@implementation PGTSCertificateVerificationDelegate

+ (id) defaultCertificateVerificationDelegate
{
	if (! gDefaultCertDelegate)
	{
		@synchronized (self)
		{
			if (! gDefaultCertDelegate)
				gDefaultCertDelegate = [[self alloc] init];
		}
	}
	return gDefaultCertDelegate;
}

- (id) init
{
	if ((self = [super init]))
	{
	}
	return self;
}

- (void) dealloc
{
	SafeCFRelease (mPolicies);
	[super dealloc];
}

- (void) finalize
{
	SafeCFRelease (mPolicies);
	[super finalize];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
- (CSSM_CERT_TYPE) x509Version: (X509 *) x509Cert
{
	CSSM_CERT_TYPE retval = CSSM_CERT_X_509v3;
	switch (X509_get_version (x509Cert))
	{
		case 1:
			retval = CSSM_CERT_X_509v1;
			break;
		case 2:
			retval = CSSM_CERT_X_509v2;
			break;
		case 3:
		default:
			break;
	}
	return retval;
}
#pragma clang diagnostic pop

/**
 * \brief Get search policies.
 *
 * To find search policies, we need to create a search criteria. To create a search criteria, 
 * we need to give the criteria creation function some constants.
 */
- (CFArrayRef) policies
{
	@synchronized (self)
	{
		if (! mPolicies)
		{
			OSStatus status = noErr;
			
			CFMutableArrayRef policies = CFArrayCreateMutable (NULL, 0, &kCFTypeArrayCallBacks);
			const CSSM_OID* currentOidPtr = NULL;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
			const CFTypeRef oidPtrs [] = {kSecPolicyAppleSSL, kSecPolicyAppleRevocation};
#pragma clang diagnostic pop
			for (int i = 0, count = BXArraySize (oidPtrs); i < count; i++)
			{
				currentOidPtr = oidPtrs [i];
                CFStringRef oid = (CFStringRef)currentOidPtr;
				SecPolicyRef policy = SecPolicyCreateWithOID(oid);
                if (policy == NULL) {
                    CFArrayRemoveAllValues(policies);
                    break;
                }
                
                CFArrayAppendValue(policies, policy);
                CFRelease(policy);
			}
			
            if (noErr == status) {
				mPolicies = CFArrayCreateCopy (NULL, policies);
            }
			SafeCFRelease (policies);
			
		}
	}
	return mPolicies;
}

/**
 * \brief Create a SecCertificateRef from an OpenSSL certificate.
 * \param bioOutput A memory buffer so we don't have to allocate one.
 */
- (SecCertificateRef) copyCertificateFromX509: (X509 *) opensslCert bioOutput: (BIO *) bioOutput {
	SecCertificateRef cert = NULL;
	
	if (bioOutput && opensslCert)
	{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
		(void) BIO_reset (bioOutput);
		if (i2d_X509_bio (bioOutput, opensslCert))
		{
			BUF_MEM* bioBuffer = NULL;
			BIO_get_mem_ptr (bioOutput, &bioBuffer);
#pragma clang diagnostic pop
            NSData *data = [[NSData alloc] initWithBytesNoCopy:bioBuffer->data length:bioBuffer->length freeWhenDone:NO];
            cert = SecCertificateCreateWithData(kCFAllocatorDefault, (CFDataRef)data);
            [data release];
		}
	}
	return cert;
}

/**
 * \brief Verify an OpenSSL X.509 certificate.
 *
 * Get the X.509 certificate from OpenSSL, encode it in DER format and let Security framework parse it again.
 * This way, we can use the Keychain to verify the certificate, since a CA trusted by the OS or the user
 * might have signed it or the user could have stored the certificate earlier. The preverification result
 * is ignored because it rejects certificates from CAs unknown to OpenSSL. 
 */ 
- (BOOL) PGTSAllowSSLForConnection: (PGTSConnection *) connection context: (void *) x509_ctx preverifyStatus: (int) preverifyStatus
{
	BOOL retval = NO;
	SecTrustResultType result = kSecTrustResultInvalid;	
	CFArrayRef certificates = NULL;
	SecTrustRef trust = NULL;
	
	certificates = [self copyCertificateArrayFromOpenSSLCertificates: (X509_STORE_CTX *) x509_ctx];
	if (! certificates)
		goto error;
	
	trust = [self copyTrustFromCertificates: certificates];
	if (! trust)
		goto error;
	
	OSStatus status = SecTrustEvaluate (trust, &result);
	if (noErr == status && kSecTrustResultProceed == result)
		retval = YES;

error:
	SafeCFRelease (certificates);
	SafeCFRelease (trust);
	return retval;
}

/**
 * \brief Create a trust.
 *
 * To verify a certificate, we need to
 * create a trust. To create a trust, we need to find search policies.
 * \param certificates An array of SecCertificateRefs.
 */
- (SecTrustRef) copyTrustFromCertificates: (CFArrayRef) certificates
{
	SecTrustRef trust = NULL;
	CFArrayRef policies = [self policies];
	if (policies && 0 < CFArrayGetCount (policies))
	{
		OSStatus status = SecTrustCreateWithCertificates (certificates, policies, &trust);
		if (noErr != status)
		{
			SafeCFRelease (trust);
			trust = NULL;
		}
	}
	return trust;
}

/**
 * \brief Create Security certificates from OpenSSL certificates.
 * \return An array of SecCertificateRefs.
 */
- (CFArrayRef) copyCertificateArrayFromOpenSSLCertificates: (X509_STORE_CTX *) x509_ctx
{
	CFMutableArrayRef certs = NULL;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
	BIO* bioOutput = BIO_new (BIO_s_mem ());
#pragma clang diagnostic pop
	
	if (bioOutput)
	{
		int count = M_sk_num (x509_ctx->untrusted);
		SecCertificateRef serverCert = [self copyCertificateFromX509: x509_ctx->cert bioOutput: bioOutput];
		if (serverCert)
		{
			certs = (CFArrayCreateMutable (NULL, count + 1, &kCFTypeArrayCallBacks));
			CFArrayAppendValue (certs, serverCert);
			SafeCFRelease (serverCert);
			
			for (int i = 0; i < count; i++)
			{
				SecCertificateRef chainCert = [self copyCertificateFromX509: (X509 *) M_sk_value (x509_ctx->untrusted, i)
																  bioOutput: bioOutput];
				if (chainCert)
				{
					CFArrayAppendValue (certs, chainCert);
					CFRelease (chainCert);
				}
				else
				{
					SafeCFRelease (certs);
					certs = NULL;
					break;
				}
			}
		}
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
		BIO_free (bioOutput);
#pragma clang diagnostic pop
	}
	
	CFArrayRef retval = NULL;
	if (certs)
	{
		retval = CFArrayCreateCopy (NULL, certs);
		CFRelease (certs);
	}
	return retval;
}
@end
