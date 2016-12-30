+++
Categories = [
  "proxy",
  "gfw",
]
menu = "main"
Description = ""
Tags = [
  "运维",
]
date = "2016-12-27T17:07:00+08:00"
title = "我的翻墙技术栈"
+++
谈到翻墙，很多人第一时间想到的就是shdowsocks，虽然简单的搭建一个shadowsocks服务就可以实现翻墙，不过很快你就会发现代理的速度并不理想，而且有时会发生长时间无法链接的情况。


所以为了解决这种弱网络连接不稳定的情况，下面我就来详细介绍我翻墙技术栈, 如何部署[kcpun](https://github.com/xtaci/kcptun)来提升代理服务器的转发速度


<!--more-->

### 服务端

**机器**

一定要买一台国外的机器(不然翻个毛墙啊),节点推荐日本的(因为地理位置比较近)


我这里用的是[vultr](https://www.vultr.com/)的vps节点是选的日本机房,用这个[优惠码](http://www.vultr.com/?ref=7049331-3B)注册可以获取20$抵用现金，推荐


**操作系统**

red hat/centos或者debain/ubuntu 均可


这是我的操作系统版本
```bash
cat /proc/version
Linux version 3.10.0-327.28.3.el7.x86_64 (builder@kbuilder.dev.centos.org) (gcc version 4.8.3 20140911 (Red Hat 4.8.3-9) (GCC) ) #1 SMP Thu Aug 18 19:05:49 UTC 2016
```

**安装软件**

我推荐使用go版本的kcpun和shadowsocks,这样部署和维护都比较方便

```
# 下载并解压go的二进制包
wget https://storage.googleapis.com/golang/go1.7.4.linux-amd64.tar.gz
tar -xf go1.7.4.linux-amd64.tar.gz
# 把文件移到库文件夹并创建连接
mv go /usr/local/lib/
ln -s /usr/local/lib/go/bin/* /usr/local/bin/
# 增加go的第三方安装包文件并把go的环境变量加入profile
mkdir /usr/local/lib/go/packages


vim /etc/profile.d/go.sh
# 把一下内容复制进去
export GOROOT=/usr/local/lib/go
export GOPATH=$GOROOT/packages
export PATH=$GOPATH/bin:$PATH

# 加载环境变量
. /etc/profile.d/go.sh

# 安装shadowsocks和kcpun
go get github.com/xtaci/kcptun/server
go get github.com/shadowsocks/shadowsocks-go

```

**配置shadowsocks**

shadowsocks配置文件格式是json

```
vim /etc/shadowsocks.json
# 把下面的json数据复制进去
{
  "server": "0.0.0.0",
  "method": "aes-256-cfb",
  "port_password": {
    "5501": "you password"
  },
  "timeout": 300
}
```

[优化shadowsocks服务器](https://shadowsocks.org/en/config/advanced.html)


**使用supervisor管理进程**


安装supervisor(没有pip自行想办法)

    pip install supervisor


配置supervisor.conf

```
vim /etc/supervisor.conf
# 把以下内容复制进去
; supervisor config file

[unix_http_server]
file=/var/run/supervisor.sock   ; (the path to the socket file)
chmod=0700                       ; sockef file mode (default 0700)

[supervisord]
logfile=/var/log/supervisor/supervisord.log ; (main log file;default $CWD/supervisord.log)
pidfile=/var/run/supervisord.pid ; (supervisord pidfile;default supervisord.pid)
childlogdir=/var/log/supervisor            ; ('AUTO' child log dir, default $TEMP)

; the below section must remain in the config file for RPC
; (supervisorctl/web interface) to work, additional interfaces may be
; added by defining them in separate rpcinterface: sections
[rpcinterface:supervisor]
supervisor.rpcinterface_factory = supervisor.rpcinterface:make_main_rpcinterface

[supervisorctl]
serverurl=unix:///var/run/supervisor.sock ; use a unix:// URL  for a unix socket

; The [include] section can just contain the "files" setting.  This
; setting can list multiple files (separated by whitespace or
; newlines).  It can also contain wildcards.  The filenames are
; interpreted as relative to this file.  Included files *cannot*
; include files themselves.

[include]
files = /etc/supervisor.d/*.ini
```

配置kcpun和shadowsocks

```
# 如果没有创建该文件夹
mkdir /etc/supervisor.d

vim /etc/supervisor.d/proxy.ini
# 把以下内容复制进去
[program:shadowsocks]
directory=/usr/lib/go/packages/bin
command=shadowsocks-server -c /etc/shadowsocks.json
user=root
process_name=%(program_name)s
numprocs=1
autostart=true
autorestart=true
stdout_logfile=/var/log/shadowsocks.log
stdout_logfile_maxbytes=10MB
stdout_logfile_backups=2
redirect_stderr=true

[program:kcpun]
directory=/usr/lib/go/packages/bin
command=server -t "127.0.0.1:5501" -l ":5501" -mode fast2 --crypt aes-128
user=root
process_name=%(program_name)s
numprocs=1
autostart=true
autorestart=true
stdout_logfile=/var/log/kcpun.log
stdout_logfile_maxbytes=10MB
stdout_logfile_backups=2
redirect_stderr=true
```

启动supervisor

    supervisord -c /etc/supervisor.conf


**iptables的filter表配置**

如果你的服务器有配iptables，那可能要增加一下规则

    iptables -I INPUT -p udp -m udp --dport 5501 -j ACCEPT

把新的配置加入开机启动

```
iptables-save > /etc/iptables.rule

vim /etc/rc.local
# 在新的一行中添加以下内容
/sbin/iptables-restore < /etc/iptables.rule

```

### 客户端配置

**kcpun客户端**

在https://github.com/xtaci/kcptun/releases/tag/v20161222 中下载对应的版本


启动客户端

    client_darwin_amd64 -r "服务器IP地址:5501" -l ":8388" -mode fast2 --crypt aes-128


**shadowsocks客户端**

windows的[下载页面](https://github.com/shadowsocks/shadowsocks-windows/releases)


Mac OS X的[下载页面](https://github.com/shadowsocks/ShadowsocksX-NG/releases)


linux桌面版本的[下载页面](https://github.com/shadowsocks/shadowsocks-qt5/wiki/Installation)


> 编辑config.json,把以下内容复制进去保存,并把这个文件导入shadowsocks

```json
{
    "configs": [
        {
            "method": "aes-256-cfb",
            "password": "your password",
            "remarks": "public_vultr",
            "server": "127.0.0.1",
            "server_port": 8388
        }
    ],
    "localPort": 1080,
    "shareOverLan": false
}
```

**使用SwitchyOmega为chrome代理**

在chrome商店或者[这里](https://github.com/FelisCatus/SwitchyOmega/releases)下载SwitchyOmega


下载的插件拖入chorme即可安装


在下载SwitchyOmega设置中增加一个pac profile,并在pac script中加入以下内容

```javascript
var domains = [
    "google.com",
    "facebook.com",
    "twitter.com",
    "google.co.jp",
    "gmail.com",
    "golang.org",
    "github.com",
    "s3.amazonaws.com",
    "twimg.com",
    "wikipedia.org",
    "youtube.com",
    "gstatic.com",
    "stackoverflow.com",
    "shadowsocks.org"

];
var domain_dict = {};
for(var i = 0; i < domains.length; i++){
    if(domains[i].endsWith(".")){
        domains[i] = domains[i].slice(0, -1)
    }
    var url_list = domains[i].split('.');

    var domain_node = domain_dict;
    for(var j = url_list.length; j > 0; j--){
        var node_name = url_list[j-1];
        if (!domain_node.hasOwnProperty(node_name)){
            if (j === 1){
                domain_node[node_name] = true;
                break;
            } else {
                domain_node[node_name] = {};
            }
        } else if(domain_node[node_name] === true) {
            break;
        }
        domain_node = domain_node[node_name];
    }
}

var proxy = "SOCKS5 127.0.0.1:1080; SOCKS 127.0.0.1:1080; DIRECT";

var direct = 'DIRECT;';

function FindProxyForURL(url, host) {
    if( host == "localhost" ||
        host == "127.0.0.1") {
        return direct;
    }
    var host_list = host.split('.')
    var domain_node = domain_dict
    for(var i = host_list.length; i > 0; i--){
        var node_name = host_list[i-1]
        if (domain_node.hasOwnProperty(node_name)){
            if(domain_node[node_name] === true){
                return proxy;
            } else {
                domain_node = domain_node[node_name]
            }

        }
        else {
            return direct;
        }
    }
    return direct;
}
```

pac用的是javascript语法，需要代理的域名只要加入domains即可


父域名会自动匹配所有子域名,比如domains中加入google.com 那www.google.com map.google.com的内容都会被代理


关于这份pac的更多内容可以看[这里](/post/switchy-proxy-pac-optimization)
