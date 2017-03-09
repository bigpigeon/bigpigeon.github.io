+++
Categories = [
  "Develop",
  "git",
]
menu = "main"
Description = ""
Tags = [
  "开发",
]
date = "2017-03-09T09:44:00+08:00"
title = "git错误push与回滚"
+++

之前看漏眼把一个zip的文件commit了,然后我又不小心push到远程gitlab上,导致项目直接大了10M。于是我查了下git的资料，发现可以用删除分支来解决这个问题,下面我来讲讲做法

<!--more-->
### 本地处理


首先需要把checkout到错误分支的前一个分支(假设我的分支名为bate)

    git checkout bate^

然后checkout到新的分支上,并把正确的文件提交过来

    git checkout -b bate-recover
    git checkout bate - file.xx
    ...

然后删除bate分支并提交,因为bate分支没合并所以需要强制删除，

    git branch -D bate
    git push origin bate --delete

最后把bate-recover分支checkout到bate上再提交，完成！！！

    git checkout -b bate
    git push origin bate


### 已pull项目处理

如果某个服务器不小心pull了这个带zip文件的分支同样需要删除分支:


    # 首先checkout到其他分支
    git checkout master
    # 删除bate分支
    git branch -D bate
    # 重新pull bate分支
    git pull origin bate
