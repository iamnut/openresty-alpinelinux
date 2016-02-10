#!/bin/ash

OPENRESTY_VERSION=1.9.7.3
LUAROCKS_VERSION=2.3.0

OPENRESTY_PREFIX=/opt/openresty
NGINX_PREFIX=${OPENRESTY_PREFIX}/nginx
NGINX_CONF=${NGINX_PREFIX}/conf/nginx.conf

LUAJIT_PREFIX=${OPENRESTY_PREFIX}/luajit

PATH="${NGINX_PREFIX}/sbin:${LUAJIT_PREFIX}/bin:${OPENRESTY_PREFIX}/bin:${PATH}"

# build tools
apk update && apk add \
  git \
  curl \
  gcc \
  make \
  perl \
  musl-dev \
  openssl \
  openssl-dev \
  zlib-dev \
  pcre-dev

# openresty
curl -sSL "https://openresty.org/download/openresty-${OPENRESTY_VERSION}.tar.gz" | tar zx
cd openresty-* \
  && ./configure \
    --prefix=${OPENRESTY_PREFIX} \
    --with-pcre-jit \
    --with-http_realip_module \
  && make && make install \
  && cd .. && rm -rf openresty-*

apk add libgcc libssl1.0 pcre

ln -sf ${LUAJIT_PREFIX}/bin/luajit /usr/local/bin/lua

# luarocks
curl -sSL "http://keplerproject.github.io/luarocks/releases/luarocks-${LUAROCKS_VERSION}.tar.gz" | tar zx
cd luarocks-* \
  && ./configure \
    --prefix=${LUAJIT_PREFIX} \
    --with-lua=${LUAJIT_PREFIX} \
    --with-lua-include=${LUAJIT_PREFIX}/include/luajit-2.1 \
    --lua-suffix=jit \
  && make && make install \
  && cd .. && rm -rf luarocks-*

${LUAJIT_PREFIX}/bin/luarocks install stringy

# config
adduser -s /sbin/nologin -h /var/www -D openresty

sed -i "s/#pid/pid/g" ${NGINX_CONF}
sed -i "s/logs\/nginx.pid/\/var/run\/openresty\/openresty.pid/g" ${NGINX_CONF}

sed -i "s/#user/user/g" ${NGINX_CONF}
sed -i "s/nobody/openresty/g" ${NGINX_CONF}

cp openresty.openrc /etc/init.d/openresty
chmod +x /etc/init.d/openresty

rc-update add openresty
rc-service openresty start

# cleanup
#apk del \
#  git \
#  curl \
#  gcc \
#  make \
#  musl-dev \
#  openssl-dev \
#  zlib-dev \
#  pcre-dev

#rm -rf /var/cache/apk/*