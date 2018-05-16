+++
title = "线程安全"
+++

如果你准守一下协定可以保证使用toyorm时的线程安全

1. 确保 **ToyBrick** 对象是只读的, 如果你想修改它，创建一个新的

2. 不要使用 **append** 去改变 **ToyBrick**中的slice字段,使用 **make** 和 **copy** 函数去克隆一个新的slice