# syntax=docker/dockerfile:1
FROM alpine:edge AS build

MAINTAINER "James Dornan <james@catch22.com>"

LABEL \
	vendor="James Dornan" \
	author="James Dornan <james@catch22.com>" \
	maintainer="James Dornan <james@catch22.com>" \
	maintainer.org="Catch22" \
	maintainer.org.uri="https://www.catch22.com" \
	com.catch22.project.repo.type="git" \
	com.catch22.project.repo.uri="https://notabug.org/jjb/memcached" \
	com.catch22.project.repo.issues="https://notabug.org/jjb/memcached/issues" \
	com.catch22.app.memcached.version="1.6.10"

ENV \
	MC_MAX=64 \
	MC_CONNECTIONS=1024 \
	MC_TREADS=4

ARG VERSION="1.6.10"
ARG CHECKSUM="ef46ac33c55d3a0f1c5ae8eb654677d84669913997db5d0c422c5eaffd694a92"

ARG OPENSSL_VERSION="1.1.1k"
ARG OPENSSL_CHECKSUM="892a0875b9872acd04a9fde79b1f943075d5ea162415de3047c327df33fbaee5"

ARG LIBEVENT_VERSION="2.1.12-stable"
ARG LIBEVENT_CHECKSUM="92e6de1be9ec176428fd2367677e61ceffc2ee1cb119035037a27d346b0403bb"

ARG SASL_VERSION="2.1.27"
ARG SASL_CHECKSUM="26866b1549b00ffd020f188a43c258017fa1c382b3ddadd8201536f72efb05d5"

ARG ENABLETLS="false"

RUN \
	wget -S -O /tmp/memcached.tar.gz \
		https://www.memcached.org/files/memcached-$VERSION.tar.gz \
	&& \
	wget -S -O /tmp/openssl.tar.gz \
		https://www.openssl.org/source/openssl-$OPENSSL_VERSION.tar.gz \
	&& \
	wget -S -O /tmp/sasl.tar.gz \
		https://github.com/cyrusimap/cyrus-sasl/releases/download/cyrus-sasl-$SASL_VERSION/cyrus-sasl-$SASL_VERSION.tar.gz \
	&& \
	wget -S -O /tmp/libevent.tar.gz \
		https://github.com/libevent/libevent/releases/download/release-$LIBEVENT_VERSION/libevent-$LIBEVENT_VERSION.tar.gz

RUN \
	[ "$(sha256sum < /tmp/openssl.tar.gz)" = "$OPENSSL_CHECKSUM  -" ] \
	&& \
	[ "$(sha256sum < /tmp/libevent.tar.gz)" = "$LIBEVENT_CHECKSUM  -" ] \
	&& \
	[ "$(sha256sum < /tmp/sasl.tar.gz)" = "$SASL_CHECKSUM  -" ] \
	&& \
	[ "$(sha256sum < /tmp/memcached.tar.gz)" = "$CHECKSUM  -" ] \
	&& \
	apk update \
	&& \
	apk add gcc linux-headers make musl-dev perl patch \
	&& \
	tar -C /tmp -xf /tmp/openssl.tar.gz \
	&& \
	tar -C /tmp -xf /tmp/libevent.tar.gz \
	&& \
	tar -C /tmp -xf /tmp/sasl.tar.gz \
	&& \
	tar -C /tmp -xf /tmp/memcached.tar.gz

WORKDIR /tmp/openssl-$OPENSSL_VERSION

RUN \
	./config no-shared \
	&& \
	make -j $(nproc) \
	&& \
	make install_sw

WORKDIR /tmp/libevent-$LIBEVENT_VERSION

RUN \
	./configure \
	&& \
	make -j $(nproc) \
	&& \
	make install

WORKDIR /tmp/cyrus-sasl-$SASL_VERSION

RUN \
	./configure --without-openssl --disable-digest --enable-static --disable-shared --prefix=/usr  --enable-auth-sasldb --sysconfdir=/etc \
	&& \
	make -j $(nproc) \
	&& \
	make install

COPY memcached-container-1.6.10.patch /tmp/

WORKDIR /tmp/memcached-$VERSION

RUN \
	patch -p0 < /tmp/memcached-container-$VERSION.patch \
	&& \
	if [ $ENABLETLS  = "true" ]; then \
	  ./configure --with-libevent --enable-tls --enable-sasl --enable-sasl-pwdb; \
	else \
	  ./configure --with-libevent; \
	fi \
	&& \
	make LDFLAGS="-static" -j $(nproc)

RUN \
	mkdir -p /rootfs/etc \
	&& \
	cp memcached COPYING LICENSE.bipbuffer /rootfs/ \
	&& \
	strip /rootfs/memcached \
	&& \
	echo "nogroup:*:10000:nobody" > /rootfs/etc/group \
	&& \
	echo "nobody:*:10000:10000:::" > /rootfs/etc/passwd

FROM scratch

COPY --from=build --chown=10000:10000 /rootfs /

USER 10000:10000

EXPOSE 11211/tcp

ENTRYPOINT ["/memcached"]
