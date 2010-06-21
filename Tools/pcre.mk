include Tools/common.mk


PCRE_BUILD_DIR   = $(BUILD_DIR)/Release/BaseTen-pcre
PCRE_VERSION     = 8.02
PCRE_SOURCE_FILE = Contrib/pcre/pcre-$(PCRE_VERSION).tar.bz2
PCRE_ROOT        = $(PCRE_BUILD_DIR)/pcre-$(PCRE_VERSION)
UNIVERSAL_LIBS   = $(foreach my_arch,$(ARCHS),$(PCRE_BUILD_DIR)/$(my_arch)/lib/libpcre.a)


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
