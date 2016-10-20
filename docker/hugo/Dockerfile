FROM debian:jessie

RUN apt-get -y update  && \
    apt-get -y install wget tar && \
rm -rf /var/lib/apt/lists/*

WORKDIR /root/
RUN wget https://storage.googleapis.com/golang/go1.7.3.linux-amd64.tar.gz && \
    tar -xf go1.7.3.linux-amd64.tar.gz /usr/lib/go && \
    rm go1.7.3.linux-amd64.tar.gz

RUN mkdir /usr/lib/go/packages
ENV GOROOT=/usr/lib/go
ENV GOPATH=/usr/lib/go/packages
RUN ln -s /usr/lib/go/bin/* /usr/bin/

RUN go get -v github.com/spf13/hugo
RUN mkdir /var/www
   
