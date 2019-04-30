+++
Categories = [
  "Deployment",
  "Golang",
]
menu = "main"
Description = "kubernetes官方部署方案踩坑记录"
Tags = [
  "开发",
  "Go语言",
]
date = "2019-04-30T11:47:00+08:00"
title = "kubernetes官方kubeadm部署笔记"
+++

老的k8s环境太乱，而且版本太老，但因为历史原因无法更新，于是我觉得在新的测试服部署一台新的k8s集群，并把所有服务慢慢迁移到新集群来


这里做一个k8s部署(踩坑)笔记

<!--more-->
## 准备阶段

#### 3台机器

需要准备至少3台机器，我这里用的是[virsh](https://linux.die.net/man/1/virsh)虚拟出3台ubuntu-18.04

这是我其中一台机器的配置，其他机器也是类似配置

```xml
<domain type='kvm' id='1'>
  <name>k8s-01</name>
  <uuid>eec00f24-7b85-4032-93c8-121d1abd5ee9</uuid>
  <memory unit='KiB'>8388608</memory>
  <currentMemory unit='KiB'>8388608</currentMemory>
  <vcpu placement='static'>8</vcpu>
  <resource>
    <partition>/machine</partition>
  </resource>
  <os>
    <type arch='x86_64' machine='pc-i440fx-xenial'>hvm</type>
  </os>
  <features>
    <acpi/>
    <apic/>
  </features>
  <clock offset='utc'>
    <timer name='rtc' tickpolicy='catchup'/>
    <timer name='pit' tickpolicy='delay'/>
    <timer name='hpet' present='no'/>
  </clock>
  <on_poweroff>destroy</on_poweroff>
  <on_reboot>restart</on_reboot>
  <on_crash>restart</on_crash>
  <pm>
    <suspend-to-mem enabled='no'/>
    <suspend-to-disk enabled='no'/>
  </pm>
  <devices>
    <emulator>/usr/bin/kvm-spice</emulator>
    <disk type='block' device='disk'>
      <driver name='qemu' type='raw'/>
      <source dev='/dev/sdb2'/>
      <backingStore/>
      <target dev='vdb' bus='virtio'/>
      <boot order='1'/>
      <alias name='virtio-disk1'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x06' function='0x0'/>
    </disk>
    <disk type='file' device='cdrom'>
      <driver name='qemu' type='raw'/>
      <source file='/home/speakin/ubuntu-18.04.2-live-server-amd64.iso'/>
      <backingStore/>
      <target dev='hda' bus='ide'/>
      <readonly/>
      <alias name='ide0-0-0'/>
      <address type='drive' controller='0' bus='0' target='0' unit='0'/>
    </disk>
    <controller type='pci' index='0' model='pci-root'>
      <alias name='pci.0'/>
    </controller>
    <controller type='ide' index='0'>
      <alias name='ide'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x01' function='0x1'/>
    </controller>
    <controller type='virtio-serial' index='0'>
      <alias name='virtio-serial0'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x05' function='0x0'/>
    </controller>
    <controller type='usb' index='0'>
      <alias name='usb'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x01' function='0x2'/>
    </controller>
    <interface type='bridge'>
      <mac address='52:54:00:e7:53:84'/>
      <source bridge='br0'/>
      <target dev='vnet0'/>
      <model type='virtio'/>
      <alias name='net0'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x03' function='0x0'/>
    </interface>
    <serial type='pty'>
      <source path='/dev/pts/0'/>
      <target port='0'/>
      <alias name='serial0'/>
    </serial>
    <console type='pty' tty='/dev/pts/0'>
      <source path='/dev/pts/0'/>
      <target type='serial' port='0'/>
      <alias name='serial0'/>
    </console>
    <channel type='spicevmc'>
      <target type='virtio' name='com.redhat.spice.0' state='disconnected'/>
      <alias name='channel0'/>
      <address type='virtio-serial' controller='0' bus='0' port='1'/>
    </channel>
    <input type='mouse' bus='ps2'/>
    <input type='keyboard' bus='ps2'/>
    <graphics type='spice' port='5900' autoport='yes' listen='127.0.0.1'>
      <listen type='address' address='127.0.0.1'/>
    </graphics>
    <graphics type='vnc' port='5901' autoport='yes' listen='127.0.0.1'>
      <listen type='address' address='127.0.0.1'/>
    </graphics>
    <sound model='ich6'>
      <alias name='sound0'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x04' function='0x0'/>
    </sound>
    <video>
      <model type='qxl' ram='65536' vram='65536' vgamem='16384' heads='1'/>
      <alias name='video0'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x0'/>
    </video>
    <redirdev bus='usb' type='spicevmc'>
      <alias name='redir0'/>
    </redirdev>
    <redirdev bus='usb' type='spicevmc'>
      <alias name='redir1'/>
    </redirdev>
    <memballoon model='virtio'>
      <alias name='balloon0'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x08' function='0x0'/>
    </memballoon>
  </devices>
  <seclabel type='dynamic' model='apparmor' relabel='yes'>
    <label>libvirt-eec00f24-7b85-4032-93c8-121d1abd5ee9</label>
    <imagelabel>libvirt-eec00f24-7b85-4032-93c8-121d1abd5ee9</imagelabel>
  </seclabel>
</domain>
```

#### 一个vpn用来科学上网

部署k8s最好用vpn而不是代理，因为k8s里面很多工具可能使用的代理方式都不一样，而且有些命令是在docker里面跑的，你还得跑进去配置


vpn要确保网段不与k8s的网段冲突


## 部署master机器

#### 使用docker作为k8s的cri

以下代码都是照抄k8s官网,只把docker的**"exec-opts": ["native.cgroupdriver=systemd"],** 改成 **"exec-opts": ["native.cgroupdriver=cgroupfs"],**

```bash
# Install Docker CE
## Set up the repository:
### Install packages to allow apt to use a repository over HTTPS
apt-get update && apt-get install apt-transport-https ca-certificates curl software-properties-common

### Add Docker’s official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -

### Add Docker apt repository.
add-apt-repository \
  "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) \
  stable"

## Install Docker CE.
apt-get update && apt-get install docker-ce=18.06.2~ce~3-0~ubuntu

# Setup daemon.
cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=cgroupfs"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

mkdir -p /etc/systemd/system/docker.service.d

# Restart docker.
systemctl daemon-reload
systemctl restart docker
```

#### 安装k8s三件套

```bash
apt-get update && apt-get install -y apt-transport-https curl
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
apt-get update
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl
```

#### 修改kubelet的Env参数

这里使用cgroupfs是 因为这个 issue <https://github.com/kubernetes/kubernetes/issues/71887>

```bash
cat > /var/lib/kubelet/kubeadm-flags.env <<EOF
KUBELET_KUBEADM_ARGS=--cgroup-driver=cgroupfs --network-plugin=cni --resolv-conf=/run/systemd/resolve/resolv.conf
EOF

cat > /etc/default/kubelet <<EOF
KUBELET_EXTRA_ARGS=--cgroup-driver=cgroupfs
EOF
```

#### 使用kubeadm初始化master节点

因为我们用flannel作为我们的cni，所以要指定一个network-cidr

    kubeadm init --pod-network-cidr=10.244.0.0/16

#### 配置kubectl

参照官方文档，只要吧/etc/kubernetes/admin.conf放到你机器对应的$HOME/.kube/config 目录,kubectl就能连上k8s了


多个k8s,也可以使用kubectl --kubeconfig config 指定对应k8s

```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

#### 使用kubectl 安装flannel

k8s必须在部署app之前安装cni，不然k8s的网络和dns无法使用

    kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/a70459be0084506e4ec919aa1c114638878db11b/Documentation/kube-flannel.yml

等待安装完成


#### 使用kubectl 安装dashboard

安装 dashboard

    kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v1.10.1/src/deploy/recommended/kubernetes-dashboard.yaml

通过kubelet创建service account 

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kube-system
```

创建cluster role binding 绑定admin-user

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kube-system
```

获取登录授权token

    kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep admin-user | awk '{print $1}')

使用proxy代理k8s

     kubectl proxy

在浏览器访问dashboard,在里面使用token登录

    http://localhost:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy

#### 创建一个k8s的token

每个k8s cluster要加入master都需要创建一个token，可以使用下面命令创建

    kubeadm token create
    // 5didvk.d09sbcov8ph2amjw 

可以通过下面命令查看已有的token

    kubeadm token list

#### 查看ca证书的hash值

cluster机器加入时需要该值

    openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //'

## 部署cluster机器

cluster机器比较简单，只需要安装docker和k8s三件套，然后使用token加入master即可

- [安装docker](#使用docker作为k8s的cri)
- [安装k8s三件套](#安装k8s三件套)

#### 加入k8s master节点

加入节点需要一个刚才在master的token和ca证书hash值，**master-port**默认是6443

    kubeadm join <master-ip>:<master-port> --token <token> --discovery-token-ca-cert-hash sha256:<hash>


## 重置k8s

如果你在安装k8s过程中某些改动或者网络情况导致不可用，可以使用下面命令，然后重新安装

    kubeadm reset 

