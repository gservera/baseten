TAR              = /usr/bin/gnutar
LIPO             = /usr/bin/lipo
TOUCH            = /usr/bin/touch
SLEEP            = /bin/sleep
MKDIR            = /bin/mkdir
LN               = /bin/ln
PATCH            = /usr/bin/patch

AVAILCPU         = $(shell /usr/sbin/sysctl -n hw.availcpu)

TARGET_ppc       = powerpc-apple-darwin
TARGET_i386      = i386-apple-darwin
TARGET_ppc64     = powerpc64-apple-darwin
TARGET_x86_64    = x86_64-apple-darwin
TARGET_armv6     = armv6-apple-darwin

CC_ppc           = $(PLATFORM_DEVELOPER_BIN_DIR)/gcc-$(GCC_VERSION_ppc)
CC_i386          = $(PLATFORM_DEVELOPER_BIN_DIR)/gcc-$(GCC_VERSION_i386)
CC_ppc64         = $(PLATFORM_DEVELOPER_BIN_DIR)/gcc-$(GCC_VERSION_ppc64)
CC_x86_64        = $(PLATFORM_DEVELOPER_BIN_DIR)/gcc-$(GCC_VERSION_x86_64)
CC_armv6         = $(DEVELOPER_DIR)/Platforms/iPhoneOS.platform/Developer/usr/bin/gcc-4.2

CFLAGS_ppc       = -arch $(ARCH)
CFLAGS_i386      = -arch $(ARCH)
CFLAGS_ppc64     = -arch $(ARCH)
CFLAGS_x86_64    = -arch $(ARCH)
CFLAGS_armv6     = -arch $(ARCH)

CPPFLAGS_ppc     = -arch $(ARCH) -mmacosx-version-min=$(MACOSX_DEPLOYMENT_TARGET) -isysroot $(SDKROOT)
CPPFLAGS_ppc64   = -arch $(ARCH) -mmacosx-version-min=$(MACOSX_DEPLOYMENT_TARGET) -isysroot $(SDKROOT)
CPPFLAGS_i386    = -arch $(ARCH) -mmacosx-version-min=$(MACOSX_DEPLOYMENT_TARGET) -isysroot $(SDKROOT)
CPPFLAGS_x86_64  = -arch $(ARCH) -mmacosx-version-min=$(MACOSX_DEPLOYMENT_TARGET) -isysroot $(SDKROOT)
CPPFLAGS_armv6   = -arch $(ARCH) -miphoneos-version-min=3.0 -isysroot $(SDKROOT)

LDFLAGS_ppc      = -arch $(ARCH) -mmacosx-version-min=$(MACOSX_DEPLOYMENT_TARGET) -Wl,-syslibroot,$(SDKROOT)
LDFLAGS_i386     = -arch $(ARCH) -mmacosx-version-min=$(MACOSX_DEPLOYMENT_TARGET) -Wl,-syslibroot,$(SDKROOT)
LDFLAGS_ppc64    = -arch $(ARCH) -mmacosx-version-min=$(MACOSX_DEPLOYMENT_TARGET) -Wl,-syslibroot,$(SDKROOT)
LDFLAGS_x86_64   = -arch $(ARCH) -mmacosx-version-min=$(MACOSX_DEPLOYMENT_TARGET) -Wl,-syslibroot,$(SDKROOT)
LDFLAGS_armv6    = -arch $(ARCH) -miphoneos-version-min=3.0 -Wl,-syslibroot,$(SDKROOT)
