TAR              = /usr/bin/gnutar
LIPO             = /usr/bin/lipo
TOUCH            = /usr/bin/touch
SLEEP            = /bin/sleep
MKDIR            = /bin/mkdir
LN               = /bin/ln
PATCH            = /usr/bin/patch

AVAILCPU         = $(shell /usr/sbin/sysctl -n hw.availcpu)

TARGET_i386      = i386-apple-darwin
TARGET_x86_64    = x86_64-apple-darwin
TARGET_armv6     = armv6-apple-darwin

CC_i386          = $(PLATFORM_DEVELOPER_BIN_DIR)/gcc-$(GCC_VERSION_i386)
CC_x86_64        = $(PLATFORM_DEVELOPER_BIN_DIR)/gcc-$(GCC_VERSION_x86_64)
CC_armv6         = $(DEVELOPER_DIR)/Platforms/iPhoneOS.platform/Developer/usr/bin/gcc-4.2

CFLAGS_i386      = -arch $(ARCH)
CFLAGS_x86_64    = -arch $(ARCH)
CFLAGS_armv6     = -arch $(ARCH)

CPPFLAGS_i386    = -arch $(ARCH) -mmacosx-version-min=$(MACOSX_DEPLOYMENT_TARGET) -isysroot $(SDKROOT)
CPPFLAGS_x86_64  = -arch $(ARCH) -mmacosx-version-min=$(MACOSX_DEPLOYMENT_TARGET) -isysroot $(SDKROOT)
CPPFLAGS_armv6   = -arch $(ARCH) -miphoneos-version-min=3.0 -isysroot $(SDKROOT)

LDFLAGS_i386     = -arch $(ARCH) -mmacosx-version-min=$(MACOSX_DEPLOYMENT_TARGET) -Wl,-syslibroot,$(SDKROOT)
LDFLAGS_x86_64   = -arch $(ARCH) -mmacosx-version-min=$(MACOSX_DEPLOYMENT_TARGET) -Wl,-syslibroot,$(SDKROOT)
LDFLAGS_armv6    = -arch $(ARCH) -miphoneos-version-min=3.0 -Wl,-syslibroot,$(SDKROOT)
