TAR              = /usr/bin/gnutar
LIPO             = /usr/bin/lipo
TOUCH            = /usr/bin/touch
SLEEP            = /bin/sleep
MKDIR            = /bin/mkdir

PCRE_BUILD_DIR   = $(BUILD_DIR)/Release/BaseTen-pcre
PCRE_VERSION     = 8.02
PCRE_SOURCE_FILE = Contrib/pcre/pcre-$(PCRE_VERSION).tar.bz2
PCRE_ROOT        = $(PCRE_BUILD_DIR)/pcre-$(PCRE_VERSION)
AVAILCPU         = $(shell /usr/sbin/sysctl -n hw.availcpu)
UNIVERSAL_LIBS   = $(foreach my_arch,ppc ppc64 i386 x86_64,$(PCRE_BUILD_DIR)/$(my_arch)/lib/libpcre.a)

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

CFLAGS_ppc       = -arch ppc
CFLAGS_i386      = -arch i386
CFLAGS_ppc64     = -arch ppc64
CFLAGS_x86_64    = -arch x86_64
CFLAGS_armv6     = -arch armv6

CPPFLAGS_ppc     = -arch ppc    -mmacosx-version-min=10.5  -isysroot $(DEVELOPER_SDK_DIR)/MacOSX10.5.sdk
CPPFLAGS_i386    = -arch i386   -mmacosx-version-min=10.5  -isysroot $(DEVELOPER_SDK_DIR)/MacOSX10.5.sdk
CPPFLAGS_ppc64   = -arch ppc64  -mmacosx-version-min=10.5  -isysroot $(DEVELOPER_SDK_DIR)/MacOSX10.5.sdk
CPPFLAGS_x86_64  = -arch x86_64 -mmacosx-version-min=10.5  -isysroot $(DEVELOPER_SDK_DIR)/MacOSX10.5.sdk
CPPFLAGS_armv6   = -arch armv6  -miphoneos-version-min=3.0 -isysroot $(DEVELOPER_DIR)/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS3.0.sdk

LDFLAGS_ppc      = -arch ppc    -mmacosx-version-min=10.5  -Wl,-syslibroot,$(DEVELOPER_SDK_DIR)/MacOSX10.5.sdk
LDFLAGS_i386     = -arch i386   -mmacosx-version-min=10.5  -Wl,-syslibroot,$(DEVELOPER_SDK_DIR)/MacOSX10.5.sdk
LDFLAGS_ppc64    = -arch ppc64  -mmacosx-version-min=10.5  -Wl,-syslibroot,$(DEVELOPER_SDK_DIR)/MacOSX10.5.sdk
LDFLAGS_x86_64   = -arch x86_64 -mmacosx-version-min=10.5  -Wl,-syslibroot,$(DEVELOPER_SDK_DIR)/MacOSX10.5.sdk
LDFLAGS_armv6    = -arch armv6  -miphoneos-version-min=3.0 -Wl,-syslibroot,$(DEVELOPER_DIR)/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS3.0.sdk


.PHONY: all clean build build-specifics build-arch


all: build


clean:
	$(RM) -rf $(PCRE_BUILD_DIR)


build: $(PCRE_BUILD_DIR)/universal/include/pcre.h $(PCRE_BUILD_DIR)/universal/lib/libpcre.a


build-arch: $(PCRE_ROOT)
	-$(MAKE) -j $(AVAILCPU) -C $(PCRE_ROOT) distclean

	cd "$(PCRE_ROOT)" && \
	CC="$(CC_$(ARCH))" \
	CFLAGS="$(CFLAGS_$(ARCH))" \
	CPPFLAGS="$(CPPFLAGS_$(ARCH))" \
	LDFLAGS="$(LDFLAGS_$(ARCH))" \
	./configure --build=$(shell $(PCRE_ROOT)/config.guess) --host=$(TARGET_$(ARCH)) --target=$(TARGET_$(ARCH)) \
		--prefix="$(PCRE_BUILD_DIR)/$(ARCH)" --enable-static --disable-shared --enable-utf8 --enable-unicode-properties

	$(MAKE) -j $(AVAILCPU) -C $(PCRE_ROOT) all
	$(MAKE) -C $(PCRE_ROOT) install


$(PCRE_BUILD_DIR)/universal/lib/libpcre.a: $(UNIVERSAL_LIBS)
	$(MKDIR) -p $(PCRE_BUILD_DIR)/universal/lib
	$(LIPO) $(UNIVERSAL_LIBS) -create -output $(PCRE_BUILD_DIR)/universal/lib/libpcre.a


$(PCRE_BUILD_DIR)/%/lib/libpcre.a: $(PCRE_SOURCE_FILE)
	ARCH=$* $(MAKE) -f Tools/pcre.mk build-arch


$(PCRE_BUILD_DIR)/universal/include/pcre.h: $(PCRE_ROOT)/pcre.h.generic
	$(MKDIR) -p $(PCRE_BUILD_DIR)/universal/include
	$(CP) $(PCRE_ROOT)/pcre.h.generic $(PCRE_BUILD_DIR)/universal/include/pcre.h


$(PCRE_ROOT)/pcre.h.generic : $(PCRE_ROOT)


$(PCRE_ROOT): $(PCRE_SOURCE_FILE)
	$(MKDIR) -p $(PCRE_BUILD_DIR)
	$(TAR) -jxf $(PCRE_SOURCE_FILE) -C $(PCRE_BUILD_DIR)
