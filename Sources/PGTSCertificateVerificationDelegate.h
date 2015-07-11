//
// PGTSCertificateVerificationDelegate.h
// BaseTen
//
// Copyright 2007-2009 Marko Karppinen & Co. LLC.
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
#import <Security/Security.h>
#import <openssl/ssl.h>
#import <BaseTen/PGTSCertificateVerificationDelegateProtocol.h>


@interface PGTSCertificateVerificationDelegate : NSObject <PGTSCertificateVerificationDelegate>
{
	CFArrayRef mPolicies;
}

+ (id) defaultCertificateVerificationDelegate;
- (SecTrustRef) copyTrustFromCertificates: (CFArrayRef) certificates;
//- (CFArrayRef) copyCertificateArrayFromOpenSSLCertificates: (X509_STORE_CTX *) x509_ctx;
@end
