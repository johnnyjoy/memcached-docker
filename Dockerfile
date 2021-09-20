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
	MC_TREADS=4 \
	MC_TLS=true \
	MC_PORT=11211

ARG VERSION="1.6.10"
ARG CHECKSUM="ef46ac33c55d3a0f1c5ae8eb654677d84669913997db5d0c422c5eaffd694a92"

ARG OPENSSL_VERSION="1.1.1k"
ARG OPENSSL_CHECKSUM="892a0875b9872acd04a9fde79b1f943075d5ea162415de3047c327df33fbaee5"

ARG LIBEVENT_VERSION="2.1.12-stable"
ARG LIBEVENT_CHECKSUM="92e6de1be9ec176428fd2367677e61ceffc2ee1cb119035037a27d346b0403bb"

ADD https://www.memcached.org/files/memcached-$VERSION.tar.gz /tmp/memcached.tar.gz
ADD https://www.openssl.org/source/openssl-$OPENSSL_VERSION.tar.gz /tmp/openssl.tar.gz
ADD https://github.com/libevent/libevent/releases/download/release-$LIBEVENT_VERSION/libevent-$LIBEVENT_VERSION.tar.gz /tmp/libevent.tar.gz

RUN \
	[ "$(sha256sum /tmp/openssl.tar.gz | cut -f1 -d' ')" = "$OPENSSL_CHECKSUM" ] \
	&& \
	[ "$(sha256sum /tmp/libevent.tar.gz | cut -f1 -d' ')" = "$LIBEVENT_CHECKSUM" ] \
	&& \
	[ "$(sha256sum /tmp/memcached.tar.gz | cut -f1 -d' ')" = "$CHECKSUM" ] \
	&& \
	apk update \
	&& \
	apk add gcc linux-headers make musl-dev perl patch \
	&& \
	tar -C /tmp -xf /tmp/openssl.tar.gz \
	&& \
	tar -C /tmp -xf /tmp/libevent.tar.gz \
	&& \
	tar -C /tmp -xf /tmp/memcached.tar.gz

RUN \
	cd /tmp/openssl-$OPENSSL_VERSION \
	&& \
	./config no-shared \
	&& \
	make -j $(nproc) \
	&& \
	make install_sw

RUN \
	cd /tmp/libevent-$LIBEVENT_VERSION \
	&& \
	./configure \
	&& \
	make -j $(nproc) \
	&& \
	make install

COPY memcached-container-1.6.10.patch /tmp/

RUN \
	cd /tmp/memcached-$VERSION \
	&& \
	patch -p0 < /tmp/memcached-container-$VERSION.patch \
	&& \
	./configure --enable-tls --enable-threads --enable-static \
	&& \
	make LDFLAGS="-static" -j $(nproc)

RUN \
	mkdir -p /rootfs/etc \
	&& \
	cd /rootfs \
	&& \
	cp /tmp/memcached-$VERSION/memcached /tmp/memcached-$VERSION/LICENSE ./ \
	&& \
	strip memcached \
	&& \
	echo "nogroup:*:10000:nobody" > etc/group \
	&& \
	echo "nobody:*:10000:10000:::" > etc/passwd

FROM scratch

COPY --from=build --chown=10000:10000 /rootfs /

USER 10000:10000

EXPOSE 11211/tcp

ENTRYPOINT ["/memcached"]
