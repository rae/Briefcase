

OPENSSL_VERSION = openssl-1.0.0d

VPATH = $(TARGET_BUILD_DIR):$(DERIVED_FILE_DIR)

all: libcrypto.a libssl.a

unpack: .unpacked
patch: .patched


diff:
	mv $(OPENSSL_VERSION) $(OPENSSL_VERSION).new
	tar xzf $(OPENSSL_VERSION).tar.gz
	mv $(OPENSSL_VERSION) $(OPENSSL_VERSION).orig
	mv $(OPENSSL_VERSION).new $(OPENSSL_VERSION)
	rm -rf tmp-extract
	diff -ruN $(OPENSSL_VERSION).orig $(OPENSSL_VERSION) > $(OPENSSL_VERSION).patch || true
	
.unpacked:
	mkdir -p $(DERIVED_FILE_DIR)
	tar xzf $(OPENSSL_VERSION).tar.gz -C $(DERIVED_FILE_DIR)
	touch $(DERIVED_FILE_DIR)/.unpacked

.patched: .unpacked
	sed "s:<SDKROOT>:$(SDKROOT):g" $(OPENSSL_VERSION).patch > $(OPENSSL_VERSION).patch.sdk
	cat $(OPENSSL_VERSION).patch.sdk | (cd $(DERIVED_FILE_DIR)/$(OPENSSL_VERSION) && patch -p1)
	touch $(DERIVED_FILE_DIR)/.patched
	
libcrypto.a libssl.a: .patched
	cd $(DERIVED_FILE_DIR)/$(OPENSSL_VERSION) && export CC=gcc-4.2 && ./Configure darwin-i386-$(PLATFORM_NAME)-gcc 
	make -C $(DERIVED_FILE_DIR)/$(OPENSSL_VERSION) build_libs
	mkdir -p $(TARGET_BUILD_DIR)
	cp $(DERIVED_FILE_DIR)/$(OPENSSL_VERSION)/libcrypto.a $(DERIVED_FILE_DIR)/$(OPENSSL_VERSION)/libssl.a $(TARGET_BUILD_DIR)
	cp -RL $(DERIVED_FILE_DIR)/$(OPENSSL_VERSION)/include/openssl $(TARGET_BUILD_DIR)/include
	 
clean:
	rm -rf $(DERIVED_FILE_DIR)/$(OPENSSL_VERSION) $(OPENSSL_VERSION).orig $(DERIVED_FILE_DIR)/.patched $(DERIVED_FILE_DIR)/.unpacked 
	rm -rf $(TARGET_BUILD_DIR)/libcrypto.a $(TARGET_BUILD_DIR)/libssl.a
	rm -rf $(TARGET_BUILD_DIR)/include/openssl
	rm -rf $(OPENSSL_VERSION).patch.sdk