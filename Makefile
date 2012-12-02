SHELL=/usr/bin/env bash
.PHONY: clean base

BUILD_ROOT=$(CURDIR)/tmp
PACKAGE_DIR=$(CURDIR)/packages
INSTALL_LOCATION=$(CURDIR)/build_output
OPEN_SSL= ${INSTALL_LOCATION}/usr/local/ssl/bin/openssl
OPEN_SSL_SOURCE= ${BUILD_ROOT}/openssl-1.0.1c 
LUAJIT=${INSTALL_LOCATION}/bin/luajit
NGINX=${INSTALL_LOCATION}/sbin/nginx
PCRE_SOURCE=${BUILD_ROOT}/pcre-8.32
NGINX_LUA_MODULE_SOURCE=${BUILD_ROOT}/lua-nginx-module-0.7.6rc1
LUA=${INSTALL_LOCATION}/bin/lua
LUA_SOURCE=${BUILD_ROOT}/lua-5.1
LUAJIT_LIB=${INSTALL_LOCATION}/lib
LUAJIT_INC=${INSTALL_LOCATION}/include/luajit-2.0
PKG_CONFIG_PATH=${INSTALL_LOCATION}/lib/pkgconfig:${INSTALL_LOCATION}/usr/local/ssl/lib/pkgconfig
.EXPORT_ALL_VARIABLES:

${NGINX}: ${LUAJIT} ${OPEN_SSL}
	cd ${BUILD_ROOT}/nginx-1.2.4/ && export LUAJIT_LIB=${LUAJIT_LIB} && ./configure --prefix=${INSTALL_LOCATION} --add-module=${BUILD_ROOT}/ngx_devel_kit-0.2.17rc2 --add-module=${BUILD_ROOT}/lua-nginx-module-0.7.6rc1 --with-pcre=${BUILD_ROOT}/pcre-8.32
	cd ${BUILD_ROOT}/nginx-1.2.4/ && make install

base: ${INSTALL_LOCATION} ${BUILD_ROOT}

${INSTALL_LOCATION}:
	mkdir -p ${INSTALL_LOCATION}

${LUAJIT}: base
	cd ${BUILD_ROOT}/LuaJIT-2.0.0 && make install -e PREFIX=${INSTALL_LOCATION}

${BUILD_ROOT}:
	mkdir -p ${BUILD_ROOT}
	cd ${PACKAGE_DIR} && for file in *.tar.gz; do tar xf $${file} -C ${BUILD_ROOT}; done

${LUA}: base
	cd ${LUA_SOURCE} && make generic install -e INSTALL_TOP=${INSTALL_LOCATION}

${OPEN_SSL}: base
	cd ${OPEN_SSL_SOURCE} && ./config
	cd ${OPEN_SSL_SOURCE} && make install -e INSTALL_PREFIX=${INSTALL_LOCATION} -e OPENSSL_DIR=${INSTALL_LOCATION}/ssl

luacrypto: ${OPEN_SSL} ${LUA}
	cd ${BUILD_ROOT}/luacrypto-master && ./configure
	cd ${BUILD_ROOT}/luacrypto-master && make

clean:
	-rm -rf ${INSTALL_LOCATION}
	-rm -rf ${BUILD_ROOT}
