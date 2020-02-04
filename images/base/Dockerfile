FROM --platform=$BUILDPLATFORM alpine:3.11 as builder

COPY . /

RUN apk add -U bash \
  && /build.sh

# Use a multi-stage build
FROM --platform=$BUILDPLATFORM alpine:3.11

COPY --from=builder /usr/local /usr/local
COPY --from=builder /opt /opt

RUN apk add -U --no-cache \
    bash \
    openssl \
    pcre \
    zlib \
    geoip \
    curl ca-certificates \
    patch \
    yajl \
    lmdb \
    libxml2 \
    libmaxminddb \
    yaml-cpp \
    nano \
    tzdata

ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/modsecurity/lib/