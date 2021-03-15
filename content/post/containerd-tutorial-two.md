---
title: "使用CNI为Containerd创建网络接口"
date: 2021-03-09T11:03:10+08:00
lastmod: 2021-03-09T11:03:10+08:00
tags : [ "go", "containerd", "k8s"]
categories : [ "go", "containerd", "k8s" ]
layout: post
type:  "post"
highlight: false
draft: false
---

上一篇讲到如何创建一个`redis-server`的容器服务，但该服务现在没有网络接口，所以我们在外面还没法访问这个服务，今天就来讲下如何通过CNI创建网络接口来访问Containerd服务

### CNI是什么

CNI(Container Network Interface) 是一套容器网络接口规范，通过插件的形式支持各种各样的网络类型，而标准化的好处就是你只需一套标准json配置就可以为一个容器创建网络接口

<!--more-->

### 创建一个网络接口

我们先试试手动创建CNI接口

##### 安装cni相关库和工具

我们先试试手动创建CNI接口，在创建之前确保你的cnitool和cni相关插件已经安装完成

- 安装cnitool

    go get github.com/containernetworking/cni/cnitool

- 安装cni插件

    git clone https://github.com/containernetworking/plugins.git
    cd plugins
    ./build_linux.sh
    mkdir -p /opt/cni/bin/
    cp bin/* /opt/cni/bin/

##### 为`redis-server`创建一个网络接口

我们需要为redis-server创建一个loop接口和一个10网段的私有接口，先将以下2个配置文件放到`/etc/cni/net.d/`下

- 10-mynet/conf 

```
  {
    "cniVersion": "0.2.0",
    "name": "mynet",
    "type": "bridge",
    "bridge": "cni0",
    "isGateway": true,
    "ipMasq": true,
    "ipam": {
      "type": "host-local",
      "subnet": "10.22.0.0/16",
      "routes": [
        { "dst": "0.0.0.0/0" }
      ]
    }
  }
```

- 99-loopback.conf 

```
{
  "cniVersion": "0.2.0",
  "name": "lo",
  "type": "loopback"
}
```

查看redis-server的pid

    ctr -n example tasks ls 
    # Output
    TASK            PID      STATUS    
    redis-server    10194    RUNNING

使用cnitool为`redis-server`创建一个网络接口

    CNI_PATH=/opt/cni/bin cnitool add mynet /proc/10194/ns/net
    CNI_PATH=/opt/cni/bin cnitool add lo /proc/10194/ns/net


查看`redis-server`网络接口, 会看到多出一个eth0的接口

    ctr -n example tasks exec --exec-id ifconfig redis-server ifconfig 
    # Output
    eth0  Link encap:Ethernet  HWaddr 7E:FF:AB:35:EE:8D  
          inet addr:10.22.0.3  Bcast:10.22.255.255  Mask:255.255.0.0
          inet6 addr: fe80::7cff:abff:fe35:ee8d/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:24 errors:0 dropped:0 overruns:0 frame:0
          TX packets:13 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0 
          RX bytes:3087 (3.0 KiB)  TX bytes:978 (978.0 B)

    lo    Link encap:Local Loopback  
          inet addr:127.0.0.1  Mask:255.0.0.0
          inet6 addr: ::1/128 Scope:Host
          UP LOOPBACK RUNNING  MTU:65536  Metric:1
          RX packets:0 errors:0 dropped:0 overruns:0 frame:0
          TX packets:0 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1000 
          RX bytes:0 (0.0 B)  TX bytes:0 (0.0 B)




查看`ip addr`，多了一个接口

    ip addr
    ...
    5: cni0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
        link/ether 22:24:c9:80:ca:80 brd ff:ff:ff:ff:ff:ff
        inet 10.22.0.1/16 brd 10.22.255.255 scope global cni0
          valid_lft forever preferred_lft forever
        inet6 fe80::2024:c9ff:fe80:ca80/64 scope link 
          valid_lft forever preferred_lft forever
    9: veth09a4c20e@if3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue master cni0 state UP group default 
        link/ether b2:e2:d4:b2:02:48 brd ff:ff:ff:ff:ff:ff link-netnsid 0
        inet6 fe80::b0e2:d4ff:feb2:248/64 scope link 
          valid_lft forever preferred_lft forever

查看路由表，多了一条记录
  ip route 
  ...
  10.22.0.0/16 dev cni0 proto kernel scope link src 10.22.0.1



查看iptables nat表多了如下规则

    iptables-save -t nat 
    ...
    -A POSTROUTING -s 10.22.0.4/32 -m comment --comment "name: \"mynet\" id: \"cnitool-8eb4ab2843a897d479f0\"" -j CNI-e32151e9f33a1b2b00f01cf5
    ...
    -A CNI-e32151e9f33a1b2b00f01cf5 -d 10.22.0.0/16 -m comment --comment "name: \"mynet\" id: \"cnitool-8eb4ab2843a897d479f0\"" -j ACCEPT
    -A CNI-e32151e9f33a1b2b00f01cf5 ! -d 224.0.0.0/4 -m comment --comment "name: \"mynet\" id: \"cnitool-8eb4ab2843a897d479f0\"" -j MASQUERADE


在该机器访问`redis-server`服务

    telnet 10.22.0.3 6379
    # Output
    Trying 10.22.0.3...
    Connected to 10.22.0.3.
    Escape character is '^]'

也可以在在redis-server服务中访问外网，域名相关配置没配，只能通过ip访问服务

    ctr -n example task exec -t --exec-id wget redis-server sh
    wget http://192.168.0.1/


