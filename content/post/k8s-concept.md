+++
Description = ""
Tags = [
  "Deployment",
  "golang",
]
Categories = [
  "开发",
]

date = "2020-04-15T18:43:37+08:00"
title = "当在k8s创建一个实体时会发生什么"
+++


### 前置条件

容器: docker


kubernetes: 1.14.2



当在k8s中创建一个deployments,注意kubeapi会通知到每一个controller，多个controll同时对一个deployment增加replicaSet只有一个会成功

```mermaid
sequenceDiagram
  kubectl->kubeapi: 创建一个deployment
  kubeapi->etcd: 持久化这次修改
  kubeapi->kubectl: 告知客户端创建成功
  deploymentController->kubeapi: 获取该deployment，创建对应的replicationSet并绑定该deployment
  replicationSetController->kubeapi: 获取该replicationSet，根据实例数创建pod
  kube_schedule->kubeapi: 获取新的pod，通过权重为它分配节点信息
  kubelet->kubeapi: 获取pod信息，通过cri发送给本地docker，创建container
  kubelet->container: 通知docker创建pod中的container
  kubelet->kubeapi: 收集container状态，更新pod状态
```
<!--more-->


当k8s中创建一个service

```mermaid
sequenceDiagram
  kubectl->kubeapi: 创建一个service
  kubeapi->etcd: 持久化这次修改
  kubeapi->kubectl: 告知客户端创建成功
  endpointController->kubeapi: 获取service更新，更新当前endpoint
  kube-proxy->kubeapi: 获取endpoint信息，根据网络plugin修改规则
```


