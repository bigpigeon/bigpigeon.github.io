+++
Categories = [
  "Develop",
  "Golang",
  "kubernetes",
]
menu = "main"
Description = "通过k8s的crd实现一个节点本地服务"
Tags = [
  "开发",
  "Go语言",
]
date = "2020-05-21T12:07:00+08:00"
title = "实现一个k8s的节点本地服务"
+++

k8s的service实体的路由规则太简单，无法设置路由节点信息，于是我通过crd扩展一个LocalService的种类来控制节点的路由


它的结构如下,创建LocalService会创建对应的节点service,通过`服务名-节点名`就可以很方便的路由到该节点的上

```
demo-service(kind:LocalService)
  \- demo-service-node1(kind:service)
  \- demo-service-node2(kind:service)
  ...
```

<!--more-->

如何扩展k8s可以看[extend-cluster](https://kubernetes.io/zh/docs/concepts/extend-kubernetes/extend-cluster/),下面开始讲解


先来看下目录结构，这个目录是依照sample-controller来改的

### 项目结构


```
├── artifacts 
│   └── examples // k8s的资源
│       ├── crd.yaml    //custom resource definition 资源
│       └── example-foo.yaml // LocalService 资源
├── controller.go // LocalService controller模块,根据LocalService生成service
├── pod_controller.go // pod controller模块,用于帮pod增加node信息label
├── hack          // 生成器工具
│   ├── boilerplate.go.txt
│   ├── custom-boilerplate.go.txt
│   ├── tools.go
│   ├── update-codegen.sh
│   └── verify-codegen.sh
├── main.go // main入口
├── pkg // k8s资源代码
│   ├── apis 
│   │   └── localservice_controller // LocalService自定义的crd类型
│   │       ├── register.go
│   │       └── v1alpha1
│   │           ├── doc.go
│   │           ├── register.go 
│   │           ├── types.go       // LocalService实体相关类型信息
│   │           └── zz_generated.deepcopy.go // update-codegen.sh生成相关类型的拷贝方法
│   ├── generated //生产的代码
│   │   ├── clientset // LocalService的客户端api，所有对该资源的操作都可以通过这个api
│   │   ├── informers // LocalService的资源查看，因为该库会缓存LocalService的资源，所以更效率并且不占用apiserver资源
│   │   └── listers   // 为informers提供list和get方法
│   └── signals // 退出信号的控制
│       ├── signal.go
│       ├── signal_posix.go
│       └── signal_windows.go
```

### apis准备

k8s有一套生成工具可以生成一系列辅助函数，我们只需要把crd的数据类型定义好，注册到scheme.AddKnownTypes中


生成代码之前注意以下几点

- 拉取的项目必须放到$GOPATH/src下，并且项目路径必须和项目地址路径相匹配
- pkg/apis/localservice_controller/v1alpha1/register.go下的SchemeGroupVersion决定apiVersion信息
- 非go module模式请将k8s.io/code-generator项目拷贝到项目根目录下


首先 定义LocalService相关类型，LocalService和LocalServiceList上面必须有 `+k8s:deepcopy-gen:interfaces=k8s.io/apimachinery/pkg/runtime.Object` 不然生产的代码会缺少`DeepCopyObject` 方法


[types.go代码](https://github.com/bigpigeon/local-service-controller/blob/master/pkg/apis/localservice_controller/v1alpha1/types.go)


注册到scheme中

[register.go代码](https://github.com/bigpigeon/local-service-controller/blob/master/pkg/apis/localservice_controller/v1alpha1/register.go)

修改完成执行update-codegen.sh生产相关代码

```bash
$ ./hack/update-codegen.sh
...

```

### 创建controller

controller能做许多不同的事情，但是它们都是通过api-server监听资源变更，修改/增加对应资源,将资源实际状态调整为其期望状态


默认操作流程:

- 通过informer().AddEventHandler增加相应资源的监听函数，informer会监听特定类型资源的变更事件
- 在监听函数中对资源进行筛选，将匹配的资源的key放入workqueue队列
- worker从队列获取task交给实际的syncHandler函数处理
- syncHandler开始处理task
- 任务完成后修改资源status,并增加相应的event
- task处理成功调用会调用`workqueue.Forget(obj)`，否则任务会重新回到队列中
- worker调用`workqueue.Done(obj)`释放对该任务的占用，无论成功与否该函数都会被调用


了解流程后再来看看`controller.go`的代码

[controller.go](https://github.com/bigpigeon/local-service-controller/blob/master/controller.go)


*这代码看似很多，其实做的事情很简单，分为以下部分*

创建controller并开始
  
- NewController-> Controller.Run


监听LocalService资源

- 创建对localService的监听，触发controller.enqueueLocalServer回调函数
- 将任务放入Controller.workqueue队列
- processNextWorkItem获取任务并调用syncHandler处理任务
- 找出所有k8s的Node和属于该LocalService的Service资源
- 匹配Service和Node，对缺失的Node创建Service，删除不存在的node上的Service
- 创建一个Event
- task处理成功调用会调用`workqueue.Forget(obj)`，否则任务会重新回到队列中
- worker调用`workqueue.Done(obj)`释放对该任务的占用，无论成功与否该函数都会被调用


### 创建pod-controller

因为Service只能通过label来匹配pod，于是我们需要创建一个pod-controller，将pod的`Spec.NodeName`同步到Labels

[pod_controller.go](https://github.com/bigpigeon/local-service-controller/blob/master/pod_controller.go)


### main函数

main函数做了以下几件事情

- 需要处理退出信号
- 初始化资源的clientset
- 初始化资源的informer
- 启动controller

所有工作准备完成，可以启动controller了

### 创建Crd资源，并启动服务

如果我们现在启动服务则会得到`Failed to list *v1alpha1.LocalService: the server could not find the requested resource`错误信息，这是因为k8s 的api-server还不知道该资源是什么，我们需要创建一个crd来告诉k8s apiserver

    kubectl create -f artifacts/examples/crd.yaml


这里需要注意：

- crd声明的资源类型`spec.names.kind`必须对应go里面定义的类型`pkg/apis/localservice_controller/v1alpha1/types.go.LocalService`,所以这里只能是LocalService，如果想修改kind名，注册的时候用`scheme.AddKnownTypeWithName`方法

启动controller
    go build .
    ./local-service-controller -kubeconfig=your/kubernetes/config

### 创建LocalService验证controller

创建LocalService和Deployments

    kubectl create -f artifacts/examples/example.yaml

等待一段k8s创建完成,查看各个资源
  
    kubectl get LocalService 

    kubectl get service -l owner

    kubectl get pod -l kind=localservice-app
    kubectl get pod -l vm/rack=k8s03

连接到k8s环境，使用curl调用服务(你可以用kube-vpn或者kubectl exec连如该k8s环境)

    curl http://localservice-app-k8s03:8080

你将看到，这消息永远来自k8s03节点

    hello  this message from mylocalservice-app-586ffc555f-dgfp8/k8s03

### 附录

local-service-controller项目地址: https://github.com/bigpigeon/local-service-controller