include Tools/common.mk


PG_BUILD_DIR   = $(BUILD_DIR)/Release/BaseTen-PostgreSQL
PG_VERSION     = 8.3.11
PG_SOURCE_FILE = Contrib/PostgreSQL/postgresql-$(PG_VERSION).tar.bz2
PG_DIR         = postgresql-$(PG_VERSION)
PG_ROOT        = $(PG_BUILD_DIR)/$(PG_DIR)

UNIVERSAL_LIBS = $(foreach my_arch,$(ARCHS),$(PG_BUILD_DIR)/$(my_arch)/lib/libpq.a)
UNIVERSAL_BINS = $(foreach my_arch,$(ARCHS),$(PG_BUILD_DIR)/$(my_arch)/bin/psql)


.PHONY: all clean build build-specifics build-arch


all: build


clean:
	$(RM) -rf $(PG_BUILD_DIR)


build: $(PG_BUILD_DIR)/universal/postgresql $(PG_BUILD_DIR)/universal/lib/libpq.a $(PG_BUILD_DIR)/universal/bin/psql


build-arch: $(PG_ROOT)
	-$(MAKE) -j $(AVAILCPU) -C $(PG_ROOT) distclean

	cd "$(PG_ROOT)" && \
	CC="$(CC_$(ARCH))" \
	CFLAGS="$(CFLAGS_$(ARCH))" \
	CPPFLAGS="$(CPPFLAGS_$(ARCH))" \
	LDFLAGS="$(LDFLAGS_$(ARCH))" \
	./configure --build=$(shell $(PG_ROOT)/config.guess) --host=$(TARGET_$(ARCH)) --target=$(TARGET_$(ARCH)) \
		--prefix="$(PG_BUILD_DIR)/$(ARCH)" \
		--disable-shared \
		--without-zlib \
		--without-readline \
		--with-openssl

	## Required targets, see src/backend/Makefile: Make symlinks...
	$(MAKE) -j $(AVAILCPU) -C $(PG_ROOT)/src/backend ../../src/include/parser/parse.h
	$(MAKE) -j $(AVAILCPU) -C $(PG_ROOT)/src/backend ../../src/include/utils/fmgroids.h
	$(MAKE) -j $(AVAILCPU) -C $(PG_ROOT)/src/port

	$(MAKE) -j $(AVAILCPU) -C $(PG_ROOT)/src/include install
	$(MAKE) -j $(AVAILCPU) -C $(PG_ROOT)/src/interfaces install
	$(MAKE) -j $(AVAILCPU) -C $(PG_ROOT)/src/bin/psql install


$(PG_BUILD_DIR)/universal/lib/libpq.a: $(UNIVERSAL_LIBS)
	$(MKDIR) -p $(PG_BUILD_DIR)/universal/lib
	$(LIPO) $(UNIVERSAL_LIBS) -create -output $(PG_BUILD_DIR)/universal/lib/libpq.a


$(PG_BUILD_DIR)/universal/bin/psql: $(UNIVERSAL_BINS)
	$(MKDIR) -p $(PG_BUILD_DIR)/universal/bin
	$(LIPO) $(UNIVERSAL_BINS) -create -output $(PG_BUILD_DIR)/universal/bin/psql


$(PG_BUILD_DIR)/universal/postgresql: $(PG_BUILD_DIR)/ppc/include
	$(MKDIR) -p $(PG_BUILD_DIR)/universal/postgresql
	$(CP) -a $(PG_BUILD_DIR)/ppc/include/* $(PG_BUILD_DIR)/universal/postgresql

	$(CP) -a $(SRCROOT)/Sources/pg_config.h $(PG_BUILD_DIR)/universal/postgresql/pg_config.h
	$(CP) -a $(SRCROOT)/Sources/pg_config.h $(PG_BUILD_DIR)/universal/postgresql/postgresql/server/pg_config.h

	$(CP) -a $(SRCROOT)/Sources/pg_config_os.h $(PG_BUILD_DIR)/universal/postgresql/pg_config_os.h
	$(CP) -a $(SRCROOT)/Sources/pg_config_os.h $(PG_BUILD_DIR)/universal/postgresql/postgresql/server/pg_config_os.h

	$(CP) -a $(SRCROOT)/Sources/ecpg_config.h $(PG_BUILD_DIR)/universal/postgresql/ecpg_config.h


$(PG_BUILD_DIR)/%/include $(PG_BUILD_DIR)/%/lib/libpq.a $(PG_BUILD_DIR)/%/bin/psql: $(PG_SOURCE_FILE)
	ARCH=$* $(MAKE) -f Tools/PostgreSQL/PostgreSQL.mk build-arch


$(PG_ROOT): $(PG_SOURCE_FILE)
	$(MKDIR) -p $(PG_BUILD_DIR)
	$(TAR) -jxf $(PG_SOURCE_FILE) -C $(PG_BUILD_DIR)
	$(LN) -s $(PG_DIR) $(PG_BUILD_DIR)/postgresql-src
	$(PATCH) -p0 -d $(PG_ROOT) < $(SRCROOT)/Patches/libpq.patch
	$(PATCH) -p0 -d $(PG_ROOT) < $(SRCROOT)/Patches/pg-makefile.patch
