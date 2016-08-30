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
RUN wget https://nginx.org/download/nginx-1.10.1.tar.gz
RUN wget http://ftp.openbsd.org/pub/OpenBSD/LibreSSL/libressl-2.4.1.tar.gz

RUN tar -xf nginx-1.10.1.tar.gz && tar -xf libressl-2.4.1.tar.gz
WORKDIR /root/nginx-1.10.1
RUN ./configure \
    --prefix=/usr/local/nginx \
    --sbin-path=/usr/sbin/nginx \
    --conf-path=/etc/nginx/nginx.conf \
    --pid-path=/var/run/nginx.pid \
    --error-log-path=/var/log/nginx/error.log \
    --http-log-path=/var/log/nginx/access.log \
    --with-openssl=../libressl-2.4.1 \
    --with-http_v2_module \
    --with-http_ssl_module \
    --with-http_realip_module \
    --with-http_stub_status_module \
    --with-threads
RUN make && make install

RUN ln -sf /dev/stdout /var/log/nginx/access.log \
	&& ln -sf /dev/stderr /var/log/nginx/error.log
#*********************************

ENV DOLLAR='$'
RUN mkdir -p /etc/nginx/temp /var/www/html
ADD nginx.conf /etc/nginx/nginx.conf
