FROM debian:jessie


#********* build nginx ***********
RUN apt-get -y update  && \
    apt-get -y install wget sed tar make && \
    apt-get -y install gcc g++ && \
    apt-get -y install libpcre3-dev and libpcre++-dev && \
    apt-get -y install zlib1g-dev && \
    apt-get -y install gettext-base && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /root/

ENV NGINX_VERSION=nginx-1.12.0
ENV SSL_VERSION=libressl-2.5.3
RUN wget https://nginx.org/download/$NGINX_VERSION.tar.gz -o /dev/null && tar -xf $NGINX_VERSION.tar.gz && \
    wget http://ftp.openbsd.org/pub/OpenBSD/LibreSSL/$SSL_VERSION.tar.gz -o /dev/null && tar -xf $SSL_VERSION.tar.gz && \
    cd /root/$NGINX_VERSION && \
    ./configure \
    --prefix=/usr/local/nginx \
    --sbin-path=/usr/sbin/nginx \
    --conf-path=/etc/nginx/nginx.conf \
    --pid-path=/var/run/nginx.pid \
    --error-log-path=/var/log/nginx/error.log \
    --http-log-path=/var/log/nginx/access.log \
    --with-openssl=../$SSL_VERSION \
    --with-http_v2_module \
    --with-http_ssl_module \
    --with-http_realip_module \
    --with-http_stub_status_module \
    --with-threads && \
    make && make install && \
    cd /root && rm -rf *

RUN ln -sf /dev/stdout /var/log/nginx/access.log \
	&& ln -sf /dev/stderr /var/log/nginx/error.log
#*********************************

ENV DOLLAR='$'
RUN mkdir -p /etc/nginx/temp /var/www/html /etc/nginx/conf.d
ADD nginx.conf /etc/nginx/nginx.conf
