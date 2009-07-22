

OPENSSL_VERSION = openssl-0.9.8k

VPATH = $(TARGET_BUILD_DIR)

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
	tar xzf $(OPENSSL_VERSION).tar.gz
	env > /tmp/env.txt
	touch .unpacked

.patched: .unpacked $(OPENSSL_VERSION).patch
	sed "s:<SDKROOT>:$(SDKROOT):g" $(OPENSSL_VERSION).patch > $(OPENSSL_VERSION).patch.sdk
	cat $(OPENSSL_VERSION).patch.sdk | (cd $(OPENSSL_VERSION) && patch -p1)
	touch .patched
	
libcrypto.a libssl.a: .patched
	cd $(OPENSSL_VERSION) && export CC=gcc-4.2 && ./Configure darwin-i386-$(PLATFORM_NAME)-gcc 
	make -C $(OPENSSL_VERSION) clean
	make -C $(OPENSSL_VERSION) build_libs
	mkdir -p $(TARGET_BUILD_DIR)
	cp $(OPENSSL_VERSION)/libcrypto.a $(OPENSSL_VERSION)/libssl.a $(TARGET_BUILD_DIR)
	cp -RL $(OPENSSL_VERSION)/include/openssl $(TARGET_BUILD_DIR)/include
	 
clean:
	rm -rf $(OPENSSL_VERSION) $(OPENSSL_VERSION).orig .patched .unpacked 
	rm -rf $(TARGET_BUILD_DIR)/libcrypto.a $(TARGET_BUILD_DIR)/libssl.a
	rm -rf $(TARGET_BUILD_DIR)/include/openssl
	rm -rf $(OPENSSL_VERSION).patch.sdk