+++
Categories = [
  "Develop",
  "Golang",
]
menu = "main"
Description = "go compile debug，查看为何无法拉取太大的go包"
Tags = [
  "开发",
  "Go语言",
]
date = "2019-09-23T16:58:00+08:00"
title = "go module无法拉取库的原因排查"
+++

有个同事问我go module突然无法拉取他写的某个库了，报了个以下错误，而且他说昨天还能拉，今天突然不行了，并且不久前又刚好重启过gitlab服务器，所以想确认是不是gitlab某些配置改了


```
package xxx.internel.io/lib/with-lfs: unknown import path "xxx.internel.io/lib/with-lfs": downloaded zip file too large
```


在多方信息干扰下我先从gitlab查起，当然比较竟然叫 `go module无法拉取库的原因排查`,问题自然不在这，在我确保gitlab的配置和重启前完全一致后,并且排除了git lfs导致的问题，我把怀疑目标移到了go module上


在一番google我找到了 [issue](https://github.com/golang/go/issues/29987) 应该就是对应这个问题的，但一直没有close,看来是没解决


但我不甘心，好歹找到问题了，如果得到的答案是无法解决这半天时间岂不是浪费了，于是乎我开始查看go源码，找到`downloaded zip file too large`关键字对应的行

<!--more-->

```bash
$ cd $GOROOT
$ grep -I  -r -n "downloaded zip file too large"
src/cmd/go/internal/modfetch/proxy.go:396:		return p.versionError(version, fmt.Errorf("downloaded zip file too large"))
src/cmd/go/internal/modfetch/coderepo.go:807:		return fmt.Errorf("downloaded zip file too large")
```

找到后就好办了，首先使用`dlv` debug看看

```bash
# 编译go之前把go module关掉
$ export GO111MODULE=off
$ go build -gcflags "all=-N -l" -o debug-go $GOROOT/src/cmd/go
# 打开go module保证go使用module拉取项目
$ export GO111MODULE=on
$ dlv exec -- ./debug-go get xxx.internel.io/lib/with-lfs
# 进入交互模式，打好断点就可以跑了
(dlv) break src/cmd/go/internal/modfetch/proxy.go:396
(dlv) break src/cmd/go/internal/modfetch/coderepo.go:807
(dlv) continue
```

等待到达错误断点然后开始debug就好了


也可以使用一些IDE，比如goland,这样可以得到比较好的交互体验，因为我懒得截图，所以就用命令行来说明

```
go: xxx.internel.io/lib/with-lfs v0.2.6
> cmd/go/internal/modfetch.(*codeRepo).Zip() /home/benjamin/.go/src/cmd/go/internal/modfetch/coderepo.go:807 (hits goroutine(47):1 total:1) (PC: 0xa97844)
   802:			dl.Close()
   803:			return err
   804:		}
   805:		dl.Close()
   806:		if lr.N <= 0 {
=> 807:			return fmt.Errorf("downloaded zip file too large")
   808:		}
   809:		size := (maxSize + 1) - lr.N
   810:		if _, err := f.Seek(0, 0); err != nil {
   811:			return err
   812:		}
```

我们跳过debug步骤，直接来说结论吧，go module 拉取项目全部逻辑


通过 在 `src/cmd/go/internal/modfetch/codehost/codehost.go:253` 打断点就可以看到go执行的所以exec

1. 初始化项目 

```
src/cmd/go/internal/modfetch/codehost/git.go:76
# 其中hash值就是 sha256.Sum256([]byte("git3:https://xxx.internel.io/lib/with-lfs")
cd $GOPATH/pkg/mod/cache/vcs/0f8908983e14c7e04862deff0f8df25b0a3477a4a53e91555891b8518004664d
git init --bare 
git remote add origin -- https://xxx.internel.io/lib/with-lfs
```

2. 列出所有git 远程分支名，用一套规则匹配最合适的tag

```
git tag -l
git ls-remote -q origin 
```

3. 检查本地对应tag的分支存不存在，不存在则从远端拉取

```
git -c log.showsignature=false log -m --format="format:%H %ct %D"  bf4fcb5a15f71ba8c5d50de10604048331ae94df --
git fetch -f --depth=1 origin refs/tags/v0.2.6:refs/tags/v0.2.6
```

4. 再次查询tag信息

```
git -c log.showsignature=false log -n1 --format="format:%H %ct %D" refs/tags/v0.2.6 --
```

5. 查看该tag的`go.mod`文件

```
git cat-file blob bf4fcb5a15f71ba8c5d50de10604048331ae94df:go.mod
```

6. 把该分支整个打成zip包并解压(这一步git lfs才会真实下载需要的大文件),因为该Run函数执行的命令行返回值直接缓存到[]byte里，而不是一个Reader，于是乎相当于你的库有多大，该进程就得占多少内存

```
git -c core.autocrlf=input -c core.eol=lf archive --format=zip --prefix=prefix/ bf4fcb5a15f71ba8c5d50de10604048331ae94df
```

7. 在TempDir下创建一个`go-codehost-`前缀的文件并把刚刚的zip内容拷过去，当字节数大于`codehost.MaxZipFile`时报错

该代码在src/cmd/go/internal/modfetch/coderepo.go:781-804

8. 将zip文件解压放入`$GOPATH/pkg/mod/cache/download`对应的项目目录

该代码地址src/cmd/go/internal/modfetch/coderepo.go:820

### 解决方案

好了，目前的问题就出在第7步这里，当文件大于`codehost.MaxZipFile`时，就会报错导致无法下载，所以解决方案嘛，就是加大codehost.MaxZipFile的值，我真机智


首先将$GOROOT下面的代码拷贝到一个安全目录

    cp -r $GOROOT /tmp/custom-go

然后修改$GOROOT到安全目录去

    export GOROOT=/tmp/custom-go

进入新目录对应的cmd/go 目录

    cd /tmp/custom-go/src/cmd/go

修改codehost.MaxZipFile到一个合适的值

    vim internal/modfetch/codehost/codehost.go
    // edit 31 line MaxZipFile

重新build go 

    go build -o custom-go .

然后使用这个custom-go去拉包就行了


### 吐槽


看过源码，感觉go module这一块实现的很不好，首先在步骤6一定会把zip包写入内存，也就是说你限制只是针对拉下来后的包，不会减少进程内存使用，`func (r *gitRepo) ReadZip(rev, subdir string, maxSize int64)` 的maxSize也没有使用


所以我才大胆改了`codehost.MaxZipFile`,这个值目前作用不大，但是还是不建议大家改go源码，到时候出问题就坑了，而且go的包这么大本来就不对




