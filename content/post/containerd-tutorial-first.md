+++
Categories = [
  "go",
  "docker",
  "containerd",
]
Description = ""
Tags = [
  "开发",
]
date = "2021-03-08T10:06:00+08:00"
title = "containerd介绍"
+++

# containerd是什么

在这里我用自己的理解总结一下，containerd是一个容器相关功能的管理工具，它上层能对接`cri`和`docker`，下层对接容器执行器，比如`runc`或者 Microsoft的`hcsshim`,中间层支持各种插件扩展，或者说containerd是一个插件集合，它的各个功能都是插件化的，你也可以加载自己的插件来增强containerd的功能

<!--more-->

# 启动containerd

首先需要启动containerd的daemon程序

首先，去github下载最新的containerd [https://github.com/containerd/containerd/releases](https://github.com/containerd/containerd/releases),当然你也可以通过系统包管理直接安装，但我还是推荐官网下二进制的方式，因为这样你能尽早下载到最新的包使用最新的功能，其次了解containerd的运行原理，了解它的各个组件的用途

下载后吧相关二进制放到/usr/local/bin

然后，去github下载最新的runc[https://github.com/opencontainers/runc/releases](https://github.com/opencontainers/runc/releases),同样吧它放到/usr/local/bin 

然后，安装cni和它相关的plugins[https://github.com/containernetworking/cni/tree/master/cnitool](https://github.com/containernetworking/cni/tree/master/cnitool)

#### 使用生成 默认配置文件  /etc/containerd/config.toml

    oom_score = -999

    [debug]
            level = "debug"

    [metrics]
            address = "127.0.0.1:1338"

    [plugins.linux]
            runtime = "runc"
            shim_debug = true

#### 配置systemd的配置文件

    [Unit]
    Description=containerd container runtime
    Documentation=https://containerd.io
    After=network.target

    [Service]
    ExecStartPre=-/sbin/modprobe overlay
    ExecStart=/usr/local/bin/containerd
    Delegate=yes
    KillMode=process

    [Install]
    WantedBy=multi-user.target

这里有2个很重要的选项，`Delegate=yes`和`KillMode=process`，你必须保证它在[Service]段中

`Delegate`允许containerd通过它创建的cgroup来管理容器，如果没有这个选项，systemd将尝试将进程移到containerd的cgroups中

`KillMode`决定containerd的被shutdown时的行为，默认情况下，systemd将查看该服务的cgroups的相关进程，并尝试把它们都杀死，但我们需要的是当更新containerd时，容器不会接收到kill信号影响，当设置`KillMode=process`时，systemd只会杀死daemon进程，其他子进程不受影响

#### 启动containerd

启动并查看containerd

    systemctl start containerd
    systemctl status containerd

# 操作containerd

下面我会通过2种方式，一种是ctr命令行工具，一种是通过gosdk用代码创建，比对一下他们的区别

#### 连接containerd

go code:

    // create a new client connected to the default socket path for containerd
	client, err := containerd.New("/run/containerd/containerd.sock")
	if err != nil {
		return err
	}
	defer client.Close()

	// create a new context with an "example" namespace
	ctx := namespaces.WithNamespace(context.Background(), "example")

ctr command:

    ctr --address /run/containerd/containerd.sock --namespace example # or
    ctr -a /run/containerd/containerd.sock -n example # or
    ctr -n example # ctr默认address就是/run/containerd/containerd.sock，可以不填

#### 拉取镜像

可以理解为`docker pull`，但当拉取docker官方镜像时必须加上`docker.io/library/`前缀

而且containerd可以拉k8s.io的镜像，而docker就不行

go code:

    // pull the redis image from DockerHub
	image, err := client.Pull(ctx, "docker.io/library/redis:alpine", containerd.WithPullUnpack)

ctr: 

    ctr -n example image pull docker.io/library/redis:alpine

#### 创建containers

container把docker的容器创建拆分成 `container`和`task` ，当然你也可以通过 `ctr run` 直接创建并运行容器

go code:

    // create a container
	container, err := client.NewContainer(
		ctx,
		"redis-server",
		containerd.WithImage(image),
		containerd.WithNewSnapshot("redis-server-snapshot", image),
		containerd.WithNewSpec(oci.WithImageConfig(image)),
	)

ctr: 

    ctr -n example containers create   docker.io/library/redis:alpine  redis-server

这2个有一个区别，通过go语言创建的，快照名是`redis-server-snapshot`，而通过工具创建的则和container名一样是`redis-server`，目前没找到命令行工具指定snapshot的方法

#### 创建task

go code:

    // create a task from the container
	task, err := container.NewTask(ctx, cio.NewCreator(cio.WithStdio))
	if err != nil {
		return err
	}

	defer task.Delete(ctx)
    // call start on the task to execute the redis server
	if err := task.Start(ctx); err != nil {
		return err
	}

ctr: 

    ctr -n example task start redis-server

#### 创建额外的process进程

除了容器的主进程，也可以在容器执行额外的进程，相当与docker的exec

通过`ps aux`命令我们可以看到容器内进程和它们之间的关系

go code:
    
    proc, err := task.Exec(ctx, "ps", &specs.Process{
		Terminal:        false,
		Args:            []string{"/bin/ps", "aux"},
		CommandLine:     "ps",
		Cwd:             "/",
		NoNewPrivileges: false,
		ApparmorProfile: "",
		OOMScoreAdj:     nil,
		SelinuxLabel:    "",
	}, cio.NewCreator(cio.WithStdio))
    // error process
	err = proc.Start(ctx)
	// error process

ctr: 

    ctr -n example tasks exec --exec-id ps redis-server ps aux

#### 结尾

现在我们已经知道怎么通过containerd来创建一个redis服务端并使用它，但现在有个问题，我们没法连如该redis，因为它还没有虚拟网卡或者ip地址，下一篇，我们继续讲 cni，从而实现容器网络的配置

