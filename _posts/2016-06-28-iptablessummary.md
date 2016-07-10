---
layout: post
title:  "iptables的各种玩法"
date:   2016-06-28 16:00:00
categories: 笔记 
excerpt: iptables的用途归纳
---
以前我也很抵触去配置iptables，当时我觉得iptables这种工具实在是太复杂了，配置的命令超级长，而且只有命令行没有图形化工具，而大多数云服务器都有自己的一套防火墙，比如aws的EC2就有自己的安全组，简单易用并且可以直接在网页上直接配置，非常的方便。

---

但后来我接触linux运维越来越多才发现，iptables虽然缺点一大堆，但它胜在功能非常强大，并且可以满足大多数网络管理上的需求，在没有更好的代替品出现前iptables绝对是必不可少的工具。


下面我就简单总结一下iptables的用途


### 什么是iptables

一提到iptables大部分人想到的估计就是防火墙，但其实防火墙只是iptables的filter表部分,iptables本身还可以做NAT（NAT表）和mangle（mangle表）

### 为什么需要iptables

iptables可以翻译成ip表，可以理解为对ip做一些处理的工具，因为iptables的这些模块，所以这个问题应该为：


    为什么需要
      filter
      nat
      mangle
      raw
      security


    filter很好理解，因为要防止外网非法访问

    SNAT在局域网访问外网的必要工具，而DNAT则是为了把局域网的服务接出去，比如如何让docker的服务端口暴露到本机上

    而mangle,raw,secrurity因为我没有接触过，所以不予评价

### 如何查看配置项

查看iptables的配置可以用iptables-save [-t table]来查看完整的配置


有人说可以直接用**iptables -L**查看，但不建议这样做，因为**iptables -L**为了格式化输出会忽略掉一些信息比如filter表中的接口信息就无法查看。


### 如何配置表

### filter

filter是iptables中最常用的表,而filter默认有3个链

```bash
INPUT: 进入linux本机时过滤
OUTPUT: 本机送出时过滤
FORWARD: 这个是访问本机转换的封包时过滤，比如你在本机配置了DNAT或者SNAT，那些被转换后并且目的地不在本地的包不会被INPUT/OUTPUT过滤器过滤，而是就由这个规则过滤
```

其中最常用的就是INPUT 链，这里我用INPUT 的链做说明

```bash
iptables -A INPUT -i eth0 -d 50.24.131.30/32 -p tcp --dport 27017 -J DROP
```

    -A表示append，就是把规则加到末尾，如果想加到表头可以使用-I

    INPUT就是配置到INPUT这个chain

    -i 就是包进入的网卡，只能在INPUT链中使用,反之-o就是包出去的网卡，只能在OUTPUT链中使用

    -d表示destination,就是**目标网络ip/网域**，如果想匹配**来源Ip/网域**就用-s,但作为服务一般很少限制来源ip

    -d/-s 设定支持一下几种格式:
    IP : 192.168.0.1
    网域: 192.168.0.0/24
    xx之外可以使用 ！表示比如
    -s ! 192.168.0.1表示匹配除192.168.0.1之外的ip

    -p 表示协议，可选的就4种tcp,udp,icmp和all，默认就是all，只有-p等于tcp或udp时才可以使用--dport和--sport

    --dport表示destination port,就是目标端口 很好理解，同理还有--sport

    -J 表示操作，主要有DROP(丢弃),ACCEPT(接受),REJECT(拒绝)和LOG(记录)


**DROP和REJECT的区别**

REJECT就是你请求过来时会告诉你拒绝消息，而DROP就是你请求过来时直接把包删掉


**预设策略**

当封包没有被链中的规则匹配时就会被预设策略匹配

预设策略有3种，分别对应3条链,我的服务器的预设策略是这样配置的

```bash
iptables -P INPUT   DROP
iptables -P OUTPUT  ACCEPT
iptables -P FORWARD ACCEPT
```

- nat表也有预设策略但用的很少就不说明了

**总结一下iptables filter的用法**

```bash
iptables [-A|-I INPUT|FILTER|OUTPUT ] [-i|-o 网络接口 ] [-s 源ip或网域] [-p tcp|udp [--sport 端口号或端口范围] [--dport 端口号或端口范围] all|icmp] [-d 目标ip或网域] <-j ACCEPT|DROP|REJECT|LOG >

# 预设策略的配置
iptables -P <INPUT|OUTPUT|FORWARD> <ACCEPT|DROP>
```

PS:filter中还有[-m 外挂模组]对包的内容做进一步匹配和筛选

---




### nat

先介绍一下nat表的三个链表

```bash
PREROUTING：在进行路由判断之前所要进行的规则(DNAT/REDIRECT)
POSTROUTING：在进行路由判断之后所要进行的规则(SNAT/MASQUERADE)
OUTPUT：與發送出去的封包有關
```

说道nat大家应该不会陌生，比如路由器的内网转外网用到的就是SNAT，而docker容器的端口转换用的就是DNAT


iptables的nat表除了SNAT和DNAT外还可以进行路由，ip选择


下面会介绍几种常用的配置方法

**SNAT**

```bash
iptables -t nat -A POSTROUTING -s 172.19.0.0/16 ! -o docker0 -j MASQUERADE
```

该命令就是把所有源地址属于172.17.0.0/16网段, 目标接口不是docker0的数据包进行伪装


- docker启动后会为所有network网段增加SNAT

**SNAT+ip选择**

假设你有好几个ip，你想选择192.168.1.210作为172.19.0.0/16网段的出口ip可以这样写


```bash
iptables -t nat -A POSTROUTING -s 172.19.0.0/16 ! -o docker0 -j MASQUERADE --to-source 192.168.1.210

# --to-source也可以指定一定范围内的ip比如192.168.1.210-192.168.1.211
```



**DNAT**

```bash
-A PREROUTING ! -i docker0 -p tcp -m tcp --dport 80 -j DNAT --to-destination 172.17.0.3:80
```

该命令就是把本地的80端口和172.17.0.3的80端口进行绑定，所有源接口不是docker0的数据包都会进行DNAT然后传给172.19.0.3:80


- 在docker run中用-p绑定了本地端口后，会自动增加上面一项

**总结一下NAT的用法**

```bash
iptables -t nat [-A|-I POSTROUTING] [--to-source ip或网域]  <-j MASQUERADE>

iptables -t nat [-A|-I PREROUTING] [--to-destination ip或网域]  <-j MASQUERADE>

# filter和nat通用参数:
[-i|-o 网络接口 ] [-s 源ip或网域] [-p tcp|udp [--sport 端口号或端口范围] [--dport 端口号或端口范围] all|icmp] [-d 目标ip或网域]
```

### 参考资料

[鳥哥私房菜 第九章 防火牆與 NAT 伺服器](http://linux.vbird.org/linux_server/0250simple_firewall.php)
