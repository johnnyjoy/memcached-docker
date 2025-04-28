# syntax=docker/dockerfile:1

################################################################################
# Global build‐args (available in all stages)
################################################################################
ARG VERSION="1.6.38"
ARG OPENSSL_VERSION="3.5.0"
ARG LIBEVENT_VERSION="2.2.1-alpha"
ARG SASL_VERSION="2.1.28"

ARG CFLAGS="-flto \
    -fmerge-all-constants \
    -fno-unwind-tables \
    -fvisibility=hidden \
    -fuse-linker-plugin \
    -Wimplicit \
    -Os -s \
    -ffunction-sections \
    -fdata-sections \
    -fno-ident \
    -fno-asynchronous-unwind-tables \
    -static \
    -Wno-cast-function-type \
    -Wno-implicit-function-declaration"

ARG LDFLAGS="-flto \
    -fuse-linker-plugin \
    -static -s \
    -Wl,--gc-sections"

ARG CPPFLAGS="-I/usr/include"

################################################################################
# Stage 1: fetch & verify sources
################################################################################
FROM alpine:edge AS fetch

ARG MEMCACHED_CHECKSUM="334d792294e37738796b5b03375c47bb6db283b1152e2ea4ccb720152dd17c66"
ARG OPENSSL_CHECKSUM="344d0a79f1a9b08029b0744e2cc401a43f9c90acd1044d09a530b4885a8e9fc0"
ARG LIBEVENT_CHECKSUM="86ca388821e81d960c696d52a29631bbeda153f0b12edae9c8f844cd61c79776"
ARG SASL_CHECKSUM="7ccfc6abd01ed67c1a0924b353e526f1b766b21f42d4562ee635a8ebfc5bb38c"

ARG VERSION OPENSSL_VERSION LIBEVENT_VERSION SASL_VERSION

WORKDIR /build
RUN \
    wget -O memcached.tar.gz \
        https://www.memcached.org/files/memcached-${VERSION}.tar.gz && \
    wget -O openssl.tar.gz \
        https://github.com/openssl/openssl/releases/download/openssl-${OPENSSL_VERSION}/openssl-${OPENSSL_VERSION}.tar.gz && \
    wget -O libevent.tar.gz \
        https://github.com/libevent/libevent/archive/refs/tags/release-${LIBEVENT_VERSION}.tar.gz && \
    wget -O sasl.tar.gz \
        https://github.com/cyrusimap/cyrus-sasl/releases/download/cyrus-sasl-${SASL_VERSION}/cyrus-sasl-${SASL_VERSION}.tar.gz

RUN \
    printf "%s %s\n" \
        "${MEMCACHED_CHECKSUM}" "memcached.tar.gz" \
        "${OPENSSL_CHECKSUM}"   "openssl.tar.gz" \
        "${LIBEVENT_CHECKSUM}"  "libevent.tar.gz" \
        "${SASL_CHECKSUM}"      "sasl.tar.gz" \
    | sha256sum -c -

RUN tar -xzf memcached.tar.gz && \
    tar -xzf openssl.tar.gz   && \
    tar -xzf libevent.tar.gz  && \
    tar -xzf sasl.tar.gz

WORKDIR /build/memcached-${VERSION}
RUN sed -i 's|SSL_get_peer_certificate|SSL_get1_peer_certificate|g' tls.c

WORKDIR /build/cyrus-sasl-${SASL_VERSION}
RUN sed '/saslint/a #include <time.h>' -i lib/saslutil.c && \
    sed '/plugin_common/a #include <time.h>' -i plugins/cram.c

################################################################################
# Stage 2: build tools + shared deps
################################################################################
FROM alpine:edge AS build-deps

# Re-export the flags so they’re in ENV here
ARG VERSION LIBEVENT_VERSION OPENSSL_VERSION
ARG CFLAGS LDFLAGS CPPFLAGS
ENV CFLAGS="${CFLAGS}" LDFLAGS="${LDFLAGS}" CPPFLAGS="${CPPFLAGS}"

# Pull in testing for upx, plus all build tools
RUN echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing" \
      >> /etc/apk/repositories && \
    apk update && \
    apk add --no-cache \
      gcc linux-headers binutils coreutils make cmake musl-dev \
      binutils-gold perl perl-utils patch wget && \
    apk add --no-cache upx || true && \
    rm -rf /var/cache/apk/*

RUN mkdir -p /out/etc && \
    printf "nogroup:*:10000:nobody\nnobody:*:10000:10000:::\n" > \
        /out/etc/{group,passwd}

# Copy in all the patches for downstream
COPY patches /patches

# Copy in sources
COPY --from=fetch /build /build

WORKDIR /build/libevent-release-${LIBEVENT_VERSION}
RUN cmake -D CMAKE_INSTALL_PREFIX=/usr \
        -D EVENT__DISABLE_THREAD_SUPPORT=ON \
        -D EVENT__DISABLE_PTHREADS=ON \
        -D EVENT__DISABLE_DEBUG_MODE=ON \
        -D EVENT__DISABLE_BENCHMARK=ON \
        -D EVENT__DISABLE_CLOCK_GETTIME=OFF \
        -D EVENT__DISABLE_MM_REPLACEMENT=ON \
        -D EVENT__DISABLE_RPC=ON \
        -D EVENT__DISABLE_ZLIB=ON \
        -D EVENT__DISABLE_OPENSSL=ON \
        -D EVENT__DISABLE_HTTP=ON \
        -D EVENT__DISABLE_MBEDTLS=ON \
        -D EVENT__BUILD_SHARED_LIBRARIES=OFF \
        -D EVENT__LIBRARY_TYPE=STATIC \
        -D EVENT__DISABLE_REGRESS=ON \
        -D EVENT__DISABLE_SAMPLES=ON \
        -D EVENT__DISABLE_DNS=ON \
        -D EVENT__DISABLE_EVRPC=ON \
        -D EVENT__DISABLE_THREAD=ON \
        -D EVENT__DISABLE_TESTS=ON && \
    make -j$(nproc) && make install

# OpenSSL (static)
WORKDIR /build/openssl-${OPENSSL_VERSION}
RUN ./config \
        --prefix=/usr \
        no-cms \
        no-md2 \
        no-md4 \
        no-sm2 \
        no-sm3 \
        no-sm4 \
        no-rc2 \
        no-rc4 \
        no-idea \
        no-aria \
        no-camellia \
        no-whirlpool \
        no-rmd160 \
        no-poly1305 \
        no-chacha \
        no-shared \
        no-tests \
        no-ssl3 \
        no-ssl3-method \
        no-weak-ssl-ciphers \
        no-comp \
        no-zlib \
        no-dynamic-engine \
        no-engine \
        no-dso \
        no-asm \
        no-async \
        no-filenames \
        no-docs \
        no-deprecated \
        no-apps && \
    make -j"$(nproc)" install_sw

################################################################################
# Stage 3: micro build (no SSL, no SASL, no Extstore, no Unix sockets)
################################################################################
FROM build-deps AS build-micro

# Re-export the flags so they’re in ENV here
ARG VERSION LIBEVENT_VERSION
ARG CFLAGS LDFLAGS CPPFLAGS
ENV CFLAGS="${CFLAGS}" LDFLAGS="${LDFLAGS}" CPPFLAGS="${CPPFLAGS}"

WORKDIR /build/memcached-${VERSION}

RUN patch -p0 < /patches/memcached/${VERSION}/micro.patch && \
    ./configure \
        --disable-sasl \
        --disable-extstore \
        --disable-docs \
        --disable-dtrace \
        --disable-tls && \
    make memcached -j$(nproc) && \
    objcopy --strip-unneeded memcached && \
    upx --ultra-brute memcached || true && \
    cp memcached /out/memcached

################################################################################
# Stage 4: slim build (no SSL, no SASL)
################################################################################
FROM build-deps AS build-slim

# Re-export the flags so they’re in ENV here
ARG VERSION
ARG CFLAGS LDFLAGS CPPFLAGS
ENV CFLAGS="${CFLAGS}" LDFLAGS="${LDFLAGS}" CPPFLAGS="${CPPFLAGS}"

WORKDIR /build/memcached-${VERSION}

RUN patch -p0 < /patches/memcached/${VERSION}/slim.patch && \
    ./configure \
        --with-libevent=/usr \
        --disable-sasl \
        --disable-docs \
        --disable-dtrace \
        --disable-tls && \
    make memcached -j$(nproc) && \
    objcopy --strip-unneeded memcached && \
    upx --ultra-brute memcached || true && \
    cp memcached /out/memcached

################################################################################
# Stage 5: full build (TLS, no SASL)
################################################################################
FROM build-deps AS build-tls

ARG VERSION
ARG CFLAGS LDFLAGS CPPFLAGS LIBS
ENV CFLAGS="${CFLAGS}" LDFLAGS="${LDFLAGS}" CPPFLAGS="${CPPFLAGS}"

# Memcached (only the daemon, patched for OpenSSL3)
WORKDIR /build/memcached-${VERSION}

RUN patch -p0 < /patches/memcached/${VERSION}/full.patch && \
    LIBS="-lcrypto -lssl" ./configure \
        --with-libevent=/usr \
        --disable-docs \
        --disable-dtrace \
        --enable-tls && \
    make memcached -j$(nproc) && \
    objcopy --strip-unneeded memcached && \
    cp memcached /out/

################################################################################
# Stage 6: full build (TLS + SASL)
################################################################################
FROM build-deps AS build-full

ARG VERSION SASL_VERSION
ARG CFLAGS LDFLAGS CPPFLAGS LIBS
ENV CFLAGS="${CFLAGS}" LDFLAGS="${LDFLAGS}" CPPFLAGS="${CPPFLAGS}"

# Cyrus-SASL (static only, patched headers)
WORKDIR /build/cyrus-sasl-${SASL_VERSION}
RUN LIBS="-lcrypto" ./configure \
        --with-openssl=/usr \
        --prefix=/usr \
        --sysconfdir=/etc/sasl2 \
        --with-dbpath=/etc/sasl2/sasldb2 \
        --libdir=/usr/lib \
        --enable-static \
        --enable-plain \
        --enable-cram \
        --disable-shared \
        --disable-gssapi \
        --disable-anon \
        --disable-krb4 \
        --disable-otp \
        --disable-digest \
        --disable-srp \
        --disable-srp-setpass \
        --disable-ntlm \
        --disable-checkapop \
        --disable-sql \
        --disable-ldapdb \
        --disable-alwaystrue \
        --disable-passdss && \
    make -j1 && \
    make -j1 install

# Memcached (only the daemon, patched for OpenSSL3)
WORKDIR /build/memcached-${VERSION}

RUN patch -p0 < /patches/memcached/${VERSION}/full.patch && \
    LIBS="-lcrypto -lssl" ./configure \
        --with-libevent=/usr \
        --disable-docs \
        --disable-dtrace \
        --enable-tls \
        --enable-sasl && \
    make memcached -j$(nproc) && \
    objcopy --strip-unneeded memcached && \
    cp memcached /out/

################################################################################
# Stage 7: Common final stage
################################################################################
FROM scratch AS base-final
LABEL maintainer="James Dornan <james@catch22.com>" vendor="Catch22"
COPY --from=build-deps /out/ /
USER 10000:10000
EXPOSE 11211
ENTRYPOINT ["/memcached"]

################################################################################
# Stage 7a: Micro
################################################################################
FROM base-final AS micro
COPY --from=build-micro /out/memcached /memcached

################################################################################
# Stage 7b: Slim
################################################################################
FROM base-final AS slim
COPY --from=build-slim /out/memcached /memcached

################################################################################
# Stage 7c: TLS-only
################################################################################
FROM base-final AS tls
COPY --from=build-tls /out/memcached /memcached

################################################################################
# Stage 7d: Full (TLS+SASL)
################################################################################
FROM base-final AS full
COPY --from=build-full /out/memcached /memcached
