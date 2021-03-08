+++
Tags = [
  "monitor",
  "grafana",
  "prometheus",
]
Categories = [
  "监控",
]
menu = "main"
Description = ""
date = "2020-02-24T10:39:00+08:00"
title = "prometheus介绍"
+++

普罗米休斯是目前非常流行的监控解决方案，他提供了一个非常好用的监控api规范和告警方法,以下是prometheus的特性

- Dimensional data, prometheus基于时间序列存储数据
- Powerful queries, prometheus提供了一种PromQL的查询语言，使用户可以很方便汇总数据
- Great visualization, 通过grafana实现强大的可视化功能， Grafana 2.5.0 (2015-10-28)开始支持prometheus的语法查询
- Efficient storage, Prometheus包含一个存储在磁盘的本地数据库，但也整合了远程存储系统作为可选项
- Simple operation, Prometheus可通过命令行参数和配置文件来配置它，命令行参数配置一些不变的系统参数，而配置文件则定义所有和爬取相关的任务
- Precise alerting, 告警规则允许你基于prometheus的表达式来定义告警条件，然后发送关于火警通知到额外的服务，每当告警表达式在给定时间点生成一个或多个矢量时，对应标签的告警计数将为对应的成员响应
- Many client libraries, 在你监控你的服务之前，你需要通过prometheus客户端库增加指标到你的代码中，它们实现了prometheus的所有指标类型
- Many integrations, 有许多库和服务将第三方系统中的现有指标导出为prometheus指标，这对无法直接使用prometheus指标来检测给定系统的情况很有用(例如HAProxy或者Linux操作系统统计信息)


<!--more-->

# 一个简单的例子

下面我们通过结合prometheus服务和go客户端来实现一个简单的监控方案

### 安装和使用prometheus

你可以通过官方源下载到最新的prometheus https://prometheus.io/download ，我这个例子用的是 `2.16.0 / 2020-02-13`版本

    wget https://github.com/prometheus/prometheus/releases/download/v2.16.0/prometheus-2.16.0.linux-amd64.tar.gz && tar -xf prometheus-2.16.0.linux-amd64.tar.gz
    cd prometheus-2.16.0.linux-amd64 
    ./prometheus --config.file prometheus.yml


访问 http://localhost:9090 即可通过webui访问prometheus了,



我们再来看看默认prometheus.yml写了什么,


- global.scrape_interval 表示爬取各个监控metrics的间隔，默认是15秒
- global.evaluation_interval 表示告警分析间隔
- global.scrape_timeout 表示爬去指标的超时时间
- scrape_configs 定义各种爬取任务，默认的带的prometheus-example 就是对自己监控指标的爬取


```
global:
  scrape_interval:     15s # Set the scrape interval to every 15 seconds. Default is every 1 minute.
  evaluation_interval: 15s # Evaluate rules every 15 seconds. The default is every 1 minute.
  # scrape_timeout is set to the global default (10s).

//...

scrape_configs:
  # The job name is added as a label `job=<job_name>` to any timeseries scraped from this config.
  - job_name: 'prometheus-example'

    # metrics_path defaults to '/metrics'
    # scheme defaults to 'http'.

    static_configs:
    - targets: ['localhost:9090']
```




### 启动一个go服务并导出prometheus指标

这里使用 `v1.4.1`版本的 github.com/prometheus/client_golang


以下是一个只带有一个opsProcessed的Counter指标的服务，opsProcessed每2秒增加1

go.mod

```
module github.com/bigpigeon/Test/go/prometheus_example_http

go 1.13

require (
	github.com/prometheus/client_golang v1.4.1
	github.com/prometheus/common v0.9.1
)

```

main.go

```
package main

import (
	"github.com/prometheus/common/expfmt"
	"net/http"
	"time"

	"github.com/prometheus/client_golang/prometheus"
)

func recordMetrics(opsProcessed prometheus.Counter) {
	go func() {
		for {
			opsProcessed.Inc()
			time.Sleep(2 * time.Second)
		}
	}()
}

func main() {
	reg := prometheus.NewRegistry()
	opsProcessed := prometheus.NewCounter(prometheus.CounterOpts{
		Namespace: "bigpigeon",
		Subsystem: "test",
		Name:      "processed_test",
		Help:      "The total number of processed events",
	})

	reg.MustRegister(opsProcessed)

	recordMetrics(opsProcessed)

	http.HandleFunc("/metrics", func(writer http.ResponseWriter, request *http.Request) {
		mfs, err := reg.Gather()
		if err != nil {
			panic(err)
		}
		for _, mf := range mfs {
			if _, err := expfmt.MetricFamilyToText(writer, mf); err != nil {
				if err != nil {
					panic(err)
				}
			}
		}
	})
	http.ListenAndServe(":19090", nil)
}
```

然后在prometheus增加以下job

```
  - job_name: "processed-example"
    static_configs:
    - targets: ['localhost:19090']
```

通过SIGHUB信号reload prometheus

    killall -SIGHUP ./prometheus


然后就可以在 prometheus的webui中的query 中输入bigpigeon_test_processed_test来查看结果


### prometheus基础


在prometheus表达式语法中，一个表达式或者子表达式可以是以下4个类型

- Instant vector: 每个Value包含一个数据样本和一个时间戳
- Range vector: 每个Value包含一组 数据样本和时间戳
- Scalar: 一个简单的浮点数
- String: 一个简单的字符串，目前没被使用

只有Instant vector是可以直接绘图的

##### String literals

e.g:

```
"this is a string"
'these are unescaped: \n \\ \t'
`these are not unescaped: \n ' " \t`
```

##### Float literals

浮点数可以写成以下形式: [-](digits)[.(digits)]

e.g:

```
-2.43
```

##### vector selectors

瞬时向量选择器就是一定时间范围的数据集


例如之前在Query输入的`bigpigeon_test_processed_test`返回的就是瞬时向量，当然你也可以加入属性过滤，比如

```
bigpigeon_test_processed_test{job="processed-example"}
```


job属性就是在prometheus的config中定义的job_name


如果你想查看范围向量，只需要在Query中输入`bigpigeon_test_processed_test[5m]`即可


这样返回的数据就会以每5分钟一组的格式返回，m表示分钟，当然你也可以用秒(s)，小时(h)等单位

```
s - seconds
m - minutes
h - hours
d - days
w - weeks
y - years
```


##### Offset modifier

`offset` 可以更改瞬时向量和范围向量的时间偏移量


一下查询查出来的是5分钟前的收集记录

```
bigpigeon_test_processed_test offset 5m
```

### prometheus操作

prometheus的查询支持基本逻辑和算法操作，

##### 算数二元操作符

下面是二元操作符可存在于prometheus中

```
+ (addition)
- (subtraction)
* (multiplication)
/ (division)
% (modulo)
^ (power/exponentiation)
```

二元算法操作符支持 scalar/scalar, vector/scalar, and vector/vector 这几种组合

- scalar/scalar
- instant vector/scalar 这个操作让instant vector中所有数据样本对scaler进行运算
- instant vector/instant vector 2个向量的成员必须完全匹配，有一边的成员不匹配，对应的指标名将从结果中去除，不在右边的条目将被删除

##### 比对二元操作符

prometheus支持以下操作符

```
== (equal)
!= (not-equal)
> (greater-than)
< (less-than)
>= (greater-or-equal)
<= (less-or-equal)
```

比对操作符支持 scalar/scalar, vector/scalar, and vector/vector 这几种组合


默认用作结果过滤

比如以下查询结果则会返回空，因为1分钟前的指标不可能大于当前指标

```
bigpigeon_test_processed_test < (bigpigeon_test_processed_test offset 1m)
```


##### 逻辑二元操作符

逻辑操作符只能在 2个 instant vectors之间使用


- vector1 and vector2 返回所有成员与vector2匹配的vector1向量
- vector1 and vector2 列出vector1和vector2匹配的所有向量
- vector1 unless vector2 TODO， 目前不明，测试结果和说明不符

##### 向量匹配

可以限定需要匹配的向量


