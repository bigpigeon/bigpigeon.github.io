+++
Categories = [
  "Operation",
  "Jekyll",
]
menu = "main"
Description = ""
Tags = [
  "运维",
]
date = "2016-02-06T14:06:00+08:00"
title = "使用docker部署jekyll"
+++

关于在docker部署jekyll在[The.Docker.Book](http://books.linuxfocus.net/files/books/James.Turnbull.The.Docker.Book.Containerization.is.the.new.virtualization.B00LRROTI4.pdf)中也有详细说明，但主要是自从jekyll升级到需要ruby2.0+版本后就没那么容易了


所以我在这记录一下部署过程以免将来再次踩坑

<!--more-->
### 首先，为什么要用docker

> docker提供了基于操作系统的虚拟化技术，可以让你很方便的把应用的环境独立出来并且可以重用

> 并且 docker提供了一套完善的工具去管理docker推出的进程

> 所以 docker相当于是supervisor + 容器的组合

### 编辑jekyll的Dockerfile和nginx的Dockerfile ###

---

#### jekyll的目录结构

```
|-base
    |-Dockerfile
|-create
    |-Dockerfile
|-push
    |-Dockerfile
    |-Rakefile
    |-key
       |-id_rsa
       |-id_rsa.pub
```

#### jekyll base目录下的Dockerfile
``` bash
FROM ubuntu:latest
MAINTAINER bigpigeon0 <bigpigeon0@gmail.com>
ENV REFRESHED_AT 2016-02-13

RUN apt-get -yqq update
RUN apt-get -yqq install ruby2.0 ruby2.0-dev ruby-dev make nodejs git

RUN for i in {1..100};\
      do \
        gem2.0 install --source=http://rubygems.org jekyll;\
        if [ "$?" -eq 0 ];\
          then break;\
        fi;\
      done;
RUN gem2.0 install redcarpet
RUN gem2.0 install --source=http://rubygems.org rake
RUN gem2.0 install bundler
```

- apt-get 增加了 ruby-dev(ruby某些库需要用到ruby-dev)

- gem2.0 使用源是http的rubugems.org(某些下载文件过大使用https会出现connection reset)

- 耐性等待jekyll的安装非常非常慢可能需要1个小时，而且没提示(想要提示可以用Bundler(gem install bundler)，但不知道为何bundler经常装到一半失败，并且缓存失败。。。)

- 总的来说就是ruby坑爹，gem更坑爹

- rake的作用是把jekyll生成的网页推到github的master分支上，因为github上的jekyll不支持插件，所以只能本地生产完推上去

---

#### jekyll create目录下的Dockerfile

``` bash
FROM bigpigeon0/jekyll:latest
MAINTAINER bigpigeon0 <bigpigeon0@gmail.com>

VOLUME ["/data", "/var/www/html"]
WORKDIR /data

ENTRYPOINT [ "jekyll", "build", "--destination=/var/www/html" ]
```

---

#### jekyll push目录下的Dockerfile

``` bash
FROM bigpigeon0/jekyll:latest
MAINTAINER bigpigeon0 <bigpigeon0@gmail.com>

RUN mkdir -p /data/rakedata /data/blog
RUN git config --global user.email bigpigeon0@gmail.com
RUN git config --global user.name bigpigeon

ADD Rakefile /data/rakedata/
COPY key/    /root/.ssh/

WORKDIR /data/rakedata

ENTRYPOINT ["rake", "publish"]
```

---

#### jekyll push目录下的Rakefile

``` ruby
require "rubygems"
require "tmpdir"

require "bundler/setup"
require "jekyll"


# Change your GitHub reponame
GITHUB_REPONAME = "bigpigeon/bigpigeon.github.io"


desc "Generate blog files"
task :generate do
  Jekyll::Site.new(Jekyll.configuration({
    "source"      => "../blog/.",
    "destination" => "_site"
  })).process
end


desc "Generate and publish blog to master"
task :publish => [:generate] do
  Dir.mktmpdir do |tmp|
    cp_r "_site/.", tmp

    pwd = Dir.pwd
    Dir.chdir tmp

    system "git init"
    system "git add ."
    message = "Site updated at #{Time.now.utc}"
    system "git commit -m #{message.inspect}"
    system "git remote add origin git@github.com:#{GITHUB_REPONAME}.git"
    system "git push origin master --force"

    Dir.chdir pwd
  end
end
```

---

#### nginx image的目录结构

```
|-Dockerfile
|-nginx
    |-static.conf
    |-nginx.conf
```

---

#### nginx image的Dockerfile

``` bash
FROM ubuntu:latest
MAINTAINER bigpigeon <bigpigeon0@gmail.com>

ENV REFRESHED_AT 2016-02-06

RUN apt-get -yqq update
RUN apt-get install -yqq nginx
RUN mkdir -p /var/www/html

ADD nginx/nginx.conf /etc/nginx/nginx.conf
ADD nginx/static.conf /etc/nginx/conf.d/static.conf

VOLUME ["/var/www/html"]
WORKDIR /var/www/html

EXPOSE 80

ENTRYPOINT ["nginx"]
```

---

#### nginx.conf

``` nginx
user www-data;
worker_processes 4;
pid /run/nginx.pid;
daemon off;
events { }
http {
  sendfile on;
  tcp_nopush on;
  tcp_nodelay on;
  keepalive_timeout 65;
  types_hash_max_size 2048;
  include /etc/nginx/mime.types;
  default_type application/octet-stream;
  access_log /var/log/nginx/access.log;
  error_log /var/log/nginx/error.log;
  gzip on;
  gzip_disable "msie6";
  include /etc/nginx/conf.d/*.conf;
}
```

---

#### static.conf

``` nginx
server {
  listen 0.0.0.0:80;
  server_name _;
  root /var/www/html/;
  index index.html index.htm;
  access_log /var/log/nginx/default_access.log;
  error_log /var/log/nginx/default_error.log;
}
```

docker的image就build好了，这里简单讲讲Dockerfile的语法


FROM: Dockerfile的第一行必须是FROM，表示基于那个基础Docker image


ENV: 设置环境变量


MAINTAINER: 告诉docker该image的作者和他的邮箱地址，也是很有必要的


RUN: 用shell执行一条命令，可以写成RUN xxx ... 或者RUN ["xxx", ...]


CMD: 执行一条命令，当image被运行(推出)时，用法和RUN相识


ENTRYPOINT: 执行一条命令，当image被运行(推出)时，并且可以在运行时对该命令附加参数


WORKDIR: 设置工作目录，相当于bash下的cd dir


USER: 设置在docker build下执行命令的用户


VOLUME: 方便容器之间挂载目录，可以在image被运行时配合--volumes-from使用


ADD: 把文件复制到image中，第一参数可填写网址，但不可访问当前目录以外的路径


COPY: 把文件夹复制到image中


ONBUILD: 在该image作为FROM基本容器再次build时执行

---

### build nginx和jekyll的image


``` bash
# build jekyll base image
cd Dockerfile存放目录
sudo docker build -t bigpigeon0/jekyll .

# build jekyll create image
cd Dockerfile存放目录
sudo docker build -t bigpigeon0/blog_create .

# build jekyll create image
cd Dockerfile存放目录
sudo docker build -t bigpigeon0/blog_push .

# build nginx image
cd Dockerfile存放目录
sudo docker build -t bigpigeon0/nginx .
```

---

### 运行Docker

``` bash
# 把jekyll的模板下载下来
mkdir -p /data/work/ && cd /data/work/
git clone https://github.com/bigpigeon/bigpigeon.github.io

# 运行一个博客生成的镜像
sudo docker run  -v /data/work/bigpigeon.github.io:/data --name blog_create bigpigeon0/blog_create

# 运行nginx的镜像
sudo docker run -p 8080:80 -d --name nginx --volumes-from blog_create bigpigeon0/nginx

# 生成博客提交到github
# 记得把key/id_rsa.pub中的内容添加到github.com/settings/ssh中
sudo docker run -t -i -v /data/work/bigpigeon.github.io:/data/blog --name blog_push bigpigeon0/blog_push

# 更新模板后重新生成网页和提交网页
docker start blog_create
docker start -a blog_push
```


### 测试网站

> 在浏览器输入http://serveraddr:8080 查看博客

---

**The.Docker.Book有[中文版](http://www.amazon.cn/%E7%AC%AC%E4%B8%80%E6%9C%ACDocker%E4%B9%A6-%E8%A9%B9%E5%A7%86%E6%96%AF%C2%B7%E7%89%B9%E6%81%A9%E5%B8%83%E5%B0%94/dp/B00RBEIFMI/)，然而我觉得价格太坑爹，还是不推荐大家买(电子书比实体书还贵)**
