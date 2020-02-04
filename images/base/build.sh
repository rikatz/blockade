#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

export DEBIAN_FRONTEND=noninteractive

export MODSECURITY_LIB_VERSION=6624a18a4e7fd9881a7a9b435db3e481e8e986a5
export OWASP_MODSECURITY_CRS_VERSION=3.2.0
export LUAJIT_VERSION=38cb695de87cfeadcba5eeaf57f39e41d529aa1f

export BUILD_PATH=/tmp/build

ARCH=$(uname -m)

get_src()
{
  hash="$1"
  url="$2"
  f=$(basename "$url")

  echo "Downloading $url"

  curl -sSL "$url" -o "$f"
  echo "$hash  $f" | sha256sum -c - || exit 10
  tar xzf "$f"
  rm -rf "$f"
}

apk update
apk upgrade

# install required packages to build
apk add \
  bash \
  gcc \
  clang \
  libc-dev \
  make \
  automake \
  openssl-dev \
  pcre-dev \
  zlib-dev \
  linux-headers \
  libxslt-dev \
  gd-dev \
  geoip-dev \
  perl-dev \
  libedit-dev \
  mercurial \
  alpine-sdk \
  findutils \
  curl ca-certificates \
  geoip-dev \
  patch \
  libaio-dev \
  openssl \
  cmake \
  util-linux \
  lmdb-tools \
  wget \
  curl-dev \
  git g++ pkgconf flex bison doxygen yajl-dev lmdb-dev libtool autoconf libxml2 pcre-dev libxml2-dev \
  python \
  libmaxminddb-dev \
  bc \
  unzip \
  dos2unix mercurial \
  yaml-cpp

mkdir --verbose -p "$BUILD_PATH"
cd "$BUILD_PATH"

get_src 7df70318762f4150e6fe27dd1838b4b89a24ed9351c82d0b332d7d8457dd1b95 \
        "https://github.com/openresty/luajit2/archive/$LUAJIT_VERSION.tar.gz"

# improve compilation times
CORES=$(($(grep -c ^processor /proc/cpuinfo) - 0))

export MAKEFLAGS=-j${CORES}
export CTEST_BUILD_FLAGS=${MAKEFLAGS}
export HUNTER_JOBS_NUMBER=${CORES}
export HUNTER_USE_CACHE_SERVERS=true

# Install luajit from openresty fork
export LUAJIT_LIB=/usr/local/lib
export LUA_LIB_DIR="$LUAJIT_LIB/lua"
export LUAJIT_INC=/usr/local/include/luajit-2.1

cd "$BUILD_PATH/luajit2-$LUAJIT_VERSION"
make CCDEBUG=-g
make install

cd "$BUILD_PATH"
git clone https://github.com/ssdeep-project/ssdeep
cd ssdeep/

./bootstrap
./configure

make
make install

# build modsecurity library
cd "$BUILD_PATH"
git clone https://github.com/SpiderLabs/ModSecurity
cd ModSecurity/
git checkout $MODSECURITY_LIB_VERSION
git submodule init
git submodule update

sh build.sh

./configure \
  --disable-doxygen-doc \
  --disable-doxygen-html \
  --disable-examples

make
make install

rm -rf /usr/local/modsecurity/lib/libmodsecurity.a
